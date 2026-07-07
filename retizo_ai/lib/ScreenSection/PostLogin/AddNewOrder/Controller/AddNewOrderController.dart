// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:culai/ScreenSection/PostLogin/AddNewOrder/Model/NoteModel.dart';
import 'package:culai/ScreenSection/PostLogin/AddNewOrder/Model/PaymentStatus.dart';
import 'package:culai/ScreenSection/PostLogin/KDS/Controller/PrinterIntegrationProvider.dart';
import 'package:culai/ScreenSection/PostLogin/Settings/PrintingDeviceProvider.dart';
import 'package:culai/services/printer_models.dart';
import 'package:http/http.dart' as http;

//-✅---------------------------------------------------------------------✅-//
class AddOrderProvider with ChangeNotifier {
  bool isAddOrderLoading = false;

  bool get isAddOrderLoader => isAddOrderLoading;

  void setAddOrderLoading(bool value) {
    if (isAddOrderLoading != value) {
      isAddOrderLoading = value;
      notifyListeners();
    }
  }

  // separate shimmer flag — only for category + menu panels
  bool _isMenuLoading = false;
  bool get isMenuLoading => _isMenuLoading;
  void _setMenuLoading(bool value) {
    if (_isMenuLoading != value) {
      _isMenuLoading = value;
      notifyListeners();
    }
  }

  //--🔹--Search Controller---------------------------------------------🔹--//
  TextEditingController SearchCategoriesController = TextEditingController();
  final FocusNode myFocusNodeCategories = FocusNode();

  TextEditingController SearchMenuController = TextEditingController();
  final FocusNode myFocusNodeMenu = FocusNode();

  TextEditingController OrderNoteController = TextEditingController();
  final FocusNode myFocusNodeOrderNote = FocusNode();

  //--🔹--Categories Listing---------------------------------------------🔹--//
  List<CategoryModel> CategoriesListing = [];
  List<CategoryModel> filteredCategoriesListing = [];

  int get CategoriesCount => filteredCategoriesListing.length;

  Future<void> getCategoriesListService(BuildContext context) async {
    // Reload dropdowns
    CategoriesListing = [];
    filteredCategoriesListing = [];
    if (!context.mounted) return;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final sessionCtrl = Provider.of<SessionProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    try {
      // 🔹 Show loader
      setAddOrderLoading(true);
      _setMenuLoading(true);

      // 🔹 Start HTTP client if not active
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // 🔹 Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        CategoriesListing.clear();
        filteredCategoriesListing.clear();
        setAddOrderLoading(false);
        return;
      }

      // 🔹 API REQUEST
      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url: CategoryListService,
        // ✅ FIX: Use correct endpoint for categories
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // 🔹 Handle invalid or expired session
      if (responseRaw is Map<String, dynamic> &&
          responseRaw.containsKey('success')) {
        final bool success = responseRaw['success'] as bool? ?? false;
        if (!success) {
          await CommonWidget.AlertSessionBottomSheet(context: context);
          setAddOrderLoading(false);
          sessionCtrl.setSessionActive(false);
          return;
        }
      }

      // 🔹 Validate response format
      if (responseRaw is! List) {
        GlobalFunction().showError(context, "Unexpected API response format");
        setAddOrderLoading(false);
        return;
      }

      // 🔹 Clear old data
      CategoriesListing.clear();
      filteredCategoriesListing.clear();

      // 🔹 Convert and map response safely
      final List<Map<String, dynamic>> records = responseRaw
          .whereType<Map<String, dynamic>>()
          .toList();

      if (records.isEmpty) {
        //GlobalFunction().debugFunction("ℹ️ No categories found.");
        setAddOrderLoading(false);
        return;
      }

      // 🔹 Map to CategoryModel
      CategoriesListing = records.map((e) {
        return CategoryModel.fromJson(e);
      }).toList();

      // 🔹 Initially filtered list = all
      filteredCategoriesListing = List.from(CategoriesListing);
      // 🔹 Immediately call BasicAPI after response
      await BasicAPI(context);
      notifyListeners();
    } catch (e, stack) {
      //GlobalFunction().debugFunction("❌ Error fetching Category List: $e");
      debugPrintStack(stackTrace: stack);
      GlobalFunction().showError(context, "Failed to load categories");
    } finally {
      setAddOrderLoading(false);
      _setMenuLoading(false);
    }
  }

  CategoryModel? SelectedCategory;
  int? selectedCategoryIndex;

  void onCategorySelected(int index, CategoryModel category) {
    selectedCategoryIndex = index;
    SelectedCategory = category;

    /*GlobalFunction().debugFunction(
      'Selected Category JSON: ${category.toJson()}',
    );*/
    notifyListeners();
  }

  //--🔹--Menu Listing---------------------------------------------------🔹--//
  List<MenuModel> MenuListing = [];
  List<MenuModel> filteredMenuListing = [];

  int get MenusCount => getFilteredMenuItems().length;

  /// 🔹 Stock map: productId → available quantity (from /products-stock API)
  Map<int, int> productStockMap = {};

  Future<void> getMenuListService(BuildContext context) async {
    MenuListing = [];
    filteredMenuListing = [];
    filteredMenuListing.clear();
    MenuListing.clear();
    if (!context.mounted) return;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    try {
      // 🔹 Show loader
      setAddOrderLoading(true);
      notifyListeners();
      // 🔹 Start HTTP client if not active
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // 🔹 Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        MenuListing.clear();
        filteredMenuListing.clear();
        setAddOrderLoading(false);
        return;
      }

      // 🔹 API REQUEST
      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url: MenuListService,
        // ✅ FIX: Use correct endpoint for categories
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // 🔹 Validate response format
      if (responseRaw is! List) {
        GlobalFunction().showError(context, "Unexpected API response format");
        setAddOrderLoading(false);
        return;
      }

      // 🔹 Clear old data
      MenuListing.clear();
      filteredMenuListing.clear();

      // 🔹 Convert and map response safely
      final List<Map<String, dynamic>> records = responseRaw
          .whereType<Map<String, dynamic>>()
          .toList();

      if (records.isEmpty) {
        // retry once — backend occasionally returns empty on first hit
        await Future.delayed(const Duration(seconds: 2));
        if (!context.mounted) return;
        final dynamic retryRaw = await httpCtrl.request(
          method: 'GET',
          url: MenuListService,
          context: context,
          headers: authHeaders,
          requireLogin: true,
        );
        if (retryRaw is List) {
          final List<Map<String, dynamic>> retryRecords = retryRaw
              .whereType<Map<String, dynamic>>()
              .toList();
          if (retryRecords.isNotEmpty) {
            MenuListing = retryRecords
                .map((e) => MenuModel.fromJson(e))
                .toList();
            filteredMenuListing = selectedCategoryId != null
                ? MenuListing.where(
                    (item) => item.mCatId == selectedCategoryId,
                  ).toList()
                : List.from(MenuListing);
            _setMenuLoading(false);
            notifyListeners();
            await getProductsStockService(context);
          }
        }
        setAddOrderLoading(false);
        return;
      }

      // 🔹 Map to MenuModel
      MenuListing = records.map((e) {
        return MenuModel.fromJson(e);
      }).toList();

      // re-apply any existing category filter
      filteredMenuListing = selectedCategoryId != null
          ? MenuListing.where(
              (item) => item.mCatId == selectedCategoryId,
            ).toList()
          : List.from(MenuListing);

      // hide menu shimmer as soon as data is ready
      _setMenuLoading(false);

      // 🔹 Notify so menu renders immediately
      notifyListeners();

      // 🔹 Fetch stock availability for stock-tracked products (non-blocking)
      await getProductsStockService(context);
    } catch (e, stack) {
      //GlobalFunction().debugFunction("❌ Error fetching Menu List: $e");
      debugPrintStack(stackTrace: stack);
      GlobalFunction().showError(context, "Failed to load Menu");
    } finally {
      setAddOrderLoading(false);
      _setMenuLoading(false);
      notifyListeners();
    }
  }

  //--🔹--getProductsStockService---------------------------------------🔹--//
  /// Fetches stock availability for all items with stockProduct == true.
  /// Populates [productStockMap] (productId → available qty).
  Future<void> getProductsStockService(BuildContext context) async {
    if (!context.mounted) return;

    // Collect only items that have stock tracking enabled
    final stockProductIds = MenuListing.where(
      (m) => m.stockProduct == true && m.mProdId != null,
    ).map((m) => m.mProdId!).toList();

    // Nothing to fetch if no stock-tracked products
    if (stockProductIds.isEmpty) return;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final dynamic responseRaw = await httpCtrl.request(
        method: 'POST',
        url: ProductsStockService,
        context: context,
        headers: authHeaders,
        body: {"product_ids": stockProductIds},
        requireLogin: true,
      );

      if (responseRaw is Map<String, dynamic> &&
          responseRaw['success'] == true) {
        final data = responseRaw['data'];
        if (data is Map<String, dynamic>) {
          productStockMap.clear();
          data.forEach((key, value) {
            final id = int.tryParse(key);
            if (id != null && value is Map<String, dynamic>) {
              final stockData = ProductStockData.fromJson(value);
              productStockMap[id] = stockData.available;
            }
          });
        }
      }
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      // Non-critical: silently fail — stock data is supplementary
    } finally {
      notifyListeners();
    }
  }

  //--🔹--Menu Item Plus-Minus-------------------------------------------🔹--//
  /// 🔹 Map to track quantity per item
  Map<int, int> itemQuantity = {}; // key = mProdId, value = count
  List<Map<String, dynamic>> selectedItems =
      []; // ✅ Array to store all items with quantity

  //--🔹--Modifier Cache-------------------------------------------------🔹--//
  /// productId → fetched modifier mappings (null = not yet fetched, [] = no modifiers)
  final Map<int, List<ModifierMappingItem>> _modifierCache = {};

  // --------------------- Increment Quantity -------------------------------//
  void incrementQuantity(MenuModel item) {
    final id = item.mProdId!;

    itemQuantity[id] = (itemQuantity[id] ?? 0) + 1;

    //  check if existing cart entries for this product have modifier-split
    // entries.If so,don't merge via UpdateSelectedItems (which would collapse
    // all entries and re-use the first entry's modifiers). Instead, find or
    // create a separate "plain" (no modifiers) entry.
    final hasModifierEntries = selectedItems.any(
      (e) =>
          e['m_prod_id'] == id &&
          (e['modifiers'] as List<dynamic>?)?.isNotEmpty == true,
    );

    if (hasModifierEntries) {
      // find existing plain entry (empty or no modifiers)
      final plainIdx = selectedItems.indexWhere(
        (e) =>
            e['m_prod_id'] == id &&
            ((e['modifiers'] as List<dynamic>?)?.isEmpty ?? true),
      );
      if (plainIdx >= 0) {
        // increment existing plain entry
        final current = (selectedItems[plainIdx]['quantity'] as int?) ?? 1;
        selectedItems[plainIdx] = Map<String, dynamic>.from(
          selectedItems[plainIdx],
        )..['quantity'] = current + 1;
      } else {
        // create new plain entry (separate from modifier entries)
        final itemJson = item.toJson();
        itemJson['quantity'] = 1;
        itemJson['modifiers'] = <dynamic>[];
        itemJson['cart_entry_id'] = _generateCartUuid();
        selectedItems.add(itemJson);
      }
    } else {
      // no modifier entries — standard merge behavior
      UpdateSelectedItems(item);
    }

    // Debug print
    printItemWithQuantity(item);
    // ✅ Tax is backend-driven per-item (tax_group) — no order-level dropdown
    calculateTaxAmount();
    updatedDPOrderPaymentMethods(OrderPaymentMethodsListing.first.type);
    notifyListeners();
  }

  // --------------------- Decrement Quantity -------------------------------//
  void decrementQuantity(MenuModel item) {
    final id = item.mProdId!;
    final currentTotal = itemQuantity[id] ?? 0;

    if (currentTotal <= 0) {
      itemQuantity.remove(id);
      selectedItems.removeWhere((e) => e['m_prod_id'] == id);
      calculateTaxAmount();
      updatedDPOrderPaymentMethods(OrderPaymentMethodsListing.first.type);
      notifyListeners();
      return;
    }

    itemQuantity[id] = currentTotal - 1;

    if (itemQuantity[id]! <= 0) {
      itemQuantity.remove(id);
      selectedItems.removeWhere((e) => e['m_prod_id'] == id);
    } else {
      // Decrement the last cart entry for this product.
      // Works correctly for both merged (qty > 1) and split (qty = 1) entries.
      final lastIdx = selectedItems.lastIndexWhere((e) => e['m_prod_id'] == id);
      if (lastIdx >= 0) {
        final currentQty = (selectedItems[lastIdx]['quantity'] as int?) ?? 1;
        if (currentQty <= 1) {
          selectedItems.removeAt(lastIdx);
        } else {
          selectedItems[lastIdx] = Map<String, dynamic>.from(
            selectedItems[lastIdx],
          )..['quantity'] = currentQty - 1;
        }
      }
    }

    if ((itemQuantity[id] ?? 0) > 0) {
      printItemWithQuantity(item);
    }
    // ✅ Tax is backend-driven per-item (tax_group) — no order-level dropdown
    calculateTaxAmount();
    updatedDPOrderPaymentMethods(OrderPaymentMethodsListing.first.type);
    notifyListeners();
  }

  // --------------------- Update Selected Items ----------------------------//
  void UpdateSelectedItems(
    MenuModel item, {
    List<SelectedModifier>? modifiers,
  }) {
    final id = item.mProdId!;
    final quantity = itemQuantity[id] ?? 0;

    // Preserve any existing modifiers if none are passed
    List<dynamic>? existingModifiers;
    final existingIndex = selectedItems.indexWhere((e) => e['m_prod_id'] == id);
    if (existingIndex != -1) {
      existingModifiers =
          selectedItems[existingIndex]['modifiers'] as List<dynamic>?;
    }

    // Remove old entry if exists
    selectedItems.removeWhere((e) => e['m_prod_id'] == id);

    // Add only if quantity > 0
    if (quantity > 0) {
      final itemJson = item.toJson();
      itemJson['quantity'] = quantity;
      // ✅ Attach modifiers: prefer freshly passed ones, fall back to existing
      if (modifiers != null) {
        itemJson['modifiers'] = modifiers.map((m) => m.toJson()).toList();
      } else if (existingModifiers != null && existingModifiers.isNotEmpty) {
        itemJson['modifiers'] = existingModifiers;
      } else {
        itemJson['modifiers'] = <dynamic>[];
      }
      selectedItems.add(itemJson);
    }
  }

  // --------------------- Print Single Item --------------------------------//
  void printItemWithQuantity(MenuModel item) {
    final count = itemQuantity[item.mProdId!] ?? 0;
    final json = item.toJson();
    GlobalFunction().debugFunction("Item JSON: $json, Quantity: $count");
  }

  // --------------------- Get Selected Items -------------------------------//
  List<Map<String, dynamic>> getSelectedItems() {
    return List.from(selectedItems); // return copy
  }

  //--🔹--Modifier Service----------------------------------------------🔹--//
  /// Fetches and caches modifiers for [productId].
  /// Returns the list (empty if no modifiers / API error).
  Future<List<ModifierMappingItem>> getModifiersForProduct(
    BuildContext context,
    int productId,
  ) async {
    // Return cached result immediately (avoids duplicate calls)
    if (_modifierCache.containsKey(productId)) {
      return _modifierCache[productId]!;
    }

    if (!context.mounted) return [];

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? '';
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _modifierCache[productId] = []; //  treat no-internet as no modifiers
        return [];
      }

      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url: '$ModifierMappingService$productId',
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // API returns a list of mapping objects
      if (responseRaw is List) {
        final items = responseRaw
            .whereType<Map<String, dynamic>>()
            .map(ModifierMappingItem.fromJson)
            .where(
              (m) =>
                  m.modifierId != null &&
                  (m.status == null ||
                      m.status!.toLowerCase() == 'active' ||
                      m.status!.isEmpty),
            )
            .toList();
        _modifierCache[productId] = items;
        return items;
      }

      // Backend wraps in { modifiers: [...] } or { data: [...] }
      if (responseRaw is Map<String, dynamic>) {
        // ✅ Primary key used by this API: 'modifiers'
        final dynamic rawList = responseRaw['modifiers'] ?? responseRaw['data'];
        if (rawList is List) {
          final items = rawList
              .whereType<Map<String, dynamic>>()
              .map(ModifierMappingItem.fromJson)
              .where(
                (m) =>
                    m.modifierId != null &&
                    (m.status == null ||
                        m.status!.toLowerCase() == 'active' ||
                        m.status!.isEmpty),
              )
              .toList();
          _modifierCache[productId] = items;
          return items;
        }
      }

      // Unexpected format → treat as no modifiers
      _modifierCache[productId] = [];
      return [];
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      // Non-critical: fail silently — order can still proceed without modifiers
      _modifierCache[productId] = [];
      return [];
    }
  }

  //--🔹--addItemToCartWithModifierCheck---------------------------------🔹--//
  /// Called from the + button on each menu card.
  /// 1. Fetches modifiers (cached after first call).
  /// 2. If product has modifiers → shows [ModifierSelectionSheet].
  /// 3. If no modifiers → behaves exactly like the old incrementQuantity.
  Future<void> addItemToCartWithModifierCheck(
    BuildContext context,
    MenuModel item,
  ) async {
    if (!context.mounted) return;

    final int productId = item.mProdId!;

    // Fetch/load modifiers
    final modifierItems = await getModifiersForProduct(context, productId);

    if (!context.mounted) return;

    if (modifierItems.isEmpty) {
      // ✅ No modifiers → standard add flow
      incrementQuantity(item);
      return;
    }

    // Build grouped structure for the UI
    final groups = ModifierGroup.fromFlatList(modifierItems);

    // Show modifier selection sheet
    final selectedMods = await ModifierSelectionSheet.show(
      context: context,
      item: item,
      groups: groups,
    );

    if (!context.mounted) return;

    // null = user dismissed without confirming
    if (selectedMods == null) return;

    // If user confirmed with no modifiers → treat as plain product (merge by qty)
    if (selectedMods.isEmpty) {
      incrementQuantity(item);
      return;
    }

    // ✅ Modifier Split: confirmation with modifiers selected.
    // Same modifier set → merge into existing entry; new set → new entry.
    final id = productId;
    itemQuantity[id] = (itemQuantity[id] ?? 0) + 1;
    _addModifierCartEntry(item, selectedMods);
    printItemWithQuantity(item);

    // ✅ Tax is backend-driven per-item (tax_group) — no order-level dropdown
    calculateTaxAmount();
    updatedDPOrderPaymentMethods(OrderPaymentMethodsListing.first.type);
    notifyListeners();
  }

  //--🔹--_addModifierCartEntry (Modifier Split Helper)----------------🔹--//
  /// Adds (or merges) a cart entry for a modifier-carrying product.
  /// - Same modifier set already in cart → increments its qty.
  /// - New modifier combination → creates a new independent entry (qty = 1).
  void _addModifierCartEntry(MenuModel item, List<SelectedModifier> modifiers) {
    final id = item.mProdId!;
    final incomingIds = modifiers.map((m) => m.modifierId).toSet();

    // Look for an existing entry with the identical modifier set
    final existingIdx = selectedItems.indexWhere((e) {
      if (e['m_prod_id'] != id) return false;
      final existingMods = e['modifiers'] as List<dynamic>? ?? [];
      if (existingMods.length != modifiers.length) return false;
      final existingIds = existingMods.map((m) => m['modifier_id']).toSet();
      return existingIds.containsAll(incomingIds) &&
          incomingIds.containsAll(existingIds);
    });

    if (existingIdx >= 0) {
      // Same modifier set → increment qty of that entry
      final current = (selectedItems[existingIdx]['quantity'] as int?) ?? 1;
      selectedItems[existingIdx] = Map<String, dynamic>.from(
        selectedItems[existingIdx],
      )..['quantity'] = current + 1;
    } else {
      // New combination → create a new independent entry
      final itemJson = item.toJson();
      itemJson['quantity'] = 1;
      itemJson['modifiers'] = modifiers.map((m) => m.toJson()).toList();
      itemJson['cart_entry_id'] = _generateCartUuid();
      selectedItems.add(itemJson);
    }
  }

  //--🔹--clearModifierCache (called by ClearData)---------------------🔹--//
  void clearModifierCache() {
    _modifierCache.clear();
  }

  // --------------------- Filter Categories Wise Menu Item Display ---------//
  int? selectedCategoryId; // null = All

  void setCategory(int? categoryId) {
    selectedCategoryId = categoryId;

    if (categoryId == null) {
      // "All" selected → सभी items दिखाएँ
      filteredMenuListing = List.from(MenuListing);
    } else {
      // सिर्फ selected category का filter
      filteredMenuListing = MenuListing.where(
        (item) => item.mCatId == categoryId,
      ).toList();
    }

    notifyListeners();
  }

  // 🔹 Get dynamically filtered menu items list based on Brand, Category and Search controller
  List<MenuModel> getFilteredMenuItems() {
    List<MenuModel> list = MenuListing;

    // 1. Filter by Brand if selected
    if (selectedBrandId != null) {
      final brandCategoryIds = CategoriesListing
          .where((cat) => cat.brandid != null && cat.brandid.toString() == selectedBrandId.toString())
          .map((cat) => cat.mCatId)
          .toSet();
      
      list = list.where((item) => brandCategoryIds.contains(item.mCatId)).toList();
    }

    // 2. Filter by Category if selected
    if (selectedCategoryId != null) {
      list = list.where((item) => item.mCatId == selectedCategoryId).toList();
    }

    // 3. Filter by Search Query
    if (SearchMenuController.text.isNotEmpty) {
      final query = SearchMenuController.text.trim().toLowerCase();
      list = list.where((item) {
        final pName = item.mPName?.toLowerCase() ?? '';
        final pArbName = item.mPArbName?.toLowerCase() ?? '';

        final nameWords = pName.split(RegExp(r'\s+'));
        final arbWords = pArbName.split(RegExp(r'\s+'));

        final matchesName = pName.startsWith(query) || nameWords.any((word) => word.startsWith(query));
        final matchesArb = pArbName.startsWith(query) || arbWords.any((word) => word.startsWith(query));

        return matchesName || matchesArb;
      }).toList();
    }

    return list;
  }

  //--🔹--Order Summary--------------------------------------------------🔹--//
  bool OrderSummaryPanelOpen = false;

  bool get isOrderSummaryPanelOpen => OrderSummaryPanelOpen;

  // 🔹 Open panel with selected order data
  void openOrderSummaryPanelWithData(bool isMobile) {
    // ✅✅✅ DEBUG: Log selectedItems when opening Order Summary
    GlobalFunction().debugFunction(
      "📋 Opening Order Summary - selectedItems count: ${selectedItems.length}",
    );
    for (var i = 0; i < selectedItems.length; i++) {
      final item = selectedItems[i];
      GlobalFunction().debugFunction(
        "📋 Selected Item $i: ${item['m_p_name']} (ID: ${item['m_prod_id']}) × ${item['quantity']} @ SAR ${item['price']}",
      );
    }

    if (!isMobile) {
      OrderSummaryPanelOpen = true; // ✅ Big screen me hamesha open
    } else {
      OrderSummaryPanelOpen = false; // ✅ Mobile me default band
    }
    notifyListeners();
  }

  // 🔹 Close panel
  void closeOrderSummaryPanel() {
    OrderSummaryPanelOpen = false;
    notifyListeners();
  }

  TextEditingController MobileController = TextEditingController();
  final FocusNode myFocusNodeMobile = FocusNode();

  // 🔹 DELETE ITEM FROM ORDER FUNCTION
  // ------------------------------------------------------------------------//
  void deleteOrderItem({
    required BuildContext context,
    required Map<String, dynamic> item,
  }) {
    try {
      final mProdId = item['m_prod_id'];
      final itemName = item['m_p_name'] ?? 'Unnamed Item';
      final qty = item['quantity'] ?? 0;
      final price = item['price'] ?? 0.0;

      // 🔹 Calculate total for that item
      final total = (qty * double.tryParse(price.toString())!).toStringAsFixed(
        2,
      );

      // 🔹 Remove from selectedItems — use cart_entry_id for modifier entries,
      // or remove only no-cart_entry_id entries for plain merged rows.
      final cartEntryId = item['cart_entry_id'] as String?;
      if (cartEntryId != null) {
        selectedItems.removeWhere((e) => e['cart_entry_id'] == cartEntryId);
      } else {
        // Plain (no-modifier) merged entry: only remove entries without a
        // cart_entry_id so any modifier-split entries for this product survive.
        selectedItems.removeWhere(
          (e) => e['m_prod_id'] == mProdId && e['cart_entry_id'] == null,
        );
      }
      // Recalculate itemQuantity as sum of remaining entries' actual quantity
      final remainingEntries = selectedItems
          .where((e) => e['m_prod_id'] == mProdId)
          .toList();
      if (remainingEntries.isEmpty) {
        itemQuantity.remove(mProdId);
      } else {
        itemQuantity[mProdId] = remainingEntries.fold<int>(
          0,
          (sum, e) => sum + ((e['quantity'] as int?) ?? 1),
        );
      }
      // 🔹 Recalculate all amounts (tax, charges, discount, net) in real-time
      recalculateAmounts(context);
      notifyListeners();

      // 🔹 Show toast with proper message
      showCustomToast(
        context: context,
        message: "🗑 '$itemName' (SAR $total) removed from order",
        backgroundColor: GlobalAppColor.ButtonColor,
      );

      // 🔹 Debug logs
      //GlobalFunction().debugFunction("🗑 Deleted Item: $itemName (SAR $total)");

      // 🔹 If all items deleted → close order summary panel
      if (selectedItems.isEmpty) {
        /*GlobalFunction().debugFunction(
          "🛑 No items left — closing order summary panel...",
        );*/
        closeOrderSummaryPanel();
      }
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error deleting item: $e");
      debugPrintStack(stackTrace: stack);
    }
  }

  //--🔹--Select-Order Priority------------------------------------------🔹--//
  String? selectedOrderPriority;
  List<OrderSummaryOrderPriorityList> OrderPriorityListing = [];

  List<OrderSummaryOrderPriorityList> get OrderPriority => OrderPriorityListing;

  Future<void> loadOrderPriorityList() async {
    final response = [
      {"id": 1, "Title": "Normal"},
      {"id": 2, "Title": "High"},
      {"id": 2, "Title": "Urgent"},
    ];

    OrderPriorityListing = response
        .map((e) => OrderSummaryOrderPriorityList.fromJson(e))
        .toList();

    // Default select first payment method if available
    selectedOrderPriority = OrderPriorityListing.isNotEmpty
        ? OrderPriorityListing[0].title
        : null;
    notifyListeners();
  }

  void updateOrderPriorityType(String newValue) {
    selectedOrderPriority = newValue;
    notifyListeners();

    final selectedModel = OrderPriorityListing.firstWhere(
      (item) => item.title == newValue,
      orElse: () => OrderSummaryOrderPriorityList(id: '', title: ''),
    );

    /*GlobalFunction().debugFunction(
      "✅ Selected Payment: $selectedOrderPriority",
    );
    GlobalFunction().debugFunction(
      "🔍 Selected OrderPriority Json: ${selectedModel.toJson()}",
    );*/
  }

  // 🔹 Overall total of all selected items (base + modifiers)
  double get overallTotal {
    double total = 0.0;
    for (var item in selectedItems) {
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      total += qty * price;
      // ✅ Include modifier prices (each modifier's price × parent item qty)
      final mods = item['modifiers'] as List<dynamic>? ?? [];
      for (final mod in mods) {
        final modPrice =
            double.tryParse(mod['price']?.toString() ?? '0') ?? 0.0;
        total += qty * modPrice;
      }
    }
    return total;
  }

  double selectedPercentage = 0;

  void updatePercentage(double val) {
    selectedPercentage = val;
    notifyListeners();
  }

  //--🔹--OrderTable Listing---------------------------------------------🔹--//
  // 🔹 Table Data Provider
  List<OrderTableData> OrderTableListing = [];

  List<OrderTableData> get OrderTable => OrderTableListing;

  int? selectedTableId;
  String? selectedTableDisplayName;
  String? selectedDPOrderTable; // Dropdown selected value (String)
  List<OrderTableData> selectedTables = [];

  // 🔹 API से Table List लाना
  Future<void> getOrderTableListService(BuildContext context) async {
    resetOrderTableSelection();
    OrderTableListing = [];
    OrderTableListing.clear();
    if (!context.mounted) return;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final userInfo = Provider.of<UserInfoProvider>(context, listen: false);
    final token = userInfo.AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        OrderTableListing.clear();
        return;
      }
      setAddOrderLoading(true);
      notifyListeners();

      OrderTableListing.clear();

      // ✅ PRIMARY: Use tableWithStatus endpoint (single call, backend-driven occupancy)
      bool usedNewEndpoint = false;
      try {
        final dynamic statusResponse = await httpCtrl.request(
          method: 'GET',
          url: "$TableWithStatusService",
          context: context,
          headers: authHeaders,
          requireLogin: true,
        );

        if (statusResponse is Map<String, dynamic> &&
            statusResponse['TableWithStatus'] != null) {
          final List<dynamic> tablesWithStatus =
              statusResponse['TableWithStatus'] as List<dynamic>;

          if (tablesWithStatus.isNotEmpty) {
            final List<Map<String, dynamic>> tableRecords = tablesWithStatus
                .whereType<Map<String, dynamic>>()
                .toList();

            OrderTableListing = tableRecords
                .map((e) => OrderTableData.fromJson(e))
                .toList();

            usedNewEndpoint = true;
            final occupiedCount = OrderTableListing.where(
              (t) => t.isOccupied,
            ).length;
            print(
              "✅ tableWithStatus: ${OrderTableListing.length} tables, $occupiedCount occupied",
            );
          }
        }
      } catch (e) {
        print("⚠️ tableWithStatus failed, falling back to old approach: $e");
      }

      // ✅ FALLBACK: Old 2-step approach (fetch tables + filter orders manually)
      if (!usedNewEndpoint) {
        final dynamic tablesResponse = await httpCtrl.request(
          method: 'GET',
          url: "$OrderTableListService?branch_id=${userInfo.branchId}",
          context: context,
          headers: authHeaders,
          requireLogin: true,
        );

        final List<Map<String, dynamic>> tableRecords = tablesResponse
            .whereType<Map<String, dynamic>>()
            .toList();

        if (tableRecords.isEmpty) {
          return;
        }

        // Fetch current orders to find occupied tables
        final String today = DateTime.now().toIso8601String().split('T')[0];
        final dynamic ordersResponse = await httpCtrl.request(
          method: 'GET',
          url:
              "$OrderListService"
              "filter/orders?status=current&date=$today",
          context: context,
          headers: authHeaders,
          requireLogin: true,
        );

        // Build map of occupied tables with order details
        final Map<String, Map<String, dynamic>> occupiedTables = {};

        if (ordersResponse is Map<String, dynamic> &&
            ordersResponse['success'] == true) {
          final List<dynamic> orders = ordersResponse['data'] ?? [];

          for (var order in orders) {
            final String? tableId = order['table_id']?.toString();
            final String? paymentStatus = order['payment_status']
                ?.toString()
                .toLowerCase();
            final String? orderStatus = order['order_status']
                ?.toString()
                .toLowerCase();

            if (tableId != null &&
                (paymentStatus == 'unpaid' || paymentStatus == 'partial') &&
                orderStatus != 'cancelled' &&
                orderStatus != 'completed') {
              occupiedTables[tableId] = {
                'order_id': order['order_id']?.toString(),
                'order_no': order['order_no']?.toString(),
                'customer_name': order['Customer']?['name'] ?? 'Guest',
                'order_status': orderStatus,
              };
            }
          }
        }

        print("📋 Fallback: ${tableRecords.length} tables");
        print("🔴 Occupied Tables: ${occupiedTables.length}");

        for (var tableJson in tableRecords) {
          final String tableId = tableJson['table_ID']?.toString() ?? '';

          if (occupiedTables.containsKey(tableId)) {
            tableJson['occupied'] = true;
            tableJson['active_order'] = occupiedTables[tableId];
          } else {
            tableJson['occupied'] = false;
            tableJson['active_order'] = null;
          }
        }

        OrderTableListing = tableRecords
            .map((e) => OrderTableData.fromJson(e))
            .toList();

        final occupiedCount = OrderTableListing.where(
          (t) => t.isOccupied,
        ).length;
        print(
          "✅ Fallback Result: ${OrderTableListing.length} tables, $occupiedCount occupied",
        );
      }

      notifyListeners();
    } catch (e, stack) {
      //GlobalFunction().debugFunction("❌ Error fetching Table List: $e");
      debugPrintStack(stackTrace: stack);
      GlobalFunction().showError(context, "Failed to load tables");
    } finally {
      setAddOrderLoading(false);
      notifyListeners();
    }
  }

  // 🔹 Dropdown Select Handling
  void updatedDPOrderTable(String? newValue) {
    selectedDPOrderTable = newValue;

    if (newValue == null || newValue.isEmpty) {
      selectedTableId = null;
      selectedTableDisplayName = null;
      //GlobalFunction().debugFunction("⚠️ No table selected");
      notifyListeners();
      return;
    }

    // ✅ Selected Model खोजें
    final selectedModel = OrderTable.firstWhere(
      (item) =>
          "${item.tableName} (Seats: ${item.seatingCapacity})" == newValue,
      orElse: () => OrderTableData(tableName: '', seatingCapacity: 0),
    );

    // ✅ Assign Values for API
    selectedTableId = selectedModel.tableID;
    selectedTableDisplayName =
        "${selectedModel.tableName} (Seats: ${selectedModel.seatingCapacity})";

    // ✅ Debug Logs
    /*GlobalFunction().debugFunction("✅ Selected Table ID: $selectedTableId");
    GlobalFunction().debugFunction(
      "✅ Selected Table Display: $selectedTableDisplayName",
    );
    GlobalFunction().debugFunction(
      "🔍 Selected Table JSON: ${selectedModel.toJson()}",
    );*/

    notifyListeners();
  }

  void resetOrderTableSelection() {
    // 🔹 Reset table dropdown every time panel opens
    selectedDPOrderTable = null; // dropdown value reset
    selectedTableId = null; // selected ID reset
    selectedTableDisplayName = null; // display name reset
    selectedTables = [];
    calculatedTableChargeAmount = 0.0;
    notifyListeners();
  }

  // ✅ Called when user confirms selection from the _TableSelectionModal
  void confirmTableSelections(List<OrderTableData> tables) {
    selectedTables = List<OrderTableData>.from(tables);
    selectedTableId = tables.isNotEmpty ? tables.first.tableID : null;
    selectedTableDisplayName = tables.isNotEmpty
        ? tables.map((t) => t.tableName).join(', ')
        : null;
    selectedDPOrderTable = selectedTableId?.toString();
    calculatedTableChargeAmount = calculatePremiumTableCharge();
    notifyListeners();
  }

  //--🔹--Select-TableType-----------------------------------------------🔹--//
  String? selectedTableType;
  OrderSummaryTableTypeList? selectedTableData;
  List<OrderSummaryTableTypeList> TableTypeListing = [];

  List<OrderSummaryTableTypeList> get TableType => TableTypeListing;

  /// 🔹 Update selected value when user changes dropdown
  void updateTableType(String newValue) {
    selectedTableType = newValue;
    selectedTableData = TableTypeListing.firstWhere(
      (item) => item.orderTypeName == newValue,
      orElse: () => TableTypeListing.first,
    );

    // 🔹 Dine In → force Unpaid, clear payment method selection
    // 🔹 Other types → force Paid, restore first payment method
    if (newValue.toLowerCase() == 'dine in') {
      if (paymentStatusList.isNotEmpty) {
        selectedPaymentStatus = paymentStatusList
            .firstWhere(
              (item) => item.title.toLowerCase() == 'unpaid',
              orElse: () => paymentStatusList.first,
            )
            .title;
      } else {
        selectedPaymentStatus = "UnPaid";
      }
      resetOrderPaymentMethodsSelection();
    } else {
      if (paymentStatusList.isNotEmpty) {
        selectedPaymentStatus = paymentStatusList
            .firstWhere(
              (item) => item.title.toLowerCase() == 'paid',
              orElse: () => paymentStatusList.first,
            )
            .title;
      } else {
        selectedPaymentStatus = "Paid";
      }
      if (OrderPaymentMethodsListing.isNotEmpty &&
          selectedPaymentMethodsData == null) {
        selectedPaymentMethodsData = OrderPaymentMethodsListing.first;
        selectedPaymentMethodsId = selectedPaymentMethodsData!.payMId;
        selectedPaymentMethodsType = selectedPaymentMethodsData!.type;
        selectedPaymentMethodsName = selectedPaymentMethodsData!.name;
      }
    }

    notifyListeners();

    GlobalFunction().debugFunction("✅ Selected Table Type: $selectedTableType");
    GlobalFunction().debugFunction(
      "🔍 Selected TableType Json: ${selectedTableData?.toJson()}",
    );
  }

  /// 🔹 Fetch API dynamically (Production - Branch Filtered)
  Future<void> getOrderTypeListService(BuildContext context) async {
    try {
      final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
      final userInfo = Provider.of<UserInfoProvider>(context, listen: false);
      final token = userInfo.AccessToken ?? "";
      final branchId = userInfo.branchId ?? 0;
      final authHeaders = APIHelper.buildAuthHeaders(token);

      // ✅ Use branch-specific endpoint for better data isolation
      final responseRaw = await httpCtrl.request(
        method: 'GET',
        url: "$OrderTypesByBranchService$branchId",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // 🔹 Map API response to model
      final List<Map<String, dynamic>> records = responseRaw
          .whereType<Map<String, dynamic>>()
          .toList();

      TableTypeListing = records
          .map((e) => OrderSummaryTableTypeList.fromJson(e))
          .toList();

      // ✅ By default select first value
      if (TableTypeListing.isNotEmpty) {
        selectedTableType = TableTypeListing.first.orderTypeName;
        selectedTableData = TableTypeListing.first;
      } else {
        selectedTableType = null;
        selectedTableData = null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error fetching TableType: $e");
    }
  }

  //-✅--CreateOrderTypeService (NEW - Production)----------------------✅-//
  /// Create a new order type (Admin feature)
  /// POST /api/order-types/
  ///
  /// @param orderTypeName - Name of the new order type (e.g., "Pick Up", "Drive Thru")
  /// @returns OrderSummaryTableTypeList? - Created order type or null
  Future<OrderSummaryTableTypeList?> createOrderTypeService(
    BuildContext context,
    String orderTypeName,
  ) async {
    if (!context.mounted) return null;

    try {
      setAddOrderLoading(true);
      notifyListeners();

      final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
      final token =
          Provider.of<UserInfoProvider>(context, listen: false).AccessToken ??
          "";
      final authHeaders = APIHelper.buildAuthHeaders(token);

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        showCustomToast(
          context: context,
          message: "No internet connection. Please check your network.",
        );
        setAddOrderLoading(false);
        return null;
      }

      GlobalFunction().debugFunction(
        "ℹ️ Creating new order type: $orderTypeName...",
      );

      final responseRaw = await httpCtrl.request(
        method: 'POST',
        url: OrderTypeService,
        context: context,
        headers: authHeaders,
        body: {"order_type_name": orderTypeName},
        requireLogin: true,
      );

      if (!context.mounted) return null;

      // Parse response
      final newOrderType = OrderSummaryTableTypeList.fromJson(responseRaw);

      GlobalFunction().debugFunction(
        "✅ Order type created successfully: ${newOrderType.orderTypeName}",
      );

      showCustomToast(
        context: context,
        message: "Order type '$orderTypeName' created successfully!",
      );

      // Refresh the order type list
      await getOrderTypeListService(context);

      return newOrderType;
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error in createOrderTypeService: $e");
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: "Failed to create order type. Please try again.",
      );
      return null;
    } finally {
      setAddOrderLoading(false);
      notifyListeners();
    }
  }

  //-✅--GetOrderTypeByIdService (NEW - Production)---------------------✅-//
  /// Get a single order type by ID
  /// GET /api/order-types/{id}
  ///
  /// @param orderTypeId - The order type ID
  /// @returns OrderSummaryTableTypeList? - Order type or null
  Future<OrderSummaryTableTypeList?> getOrderTypeByIdService(
    BuildContext context,
    int orderTypeId,
  ) async {
    if (!context.mounted) return null;

    try {
      setAddOrderLoading(true);
      notifyListeners();

      final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
      final token =
          Provider.of<UserInfoProvider>(context, listen: false).AccessToken ??
          "";
      final authHeaders = APIHelper.buildAuthHeaders(token);

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        showCustomToast(
          context: context,
          message: "No internet connection. Please check your network.",
        );
        setAddOrderLoading(false);
        return null;
      }

      GlobalFunction().debugFunction("ℹ️ Loading order type #$orderTypeId...");

      final responseRaw = await httpCtrl.request(
        method: 'GET',
        url: "$OrderTypeByIdService$orderTypeId",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      if (!context.mounted) return null;

      final orderType = OrderSummaryTableTypeList.fromJson(responseRaw);

      GlobalFunction().debugFunction(
        "✅ Loaded order type: ${orderType.orderTypeName}",
      );

      notifyListeners();
      return orderType;
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error in getOrderTypeByIdService: $e");
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: "Failed to load order type. Please try again.",
      );
      return null;
    } finally {
      setAddOrderLoading(false);
      notifyListeners();
    }
  }

  //-✅--UpdateOrderTypeService (NEW - Production)----------------------✅-//
  /// Update an existing order type (Admin feature)
  /// PUT /api/order-types/{id}
  ///
  /// @param orderTypeId - ID of the order type to update
  /// @param orderTypeName - New name for the order type
  /// @returns bool - true if updated successfully
  Future<bool> updateOrderTypeService(
    BuildContext context,
    int orderTypeId,
    String orderTypeName,
  ) async {
    if (!context.mounted) return false;

    try {
      setAddOrderLoading(true);
      notifyListeners();

      final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
      final token =
          Provider.of<UserInfoProvider>(context, listen: false).AccessToken ??
          "";
      final authHeaders = APIHelper.buildAuthHeaders(token);

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        showCustomToast(
          context: context,
          message: "No internet connection. Please check your network.",
        );
        setAddOrderLoading(false);
        return false;
      }

      GlobalFunction().debugFunction(
        "ℹ️ Updating order type #$orderTypeId to: $orderTypeName...",
      );

      await httpCtrl.request(
        method: 'PUT',
        url: "$OrderTypeByIdService$orderTypeId",
        context: context,
        headers: authHeaders,
        body: {"order_type_name": orderTypeName},
        requireLogin: true,
      );

      if (!context.mounted) return false;

      GlobalFunction().debugFunction(
        "✅ Order type #$orderTypeId updated successfully",
      );

      showCustomToast(
        context: context,
        message: "Order type updated to '$orderTypeName'!",
      );

      // Refresh the order type list
      await getOrderTypeListService(context);

      return true;
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error in updateOrderTypeService: $e");
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: "Failed to update order type. Please try again.",
      );
      return false;
    } finally {
      setAddOrderLoading(false);
      notifyListeners();
    }
  }

  //-✅--DeleteOrderTypeService (NEW - Production)----------------------✅-//
  /// Delete an order type (Admin feature)
  /// DELETE /api/order-types/{id}
  ///
  /// @param orderTypeId - ID of the order type to delete
  /// @returns bool - true if deleted successfully
  Future<bool> deleteOrderTypeService(
    BuildContext context,
    int orderTypeId,
  ) async {
    if (!context.mounted) return false;

    try {
      setAddOrderLoading(true);
      notifyListeners();

      final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
      final token =
          Provider.of<UserInfoProvider>(context, listen: false).AccessToken ??
          "";
      final authHeaders = APIHelper.buildAuthHeaders(token);

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        showCustomToast(
          context: context,
          message: "No internet connection. Please check your network.",
        );
        setAddOrderLoading(false);
        return false;
      }

      GlobalFunction().debugFunction("ℹ️ Deleting order type #$orderTypeId...");

      await httpCtrl.request(
        method: 'DELETE',
        url: "$OrderTypeByIdService$orderTypeId",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      if (!context.mounted) return false;

      GlobalFunction().debugFunction(
        "✅ Order type #$orderTypeId deleted successfully",
      );

      showCustomToast(
        context: context,
        message: "Order type deleted successfully!",
      );

      // Refresh the order type list
      await getOrderTypeListService(context);

      return true;
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error in deleteOrderTypeService: $e");
      debugPrintStack(stackTrace: stack);
      showCustomToast(
        context: context,
        message: "Failed to delete order type. Please try again.",
      );
      return false;
    } finally {
      setAddOrderLoading(false);
      notifyListeners();
    }
  }

  //--🔹--OrderTax Listing---------------------------------------------🔹--//
  List<OrderTaxData> OrderTaxListing = [];

  List<OrderTaxData> get OrderTax => OrderTaxListing;

  int? selectedTaxId;
  double? selectedTaxRate;
  OrderTaxData? selectedTaxData; // Selected Model

  // 🔹 API से Table List लाना
  Future<void> getOrderTaxListService(BuildContext context) async {
    resetOrderTaxSelection();
    selectedTaxId = null;
    selectedTaxRate = null;
    selectedTaxData = null;
    OrderTaxListing = [];
    if (!context.mounted) return;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        OrderTableListing.clear();
        return;
      }
      setAddOrderLoading(true);
      notifyListeners();
      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url: OrderTaxListService,
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      OrderTaxListing.clear();

      final List<Map<String, dynamic>> records = responseRaw
          .whereType<Map<String, dynamic>>()
          .toList();

      if (records.isEmpty) {
        //GlobalFunction().debugFunction("ℹ️ No tables found.");
        return;
      }
      OrderTaxListing = records.map((e) => OrderTaxData.fromJson(e)).toList();
      // ✅ Bug #5: Auto-select General Tax ID for API (UI stays hidden per Bug #2)
      // Match by appliedOn field ("general_tax") — more reliable than name string match.
      // Fallback to name-contains for backwards compatibility with other environments.
      final generalTaxList = OrderTaxListing.where(
        (e) =>
            e.appliedOn.toLowerCase() == 'general_tax' ||
            e.name.toLowerCase().contains('general tax'),
      );
      if (generalTaxList.isNotEmpty) {
        selectedTaxId = generalTaxList.first.taxid;
        selectedTaxRate = double.tryParse(generalTaxList.first.rate);
      } else {
        selectedTaxId = null;
        selectedTaxRate = null;
      }
      selectedTaxData = null; // Keep null — UI stays hidden (Bug #2)
      notifyListeners();
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error fetching Table List: $e");
      debugPrintStack(stackTrace: stack);
      GlobalFunction().showError(context, "Failed to load tables");
    } finally {
      setAddOrderLoading(false);
      notifyListeners();
    }
  }

  // 🔹 Dropdown Select Handling
  // 🔹 Dropdown Select Handling - Tax
  void updatedDPOrderTax(String? newValue) {
    if (newValue == null || newValue.isEmpty) {
      selectedTaxId = null;
      selectedTaxRate = null;
      selectedTaxData = null;
      calculatedTaxAmount = 0.0;

      // ✅ Recalculate net
      calculateNetAmount();

      notifyListeners();
      return;
    }

    // 🔹 Find selected tax model
    final selectedModel = OrderTaxListing.firstWhere(
      (item) => "${item.name} (${item.rate})" == newValue,
      orElse: () => OrderTaxData(name: "N/A", rate: "0"),
    );

    selectedTaxId = selectedModel.taxid;
    selectedTaxRate = double.tryParse(selectedModel.rate) ?? 0.0;
    selectedTaxData = selectedModel;

    /*GlobalFunction().debugFunction("✅ Selected TaxID: $selectedTaxId");
    GlobalFunction().debugFunction("✅ Selected TaxRate: $selectedTaxRate");
    GlobalFunction().debugFunction(
      "🔍 Selected TableType Json: ${selectedModel.toJson()}",
    );*/

    // ✅ Recalculate tax amount
    calculateTaxAmount();

    // ✅ Update net amount after tax change
    calculateNetAmount();

    notifyListeners();
  }

  // 🔹 Reset Dropdown Selection
  void resetOrderTaxSelection() {
    selectedTaxId = null;
    selectedTaxRate = null;
    selectedTaxData = null;
    notifyListeners();
  }

  //--🔹--OrderCharges Listing-------------------------------------------🔹--//
  // 🔹 Listing
  List<OrderChargesDataItem> OrderChargesListing = [];

  List<OrderChargesDataItem> get OrderCharges => OrderChargesListing;

  // 🔹 Selected
  int? selectedChargesId;
  String? selectedChargesAmt;
  String? selectedChargesType;
  OrderChargesDataItem? selectedChargesData; // Selected Model

  // 🔹 API: Fetch Order Charges List
  Future<void> getOrderChargesListService(BuildContext context) async {
    resetOrderChargesSelection();
    OrderChargesListing = [];
    selectedChargesId = null;
    selectedChargesAmt = null;
    selectedChargesType = null;
    selectedChargesData = null;
    if (!context.mounted) return;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        OrderChargesListing.clear();
        return;
      }
      setAddOrderLoading(true);
      notifyListeners();
      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url: OrderChargesListService,
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // 🔹 Reset old list
      OrderChargesListing.clear();

      if (responseRaw == null || responseRaw['success'] != true) {
        GlobalFunction().debugFunction("❌ API failed or empty response");
        return;
      }

      final List<dynamic> records = responseRaw['data'] ?? [];
      if (records.isEmpty) {
        GlobalFunction().debugFunction("ℹ️ No charges found.");
        return;
      }

      // 🔹 Map to Model
      OrderChargesListing = records
          .whereType<Map<String, dynamic>>()
          .map((e) => OrderChargesDataItem.fromJson(e))
          .toList();

      notifyListeners();
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error fetching Charges List: $e");
      debugPrintStack(stackTrace: stack);
      GlobalFunction().showError(context, "Failed to load charges");
    } finally {
      setAddOrderLoading(false);
      notifyListeners();
    }
  }

  // 🔹 Dropdown Select Handling (Charges)
  void updatedDPOrderCharges(String? newValue) {
    if (newValue == null || newValue.isEmpty) {
      selectedChargesId = null;
      selectedChargesAmt = null;
      selectedChargesType = null;
      selectedChargesData = null;
      calculatedChargesAmount = 0.0;

      // ✅ Recalculate net
      calculateNetAmount();

      notifyListeners();
      return;
    }

    final selectedModel = OrderChargesListing.firstWhere(
      (item) => "${item.name} (${item.value})" == newValue,
      orElse: () => OrderChargesDataItem(),
    );

    selectedChargesId = selectedModel.chargeId;
    selectedChargesAmt = selectedModel.value;
    selectedChargesType = selectedModel.type;
    selectedChargesData = selectedModel;

    /*GlobalFunction().debugFunction("✅ Selected ChargesID: $selectedChargesId");
    GlobalFunction().debugFunction("✅ Selected ChargesAmt: $selectedChargesAmt");
    GlobalFunction().debugFunction("✅ Selected ChargesType: $selectedChargesType");
    GlobalFunction().debugFunction(
      "🔍 Selected TableType Json: ${selectedModel.toJson()}",
    );*/

    // ✅ Recalculate charges
    calculateChargesAmount();

    // ✅ Update net amount after charges change
    calculateNetAmount();

    notifyListeners();
  }

  // 🔹 Reset Dropdown Selection
  void resetOrderChargesSelection() {
    selectedChargesId = null;
    selectedChargesAmt = null;
    selectedChargesType = null;
    selectedChargesData = null;
    notifyListeners();
  }

  //--🔹--OrderPaymentMethods Listing------------------------------------🔹--//
  // 🔹 Listing
  List<OrderPaymentMethodsData> OrderPaymentMethodsListing = [];

  List<OrderPaymentMethodsData> get PaymentMethods =>
      OrderPaymentMethodsListing;

  // 🔹 Selected
  int? selectedPaymentMethodsId;
  String? selectedPaymentMethodsType;
  String? selectedPaymentMethodsName;
  OrderPaymentMethodsData? selectedPaymentMethodsData; // Selected Model

  // 🔹 API: Fetch PaymentMethods Charges List
  Future<void> getOrderPaymentMethodsListService(BuildContext context) async {
    resetOrderPaymentMethodsSelection();
    OrderPaymentMethodsListing = [];
    selectedPaymentMethodsId = null;
    selectedPaymentMethodsType = null;
    selectedPaymentMethodsName = null;
    selectedPaymentMethodsData = null;
    if (!context.mounted) return;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        OrderPaymentMethodsListing.clear();
        return;
      }
      setAddOrderLoading(true);
      notifyListeners();
      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url: OrderPaymentMethodsListService,
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // 🔹 Reset old list
      OrderPaymentMethodsListing.clear();

      final List<Map<String, dynamic>> records = responseRaw
          .whereType<Map<String, dynamic>>()
          .toList();

      if (records.isEmpty) {
        GlobalFunction().debugFunction("ℹ️ No tables found.");
        return;
      }

      OrderPaymentMethodsListing = records
          .map((e) => OrderPaymentMethodsData.fromJson(e))
          .toList();
      // ===== AUTO SELECT FIRST VALUE =====
      if (OrderPaymentMethodsListing.isNotEmpty) {
        selectedPaymentMethodsData = OrderPaymentMethodsListing.first;
        selectedPaymentMethodsId = selectedPaymentMethodsData!.payMId;
        selectedPaymentMethodsType = selectedPaymentMethodsData!.type;
        selectedPaymentMethodsName = selectedPaymentMethodsData!.name;
      } else {
        selectedPaymentMethodsData = null;
        selectedPaymentMethodsId = null;
        selectedPaymentMethodsType = null;
        selectedPaymentMethodsName = null;
      }
      notifyListeners();
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error fetching Charges List: $e");
      debugPrintStack(stackTrace: stack);
      GlobalFunction().showError(context, "Failed to load charges");
    } finally {
      setAddOrderLoading(false);
      notifyListeners();
    }
  }

  // 🔹 Dropdown Select Handling
  void updatedDPOrderPaymentMethods(String? newValue) {
    if (newValue == null || newValue.isEmpty) {
      // Reset selection
      selectedPaymentMethodsId = null;
      selectedPaymentMethodsType = null;
      selectedPaymentMethodsName = null;
      selectedPaymentMethodsData = null;
      GlobalFunction().debugFunction("⚠️ No payment method selected");
      notifyListeners();
      return;
    }

    try {
      // Find the selected payment method by name
      final selectedModel = OrderPaymentMethodsListing.firstWhere(
        (item) => item.name == newValue,
        orElse: () => throw Exception("Payment method not found"),
      );

      // Assign to selected fields
      selectedPaymentMethodsId = selectedModel.payMId;
      selectedPaymentMethodsType = selectedModel.type;
      selectedPaymentMethodsName = selectedModel.name;
      selectedPaymentMethodsData = selectedModel;

      // Debug logs
      GlobalFunction().debugFunction(
        "✅ Selected Payment Methods ID: $selectedPaymentMethodsId",
      );
      GlobalFunction().debugFunction(
        "✅ Selected PaymentMethods Type: $selectedPaymentMethodsType",
      );
      GlobalFunction().debugFunction(
        "✅ Selected PaymentMethods Name: $selectedPaymentMethodsName",
      );
      GlobalFunction().debugFunction(
        "🔍 Selected PaymentMethods JSON: ${selectedModel.toJson()}",
      );

      notifyListeners();
    } catch (e) {
      // Safe fallback if something goes wrong
      selectedPaymentMethodsId = null;
      selectedPaymentMethodsType = null;
      selectedPaymentMethodsName = null;
      selectedPaymentMethodsData = null;
      GlobalFunction().debugFunction("❌ Payment method selection error: $e");
      notifyListeners();
    }
  }

  // 🔹 Reset Dropdown Selection
  void resetOrderPaymentMethodsSelection() {
    selectedPaymentMethodsId = null;
    selectedPaymentMethodsType = null;
    selectedPaymentMethodsName = null;
    selectedPaymentMethodsData = null;
    notifyListeners();
  }

  //--🔹--BasicAPI-------------------------------------------------------🔹--//
  Future<void> BasicAPI(BuildContext context) async {
    final sessionCtrl = Provider.of<SessionProvider>(context, listen: false);
    if (sessionCtrl.isSessionActive) {
      //--✅--MenuList-----------✅--//
      MenuListing = [];
      filteredMenuListing = [];
      filteredMenuListing.clear();
      MenuListing.clear();
      await getMenuListService(context);

      //--✅--OrderTable---------✅--//
      resetOrderTableSelection();
      OrderTableListing = [];
      OrderTableListing.clear();
      await getOrderTableListService(context);

      //--✅--OrderTableType-------✅--//
      TableTypeListing = [];
      await getOrderTypeListService(context);

      //--✅--OrderTax------------✅--//
      resetOrderTaxSelection();
      selectedTaxId = null;
      selectedTaxRate = null;
      selectedTaxData = null;
      OrderTaxListing = [];
      await getOrderTaxListService(context);

      //--✅--OrderCharges----------✅--//
      resetOrderChargesSelection();
      OrderChargesListing = [];
      selectedChargesId = null;
      selectedChargesAmt = null;
      selectedChargesType = null;
      selectedChargesData = null;
      await getOrderChargesListService(context);

      //--✅--OrderPaymentMethods----------✅--//
      resetOrderPaymentMethodsSelection();
      OrderPaymentMethodsListing = [];
      selectedPaymentMethodsId = null;
      selectedPaymentMethodsType = null;
      selectedPaymentMethodsName = null;
      selectedPaymentMethodsData = null;
      await getOrderPaymentMethodsListService(context);
    }
    notifyListeners();
  }

  //--🔹--CalculationValue-----------------------------------------------🔹--//
  // 🔹 Calculation Values
  double calculatedTaxAmount = 0.0;
  double calculatedChargesAmount = 0.0;
  double calculatedDiscountAmount = 0.0;
  double calculatedNetAmount = 0.0;
  double calculatedTableChargeAmount = 0.0;

  /// Tax-exclusive net portion of items (for breakdown display only).
  double calculatedNetExclTax = 0.0;

  //-✅---_calcTaxBreakdown (matches web app calculateTaxBreakdown exactly)-------
  /// Tax-INCLUSIVE reverse calculation. All prices are stored tax-inclusive.
  ///
  /// Correct formula (verified against live backend data):
  ///   taxGroup "0" or ""  → VAT-only  : divisor = 1.15
  ///   taxGroup "100.00"   → Extra+VAT : divisor = (1 + extraRate) × 1.15
  ///
  /// For 100% extra tax (taxGroup="100.00"):
  ///   netPrice    = price / 2.30   (= 200 / 2.30 = 86.96 ✅)
  ///   extraTax    = netPrice × 1.0 = 86.96
  ///   vatTax      = (netPrice + extraTax) × 0.15 = 173.92 × 0.15 = 26.09
  ///   total check = 86.96 + 86.96 + 26.09 = 200.01 ≈ 200 ✅
  Map<String, double> _calcTaxBreakdown(double totalPrice, String taxGroup) {
    // Parse extra tax rate from taxGroup string (e.g. "100.00" → 1.0, "0"/"" → 0.0)
    final extraRate =
        (double.tryParse(taxGroup) ?? 0.0) / 100.0; // 100.00 → 1.0

    // Divisor: (1 + extraRate) × 1.15 — covers both VAT-only and compound tax
    final divisor = (1.0 + extraRate) * 1.15;
    final netPrice = totalPrice / divisor;

    // Extra (tobacco/sheesha) tax: percentage of net price
    final extraTax = netPrice * extraRate;

    // VAT (15%) is applied on (net + extra tax) — matches backend stored_tax_values
    final vatTax = (netPrice + extraTax) * 0.15;

    final totalTax = extraTax + vatTax;
    return {
      'netPrice': double.parse(netPrice.toStringAsFixed(2)),
      'tobaccoTax': double.parse(extraTax.toStringAsFixed(2)),
      'vatTax': double.parse(vatTax.toStringAsFixed(2)),
      'totalTax': double.parse(totalTax.toStringAsFixed(2)),
    };
  }

  //-✅---calculateTaxAmount--------
  /// Iterates every cart item, reverse-extracts the tax component from the
  /// tax-inclusive price (matching the web app calculateTaxBreakdown logic).
  void calculateTaxAmount() {
    double totalNet = 0.0;
    double totalTax = 0.0;

    for (final item in selectedItems) {
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      double itemPrice = double.tryParse(item['price'].toString()) ?? 0.0;
      // ✅ Include modifier prices in tax base (same tax_group as parent item)
      final mods = item['modifiers'] as List<dynamic>? ?? [];
      for (final mod in mods) {
        itemPrice += double.tryParse(mod['price']?.toString() ?? '0') ?? 0.0;
      }
      final totalPrice = qty * itemPrice; // tax-inclusive: item + modifiers
      final taxGroup = item['tax_group']?.toString() ?? '0';
      final breakdown = _calcTaxBreakdown(totalPrice, taxGroup);
      totalNet += breakdown['netPrice']!;
      totalTax += breakdown['totalTax']!;
    }

    calculatedTaxAmount = double.parse(totalTax.toStringAsFixed(2));
    calculatedNetExclTax = double.parse(totalNet.toStringAsFixed(2));

    // Ensure net always updates
    calculateNetAmount();
  }

  //-✅---calculateChargesAmount------
  void calculateChargesAmount() {
    final subtotal = overallTotal;
    final type = selectedChargesType?.toLowerCase() ?? "amount";
    final value = double.tryParse(selectedChargesAmt?.toString() ?? "0") ?? 0.0;

    calculatedChargesAmount = type == "percentage"
        ? (subtotal * value) / 100
        : value;
    calculatedChargesAmount = double.parse(
      calculatedChargesAmount.toStringAsFixed(2),
    );

    /*    GlobalFunction().debugFunction(
      "✅ Charges Calculated: Type $type | Value $value | Subtotal $subtotal | Final $calculatedChargesAmount",
    );*/

    // Ensure net always updates
    calculateNetAmount();
  }

  //-✅---calculateDiscountAmount------
  void calculateDiscountAmount(BuildContext context) {
    final subtotal = overallTotal;
    final discountPercent = context
        .read<NumberInputDiscountProvider>()
        .value
        .toDouble();

    calculatedDiscountAmount = (subtotal * discountPercent) / 100;
    calculatedDiscountAmount = double.parse(
      calculatedDiscountAmount.toStringAsFixed(2),
    );

    /*    GlobalFunction().debugFunction(
      "💸 Discount Calculated: $discountPercent% of $subtotal = $calculatedDiscountAmount",
    );*/

    // Ensure net always updates
    calculateNetAmount();
  }

  //-✅---calculateNetAmount------
  /// Grand total = subtotal (tax-inclusive) + charges - discount.
  /// ✅ Tax is already INSIDE each item price — do NOT add calculatedTaxAmount again.
  void calculateNetAmount() {
    final subtotal = overallTotal; // sum of (qty × price) — tax already inside
    final charges = calculatedChargesAmount;
    final discount = calculatedDiscountAmount;

    calculatedNetAmount = subtotal + charges - discount;
    calculatedNetAmount = double.parse(calculatedNetAmount.toStringAsFixed(2));
    calculatedTableChargeAmount = calculatePremiumTableCharge();

    notifyListeners();
  }

  double calculatePremiumTableCharge() {
    if (selectedTableId == null || selectedTableId! <= 0) return 0.0;

    final matchingTables = OrderTableListing.where((t) => t.tableID == selectedTableId);
    if (matchingTables.isEmpty) return 0.0;

    final table = matchingTables.first;
    if (!table.isPremium) return 0.0;

    final minimum = table.minimumSpendAmount;
    if (minimum <= 0) {
      return double.parse(table.tableChargeAmount.toStringAsFixed(2));
    }

    final shortfall = minimum - calculatedNetAmount;
    if (shortfall <= 0) return 0.0;
    return double.parse(shortfall.toStringAsFixed(2));
  }

  double get finalPayableAmount => double.parse(
    (calculatedNetAmount + calculatedTableChargeAmount).toStringAsFixed(2),
  );

  //-✅---recalculateAmounts------
  void recalculateAmounts(BuildContext context) {
    final subtotal = overallTotal; // tax-inclusive sum of all items

    // 🔹 Tax — per-item inclusive reverse breakdown (matches web app logic)
    // ✅ Modifier prices share the same tax_group as the parent item
    double totalNet = 0.0;
    double totalTax = 0.0;
    for (final item in selectedItems) {
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      double itemPrice = double.tryParse(item['price'].toString()) ?? 0.0;
      // ✅ Include modifier prices in tax base
      final mods = item['modifiers'] as List<dynamic>? ?? [];
      for (final mod in mods) {
        itemPrice += double.tryParse(mod['price']?.toString() ?? '0') ?? 0.0;
      }
      final totalPrice = qty * itemPrice; // tax-inclusive: item + modifiers
      final taxGroup = item['tax_group']?.toString() ?? '0';
      final breakdown = _calcTaxBreakdown(totalPrice, taxGroup);
      totalNet += breakdown['netPrice']!;
      totalTax += breakdown['totalTax']!;
    }
    calculatedTaxAmount = double.parse(totalTax.toStringAsFixed(2));
    calculatedNetExclTax = double.parse(totalNet.toStringAsFixed(2));

    // 🔹 Charges
    final chargesValue =
        double.tryParse(selectedChargesAmt?.toString() ?? "0") ?? 0.0;
    calculatedChargesAmount =
        (selectedChargesType?.toLowerCase() == "percentage")
        ? subtotal * chargesValue / 100
        : chargesValue;
    calculatedChargesAmount = double.parse(
      calculatedChargesAmount.toStringAsFixed(2),
    );

    // 🔹 Discount
    double discountPercent = 0.0;
    try {
      discountPercent = context
          .read<NumberInputDiscountProvider>()
          .value
          .toDouble();
    } catch (_) {}
    calculatedDiscountAmount = subtotal * discountPercent / 100;
    calculatedDiscountAmount = double.parse(
      calculatedDiscountAmount.toStringAsFixed(2),
    );

    // 🔹 Net Amount: tax-inclusive subtotal + charges - discount
    // ✅ Tax is already INSIDE subtotal — do NOT add calculatedTaxAmount again.
    calculatedNetAmount =
        subtotal + calculatedChargesAmount - calculatedDiscountAmount;
    calculatedNetAmount = double.parse(calculatedNetAmount.toStringAsFixed(2));
    calculatedTableChargeAmount = calculatePremiumTableCharge();

    notifyListeners();
  }

  //--🔹--BookingValidation---------------------------------------------🔹--//
  bool isBookingLoading = false;
  String? bookingLoadingAction;

  bool get isBookingLoader => isBookingLoading;

  void setBookingLoading(bool value, {String? action}) {
    isBookingLoading = value;
    if (value) {
      if (action != null) {
        bookingLoadingAction = action;
      }
    } else {
      bookingLoadingAction = null;
    }
    notifyListeners();
  }

  Future<void> BookingValidation(
    BuildContext context,
    String OrderStatus,
  ) async {
    GlobalFunction.hideKeyboard(context);
    final paxProvider = context.read<NumberInputPAXProvider>();
    final discountProvider = context.read<NumberInputDiscountProvider>();

    final validations = [
      {
        "condition": selectedItems.isEmpty,
        "message": "Please add at least one item to the order.",
      },
      {
        "condition": selectedTableType == null,
        "message": "Please Select Table Type!",
      },

      /*{
        "condition": MobileController.text.isEmpty,
        "message": "Please Enter Mobile Number",
      },
      {
        "condition": MobileController.text.length != 10,
        "message": "Please Enter Valid Mobile Number",
      },
      {
        "condition": CustomerMobileFound == false,
        "message": "Mobile Number not registered with us!",
      },*/
      // Sirf Dine In ke liye table validation
      {
        "condition":
            selectedTableType?.toLowerCase() == 'dine in' &&
            (selectedTableId == null || selectedTableId! <= 0),
        "message": "Please Select Table!",
      },

      // Sirf Dine In ke liye PAX validation
      /* {
        "condition": selectedTableType == "Dine In" && paxProvider.value == 0,
        "message": "Please Select PAX Person!",
      },*/

      /*{"condition": selectedTaxId == null, "message": "Please Select Tax!"},
      {
        "condition": selectedChargesId == null,
        "message": "Please Select Charges!",
      },
      {
        "condition": discountProvider.value == 0,
        "message": "Please Select Discount!",
      },*/
      {
        "condition":
            selectedTableType?.toLowerCase() != 'dine in' &&
            selectedPaymentMethodsId == null,
        "message": "Please Select Payment Method!",
      },
    ];

    for (var v in validations) {
      if (v["condition"] as bool) {
        PopupAlertHelper.showPopupFailedAlert(
          context,
          "Failed",
          "",
          v["message"] as String,
        );
        return;
      }
    }
    final isConnected = await GlobalFunction().checkInternetConnection(context);
    if (isConnected) {
      setBookingLoading(true, action: OrderStatus);
      // 🔹 Verify stock availability before placing order
      final canProceed = await checkStockService(context);
      if (!canProceed) {
        setBookingLoading(false);
        return;
      }

      // ✅ PRODUCTION FIX: Check if adding to existing order (occupied table scenario)
      final occupiedTable = selectedTables.firstWhere(
        (table) => table.isOccupied,
        orElse: () => OrderTableData(tableID: 0, tableName: ''),
      );

      if (occupiedTable.tableID != 0 && occupiedTable.occupiedOrderId != null) {
        // 🔹 TABLE IS OCCUPIED → Add items to existing order (MERGE)
        GlobalFunction().debugFunction(
          "🔄 MERGE MODE: Adding items to existing Order #${occupiedTable.occupiedOrderNumber} (ID: ${occupiedTable.occupiedOrderId})",
        );
        await addItemsToExistingOrderFlow(
          context,
          int.parse(occupiedTable.occupiedOrderId!),
        );
      } else {
        // 🔹 TABLE IS FREE → Create new order (NORMAL FLOW)
        GlobalFunction().debugFunction("✨ CREATE MODE: Creating new order");
        await BookingService(context, OrderStatus);
      }
      /*printBookingBody(context, OrderStatus);*/
    }
    notifyListeners();
  }

  //--🔹--addItemsToExistingOrderFlow (MERGE LOGIC)--------------------🔹--//
  /// 🎯 PRODUCTION FEATURE: Add items to existing order when table is occupied
  /// 📍 Called when user selects occupied table and places order
  /// 🔄 Uses POST /order-details/ per item — the same proven endpoint that
  ///    HomeController.addItemToOrderService uses. The backend creates the
  ///    item row AND recalculates order master totals automatically.
  Future<void> addItemsToExistingOrderFlow(
    BuildContext context,
    int existingOrderId,
  ) async {
    if (!context.mounted) return;

    final userInfoCtrl = Provider.of<UserInfoProvider>(context, listen: false);
    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);

    setBookingLoading(true);
    GlobalFunction.hideKeyboard(context);

    try {
      var headers = {
        'Authorization': 'Bearer ${userInfoCtrl.AccessToken ?? ""}',
        'Content-Type': 'application/json',
      };

      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // ── Step 1: Validate cart ──────────────────────────────────────
      int totalNewRows = 0;
      for (var item in selectedItems) {
        final int qty = (item['quantity'] as num?)?.toInt() ?? 0;
        final int productId = item['m_prod_id'] ?? 0;
        if (productId == 0 || qty == 0) continue;
        totalNewRows++;
        final List<dynamic> mods = item['modifiers'] as List<dynamic>? ?? [];
        totalNewRows += mods.length;
      }

      if (totalNewRows == 0) {
        PopupAlertHelper.showPopupFailedAlert(
          context,
          "Error",
          "",
          "No valid items to add.",
        );
        return;
      }

      // ── Step 2: GET existing order via DIRECT API ──────────────────
      // CRITICAL: Use GET /order-master/:id (NOT filter API).
      // The filter API returns Dart-enriched data (stored_tax_values,
      // tax_breakdown, quantity, subtotal) which confuses the backend.
      // The direct GET returns RAW DB fields (qty, net_amt, net_price,
      // tax_amt, etc.) — exactly what the web sends in its PUT.
      GlobalFunction().debugFunction(
        "📦 Adding $totalNewRows rows to Order #$existingOrderId (direct GET approach)",
      );

      final dynamic orderResp = await httpCtrl.request(
        method: 'GET',
        url: '${GlobalServiceURL.OrderListUrl}$existingOrderId',
        context: context,
        headers: headers,
        requireLogin: true,
      );

      List<dynamic> existingRawDetails = [];
      if (orderResp is Map<String, dynamic>) {
        // Direct GET may return { order_id, details, ... } or { success, order: { ... } }
        final dynamic orderData = orderResp['order'] ?? orderResp;
        if (orderData is Map<String, dynamic>) {
          existingRawDetails = (orderData['details'] as List<dynamic>?) ?? [];
        }
      }

      GlobalFunction().debugFunction(
        '🔍 Existing order $existingOrderId has ${existingRawDetails.length} raw items (from direct GET)',
      );

      // Log raw detail fields so we can verify exact DB values
      for (final item in existingRawDetails) {
        if (item is Map) {
          GlobalFunction().debugFunction(
            "  🔍 RAW DB [${item['order_det_id']}]: "
            "${item['product']?['m_p_name'] ?? item['name'] ?? ''} "
            "qty=${item['qty']}, rate=${item['rate']}, "
            "net_amt=${item['net_amt']}, net_price=${item['net_price']}, "
            "tax_amt=${item['tax_amt']}, extra_amt=${item['extra_amt']}, "
            "type=${item['type']}, link=${item['link']}",
          );
        }
      }

      // ── Step 3: Combine existing items + new items ──────────────────
      // WEB MATCHING: Send existing items 100% RAW from direct GET.
      // The web does: const existingDetails = existingOrderData.details || [];
      //               const allDetails = [...existingDetails, ...newDetails];
      // ZERO modifications to existing items.
      final List<dynamic> allDetails = [];

      // Existing items: send 100% RAW from direct GET response
      for (final item in existingRawDetails) {
        if (item is! Map) continue;
        // Deep copy to avoid modifying the original
        allDetails.add(Map<String, dynamic>.from(item as Map));
      }

      final int existingCount = allDetails.length;

      // ── Step 3b: Build NEW item rows from cart ─────────────────────
      // Web uses: cart.forEach((item, index) => { ... link: index ... })
      // link = cart item index (0-based), NOT the combined allDetails index
      int cartItemIndex = 0;

      for (var item in selectedItems) {
        final int qty = (item['quantity'] as num?)?.toInt() ?? 0;
        final double price = double.tryParse(item['price'].toString()) ?? 0.0;
        final int productId = item['m_prod_id'] ?? 0;
        final String? userNote = item['note']?.toString().trim();

        if (productId == 0 || qty == 0) continue;

        final List<dynamic> modifiers =
            item['modifiers'] as List<dynamic>? ?? [];
        final String taxGroup = item['tax_group']?.toString() ?? '0';

        // Product row — rate = product price ONLY (not inflated with modifiers)
        final double productNetAmt = qty * price;
        final String cartUuid =
            item['cart_entry_id'] as String? ?? _generateCartUuid();

        // Web uses cart index for modifier link, NOT allDetails index
        final int currentCartIndex = cartItemIndex;

        final Map<String, dynamic> productRow = {
          'm_prod_id': productId,
          'qty': qty,
          'rate': double.parse(price.toStringAsFixed(2)),
          'net_amt': double.parse(productNetAmt.toStringAsFixed(2)),
          'status': 'ordered',
          'type': 'product',
          'link': null,
          'cart_uuid': cartUuid,
        };
        if (userNote != null && userNote.isNotEmpty) {
          productRow['note'] = userNote;
        }
        allDetails.add(productRow);

        GlobalFunction().debugFunction(
          "  📦 New product: ${item['m_p_name']} × $qty @ SAR $price"
          " | tax_group=$taxGroup, cartIndex=$currentCartIndex",
        );

        // Modifier rows — separate, linked to parent by cart index
        for (final mod in modifiers) {
          final double modPrice =
              double.tryParse(mod['price']?.toString() ?? '0') ?? 0.0;
          final int modProdId = mod['modifier_id'] as int? ?? 0;
          final String modName = mod['modifier_name']?.toString() ?? '';
          if (modProdId == 0) continue;

          final double modNetAmt = qty * modPrice;
          allDetails.add({
            'm_prod_id': modProdId,
            'qty': qty,
            'rate': double.parse(modPrice.toStringAsFixed(2)),
            'net_amt': double.parse(modNetAmt.toStringAsFixed(2)),
            'status': 'ordered',
            'type': 'modifier',
            'link': currentCartIndex, // cart index, matching web
            'note': modName,
            'cart_uuid': cartUuid,
          });

          GlobalFunction().debugFunction(
            "  📦 New modifier: $modName × $qty @ SAR $modPrice"
            " | link=$currentCartIndex, tax_group=$taxGroup",
          );
        }

        cartItemIndex++;
      }

      // ── Step 4: Calculate total from all items ─────────────────────
      // CRITICAL: For existing items from direct GET, the product row's
      // net_amt is already inflated (includes modifier prices), AND there
      // are separate modifier rows with their own net_amt. Summing both
      // would double-count modifiers.
      //
      // The web avoids this because it fetches from the filter API which
      // returns non-inflated data. Since we use the direct GET, we must
      // skip existing modifier rows (they have order_det_id + type=modifier).
      //
      // For NEW items, product net_amt = qty × price (NO modifiers), so
      // new modifier rows DO need to be counted.
      double totalSubtotal = 0;
      for (final item in allDetails) {
        if (item is Map) {
          // Skip existing modifier rows — their price is already baked
          // into the parent product row's DB net_amt.
          final bool isExisting = item.containsKey('order_det_id');
          final String itemType = (item['type']?.toString() ?? '')
              .toLowerCase();
          if (isExisting && itemType == 'modifier') continue;

          final dynamic netAmtVal = item['net_amt'];
          if (netAmtVal != null) {
            totalSubtotal += double.tryParse(netAmtVal.toString()) ?? 0;
          }
        }
      }

      GlobalFunction().debugFunction(
        '🔄 Combined details: ${allDetails.length} items '
        '($existingCount existing + ${allDetails.length - existingCount} new), '
        'total_subtotal=$totalSubtotal',
      );

      // ── Step 5: ONE PUT /order-master/{id} ─────────────────────────
      // CRITICAL: Send FLAT body (NO 'orderData' wrapper).
      // The web sends: { order_details, net_amt, ... } at TOP level.
      // The backend looks for 'order_details' at the top level:
      //   - Keeps existing items (those with order_det_id)
      //   - Creates new items (those without order_det_id)
      //   - Properly stores type, link, tax fields for new items
      //   - Recalculates net_price/tax_amt/extra_amt from tax_group
      //   - Recalculates order totals from all items
      final newTables = selectedTables.where((t) => !t.isOccupied).toList();
      final String tableIdStr = selectedTables.map((t) => t.tableID).join(',');
      final String newTableIdStr = newTables.map((t) => t.tableID).join(',');

      final Map<String, dynamic> putBody = {
        'table_id': tableIdStr,
        'new_table_id': newTableIdStr,
        'net_amt': double.parse(totalSubtotal.toStringAsFixed(2)),
        'tax_amt': 0,
        'discount_amt': 0,
        'total_amt': double.parse(totalSubtotal.toStringAsFixed(2)),
        'order_details': allDetails,
        'modified_by': userInfoCtrl.orgUserId ?? '',
        'stock_validation_mode': 'strict',
        'check_stock': true,
      };

      GlobalFunction().debugFunction(
        '📤 PUT /order-master/$existingOrderId with ${allDetails.length} items',
      );

      final dynamic putResp = await httpCtrl.request(
        method: 'PUT',
        url: '${GlobalServiceURL.UpdateExistingOrderUrl}$existingOrderId',
        context: context,
        headers: headers,
        body: putBody,
        requireLogin: true,
      );

      final bool putOk = putResp is Map && putResp['success'] == true;
      if (putOk) {
        final respOrder = putResp['order'];
        final String respTotal = respOrder is Map
            ? (respOrder['total_amt']?.toString() ?? '')
            : '';
        final int respItems = respOrder is Map && respOrder['details'] is List
            ? (respOrder['details'] as List).length
            : 0;

        // Log each item's tax fields from response
        if (respOrder is Map && respOrder['details'] is List) {
          for (final rd in (respOrder['details'] as List)) {
            if (rd is Map) {
              GlobalFunction().debugFunction(
                '   RESP [${rd["order_det_id"]}] ${rd["product"]?["m_p_name"] ?? ""} '
                'net_price=${rd["net_price"]}, tax_amt=${rd["tax_amt"]}, '
                'extra_amt=${rd["extra_amt"]}, type=${rd["type"]}, link=${rd["link"]}',
              );
            }
          }
        }

        GlobalFunction().debugFunction(
          '✅ PUT success: total_amt=$respTotal, items=$respItems',
        );
      } else {
        GlobalFunction().debugFunction(
          '⚠️ PUT response: ${putResp is Map ? putResp['message'] : putResp}',
        );
      }

      showCustomToast(
        context: context,
        message: "$cartItemIndex items added to Order #$existingOrderId",
      );

      // 🖨️ KDS auto-print — print ONLY the new items just added, not the
      // full merged order (existing items were already printed when first ordered).
      // Snapshot selectedItems NOW before _clearCartAndNavigateHome clears them.
      if (context.mounted) {
        final List<Map<String, dynamic>> newItemsSnapshot =
            List<Map<String, dynamic>>.from(
              selectedItems.whereType<Map<String, dynamic>>(),
            );
        // Pull order_no from PUT response for the ticket header.
        final dynamic respOrderData = (putResp is Map)
            ? putResp['order']
            : null;
        final String existingOrderNo = respOrderData is Map
            ? (respOrderData['order_no']?.toString() ??
                  existingOrderId.toString())
            : existingOrderId.toString();
        _triggerKdsAutoPrintForNewItems(
          context,
          existingOrderNo,
          newItemsSnapshot,
        );
      }

      await _clearCartAndNavigateHome(context);
    } catch (e, stack) {
      GlobalFunction().debugFunction(
        "❌ Error in addItemsToExistingOrderFlow: $e",
      );
      debugPrintStack(stackTrace: stack);
      PopupAlertHelper.showPopupFailedAlert(
        context,
        "Error",
        "",
        "Failed to add items. Please try again.",
      );
    } finally {
      setBookingLoading(false);
      notifyListeners();
    }
  }

  /// Helper: Clear cart and navigate to home after successful order
  Future<void> _clearCartAndNavigateHome(BuildContext context) async {
    // Clear cart
    selectedItems.clear();
    selectedTableId = null;
    selectedTableDisplayName = null;
    selectedDPOrderTable = null;
    selectedTableType = null;
    selectedTables = [];

    notifyListeners();

    // ✅ Immediately refresh the order list so that when the user lands on
    // HomeScreen the updated totals (recalculated by the backend after new
    // items were added) are already in memory.  Using silent=true avoids
    // showing the full-screen skeleton loader during this background refresh.
    final homeCtrl = Provider.of<HomeProvider>(context, listen: false);
    if (context.mounted) {
      final formattedDate =
          "${homeCtrl.selectedDate.year}-${homeCtrl.selectedDate.month.toString().padLeft(2, '0')}-${homeCtrl.selectedDate.day.toString().padLeft(2, '0')}";
      await homeCtrl.getOrderListService(
        context,
        homeCtrl.selectedFilter,
        formattedDate,
        silent: true,
      );
    }

    // Navigate back to home
    if (context.mounted) {
      closeOrderSummaryPanel();
      Navigator.pop(context);
    }
  }

  //--🔹--getSelectedItemsForApi----------------------------------------🔹--//
  /// Builds the `details` array sent to POST /order-master.
  /// Each cart item produces:
  ///   - 1 "product" row
  ///   - N "modifier" rows (one per selected modifier), all sharing the same
  ///     cart_uuid so the backend can group them.
  List<Map<String, dynamic>> getSelectedItemsForApi() {
    final List<Map<String, dynamic>> rows = [];

    for (final item in selectedItems) {
      final qty = (item['quantity'] as num?)?.toInt() ?? 0;
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      final note = item['note']?.toString() ?? '';
      // ✅ tax_group required by backend for per-item inclusive tax calculation
      final taxGroup = item['tax_group']?.toString() ?? '0';
      // ✅ Use the item's cart_entry_id as cart_uuid when present (modifier split
      // entries already have a unique ID assigned). Fallback to a fresh UUID for
      // non-modifier items so every product row still has a unique cart_uuid.
      final cartUuid = item['cart_entry_id'] as String? ?? _generateCartUuid();

      // ── Product net_amt = (rate + modifiers) × qty ────────────────────
      // Web calculateItemTotalPrice: (basePrice + modifierTotal) * qty.
      // Modifier prices are INCLUDED in the product row's net_amt so the
      // backend's product-row-only total calculation gives the correct grand
      // total. Modifier rows are sent separately for display/tracking only.
      final modifiers = item['modifiers'] as List<dynamic>? ?? [];
      double modifierPriceTotal = 0.0;
      for (final mod in modifiers) {
        modifierPriceTotal +=
            double.tryParse(mod['price']?.toString() ?? '0') ?? 0.0;
      }
      final productNetAmt = (price + modifierPriceTotal) * qty;

      // ── Product row ──────────────────────────────────────────────────
      rows.add({
        "m_prod_id": item['m_prod_id'],
        "combo_id": null,
        "qty": qty,
        "rate": price, // original product rate (for display)
        "net_amt": double.parse(productNetAmt.toStringAsFixed(2)),
        "status": "ordered",
        "note": note,
        "tax_group": taxGroup,
        "type": "product",
        "link": null,
        "cart_uuid": cartUuid,
      });

      // ── Modifier rows ────────────────────────────────────────────────
      // critical: do not  send tax_group on modifier rows.The web never sends
      // tax_group for modifier rows. When the backend sees tax_group on a
      // modifier row it independently recalculates tax and includes that row
      // in the order total — double-counting the modifier price that is
      // already embedded in the parent product row's net_amt.
      for (final mod in modifiers) {
        final modPrice =
            double.tryParse(mod['price']?.toString() ?? '0') ?? 0.0;
        final modNetAmt = (qty * modPrice).toStringAsFixed(2);
        rows.add({
          "m_prod_id": mod['modifier_id'],
          "combo_id": null,
          "qty": qty,
          "rate": modPrice,
          "net_amt": double.parse(modNetAmt),
          "status": "ordered",
          "note": mod['modifier_name']?.toString() ?? '',
          // NO tax_group — matches web; prevents backend double-counting
          "type": "modifier",
          "link": cartUuid,
          "cart_uuid": cartUuid,
        });
      }
    }

    return rows;
  }

  //--🔹--_generateCartUuid (Helper)------------------------------------🔹--//
  /// Generates a unique cart UUID for grouping a product with its modifier rows.
  /// Format: cart-[random_base36]-[timestamp_base36]
  String _generateCartUuid() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = (Random().nextInt(999999999) + 1)
        .toRadixString(36)
        .padLeft(9, '0');
    return 'cart-$rand-$ts';
  }

  //--🔹--hasStockProducts (Helper)-------------------------------------🔹--//
  /// returns true if any item currently in the cart has stock tracking enabled.
  bool get hasStockProducts {
    for (final item in selectedItems) {
      final id = item['m_prod_id'] as int?;
      if (id == null) continue;
      try {
        final menuItem = MenuListing.firstWhere((m) => m.mProdId == id);
        if (menuItem.stockProduct == true) return true;
      } catch (_) {}
    }
    return false;
  }

  //--🔹--checkStockService---------------------------------------------🔹--//
  /// Calls POST /order-master/check-stock with all cart item IDs.
  /// Returns [true] if order can proceed, [false] if blocked due to stock issues.
  Future<bool> checkStockService(BuildContext context) async {
    if (!context.mounted) return true;

    // Skip check if no stock-tracked products in cart
    if (!hasStockProducts) return true;

    // Build cart_items list: one entry per unit ordered
    final List<int> cartItems = [];
    for (final item in selectedItems) {
      final id = item['m_prod_id'] as int?;
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      if (id != null) {
        for (int i = 0; i < qty; i++) {
          cartItems.add(id);
        }
      }
    }

    if (cartItems.isEmpty) return true;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final dynamic responseRaw = await httpCtrl.request(
        method: 'POST',
        url: CheckStockService,
        context: context,
        headers: authHeaders,
        body: {"cart_items": cartItems},
        requireLogin: true,
      );

      if (responseRaw is Map<String, dynamic>) {
        final result = CheckStockResponse.fromJson(responseRaw);

        if (!result.canPlaceOrder && result.stockIssues.isNotEmpty) {
          // 🔹 Build issue message
          final issueLines = result.stockIssues
              .map(
                (issue) =>
                    "• ${issue.productName}: needed ${issue.requested}, available ${issue.available}",
              )
              .join("\n");

          if (context.mounted) {
            await PopupAlertHelper.showPopupFailedAlert(
              context,
              "Stock Unavailable",
              "OK",
              "These items are out of stock:\n$issueLines\n\nPlease reduce quantities and try again.",
            );
          }
          return false; // 🚫 Block order
        }

        return result.canPlaceOrder; // ✅ Allow order
      }
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      // On error, allow order to proceed (fail-open for stock check)
    }

    return true;
  }

  //--🔹--printBookingBody (Optional for Debugging)----------------------🔹--//
  /*  void printBookingBody(BuildContext context, String OrderStatus) {
    final apiItems = getSelectedItemsForApi();
    final userInfoCtrl = Provider.of<UserInfoProvider>(context, listen: false);
    final body = {
      "cust_id": "0",
      "table_id": selectedTableId?.toString() ?? "",
      "order_date": DateTime.now().toUtc().toIso8601String(),
      "type": selectedTableType.toString(),
      "net_amt": overallTotal.toString(),
      "taxid": selectedTaxId.toString(),
      "tax_amt": calculatedTaxAmount.toString(),
      "charge_id": selectedChargesId.toString(),
      "charge_amt": calculatedChargesAmount.toString(),
      "pay_m_id": selectedPaymentMethodsId.toString(),
      "order_status": OrderStatus.toString(),
      "discount_per": context
          .read<NumberInputDiscountProvider>()
          .value
          .toString(),
      "discount_amt": calculatedDiscountAmount.toString(),
      "total_amt": calculatedNetAmount.toString(),
      "created_by": userInfoCtrl.orgId.toString(),
      "org_id": userInfoCtrl.orgId.toString(),
      "branch_id": userInfoCtrl.branchId.toString(),
      "pax": context.read<NumberInputPAXProvider>().value.toString(),
      "priority": selectedOrderPriority.toString(),
      "details": apiItems,
    };

    // Print as Map
    GlobalFunction().debugFunction("Booking Body as Map: $body");
    // Print as formatted JSON
    final prettyBody = JsonEncoder.withIndent('  ').convert(body);
    GlobalFunction().debugFunction("Booking Body JSON:\n$prettyBody");
  }*/

  //--🔹--BookingService with http.Request-------------------------------🔹--//
  Future<void> BookingService(BuildContext context, String OrderStatus) async {
    if (!context.mounted) return;

    // check if cash drawer is open before creating order
    final drawerCtrl = Provider.of<CashDrawerProvider>(context, listen: false);
    if (!drawerCtrl.isDrawerOpen) {
      GlobalFunction().showError(
        context,
        "Cash drawer is closed. Please open the drawer to create orders.",
      );
      return;
    }

    // ✅✅✅ DEBUG: Log selectedItems BEFORE creating apiItems
    GlobalFunction().debugFunction(
      "🔍🔍🔍 BEFORE API CALL - selectedItems count: ${selectedItems.length}",
    );
    for (var i = 0; i < selectedItems.length; i++) {
      final item = selectedItems[i];
      GlobalFunction().debugFunction(
        "🔍 Item $i: ${item['m_p_name']} (ID: ${item['m_prod_id']}) × ${item['quantity']} = SAR ${item['price']}",
      );
    }

    final apiItems = getSelectedItemsForApi();

    // ✅✅✅ DEBUG: Log apiItems AFTER transformation
    GlobalFunction().debugFunction(
      "🔍🔍🔍 AFTER getSelectedItemsForApi() - apiItems count: ${apiItems.length}",
    );
    double debugDetailSum = 0;
    for (var i = 0; i < apiItems.length; i++) {
      final item = apiItems[i];
      final netAmt = (item['net_amt'] as num?)?.toDouble() ?? 0;
      debugDetailSum += netAmt;
      GlobalFunction().debugFunction(
        "🔍 API Item $i: [${item['type']}] Product ID ${item['m_prod_id']} × ${item['qty']} @ SAR ${item['rate']} = SAR ${item['net_amt']}",
      );
    }
    GlobalFunction().debugFunction(
      "🔍🔍🔍 TOTAL CHECK: detail_rows_sum=$debugDetailSum, overallTotal=$overallTotal, "
      "calculatedNetAmount=$calculatedNetAmount — these should match (detail_rows_sum == overallTotal)",
    );
    final userInfoCtrl = Provider.of<UserInfoProvider>(context, listen: false);
    final CashAmountCtrl = Provider.of<CashAmountProvider>(
      context,
      listen: false,
    );
    final CardAmountCtrl = Provider.of<CardAmountProvider>(
      context,
      listen: false,
    );

    final isConnected = await GlobalFunction().checkInternetConnection(context);
    if (!isConnected) return;

    GlobalFunction.hideKeyboard(context);
    setBookingLoading(true);

    try {
      // 🔹 Build headers
      var headers = {
        'Authorization': 'Bearer ${userInfoCtrl.AccessToken ?? ""}',
        'Content-Type': 'application/json',
      };

      // 🔹 Build body
      final isSplit =
          selectedPaymentMethodsType.toString().toUpperCase() == "SPLIT";

      // ✅ Count items that do not have stock tracking enabled
      final itemsWithoutStockCheck = selectedItems.where((item) {
        final id = item['m_prod_id'] as int?;
        if (id == null) return true;
        try {
          final menuItem = MenuListing.firstWhere((m) => m.mProdId == id);
          return menuItem.stockProduct != true;
        } catch (_) {
          return true;
        }
      }).length;

      // Capture the order note NOW — before any async gaps — so the auto-print
      // and the API body both use exactly the same value.
      final capturedOrderNote = OrderNoteController.text.trim().isEmpty
          ? null
          : OrderNoteController.text.trim();

      var body = {
        "cust_id": null,
        "table_id": selectedTables.map((t) => t.tableID).join(','),
        "order_date": DateTime.now().toUtc().toIso8601String(),
        "type": selectedTableType ?? "Dine In",
        // ✅ net_amt = pre-tax sum (backend stores/expects pre-tax value)
        // calculatedNetExclTax is derived by _calcTaxBreakdown per item
        "net_amt": calculatedNetExclTax > 0
            ? calculatedNetExclTax
            : overallTotal,
        "order_des": capturedOrderNote,
        "taxid": selectedTaxId ?? 0,
        "tax_amt": calculatedTaxAmount,
        "charge_id": selectedChargesId,
        "charge_amt": calculatedChargesAmount,
        // Table charge is applied when the order goes through payment, not
        // when the dine-in order is first created.
        "table_charge": 0.0,
        "pay_m_id": selectedPaymentMethodsId ?? 0,
        "order_status": OrderStatus,
        "discount_per": context.read<NumberInputDiscountProvider>().value,
        "discount_amt": calculatedDiscountAmount,
        "total_amt": calculatedNetAmount,
        "created_by": userInfoCtrl.orgId ?? "",
        "modified_by": userInfoCtrl.orgUserId ?? "",
        "org_id": userInfoCtrl.orgId ?? "",
        "branch_id": userInfoCtrl.branchId ?? 0,
        "pax": context.read<NumberInputPAXProvider>().value,
        "priority": selectedOrderPriority ?? "normal",
        "payment_status": selectedPaymentStatus.toString().toLowerCase(),
        "stock_validation_mode": "strict",
        "has_stock_issues": false,
        "items_without_stock_check": itemsWithoutStockCheck,
        "details": apiItems,
        "check_stock": hasStockProducts,
        "is_split_payment": isSplit,
        // Send as double (number) matching web behaviour so backend creates Cash/Card entries
        "cashout": isSplit
            ? (double.tryParse(CashAmountCtrl.controller.text) ?? 0.0)
            : null,
        "cardout": isSplit
            ? (double.tryParse(CardAmountCtrl.controller.text) ?? 0.0)
            : null,
        "payment_type": selectedPaymentMethodsType?.toLowerCase(),
      };

      // 🔹 Debug: URL, headers, body
      GlobalFunction().debugFunction(
        "📤 Booking API URL: $BookingOrderService",
      );
      GlobalFunction().debugFunction("📤 Headers: $headers");

      // ✅✅✅ DEBUG: Log details array specifically
      GlobalFunction().debugFunction(
        "📤 Body details array (${(body['details'] as List).length} items):",
      );
      final detailsList = body['details'] as List;
      for (var i = 0; i < detailsList.length; i++) {
        GlobalFunction().debugFunction("   [$i] ${jsonEncode(detailsList[i])}");
      }

      GlobalFunction().debugFunction("📤 Full Body:\n${jsonEncode(body)}");

      // 🔹 Create request
      var request = http.Request('POST', Uri.parse(BookingOrderService));
      request.headers.addAll(headers);
      request.body = jsonEncode(body);

      // 🔹 Send request
      http.StreamedResponse response = await request.send();

      // 🔹 Read response
      final responseBody = await response.stream.bytesToString();
      GlobalFunction().debugFunction("📥 Status Code: ${response.statusCode}");
      GlobalFunction().debugFunction("📥 API Response:\n$responseBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(responseBody);
        final message = result['message']?.toString() ?? 'Success';

        // ✅ Treat any 200/201 response as success (backend may vary message text)
        final bool isSuccess =
            response.statusCode == 200 ||
            response.statusCode == 201 ||
            result['success'] == true ||
            (message.toLowerCase().contains('created') ||
                message.toLowerCase().contains('success'));

        showCustomToast(
          context: context,
          message: message.isNotEmpty ? message : 'Order placed successfully!',
          backgroundColor: GlobalAppColor.ButtonColor,
        );

        if (isSuccess) {
          // ✅ FIX: Set pendingRefresh BEFORE Navigator.pop so HomeScreen sees
          // it immediately when `await navigateToScreen(...)` returns.
          // After pop, the AddNewOrder context is unmounted but HomeProvider
          // (which lives above in the widget tree) stays alive — flag is safe.
          final homeProvider = context.read<HomeProvider>();
          homeProvider.setPendingRefresh(true); // ← must be BEFORE pop

          // 🖨️ Auto-print KDS ticket to backend-configured KDS printer.
          // Fire-and-forget — never blocks or interrupts the order submission flow.
          _triggerKdsAutoPrint(context, result, capturedOrderNote);

          closeOrderSummaryPanel();
          Navigator.pop(context);
        }
      } else {
        // 🔹 API returned non-200
        GlobalFunction().debugFunction(
          "❌ Server error: ${response.reasonPhrase}",
        );
        showCustomToast(
          context: context,
          message: "Server error: ${response.reasonPhrase}",
          backgroundColor: GlobalAppColor.ButtonColor,
        );
      }
    } catch (e, stack) {
      //GlobalFunction().debugFunction("❌ Error while booking: $e");
      debugPrintStack(stackTrace: stack);
      GlobalFunction().showError(context, GlobalFlag.SomethingWrong);
    } finally {
      setBookingLoading(false);
    }

    notifyListeners();
  }

  // ── KDS Auto-Print ──────────────────────────────────────────────────────//
  /// Fires KDS auto-print immediately after a successful order creation.
  /// This is intentionally synchronous-looking but unawaited internally.
  /// Any exception is caught; the order flow is never blocked.
  ///
  /// [capturedOrderNote] must be pre-captured before any async gaps to guarantee
  /// the note text is the same value already sent in the API body.
  void _triggerKdsAutoPrint(
    BuildContext context,
    Map<String, dynamic> result,
    String? capturedOrderNote,
  ) {
    if (!context.mounted) return;

    final printingDeviceProvider = context.read<PrintingDeviceProvider>();
    final printerProvider = context.read<PrinterIntegrationProvider>();
    final userInfo = Provider.of<UserInfoProvider>(context, listen: false);

    // Extract order number — try multiple common backend response shapes
    final orderNo =
        result['data']?['order_no']?.toString() ??
        result['order']?['order_no']?.toString() ??
        result['order_no']?.toString() ??
        '';

    final storeName = userInfo.orgName ?? '';

    // Table name without the "(Seats: X)" suffix appended by modal selection
    final tableName = selectedTableDisplayName?.split(' (Seats:').first.trim() ?? '';

    final now = DateTime.now();
    final printDate =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    // Build KDS items — products followed by their modifiers as separate
    // "+" rows.  This matches HomeWidget (manual print) exactly, and is the
    // format Kotlin expects: items whose name starts with "+" are rendered
    // as indented modifier lines.
    // NOTE: do NOT use PrintJobItem.modifiers (List<String>) — Kotlin does
    // not read that field; only the "+" item-name convention is handled.
    final List<PrintJobItem> kdsItems = [];
    for (final item in selectedItems) {
      final itemNote = item['note']?.toString().trim();
      kdsItems.add(
        PrintJobItem(
          name: item['m_p_name']?.toString() ?? 'Item',
          quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          price: double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
          notes: (itemNote == null || itemNote.isEmpty) ? null : itemNote,
        ),
      );
      // Expand each selected modifier as a separate "+ modifierName" item,
      // exactly as HomeWidget does for the manual KDS print path.
      final rawMods = item['modifiers'] as List<dynamic>?;
      if (rawMods != null) {
        for (final mod in rawMods) {
          final modName = mod['modifier_name']?.toString() ?? '';
          if (modName.isNotEmpty) {
            kdsItems.add(
              PrintJobItem(
                name: '+ $modName',
                quantity: ((mod['quantity'] as num?)?.toInt() ?? 1) *
                    ((item['quantity'] as num?)?.toInt() ?? 1),
                price: double.tryParse(mod['price']?.toString() ?? '0') ?? 0.0,
              ),
            );
          }
        }
      }
    }

    // Fire-and-forget with visual feedback.  The returned Future is
    // intentionally unawaited so the order flow is never blocked.
    // .then / .catchError run on the microtask queue, after Navigator.pop
    // has already returned control to the home screen.
    printingDeviceProvider
        .autoPrintKDS(
          printerProvider: printerProvider,
          orderData: {
            'storeName': storeName,
            'orderNumber': orderNo,
            'tableName': tableName,
            'orderType': selectedTableType ?? 'Dine In',
            'items': kdsItems,
            'priority': selectedOrderPriority ?? 'normal',
            'date': printDate,
            'orderNotes': capturedOrderNote,
          },
        )
        .then((success) {
          if (success) {
            debugPrint(
              '✅ [AutoPrint] KDS auto-print completed for order $orderNo',
            );
          } else {
            debugPrint(
              '⚠️  [AutoPrint] KDS auto-print skipped or failed for order $orderNo',
            );
          }
        })
        .catchError((e) {
          debugPrint('⚠️  [AutoPrint] KDS auto-print error: $e');
        });
  }

  // ── KDS Auto-Print (existing-order add) ────────────────────────────────//
  /// Fires KDS auto-print after items are added to an existing order.
  /// Prints ONLY the newly-added items — the existing items were already
  /// printed when the original order was placed.
  void _triggerKdsAutoPrintForNewItems(
    BuildContext context,
    String orderNo,
    List<Map<String, dynamic>> newItems,
  ) {
    if (!context.mounted || newItems.isEmpty) return;

    final printingDeviceProvider = context.read<PrintingDeviceProvider>();
    final printerProvider = context.read<PrinterIntegrationProvider>();
    final userInfo = Provider.of<UserInfoProvider>(context, listen: false);

    final storeName = userInfo.orgName ?? '';

    final tableName = selectedTableDisplayName?.split(' (Seats:').first.trim() ?? '';

    final now = DateTime.now();
    final printDate =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    // Build KDS items from new items only — same format as _triggerKdsAutoPrint
    final List<PrintJobItem> kdsItems = [];
    for (final item in newItems) {
      final itemNote = item['note']?.toString().trim();
      kdsItems.add(
        PrintJobItem(
          name: item['m_p_name']?.toString() ?? 'Item',
          quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          price: double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
          notes: (itemNote == null || itemNote.isEmpty) ? null : itemNote,
        ),
      );
      final rawMods = item['modifiers'] as List<dynamic>?;
      if (rawMods != null) {
        for (final mod in rawMods) {
          final modName = mod['modifier_name']?.toString() ?? '';
          if (modName.isNotEmpty) {
            kdsItems.add(
              PrintJobItem(
                name: '+ $modName',
                quantity: ((mod['quantity'] as num?)?.toInt() ?? 1) *
                    ((item['quantity'] as num?)?.toInt() ?? 1),
                price: double.tryParse(mod['price']?.toString() ?? '0') ?? 0.0,
              ),
            );
          }
        }
      }
    }

    if (kdsItems.isEmpty) return;

    // Fire-and-forget with logging — same pattern as _triggerKdsAutoPrint
    printingDeviceProvider
        .autoPrintKDS(
          printerProvider: printerProvider,
          orderData: {
            'storeName': storeName,
            'orderNumber': orderNo,
            'tableName': tableName,
            'orderType': selectedTableType ?? 'Dine In',
            'items': kdsItems,
            'priority': selectedOrderPriority ?? 'normal',
            'date': printDate,
            'orderNotes': null,
          },
        )
        .then((success) {
          if (success) {
            debugPrint(
              '✅ [AutoPrint] KDS auto-print (add items) completed for order $orderNo',
            );
          }
        })
        .catchError((e) {
          debugPrint('⚠️  [AutoPrint] KDS auto-print (add items) error: $e');
        });
  }

  //--🔹--Mobile-Verification with http.Request--------------------------🔹--//
  bool CustomerMobileFound = true;
  TextEditingController NameController = TextEditingController();
  final FocusNode myFocusNodeName = FocusNode();

  TextEditingController EmailController = TextEditingController();
  final FocusNode myFocusNodeEmail = FocusNode();

  TextEditingController AddressController = TextEditingController();
  final FocusNode myFocusNodeAddress = FocusNode();

  TextEditingController SpecialInstructionsController = TextEditingController();
  final FocusNode myFocusNodeSpecialInstructions = FocusNode();

  bool isMobileVerificationLoading = false;

  bool get isMobileVerificationLoader => isMobileVerificationLoading;

  void setMobileVerificationLoading(bool value) {
    isMobileVerificationLoading = value;
    notifyListeners();
  }

  //--🔹--MobileVerificationService--------------------------------------🔹--//
  String? CustomerName;
  String? CustomerMobile;
  String? CustomerDiscount;
  Timer? debounce;

  Future<bool> MobileVerificationService(
    BuildContext context,
    String mobile,
  ) async {
    if (!context.mounted) return false;
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    final httpCtrl = context.read<HttpServiceProvider>();

    try {
      // ✅ Loader ON
      GlobalFunction.hideKeyboard(context);
      setBookingLoading(true);
      notifyListeners();

      // ✅ Step 1: Internet Check
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) {
        GlobalFunction().debugFunction(
          "🚫 Internet not connected — API skipped",
        );
        setBookingLoading(false);
        return false;
      }

      // ✅ Step 2: Start HTTP client if not active
      if (!httpCtrl.isApiActive) {
        httpCtrl.startHttpClient();
        GlobalFunction().debugFunction("🌐 Http client started");
      }

      // ✅ Step 3: API Call
      final response = await httpCtrl.request(
        method: 'GET',
        url: "$SearchMobileService$mobile",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // ✅ Debug full response
      GlobalFunction().debugFunction("📩 API Response: $response");

      // ✅ Step 4: Parse Response
      final String message = (response['message'] ?? '').toString().trim();
      final dynamic customerData = response['customer'];
      if (message.isEmpty) {
        showCustomToast(
          context: context,
          message: "Empty response from server",
        );
        return false;
      }

      if (message.toLowerCase().contains('not found')) {
        // ❌ Customer not found
        CustomerMobileFound = false;
        CustomerName = null;
        CustomerMobile = null;
        CustomerDiscount = null;
        GlobalFunction().debugFunction("⚠️ $message");
        showCustomToast(
          context: context,
          message: message,
        ); // ✅ show message from API
        return false;
      } else {
        // ✅ Customer found or any other success case
        CustomerMobileFound = true;
        GlobalFunction().debugFunction("✅ $message");
        showCustomToast(
          context: context,
          message: message,
        ); // ✅ same message from API
        // ✅ Discount update logic
        if (customerData != null && customerData['discount'] != null) {
          final discountValue =
              int.tryParse(customerData['discount'].toString()) ?? 0;

          // Discount value ko 0–100 ke beech clamp karna
          final clampedDiscount = discountValue.clamp(0, 100);

          // Manual input method se update karna
          context.read<NumberInputDiscountProvider>().manualInput(
            context,
            clampedDiscount.toString(),
          );
          // Customer name ko ek variable me store karna
          CustomerName = customerData['name']?.toString() ?? 'Unknown';
          CustomerMobile = customerData['mobile']?.toString() ?? 'Unknown';
          CustomerDiscount = customerData['discount']?.toString() ?? '0';
          GlobalFunction().debugFunction(
            "Customer Name: $CustomerName ,Customer Mobile: $CustomerMobile,Customer Discount: $CustomerDiscount",
          );
        }

        return true;
      }
    } catch (e, stack) {
      // ❌ Error Handling
      GlobalFunction().debugFunction(
        "❌ Error in MobileVerificationService: $e",
      );
      debugPrintStack(stackTrace: stack);
      showCustomToast(context: context, message: "Something went wrong");
      return false;
    } finally {
      // ✅ Loader OFF (Always)
      setBookingLoading(false);
      notifyListeners();
    }
  }

  //--🔹--AddCustomerServiceAPI-------------------------------------------🔹--//
  Future<void> AddCustomerServiceAPI(BuildContext context) async {
    if (!context.mounted) return;

    final httpCtrl = context.read<HttpServiceProvider>();
    final UserInfoCtrl = context.read<UserInfoProvider>();
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    try {
      // ✅ Loader ON
      GlobalFunction.hideKeyboard(context);
      setMobileVerificationLoading(true);
      notifyListeners();

      // ✅ Step 1: Internet Check
      final bool isConnected = await GlobalFunction().checkInternetConnection(
        context,
      );
      if (!isConnected) {
        GlobalFunction().debugFunction(
          "🚫 Internet not connected — API skipped",
        );
        setMobileVerificationLoading(false);
        return;
      }

      // ✅ Step 2: Start HTTP client if not active
      if (!httpCtrl.isApiActive) {
        httpCtrl.startHttpClient();
        GlobalFunction().debugFunction("🌐 Http client started");
      }

      // ✅ Step 3: Prepare Request Body
      final Map<String, dynamic> requestBody = {
        "name": NameController.text.trim(),
        "mobile": MobileController.text.trim(),
        "email": EmailController.text.trim(),
        "address": AddressController.text.trim(),
        "org_id": UserInfoCtrl.orgId.toString(),
        "status": "Active",
        "created_by": UserInfoCtrl.orgUserId.toString(),
      };

      //GlobalFunction().debugFunction("📤 AddCustomer Body: $requestBody");

      // ✅ Step 4: API Call
      final response = await httpCtrl.request(
        method: 'POST',
        url: AddCustomerService,
        context: context,
        headers: authHeaders,
        body: requestBody,
        requireLogin: true,
      );

      // ✅ Debug full response
      //GlobalFunction().debugFunction("📩 API Response: $response");

      // ✅ Step 5: Parse Response
      final String message = (response['message'] ?? '').toString().trim();
      final dynamic customerData = response['customer'];

      // 🧠 Validation: Empty message
      if (message.isEmpty) {
        //GlobalFunction().debugFunction("⚠️ Empty message in response");
        showCustomToast(
          context: context,
          message: "Empty response from server",
        );
        return;
      }

      // 🟢 Success condition — both message & customer object present
      if (message.toLowerCase().contains("customer created successfully") &&
          customerData != null &&
          customerData is Map &&
          customerData.isNotEmpty) {
        await MobileVerificationService(context, MobileController.text);
        GlobalFunction().debugFunction("✅ $message");
        showCustomToast(context: context, message: message);

        // ✅ Optional: store newly created customer details if needed
        GlobalFunction().debugFunction(
          "🧾 New Customer ID: ${customerData['cust_id']}",
        );

        CustomerMobileFound = true;

        // ✅ Close modal / bottomsheet
        Navigator.pop(context);
      } else {
        // ⚠️ Other responses (validation, duplicate, error etc.)
        GlobalFunction().debugFunction("⚠️ $message");
        showCustomToast(context: context, message: message);
      }
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error in AddCustomerServiceAPI: $e");
      debugPrintStack(stackTrace: stack);
      showCustomToast(context: context, message: "Something went wrong");
    } finally {
      // ✅ Loader OFF (Always)
      setMobileVerificationLoading(false);
      notifyListeners();
    }
  }

  //--🔹--BrandApi Listing-----------------------------------------------🔹--//
  // 🔹 Listing
  List<BrandModel> BrandListing = [];
  // 🔹 Selected
  int? selectedBrandId;
  String? selectedBrandType;
  BrandModel? selectedBrandData; // Selected Model

  // 🔹 API: Fetch BrandListService Charges List
  Future<void> getBrandListService(BuildContext context) async {
    if (!context.mounted) return;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);
    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        OrderPaymentMethodsListing.clear();
        return;
      }
      setAddOrderLoading(true);
      notifyListeners();
      final dynamic responseRaw = await httpCtrl.request(
        method: 'GET',
        url: BrandsService,
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // 🔹 Reset old list
      BrandListing.clear();

      final List<Map<String, dynamic>> records = responseRaw
          .whereType<Map<String, dynamic>>()
          .toList();

      if (records.isEmpty) {
        GlobalFunction().debugFunction("ℹ️ No brand found.");
        return;
      }

      BrandListing = records.map((e) => BrandModel.fromJson(e)).toList();

      notifyListeners();
    } catch (e, stack) {
      GlobalFunction().debugFunction("❌ Error fetching Charges List: $e");
      debugPrintStack(stackTrace: stack);
      GlobalFunction().showError(context, "Failed to load charges");
    } finally {
      setAddOrderLoading(false);
      notifyListeners();
    }
  }

  // 🔹 Dropdown Select Handling
  void updatedBrand(String? newValue) {
    if (newValue == null || newValue.isEmpty) {
      selectedBrandId = null;
      selectedBrandType = null;
      selectedBrandData = null;
      //GlobalFunction().debugFunction("⚠️ No charge selected");
      notifyListeners();
      return;
    }

    final selectedModel = BrandListing.firstWhere(
      (item) => item.brandName == newValue,
      orElse: () => BrandModel(),
    );

    selectedBrandId = selectedModel.brandId;
    selectedBrandType = selectedModel.brandName;
    selectedBrandData = selectedModel;

    /*GlobalFunction().debugFunction("✅ Selected BrandId: $selectedBrandId");
    GlobalFunction().debugFunction("✅ Selected Brand Type: $selectedBrandType");
    GlobalFunction().debugFunction(
      "🔍 Selected Brand JSON: ${selectedModel.toJson()}",
    );*/

    notifyListeners();
  }

  // 🔹 Reset Dropdown Selection
  void resetBrandSelection() {
    selectedBrandId = null;
    selectedBrandType = null;
    selectedBrandData = null;
    notifyListeners();
  }

  //--🔹--filterCategoriesByBrand----------------------------------------🔹--//
  // 🔹 Brand ke hisaab se categories filter karne ka function
  void filterCategoriesByBrand(int? brandId) {
    if (brandId == null) {
      filteredCategoriesListing = [];
      notifyListeners();
      return;
    }
    filteredCategoriesListing = CategoriesListing.where(
      (e) => e.brandid != null && e.brandid.toString() == brandId.toString(),
    ).toList();

    notifyListeners();
  }

  //--🔹--Note Listing---------------------------------------------🔹--//
  bool isPrefilled = false;
  List<NoteModel> NoteListing = [];
  List<String> selectedIngredients = [];

  Future<void> getNoteListService(
    BuildContext context,
    String productId,
  ) async {
    // ⭐ CLEAN state for every new product
    isPrefilled = false;
    selectedIngredients = [];
    SpecialInstructionsController.clear();

    NoteListing = [];

    if (!context.mounted) return;

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? "";
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      setAddOrderLoading(true);

      // Internet check
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        setAddOrderLoading(false);
        return;
      }

      // Ensure client is active
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      // API Request
      final responseRaw = await httpCtrl.request(
        method: 'GET',
        url: "${NoteListService}m_prod_id=$productId",
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      // API must return LIST
      if (responseRaw is! List) {
        GlobalFunction().showError(context, "Invalid API format");
        setAddOrderLoading(false);
        return;
      }

      // Convert & Filter only map records
      final List<Map<String, dynamic>> records = responseRaw
          .whereType<Map<String, dynamic>>()
          .toList();

      // Empty list case
      if (records.isEmpty) {
        NoteListing = [];
        notifyListeners();
        setAddOrderLoading(false);
        return;
      }

      // Map safely
      NoteListing = records.map((e) => NoteModel.fromJson(e)).toList();

      notifyListeners();
    } catch (e, st) {
      debugPrint("ERROR NOTE LIST: $e");
      debugPrintStack(stackTrace: st);
      GlobalFunction().showError(context, "Failed to load notes");
    } finally {
      setAddOrderLoading(false);
    }
  }

  // Set ingredient & update controller
  void selectIngredient(NoteModel note) {
    String name = note.inventoryProduct.pName.trim();

    // 🔥 1. Toggle selection
    if (selectedIngredients.contains(name)) {
      selectedIngredients.remove(name);
    } else {
      selectedIngredients.add(name);
    }

    // 🔥 2. Extract ONLY typed text (Remove: lines ko hatao)
    String typedText = SpecialInstructionsController.text
        .split("\n")
        .where((line) => !line.trim().startsWith("Remove:"))
        .join("\n")
        .trim();

    // 🔥 3. ALWAYS rebuild Remove lines from selectedIngredients — NO DUPLICATE EVER
    String removeLines = selectedIngredients.isNotEmpty
        ? selectedIngredients.map((e) => "Remove: $e").join("\n")
        : "";

    // 🔥 4. Merge properly
    String finalText = "";

    if (typedText.isNotEmpty && removeLines.isNotEmpty) {
      finalText = "$typedText\n$removeLines";
    } else if (typedText.isNotEmpty) {
      finalText = typedText;
    } else {
      finalText = removeLines;
    }

    // 🔥 5. Assign back
    SpecialInstructionsController.text = finalText;

    notifyListeners();
  }

  // AddNote
  void updateItemNote({
    required String mProdId,
    required String note,
    String? cartEntryId,
  }) {
    // Use cart_entry_id for modifier split entries (exact unit match),
    // fall back to m_prod_id for non-modifier items.
    final int index;
    if (cartEntryId != null) {
      index = selectedItems.indexWhere(
        (item) => item['cart_entry_id'] == cartEntryId,
      );
    } else {
      index = selectedItems.indexWhere(
        (item) => item['m_prod_id'].toString() == mProdId,
      );
    }

    if (index != -1) {
      selectedItems[index]['note'] = note;
      notifyListeners();
    }
  }

  //--🔹 Payment Status -----------------------------------------------🔹--//
  String? selectedPaymentStatus;
  List<PaymentStatusModel> paymentStatusList = [];

  //-- Load Payment Status
  Future<void> loadPaymentStatusList() async {
    final response = [
      {"id": 1, "Title": "Paid"},
      {"id": 2, "Title": "UnPaid"},
    ];

    paymentStatusList = response
        .map((e) => PaymentStatusModel.fromJson(e))
        .toList();

    // 🔹 Default based on current table type: Dine In → Unpaid, others → Paid
    if (paymentStatusList.isNotEmpty) {
      final isDineIn = selectedTableType?.toLowerCase() == 'dine in';
      selectedPaymentStatus = paymentStatusList
          .firstWhere(
            (item) => isDineIn
                ? item.title.toLowerCase() == 'unpaid'
                : item.title.toLowerCase() == 'paid',
            orElse: () => paymentStatusList.first,
          )
          .title;
    }

    notifyListeners();
  }

  //-- Update selected value (User selection)
  void updatePaymentStatus(String? newValue) {
    if (newValue == null) return;

    selectedPaymentStatus = newValue; // ✅ User selection
    notifyListeners();

    final selectedModel = paymentStatusList.firstWhere(
      (item) => item.title == selectedPaymentStatus,
      orElse: () => PaymentStatusModel(id: 0, title: ""),
    );

    GlobalFunction().debugFunction(
      "✅ Selected Payment Status: $selectedPaymentStatus",
    );
    GlobalFunction().debugFunction(
      "🔍 Selected PaymentStatus Model: ${selectedModel.toJson()}",
    );
  }

  //--🔹--Clear All Data-------------------------------------------------🔹--//
  Future<void> ClearData(BuildContext context) async {
    // ── Reset all UI / state fields ──────────────────────────────────────────
    OrderNoteController.clear();
    isPrefilled = false;
    NoteListing = [];
    selectedIngredients = [];
    CustomerName = null;
    CustomerMobile = null;
    CustomerDiscount = null;
    isBookingLoading = false;
    setBookingLoading(false);
    isAddOrderLoading = false;
    setAddOrderLoading(false);
    selectedCategoryIndex = -1;
    SearchCategoriesController.clear();
    myFocusNodeCategories.unfocus();
    SearchMenuController.clear();
    myFocusNodeMenu.unfocus();
    itemQuantity = {};
    selectedItems = [];
    clearModifierCache();
    resetOrderTableSelection();
    resetOrderTaxSelection();
    resetOrderChargesSelection();
    resetOrderPaymentMethodsSelection();
    selectedOrderPriority = null;
    OrderPriorityListing = [];
    MobileController.clear();
    myFocusNodeMobile.unfocus();
    context.read<NumberInputDiscountProvider>().reset(context);
    context.read<NumberInputPAXProvider>().reset();
    NameController.clear();
    myFocusNodeName.unfocus();
    EmailController.clear;
    myFocusNodeEmail.unfocus();
    AddressController.clear;
    myFocusNodeAddress.unfocus();
    CustomerMobileFound = true;
    isMobileVerificationLoading = false;
    SpecialInstructionsController.clear();
    myFocusNodeSpecialInstructions.unfocus();
    NameController.text = context.read<UserInfoProvider>().name.toString();
    EmailController.text = context.read<UserInfoProvider>().email.toString();

    // ── Clear list caches ────────────────────────────────────────────────────
    CategoriesListing.clear();
    CategoriesListing = [];
    filteredCategoriesListing = [];
    filteredMenuListing.clear();
    MenuListing = [];
    filteredMenuListing = [];
    TableTypeListing = [];
    OrderTableListing = [];
    OrderTaxListing = [];
    OrderChargesListing = [];
    OrderPaymentMethodsListing = [];
    BrandListing = [];

    // ── Fetch all API data ───────────────────────────────────────────────────
    // getCategoriesListService → internally calls BasicAPI which loads:
    // menu, tables, order types, tax, charges, payment methods.
    // Only extra calls needed: brands, order priority, payment status.
    await getCategoriesListService(context);
    await getBrandListService(context);
    await loadOrderPriorityList();
    await loadPaymentStatusList();

    notifyListeners();
  }

  Future<void> loadOrderForEdit(
    BuildContext context,
    Map<String, dynamic> orderData,
  ) async {
    final AddOrderCtrl = context.read<AddOrderProvider>();
    AddOrderCtrl.isPrefilled = true;

    // Customer
    AddOrderCtrl.CustomerName = orderData['Customer'];
    AddOrderCtrl.CustomerMobile = orderData['cust_id'] != 0
        ? orderData['cust_id'].toString()
        : null;
    AddOrderCtrl.CustomerDiscount = orderData['discount_per']?.toString();

    // Discount
    if (orderData['discount_per'] != null) {
      context.read<NumberInputDiscountProvider>().manualInput(
        context,
        orderData['discount_per'].toString(),
      );
    }

    // PAX
    if (orderData['pax'] != null) {
      context.read<NumberInputPAXProvider>().manualInput(
        orderData['pax'].toString(),
      );
    }

    // Table Type
    AddOrderCtrl.selectedTableType = orderData['type'];
    if ((orderData['type'] as String?)?.toLowerCase() == 'dine in') {
      AddOrderCtrl.selectedDPOrderTable = orderData['table_id'].toString();
      // ✅ Restore multi-select table state for the modal UI
      final tableIdString = orderData['table_id']?.toString() ?? '';
      final tableIds = tableIdString.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((e) => e != 0).toList();
      
      AddOrderCtrl.selectedTables = AddOrderCtrl.OrderTableListing.where(
        (t) => tableIds.contains(t.tableID),
      ).toList();

      if (tableIds.isNotEmpty) {
        AddOrderCtrl.selectedTableId = tableIds.first;
        AddOrderCtrl.selectedTableDisplayName = AddOrderCtrl.selectedTables.isNotEmpty
            ? AddOrderCtrl.selectedTables.map((t) => t.tableName).join(', ')
            : 'Table Selected';
      }
    }

    // Tax
    if (orderData['taxid'] != null) {
      final tax = AddOrderCtrl.OrderTaxListing.firstWhere(
        (e) => e.taxid == orderData['taxid'],
        orElse: () => OrderTaxData(taxid: 0, rate: "0", name: ""),
      );
      if (tax.taxid != 0) {
        AddOrderCtrl.selectedTaxData = tax;
        AddOrderCtrl.selectedTaxId = tax.taxid;
        AddOrderCtrl.selectedTaxRate = double.tryParse(tax.rate) ?? 0.0;
      }
    }

    // Charges
    if (orderData['charge_id'] != null) {
      final charge = AddOrderCtrl.OrderChargesListing.firstWhere(
        (e) => e.chargeId == orderData['charge_id'],
        orElse: () => OrderChargesDataItem(chargeId: 0, type: "", value: "0"),
      );

      if (charge.chargeId != 0) {
        AddOrderCtrl.selectedChargesData = charge;
        AddOrderCtrl.selectedChargesId = charge.chargeId;
        AddOrderCtrl.selectedChargesType = charge.type;
        AddOrderCtrl.selectedChargesAmt = charge.value; // value already String
      }
    }

    // Payment
    if (orderData['pay_m_id'] != null) {
      final payment = AddOrderCtrl.OrderPaymentMethodsListing.firstWhere(
        (e) => e.payMId == orderData['pay_m_id'],
        orElse: () => OrderPaymentMethodsData(payMId: 0, type: ""),
      );
      if (payment.payMId != 0) {
        AddOrderCtrl.selectedPaymentMethodsData = payment;
        AddOrderCtrl.selectedPaymentMethodsId = payment.payMId;
        AddOrderCtrl.selectedPaymentMethodsType = payment.type;
        AddOrderCtrl.selectedPaymentMethodsName = payment.name;
      }
    }

    // Order Priority
    AddOrderCtrl.selectedOrderPriority = orderData['priority'];

    // Selected Items
    AddOrderCtrl.selectedItems = [];
    AddOrderCtrl.itemQuantity = {};

    if (orderData['details'] != null) {
      for (var item in orderData['details']) {
        final product = item['product'];

        final menuItem = AddOrderCtrl.MenuListing.firstWhere(
          (m) => m.mProdId == item['m_prod_id'],
          orElse: () => MenuModel(
            mProdId: item['m_prod_id'],
            mPName: product['m_p_name'],
            price: item['rate']?.toString(),
            mProductIcon: product['m_product_icon'],
          ),
        );

        // Qty may come as 'qty' or 'quantity' depending on API response
        final itemQty = (item['qty'] ?? item['quantity'] ?? 1) as int;
        // Price may come as 'rate' or 'price'
        final itemPrice = (item['rate'] ?? item['price'] ?? '0').toString();

        AddOrderCtrl.itemQuantity[item['m_prod_id']] = itemQty;

        AddOrderCtrl.selectedItems.add({
          'm_prod_id': item['m_prod_id'],
          'quantity': itemQty,
          'price': itemPrice,
          'note': item['note'] ?? '',
          'm_p_name': product['m_p_name'] ?? menuItem.mPName ?? '',
          'm_product_icon':
              product['m_product_icon'] ?? menuItem.mProductIcon ?? '',
          // ✅ CRITICAL: tax_group must be carried into selectedItems so that
          // _calcTaxBreakdown uses the correct rate during edit recalculation.
          // Fallback order: item field → product field → default "0"
          'tax_group': (item['tax_group'] ?? product['tax_group'] ?? '0')
              .toString(),
        });
      }
    }

    // Recalculate
    AddOrderCtrl.recalculateAmounts(context);
    AddOrderCtrl.notifyListeners();
  }
}

//-✅---------------------------------------------------------------------✅-//
