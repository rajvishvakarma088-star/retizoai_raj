// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

//-✅---------------------------------------------------------------------✅-//
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/services.dart';
import 'package:culai/ScreenSection/PostLogin/AddNewOrder/Widget/CashAmount.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
class AddOrderWidget {
  //-✅--AddNewOrders-----------------------------------------------------✅-//
  Widget AddNewOrders(BuildContext context, UserInfoProvider UserInfoCtrl) {
    return Consumer2<AddOrderProvider, UserInfoProvider>(
      builder: (context, AddOrderCtrl, UserInfoCtrl, child) {
        return HomeWidget().buildDropdown(
          hintText: "All Brands",
          iconPadding: 0,
          decoration: BoxDecoration(
            color: GlobalAppColor.WhiteColorCode,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: GlobalAppColor.DarkTextColorCode.withOpacity(.1),
              width: 2,
            ),
          ),
          showTextLeft: true,
          showIconRight: true,
          items: [
            "All Brands", // Default Option 👈
            ...AddOrderCtrl.BrandListing.map((e) => e.brandName),
          ],
          value: AddOrderCtrl.selectedBrandType ?? "All Brands",
          onChanged: AddOrderCtrl.isBookingLoader
              ? null
              : (value) {
                  AddOrderCtrl.updatedBrand(value);

                  // FIX: Agar "All Brands" choose kiya gaya ho
                  if (value == "All Brands") {
                    AddOrderCtrl.selectedBrandId = null;
                    AddOrderCtrl.filteredCategoriesListing = [];
                    AddOrderCtrl.setCategory(null);
                    AddOrderCtrl.notifyListeners();
                    AddOrderCtrl.selectedCategoryIndex = -1;
                    return;
                  }
                  AddOrderCtrl.selectedCategoryIndex = 0;
                  AddOrderCtrl.filterCategoriesByBrand(
                    AddOrderCtrl.selectedBrandId,
                  );
                  AddOrderCtrl.setCategory(null);
                },

          hintStyle: CommonWidget.CommonTitleTextStyle(
            color: GlobalAppColor.DarkTextColorCode,
            fontSize: 13,
          ),
          itemStyle: CommonWidget.CommonTitleTextStyle(
            color: GlobalAppColor.DarkTextColorCode,
            fontSize: 13,
          ),
        );
      },
    );
  }

  //-✅--Search-Categories-Orders-----------------------------------------✅-//
  Widget SearchCategoriesOrders(
    BuildContext context,
    AddOrderProvider AddOrderCtrl,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;

        // 🔹 Set max width for large screens
        double maxRowWidth = screenWidth >= 1200
            ? 800
            : screenWidth >= 800
            ? 700
            : screenWidth; // mobile full width
        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxRowWidth),
            child: CommonWidget().AddOrderSearchTextField(
              enabled:
                  !AddOrderCtrl.isMenuLoading &&
                  AddOrderCtrl.CategoriesListing.isNotEmpty,
              controller: AddOrderCtrl.SearchCategoriesController,
              focusNode: AddOrderCtrl.myFocusNodeCategories,
              onChanged: (value) {
                AddOrderCtrl.notifyListeners(); // Refresh UI to trigger dynamic search filter
              },
            ),
          ),
        );
      },
    );
  }

  //-✅-----------Categories-List-----------------------------------------✅-//
  Widget CategoriesListWidget(
    BuildContext context,
    List<CategoryModel> data,
    AddOrderProvider AddOrderCtrl,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        if (AddOrderCtrl.isMenuLoading) {
          return CommonShimmer.CategoryListShimmer(context, 6);
        }

        // 🔹 Calculate the correctly filtered list dynamically based on Brand and Search text
        List<CategoryModel> baseList = AddOrderCtrl.selectedBrandId != null
            ? AddOrderCtrl.CategoriesListing.where(
                (e) => e.brandid != null && e.brandid.toString() == AddOrderCtrl.selectedBrandId.toString(),
              ).toList()
            : AddOrderCtrl.CategoriesListing;

        // Apply Search Filter if search query is entered
        List<CategoryModel> filteredList = baseList;
        if (AddOrderCtrl.SearchCategoriesController.text.isNotEmpty) {
          final query = AddOrderCtrl.SearchCategoriesController.text.toLowerCase();
          filteredList = baseList.where((cat) {
            return cat.mCatName.toLowerCase().contains(query) ||
                (cat.mCatArbName != null && cat.mCatArbName.toLowerCase().contains(query)) ||
                (cat.status != null && cat.status.toLowerCase().contains(query));
          }).toList();
        }

        // 🔹 Brand Select ho ⇒ "All" button add
        if (AddOrderCtrl.selectedBrandId != null && filteredList.isNotEmpty) {
          filteredList = [
            CategoryModel(
              mCatId: -1,
              mCatName: "All",
              mCatArbName: "الكل",
              mCatIcon:
                  "https://www.pngitem.com/pimgs/m/141-1412195_menu-icon-png-transparent-png.png",
              status: '',
              brandid: '',
              creationDatetime: '',
              createdBy: '',
              modificationDatetime: '',
              modifiedBy: '',
              orgId: '',
            ),
            ...filteredList,
          ];
        }

        if (filteredList.isEmpty) {
          return Text(
            GlobalFlag.NoDataFound,
            style: CommonWidget.CommonTitleTextStyle(),
          );
        }

        return SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final item = filteredList[index];
              final bool isSelected = AddOrderCtrl.selectedCategoryIndex == index;
              return GestureDetector(
                onTap: () {
                  if (item.mCatId == -1) {
                    AddOrderCtrl.setCategory(null);
                  } else {
                    AddOrderCtrl.setCategory(item.mCatId);
                  }
                  AddOrderCtrl.onCategorySelected(index, item);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? GlobalAppColor.ButtonColor : GlobalAppColor.WhiteColorCode,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : GlobalAppColor.LightTextColorCode.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.mCatIcon != null && item.mCatIcon.isNotEmpty) ...[
                        CommonWidget().RectangleCachedImage(
                          context: context,
                          imageUrl: item.mCatIcon.startsWith("https")
                              ? item.mCatIcon
                              : "${GlobalServiceURL.ImageBaseUrl}${item.mCatIcon}",
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        item.mCatName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : GlobalAppColor.DarkTextColorCode,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  //-✅--Search-Menu-Orders-----------------------------------------------✅-//
  Widget SearchMenuOrders(BuildContext context, AddOrderProvider AddOrderCtrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;

        // 🔹 Set max width for large screens
        double maxRowWidth = screenWidth >= 1200
            ? 800
            : screenWidth >= 800
            ? 700
            : screenWidth; // mobile full width
        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxRowWidth),
            child: CommonWidget().AddOrderSearchTextField(
              hintText: 'Search menu items...',
              enabled:
                  !AddOrderCtrl.isMenuLoading &&
                  AddOrderCtrl.MenuListing.isNotEmpty,
              controller: AddOrderCtrl.SearchMenuController,
              focusNode: AddOrderCtrl.myFocusNodeMenu,
              onChanged: (value) {
                AddOrderCtrl.notifyListeners();
              },
            ),
          ),
        );
      },
    );
  }

  //-✅-----------Menu-List-----------------------------------------------✅-//
  Widget MenuListWidget(
    BuildContext context,
    List<MenuModel> data,
    AddOrderProvider AddOrderCtrl,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        if (AddOrderCtrl.isMenuLoading) {
          return CommonShimmer.MenuListShimmer(context, 4);
        }

        final filteredList = AddOrderCtrl.getFilteredMenuItems();

        if (filteredList.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 22.0),
            child: Text(
              GlobalFlag.NoDataFound,
              style: CommonWidget.CommonTitleTextStyle(),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final orientation = MediaQuery.of(context).orientation;
            int itemsPerRow;

            /// Small Mobile (≤ 600px)
            if (screenWidth <= 600) {
              itemsPerRow = 2;
            }
            /// Medium Devices (600 - 999)
            else if (screenWidth > 600 && screenWidth < 1000) {
              itemsPerRow = 5;
            }
            /// Large Screen / Tablets (≥ 1000px)
            else {
              itemsPerRow = 8;
            }

            /// Force same layout in landscape for mobiles
            if (orientation == Orientation.landscape && screenWidth <= 600) {
              itemsPerRow = 4;
            }

            final rowCount =
                (filteredList.length / itemsPerRow).ceil();

            return ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: rowCount,
              itemBuilder: (context, rowIndex) {
                if (rowIndex >= rowCount) {
                  return const SizedBox.shrink(); // Out of bounds check
                }
                List<Widget> rowItems = [];

                for (int i = 0; i < itemsPerRow; i++) {
                  final itemIndex = rowIndex * itemsPerRow + i;

                  if (itemIndex < filteredList.length) {
                    final item = filteredList[itemIndex];

                    rowItems.add(
                      Expanded(
                        child: InkWell(
                          overlayColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                          child: AnimationLimiter(
                            child: CommonWidget().buildStaggeredAnimation(
                              index: rowIndex,
                              child: IntrinsicHeight(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 5,
                                  ),
                                  margin: const EdgeInsets.only(
                                    right: 8,
                                    bottom: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GlobalAppColor.WhiteColorCode,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 0.8,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        // Product Image / Icon Banner
                                        Builder(
                                          builder: (context) {
                                            final String imgVal = item.mProductIcon ?? '';
                                            final String imageUrl = imgVal.isNotEmpty
                                                ? (imgVal.startsWith('http')
                                                    ? imgVal
                                                    : '${GlobalServiceURL.ImageBaseUrl}$imgVal')
                                                : '';
                                            return Container(
                                              height: 75,
                                              width: double.infinity,
                                              margin: const EdgeInsets.only(bottom: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: imageUrl.isNotEmpty
                                                    ? CommonWidget().RectangleCachedImage(
                                                        context: context,
                                                        imageUrl: imageUrl,
                                                        width: double.infinity,
                                                        height: 75,
                                                        decoration: const BoxDecoration(),
                                                      )
                                                    : Icon(
                                                        Symbols.restaurant,
                                                        color: Colors.grey.shade300,
                                                      ),
                                              ),
                                            );
                                          },
                                        ),
                                        // Product Name
                                        Flexible(
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              item.mPName ?? 'N/A',
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    color: GlobalAppColor.DarkTextColorCode,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    height: 1.2,
                                                    letterSpacing: 0.3,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        // Arabic Name
                                        Flexible(
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              item.mPArbName ?? 'N/A',
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w300,
                                                    color: GlobalAppColor.DarkTextColorCode.withOpacity(0.6),
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        // Price Row
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Icon(
                                              Symbols.credit_card,
                                              size: 13,
                                              color: GlobalAppColor
                                                  .DarkTextColorCode.withOpacity(.6),
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                item.price ?? '0.0',
                                                textAlign: TextAlign.center,
                                                style: CommonWidget.CommonTitleTextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: GlobalAppColor
                                                      .DarkTextColorCode.withOpacity(.7),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Stock Badge (only for stock-tracked items)
                                        if (item.stockProduct == true) ...[
                                          const SizedBox(height: 4),
                                          Builder(
                                            builder: (ctx) {
                                              final available =
                                                  AddOrderCtrl
                                                      .productStockMap[item
                                                      .mProdId] ??
                                                  0;
                                              final Color badgeColor =
                                                  available == 0
                                                  ? Colors.red
                                                  : available <= 5
                                                  ? Colors.orange
                                                  : Colors.green;
                                              final String badgeText =
                                                  available == 0
                                                  ? 'Out of Stock'
                                                  : '$available left';
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: badgeColor.withOpacity(
                                                    0.12,
                                                  ),
                                                  border: Border.all(
                                                    color: badgeColor,
                                                    width: 0.7,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  badgeText,
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    color: badgeColor,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                        // Add Item rectangular controller
                                        const SizedBox(height: 6),
                                        Builder(
                                          builder: (context) {
                                            final isOutOfStock = item.stockProduct == true &&
                                                (AddOrderCtrl.productStockMap[item.mProdId] ?? 0) == 0;
                                            final hasQty = (AddOrderCtrl.itemQuantity[item.mProdId] ?? 0) > 0;
                                            return Container(
                                              height: 34,
                                              width: 120,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                border: Border.all(
                                                  color: hasQty
                                                      ? GlobalAppColor.DarkBlueColor.withOpacity(0.5)
                                                      : Colors.grey.shade300,
                                                  width: 0.8,
                                                ),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(5),
                                                child: Row(
                                                  children: [
                                                    // Minus Button
                                                    Expanded(
                                                      child: _AnimatedActionButton(
                                                        onTap: () {
                                                          HapticFeedback.lightImpact();
                                                          AddOrderCtrl.decrementQuantity(item);
                                                        },
                                                        backgroundColor: Colors.transparent,
                                                        child: Icon(
                                                          Icons.remove,
                                                          size: 14,
                                                          color: GlobalAppColor.DarkBlueColor,
                                                        ),
                                                      ),
                                                    ),
                                                    // Divider
                                                    Container(
                                                      width: 0.8,
                                                      color: Colors.grey.shade300,
                                                      height: double.infinity,
                                                    ),
                                                    // Quantity
                                                    Container(
                                                      width: 32,
                                                      alignment: Alignment.center,
                                                      child: Text(
                                                        "${AddOrderCtrl.itemQuantity[item.mProdId] ?? 0}",
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                          color: GlobalAppColor.DarkTextColorCode,
                                                        ),
                                                      ),
                                                    ),
                                                    // Divider
                                                    Container(
                                                      width: 0.8,
                                                      color: Colors.grey.shade300,
                                                      height: double.infinity,
                                                    ),
                                                    // Plus Button
                                                    Expanded(
                                                      child: _AnimatedActionButton(
                                                        onTap: isOutOfStock
                                                            ? null
                                                            : () async {
                                                                HapticFeedback.lightImpact();
                                                                await AddOrderCtrl.addItemToCartWithModifierCheck(
                                                                  context,
                                                                  item,
                                                                );
                                                              },
                                                        backgroundColor: isOutOfStock
                                                            ? Colors.transparent
                                                            : GlobalAppColor.DarkBlueColor,
                                                        child: Icon(
                                                          Icons.add,
                                                          size: 14,
                                                          color: isOutOfStock
                                                              ? Colors.grey.shade400
                                                              : Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    rowItems.add(const Expanded(child: SizedBox()));
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: rowItems,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  //-✅--buildAmountRow---------------------------------------------------✅-//
  Widget buildAmountRow(
    BuildContext context,
    String title,
    String titleTwo, {
    Color? textColor, // for left title
    FontWeight? textFont, // for left title
    double? fontSize, // for left title
    Color? valueColor, // for right title
    FontWeight? valueFont, // for right title
    double? valueFontSize, // for right title
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // 🔹 Left Title
          SizedBox(
            child: Text(
              title,
              textAlign: TextAlign.start,
              maxLines: 1,
              softWrap: false,
              style: CommonWidget.CommonTitleTextStyle(
                color: textColor ?? GlobalAppColor.DarkTextColorCode,
                fontWeight: textFont ?? FontWeight.w400,
                fontSize: fontSize ?? 15,
              ),
            ),
          ),

          // 🔹 Right Title + Icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                titleTwo,
                textAlign: TextAlign.start,
                maxLines: 1,
                softWrap: true,
                style: CommonWidget.CommonTitleTextStyle(
                  color: textColor ?? GlobalAppColor.DarkTextColorCode,
                  fontWeight: textFont ?? FontWeight.w400,
                  fontSize: fontSize ?? 15,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Symbols.credit_card,
                color: GlobalAppColor.DarkTextColorCode,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  //--🔹--AddUser--------------------------------------------------------🔹--//
  static Future<bool> AddUser({required BuildContext context}) async {
    final result = await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => AddMobile(),
    );
    return result ?? false;
  }

  //--🔹--AddSpecialInstructions-----------------------------------------🔹--//
  static Future<bool> AddSpecialInstructionsWidget({
    required BuildContext context,
    required Map<String, dynamic> item,
  }) async {
    final result = await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => AddSpecialInstructions(item: item),
    );
    return result ?? false;
  }

  //-✅--Responsive Pay Bill Panel-----------------------------------------✅-//
  Widget OrderSummaryPanel(
    BuildContext context,
    List<MenuModel> data,
    AddOrderProvider AddOrderCtrl,
    bool isMobile,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isPortrait = screenHeight >= screenWidth;

    double panelWidth = isMobile ? screenWidth * 0.82 : screenWidth * 0.35;
    if (isMobile && panelWidth > 450) panelWidth = 450;
    if (!isMobile && panelWidth > 500) panelWidth = 500;

    Widget panelContent(bool showCloseButton) {
      return Column(
        children: [
          if (showCloseButton) ...[
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Container(
            height: kToolbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            color: GlobalAppColor.WhiteColorCode,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order Summary (${AddOrderCtrl.selectedItems.length} items)",
                  style: CommonWidget.CommonTitleTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showCloseButton)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: GlobalAppColor.DarkTextColorCode.withOpacity(.6),
                    ),
                    onPressed: AddOrderCtrl.isBookingLoader
                        ? null
                        : () => AddOrderCtrl.closeOrderSummaryPanel(),
                  ),
              ],
            ),
          ),
          CommonWidget().DividerWidget(height: 1.0),
          const SizedBox(height: 5),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isPortrait ? 10 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //--✅--DropDown-Table-TableType---------------✅--//
                  IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // 🔹 Table Dropdown
                        Expanded(
                          flex: 2,
                          child: Consumer<AddOrderProvider>(
                            builder: (context, AddOrderCtrl, child) {
                              return HomeWidget().buildDropdown(
                                hintText: AddOrderCtrl.TableType.isEmpty
                                    ? "No Table Types"
                                    : "Select Type",
                                iconPadding: 0,
                                decoration: BoxDecoration(
                                  color: GlobalAppColor.WhiteColorCode,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: GlobalAppColor
                                        .DarkTextColorCode.withOpacity(.1),
                                    width: 2,
                                  ),
                                ),
                                showTextLeft: true,
                                showIconRight: true,
                                items: AddOrderCtrl.TableType.map(
                                  (e) => e.orderTypeName,
                                ).toList(),

                                // 🔹 Default value: first item if nothing selected
                                value:
                                    AddOrderCtrl.selectedTableType ??
                                    (AddOrderCtrl.TableType.isNotEmpty
                                        ? AddOrderCtrl
                                              .TableType
                                              .first
                                              .orderTypeName
                                        : null),

                                onChanged: AddOrderCtrl.isBookingLoader
                                    ? null
                                    : (value) {
                                        if (value != null) {
                                          AddOrderCtrl.updateTableType(value);
                                        }
                                      },
                                hintStyle: CommonWidget.CommonTitleTextStyle(
                                  color: GlobalAppColor.DarkTextColorCode,
                                  fontSize: 13,
                                ),
                                itemStyle: CommonWidget.CommonTitleTextStyle(
                                  color: GlobalAppColor.DarkTextColorCode,
                                  fontSize: 13,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            child: CommonWidget().AddOrderSearchTextField(
                              enabled: !AddOrderCtrl.isAddOrderLoader,
                              showSuffixIcon: false,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly, // ✅ Only digits
                                LengthLimitingTextInputFormatter(
                                  10,
                                ), // ✅ Max 10 digits
                              ],
                              textStyle: CommonWidget.CommonTitleTextStyle(
                                color: GlobalAppColor.DarkTextColorCode,
                                fontSize: 13,
                              ),
                              hintStyle: CommonWidget.CommonTitleTextStyle(
                                color: GlobalAppColor.DarkTextColorCode,
                                fontSize: 13,
                              ),
                              showPrefixIcon: false,
                              hintText: 'Enter Mobile',
                              controller: AddOrderCtrl.MobileController,
                              focusNode: AddOrderCtrl.myFocusNodeMobile,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10, // slightly tighter
                                horizontal: 4, // reduced horizontal padding
                              ),
                              onChanged: AddOrderCtrl.isAddOrderLoader
                                  ? null
                                  : (value) async {
                                      GlobalFunction().debugFunction(
                                        "Typed: $value",
                                      );
                                      if (AddOrderCtrl.debounce?.isActive ??
                                          false) {
                                        AddOrderCtrl.debounce!.cancel();
                                      }
                                      AddOrderCtrl.debounce = Timer(
                                        const Duration(milliseconds: 300),
                                        () async {
                                          if (value.length == 10) {
                                            // **Focus ko preserve karo**
                                            await AddOrderCtrl.MobileVerificationService(
                                              context,
                                              value,
                                            );
                                          } else {
                                            AddOrderCtrl.CustomerName = null;
                                            AddOrderCtrl.CustomerMobile = null;
                                            AddOrderCtrl.CustomerDiscount =
                                                null;
                                          }
                                        },
                                      );
                                    },
                            ),
                          ),
                        ),

                        // 🔹 Table Type Dropdown
                      ],
                    ),
                  ),
                  (AddOrderCtrl.selectedTableType?.toLowerCase() == 'dine in')
                      ? SizedBox(height: 10)
                      : SizedBox.shrink(),
                  (AddOrderCtrl.selectedTableType?.toLowerCase() == 'dine in')
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ Tappable "Select Tables" field — opens modal
                            GestureDetector(
                              onTap: AddOrderCtrl.isBookingLoader
                                  ? null
                                  : () async {
                                      final result =
                                          await showDialog<
                                            List<OrderTableData>
                                          >(
                                            context: context,
                                            barrierDismissible: true,
                                            builder: (_) =>
                                                _TableSelectionModal(
                                                  tables:
                                                      AddOrderCtrl.OrderTable,
                                                  initialSelectedIds: AddOrderCtrl.selectedTables.map((t) => t.tableID).toList(),
                                                ),
                                          );
                                      if (result != null) {
                                        AddOrderCtrl.confirmTableSelections(
                                          result,
                                        );
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                                               decoration: BoxDecoration(
                                  color: GlobalAppColor.WhiteColorCode,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: GlobalAppColor
                                        .DarkTextColorCode.withOpacity(.1),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.table_chart,
                                      size: 16,
                                      color: GlobalAppColor
                                          .DarkTextColorCode.withOpacity(.45),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        AddOrderCtrl.selectedTableId == null
                                            ? (AddOrderCtrl.OrderTable.isEmpty
                                                  ? 'No tables available'
                                                  : 'Select Table')
                                            : '${AddOrderCtrl.selectedTableDisplayName}',
                                        style: CommonWidget.CommonTitleTextStyle(
                                          color:
                                              AddOrderCtrl.selectedTableId == null
                                              ? GlobalAppColor
                                                    .DarkTextColorCode.withOpacity(
                                                  .45,
                                                )
                                              : GlobalAppColor
                                                    .DarkTextColorCode,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: GlobalAppColor
                                          .DarkTextColorCode.withOpacity(.45),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // ✅ Green status banner — shown once tables are selected
                            if (AddOrderCtrl.selectedTableId != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Builder(
                                  builder: (context) {
                                    final t = AddOrderCtrl.OrderTable.firstWhere((e) => e.tableID == AddOrderCtrl.selectedTableId, orElse: () => OrderTableData(tableName: '', seatingCapacity: 0));
                                    return Text(
                                      '${t.tableName}: ${t.isPremium ? (t.minimumSpendAmount > 0 ? 'Premium min ${t.minimumSpendAmount.toStringAsFixed(2)}' : (t.tableChargeAmount > 0 ? 'Table charge ${t.tableChargeAmount.toStringAsFixed(2)}' : 'Premium')) : 'Available'}',
                                      style: const TextStyle(
                                        color: Color(0xFF166534),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            PAXInputField(),
                          ],
                        )
                      : SizedBox.shrink(),
                  AddOrderCtrl.CustomerMobileFound == false
                      ? SizedBox(height: 10)
                      : SizedBox.shrink(),
                  AddOrderCtrl.CustomerMobileFound == false
                      ? Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: const Color(0xFF991B1B),
                              width: 0.8,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  "X Customer not found",
                                  style: CommonWidget.CommonTitleTextStyle(
                                    color: const Color(0xFF991B1B),
                                  ),
                                ),
                                Spacer(),
                                InkWell(
                                  overlayColor: MaterialStateProperty.all(
                                    Colors.transparent,
                                  ),
                                  onTap: () async {
                                    final isConnected = await GlobalFunction()
                                        .checkInternetConnection(context);
                                    if (isConnected) {
                                      await AddUser(context: context);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(5),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: GlobalAppColor.ButtonColor,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        const Icon(
                                          Icons.add,
                                          size: 22,
                                          color: Colors.white,
                                        ),
                                        Text(
                                          "ADD",
                                          style:
                                              CommonWidget.CommonTitleTextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox.shrink(),

                  // ✅ Edit-time safe condition for showing customer info
                  ((AddOrderCtrl.CustomerName != null &&
                              AddOrderCtrl.CustomerName!.toLowerCase() !=
                                  'n/a') ||
                          (AddOrderCtrl.CustomerMobile != null &&
                              AddOrderCtrl.CustomerMobile != '0' &&
                              AddOrderCtrl.CustomerMobile!.trim().isNotEmpty))
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Provider.of<ThemeProvider>(context, listen: false).currentTheme == 'dark' ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: Colors.green,
                                width: 0.8,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Icon(Symbols.check, color: Colors.green),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      "${(AddOrderCtrl.CustomerName != null && AddOrderCtrl.CustomerName!.toLowerCase() != 'n/a') ? AddOrderCtrl.CustomerName : ''}"
                                      "${(AddOrderCtrl.CustomerMobile != null && AddOrderCtrl.CustomerMobile != '0' && AddOrderCtrl.CustomerMobile!.trim().isNotEmpty) ? '(${AddOrderCtrl.CustomerMobile})' : ''}"
                                      "${(AddOrderCtrl.CustomerDiscount != null && AddOrderCtrl.CustomerDiscount!.isNotEmpty && (int.tryParse(AddOrderCtrl.CustomerDiscount!) ?? 0) > 0) ? " • ${AddOrderCtrl.CustomerDiscount}% Default Discount" : ""}",
                                      style: CommonWidget.CommonTitleTextStyle(
                                        color: Provider.of<ThemeProvider>(context, listen: false).currentTheme == 'dark' ? const Color(0xFFD1FAE5) : const Color(0xFF166534),
                                        height: 1.2,
                                      ),
                                      overflow: TextOverflow.visible,
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SizedBox.shrink(),

                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: GlobalAppColor.WhiteColorCode,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: GlobalAppColor.LightTextColorCode.withOpacity(0.15),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Items",
                            style: CommonWidget.CommonTitleTextStyle(
                              color: GlobalAppColor.DarkTextColorCode,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          // 🔹 Selected Items List
                          Consumer<AddOrderProvider>(
                            builder: (context, AddOrderCtrl, child) {
                              final selectedItems =
                                  AddOrderCtrl.getSelectedItems();
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: selectedItems.length,
                                itemBuilder: (context, index) {
                                  final item = selectedItems[index];
                                  final name = item['m_p_name'] ?? 'Unnamed';
                                  final qty = item['quantity'] ?? 0;
                                  final price = item['price'] ?? 0.0;
                                  final mProdId = item['m_prod_id'];

                                  // 🔹 Note sanitize: Remove "Remove:" and ignore blank/N/A
                                  String rawNote =
                                      item['note']?.toString().trim() ?? '';
                                  String cleanNote =
                                      rawNote.isNotEmpty &&
                                          rawNote.toLowerCase() != 'n/a'
                                      ? rawNote
                                            .replaceAll("Remove: ", "")
                                            .trim()
                                      : '';

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            // 🔹 Item name + quantity
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "$name x $qty",
                                                    overflow: TextOverflow.ellipsis,
                                                    style:
                                                        CommonWidget.CommonTitleTextStyle(
                                                          color: GlobalAppColor
                                                              .DarkTextColorCode,
                                                        ),
                                                  ),
                                                  Text(
                                                    item['m_p_arb_name'] ?? '',
                                                    style: CommonWidget.CommonTitleTextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w300,
                                                      color: GlobalAppColor.DarkTextColorCode.withOpacity(0.7),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // 🔹 Price + delete icon
                                            Expanded(
                                              flex: 2,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: <Widget>[
                                                  // 🧾 Note edit icon
                                                  InkWell(
                                                    overlayColor:
                                                        MaterialStateProperty.all(
                                                          Colors.transparent,
                                                        ),
                                                    onTap:
                                                        AddOrderCtrl
                                                            .isBookingLoader
                                                        ? null
                                                        : () async {
                                                            bool isConnected =
                                                                await GlobalFunction()
                                                                    .checkInternetConnection(
                                                                      context,
                                                                    );
                                                            if (isConnected) {
                                                              await AddOrderCtrl.getNoteListService(
                                                                context,
                                                                mProdId
                                                                    .toString(),
                                                              );
                                                              await AddSpecialInstructionsWidget(
                                                                context:
                                                                    context,
                                                                item: item,
                                                              );
                                                            }
                                                          },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFFF3F4F6,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: Border.all(
                                                          color: GlobalAppColor
                                                              .DarkTextColorCode.withOpacity(.1),
                                                          width: 0.5,
                                                        ),
                                                      ),
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(
                                                          3.0,
                                                        ),
                                                        child: Center(
                                                          child: Icon(
                                                            Symbols.article,
                                                            size: 15,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 5),
                                                  Flexible(
                                                    child: Builder(
                                                      builder: (ctx) {
                                                        // Base item total
                                                        double lineTotal =
                                                            qty *
                                                            (double.tryParse(
                                                                  price
                                                                      .toString(),
                                                                ) ??
                                                                0.0);
                                                        // Add modifier prices
                                                        final mods =
                                                            item['modifiers']
                                                                as List<
                                                                  dynamic
                                                                >? ??
                                                            [];
                                                        for (final mod
                                                            in mods) {
                                                          lineTotal +=
                                                              qty *
                                                              (double.tryParse(
                                                                    mod['price']
                                                                            ?.toString() ??
                                                                        '0',
                                                                  ) ??
                                                                  0.0);
                                                        }
                                                        return Text(
                                                          lineTotal
                                                              .toStringAsFixed(
                                                                2,
                                                              ),
                                                          textAlign:
                                                              TextAlign.end,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: CommonWidget.CommonTitleTextStyle(
                                                            color: GlobalAppColor
                                                                .DarkTextColorCode,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),

                                                  const SizedBox(width: 8),

                                                  // 🗑 Delete icon
                                                  InkWell(
                                                    overlayColor:
                                                        MaterialStateProperty.all(
                                                          Colors.transparent,
                                                        ),
                                                    onTap:
                                                        AddOrderCtrl
                                                            .isBookingLoader
                                                        ? null
                                                        : () async {
                                                            bool isConnected =
                                                                await GlobalFunction()
                                                                    .checkInternetConnection(
                                                                      context,
                                                                    );
                                                            if (isConnected) {
                                                              AddOrderCtrl.deleteOrderItem(
                                                                context:
                                                                    context,
                                                                item: item,
                                                              );
                                                            }
                                                          },
                                                    child: Icon(
                                                      Symbols.delete,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        // 🔹 Modifiers (if any)
                                        Builder(
                                          builder: (ctx) {
                                            final rawMods =
                                                item['modifiers']
                                                    as List<dynamic>?;
                                            if (rawMods == null ||
                                                rawMods.isEmpty) {
                                              return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 5,
                                              ),
                                              child: Wrap(
                                                spacing: 5,
                                                runSpacing: 4,
                                                children: rawMods.map((mod) {
                                                  final modName =
                                                      mod['modifier_name']
                                                          ?.toString() ??
                                                      '';
                                                  final modPrice =
                                                      double.tryParse(
                                                        mod['price']
                                                                ?.toString() ??
                                                            '0',
                                                      ) ??
                                                      0.0;
                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 7,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          GlobalAppColor
                                                              .ButtonColor.withOpacity(
                                                            0.08,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            GlobalAppColor
                                                                .ButtonColor.withOpacity(
                                                              0.3,
                                                            ),
                                                        width: 0.8,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Symbols.add_circle,
                                                          size: 11,
                                                          color: GlobalAppColor
                                                              .ButtonColor,
                                                        ),
                                                        const SizedBox(
                                                          width: 3,
                                                        ),
                                                        Text(
                                                          modPrice > 0
                                                              ? '$modName (+${modPrice.toStringAsFixed(2)})'
                                                              : modName,
                                                          style: CommonWidget.CommonTitleTextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: GlobalAppColor
                                                                .ButtonColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            );
                                          },
                                        ),

                                        // 🔹 Note only if meaningful
                                        if (cleanNote.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 0,
                                              right: 5,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Symbols.article,
                                                  size: 15,
                                                  color: const Color(
                                                    0xFF991B1B,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  cleanNote,
                                                  style:
                                                      CommonWidget.CommonTitleTextStyle(
                                                        color: const Color(
                                                          0xFF991B1B,
                                                        ),
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },

                                // 🔹 Divider condition
                                separatorBuilder: (context, index) {
                                  if (selectedItems.length <= 1 ||
                                      index == selectedItems.length - 1) {
                                    return const SizedBox.shrink();
                                  }
                                  return Divider(
                                    color: GlobalAppColor
                                        .DarkTextColorCode.withOpacity(.1),
                                    thickness: 1,
                                    height: 8,
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  /* IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // 🔹 Table Dropdown
                        Expanded(
                          flex: 2,
                          child: HomeWidget().buildDropdown(
                            hintText: AddOrderCtrl.OrderTax.isEmpty
                                ? 'Tax not available'
                                : 'Select Tax',
                            iconPadding: 0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: GlobalAppColor
                                    .DarkTextColorCode.withOpacity(.1),
                                width: 2,
                              ),
                            ),
                            showTextLeft: true,
                            showIconRight: true,
                            items: AddOrderCtrl.OrderTax.map(
                              (e) => "${e.name} (${e.rate})",
                            ).toList(),
                            value: AddOrderCtrl.selectedTaxData != null
                                ? "${AddOrderCtrl.selectedTaxData!.name} (${AddOrderCtrl.selectedTaxData!.rate})"
                                : (AddOrderCtrl.OrderTax.isNotEmpty
                                      ? "${AddOrderCtrl.OrderTax.first.name} (${AddOrderCtrl.OrderTax.first.rate})"
                                      : null),
                            onChanged: AddOrderCtrl.isBookingLoader
                                ? null
                                : (value) {
                                    AddOrderCtrl.updatedDPOrderTax(value);
                                  },
                            hintStyle: CommonWidget.CommonTitleTextStyle(
                              color: GlobalAppColor.DarkTextColorCode,
                              fontSize: 13,
                            ),
                            itemStyle: CommonWidget.CommonTitleTextStyle(
                              color: GlobalAppColor.DarkTextColorCode,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 🔹 Table Type Dropdown
                        Expanded(
                          flex: 2,
                          child: HomeWidget().buildDropdown(
                            hintText: AddOrderCtrl.OrderCharges.isEmpty
                                ? 'No Charges Available'
                                : 'Select Charges',
                            iconPadding: 0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: GlobalAppColor
                                    .DarkTextColorCode.withOpacity(.1),
                                width: 2,
                              ),
                            ),
                            showTextLeft: true,
                            showIconRight: true,
                            items: AddOrderCtrl.OrderCharges.map(
                              (e) => "${e.name} (${e.value})",
                            ).toList(),
                            value: AddOrderCtrl.selectedChargesData != null
                                ? "${AddOrderCtrl.selectedChargesData!.name} (${AddOrderCtrl.selectedChargesData!.value})"
                                : null,
                            onChanged: AddOrderCtrl.isBookingLoader
                                ? null
                                : (value) {
                                    AddOrderCtrl.updatedDPOrderCharges(value);
                                  },
                            hintStyle: CommonWidget.CommonTitleTextStyle(
                              color: GlobalAppColor.DarkTextColorCode,
                              fontSize: 13,
                            ),
                            itemStyle: CommonWidget.CommonTitleTextStyle(
                              color: GlobalAppColor.DarkTextColorCode,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),*/
                  SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // 🔹 Discount Column
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label
                              Text(
                                "Discount",
                                style: CommonWidget.CommonTitleTextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Input Field
                              DiscountInputField(),
                            ],
                          ),
                        ),

                        if (AddOrderCtrl.selectedTableType?.toLowerCase() !=
                            'dine in')
                          const SizedBox(width: 8),

                        // 🔹 Payment Method Column
                        if (AddOrderCtrl.selectedTableType?.toLowerCase() !=
                            'dine in')
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Label
                                Text(
                                  "Payment Method",
                                  style: CommonWidget.CommonTitleTextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Dropdown
                                HomeWidget().buildDropdown(
                                  hintText: AddOrderCtrl.PaymentMethods.isEmpty
                                      ? 'No Payment Methods Available'
                                      : 'Select Payment',
                                  iconPadding: 0,
                                  decoration: BoxDecoration(
                                    color: GlobalAppColor.WhiteColorCode,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: GlobalAppColor
                                          .DarkTextColorCode.withOpacity(.1),
                                      width: 2,
                                    ),
                                  ),
                                  showTextLeft: true,
                                  showIconRight: true,
                                  items: AddOrderCtrl.PaymentMethods.map(
                                    (e) => e.name,
                                  ).toList(),
                                  value:
                                      AddOrderCtrl.selectedPaymentMethodsData !=
                                          null
                                      ? AddOrderCtrl
                                            .selectedPaymentMethodsData!
                                            .name
                                      : (AddOrderCtrl.PaymentMethods.isNotEmpty
                                            ? AddOrderCtrl
                                                  .PaymentMethods
                                                  .first
                                                  .name
                                            : null),
                                  onChanged: AddOrderCtrl.isBookingLoader
                                      ? null
                                      : (value) {
                                          AddOrderCtrl.updatedDPOrderPaymentMethods(
                                            value,
                                          );
                                        },
                                  hintStyle: CommonWidget.CommonTitleTextStyle(
                                    color: GlobalAppColor.DarkTextColorCode,
                                    fontSize: 13,
                                  ),
                                  itemStyle: CommonWidget.CommonTitleTextStyle(
                                    color: GlobalAppColor.DarkTextColorCode,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (AddOrderCtrl.selectedTableType?.toLowerCase() !=
                      'dine in')
                    SizedBox(height: 10),
                  if (AddOrderCtrl.selectedTableType?.toLowerCase() !=
                      'dine in')
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: GlobalAppColor.WhiteColorCode,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: GlobalAppColor.DarkTextColorCode.withOpacity(
                            .1,
                          ),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            if (AddOrderCtrl.selectedPaymentMethodsType
                                    .toString()
                                    .toUpperCase() !=
                                "SPLIT")
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          AddOrderCtrl
                                              .selectedPaymentMethodsType
                                              .toString(),
                                          style:
                                              CommonWidget.CommonTitleTextStyle(
                                                color: GlobalAppColor
                                                    .HomeLightTextColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          AddOrderCtrl
                                              .selectedPaymentMethodsType
                                              .toString(),
                                          style:
                                              CommonWidget.CommonTitleTextStyle(
                                                color: GlobalAppColor
                                                    .HomeLightTextColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Symbols.credit_card,
                                        color: Color(0xFF374151),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        AddOrderCtrl.calculatedNetAmount
                                            .toStringAsFixed(2),
                                        style:
                                            CommonWidget.CommonTitleTextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15,
                                              color: const Color(0xFF374151),
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            if (AddOrderCtrl.selectedPaymentMethodsType
                                    .toString()
                                    .toUpperCase() ==
                                "SPLIT")
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // 🔹 CASH WRAPPER
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Cash Amount (SAR)",
                                            style:
                                                CommonWidget.CommonTitleTextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          CashAmount(),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // 🔹 CARD WRAPPER
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Card Amount (SAR)",
                                            style:
                                                CommonWidget.CommonTitleTextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          CardAmount(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (AddOrderCtrl.selectedPaymentMethodsType
                                    .toString()
                                    .toUpperCase() ==
                                "SPLIT")
                              Consumer3<
                                CashAmountProvider,
                                CardAmountProvider,
                                AddOrderProvider
                              >(
                                builder: (context, cash, card, order, child) {
                                  double liveTotal = cash.value + card.value;

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Cash:",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 14,
                                                  ),
                                            ),
                                            Text(
                                              "₺${cash.value.toStringAsFixed(2)}",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 14,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Card:",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 14,
                                                  ),
                                            ),
                                            Text(
                                              "₺${card.value.toStringAsFixed(2)}",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 14,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Total:",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            Text(
                                              "₺${liveTotal.toStringAsFixed(2)}",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Order Total:",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Text(
                                              "₺${order.overallTotal.toStringAsFixed(2)}",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 10),
                  Text(
                    "Order Priority",
                    style: CommonWidget.CommonTitleTextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 3),
                  HomeWidget().buildDropdown(
                    decoration: BoxDecoration(
                      color: GlobalAppColor.WhiteColorCode,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: GlobalAppColor.DarkTextColorCode.withOpacity(.1),
                        width: 2,
                      ),
                    ),
                    showTextLeft: true,
                    // optional: text left aligned
                    showIconRight: true,
                    // optional: icon right side
                    items: AddOrderCtrl.OrderPriority.map(
                      (e) => e.title!,
                    ).toList(),
                    value: AddOrderCtrl.selectedOrderPriority,
                    onChanged: AddOrderCtrl.isBookingLoader
                        ? null
                        : (value) {
                            AddOrderCtrl.updateOrderPriorityType(value);
                          },
                    hintStyle: CommonWidget.CommonTitleTextStyle(
                      color: GlobalAppColor.DarkTextColorCode,
                      fontSize: 13,
                    ),
                    itemStyle: CommonWidget.CommonTitleTextStyle(
                      color: GlobalAppColor.DarkTextColorCode,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Order Note",
                    style: CommonWidget.CommonTitleTextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 3),
                  Container(
                    height: 60, // ✅ Fixed height
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: GlobalAppColor.WhiteColorCode,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: GlobalAppColor.DarkTextColorCode.withOpacity(.1),
                        width: 2,
                      ),
                    ),
                    child: TextField(
                      controller:
                          AddOrderCtrl.OrderNoteController, // आपका controller
                      keyboardType: TextInputType.multiline,
                      maxLines: null, // ✅ Multiple lines allowed
                      style: CommonWidget.CommonTitleTextStyle(
                        color: GlobalAppColor.DarkTextColorCode,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter Order Note",
                        hintStyle: CommonWidget.CommonTitleTextStyle(
                          color: GlobalAppColor.DarkTextColorCode.withOpacity(
                            0.6,
                          ),
                          fontSize: 13,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 15),
                  CommonWidget().DividerWidget(height: 1.0),
                  SizedBox(height: 5),
                  buildAmountRow(
                    context,
                    "Subtotal",
                    AddOrderCtrl.overallTotal.toStringAsFixed(2),
                  ),

                  AddOrderCtrl.selectedTaxData != null
                      ? buildAmountRow(
                          context,
                          "Tax (${AddOrderCtrl.selectedTaxRate?.toStringAsFixed(2) ?? '0.00'}%)",
                          AddOrderCtrl.calculatedTaxAmount.toStringAsFixed(2),
                        )
                      : const SizedBox.shrink(),

                  AddOrderCtrl.selectedChargesId != null
                      ? buildAmountRow(
                          context,
                          AddOrderCtrl.selectedChargesType?.toLowerCase() ==
                                  "percentage"
                              ? "Charges (${AddOrderCtrl.selectedChargesAmt ?? '0'}%)"
                              : "Charges",
                          AddOrderCtrl.calculatedChargesAmount.toStringAsFixed(
                            2,
                          ),
                        )
                      : const SizedBox.shrink(),

                  context.watch<NumberInputDiscountProvider>().value > 0
                      ? buildAmountRow(
                          context,
                          "Discount (${context.read<NumberInputDiscountProvider>().value}%)",
                          "-${AddOrderCtrl.calculatedDiscountAmount.toStringAsFixed(2)}",
                          textColor: GlobalAppColor.AvailableCode,
                        )
                      : const SizedBox.shrink(),
                  SizedBox(height: 5),
                  CommonWidget().DividerWidget(height: 1.0),
                  SizedBox(height: 5),
                  buildAmountRow(
                    context,
                    "Total",
                    AddOrderCtrl.calculatedNetAmount.toStringAsFixed(2),
                    textFont: FontWeight.w500,
                  ),
                  // Bottom buttons
                  Padding(
                    padding: EdgeInsets.only(
                      top: 15,
                      bottom: MediaQuery.of(context).viewInsets.bottom > 0
                          ? MediaQuery.of(context).viewInsets.bottom + 10
                          : (Platform.isIOS ? 12.0 : 8.0),
                    ),
                    child: Column(
                      children: [
                        CommonWidget().CustomElevatedButton(
                          backgroundColor: GlobalAppColor.ButtonDarkColor,
                          width: double.infinity,
                          title: "Place Order",
                          isLoading: AddOrderCtrl.isBookingLoader &&
                              AddOrderCtrl.bookingLoadingAction == "ordered",
                          onPressed: AddOrderCtrl.isBookingLoader
                              ? null
                              : () async {
                                  bool isConnected = await GlobalFunction()
                                      .checkInternetConnection(context);
                                  if (isConnected) {
                                    AddOrderCtrl.BookingValidation(
                                      context,
                                      "ordered",
                                    );
                                  }
                                },
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        CommonWidget().CustomElevatedButton(
                          backgroundColor: const Color(0xFF3B82F6),
                          width: double.infinity,
                          title: "Save Draft",
                          isLoading: AddOrderCtrl.isBookingLoader &&
                              AddOrderCtrl.bookingLoadingAction == "draft",
                          onPressed: AddOrderCtrl.isBookingLoader
                              ? null
                              : () async {
                                  bool isConnected = await GlobalFunction()
                                      .checkInternetConnection(context);
                                  if (isConnected) {
                                    AddOrderCtrl.BookingValidation(
                                      context,
                                      "draft",
                                    );
                                  }
                                },
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 12,
                          ),
                        ),
                        SizedBox(height: Platform.isIOS ? 15 : 5),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (!isMobile) {
      return Container(
        width: panelWidth,
        color: GlobalAppColor.WhiteColorCode,
        child: panelContent(false),
      );
    }

    return Container(
      color: GlobalAppColor.WhiteColorCode,
      child: panelContent(true),
    );
  }
}

//-✅---------------------------------------------------------------------✅-//

// ─── Table Selection Modal ───────────────────────────────────────────────────
// Shown when user taps "Select Tables" in the Order Summary panel (Dine In).
// Supports multi-select, location filter chips, Premium badge, status circle.
// Returns List<OrderTableData> on Confirm, null on Cancel / barrier dismiss.
class _TableSelectionModal extends StatefulWidget {
  final List<OrderTableData> tables;
  final List<int> initialSelectedIds;

  const _TableSelectionModal({
    required this.tables,
    required this.initialSelectedIds,
  });

  @override
  State<_TableSelectionModal> createState() => _TableSelectionModalState();
}

class _TableSelectionModalState extends State<_TableSelectionModal> {
  final List<OrderTableData> _selected = [];
  String _activeLocation = 'All';

  @override
  void initState() {
    super.initState();
    for (final t in widget.tables) {
      if (widget.initialSelectedIds.contains(t.tableID)) {
        _selected.add(t);
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<String> get _locations {
    final seen = <String>{};
    final locs = <String>['All'];
    for (final t in widget.tables) {
      if (t.location.isNotEmpty &&
          t.location != 'N/A' &&
          seen.add(t.location)) {
        locs.add(t.location);
      }
    }
    return locs;
  }

  List<OrderTableData> get _filtered {
    if (_activeLocation == 'All') return widget.tables;
    return widget.tables.where((t) => t.location == _activeLocation).toList();
  }

  bool _isSelected(int id) => _selected.any((t) => t.tableID == id);

  String? _getBlockedReason(OrderTableData table) {
    if (_isSelected(table.tableID)) return null;

    // Check if any premium table is currently selected
    final hasPremiumSelected = _selected.any((t) => t.isPremium);
    if (hasPremiumSelected) {
      return "Premium table selected alone";
    }

    // If the table we want to select is Premium
    if (table.isPremium) {
      if (_selected.isNotEmpty) {
        return "Premium table must be selected alone";
      }
    }

    // Check if an occupied table is currently selected
    final hasOccupiedSelected = _selected.any((t) => t.isOccupied);

    if (table.isOccupied) {
      if (hasOccupiedSelected) {
        return "Only one occupied table allowed";
      }
      // Premium tables are handled by the premium check above
    }

    return null;
  }

  void _toggle(OrderTableData table) {
    final sel = _isSelected(table.tableID);
    if (!sel) {
      final reason = _getBlockedReason(table);
      if (reason != null) {
        showCustomToast(
          context: context,
          message: reason,
        );
        return;
      }
    }

    if (table.isOccupied && !sel) {
      // ✅ For occupied tables, show confirmation dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                'Table Occupied',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${table.tableName} is currently occupied with an active order.',
                style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
              SizedBox(height: 12),
              if (table.occupiedOrderNumber != null) ...[
                _infoRow('Order', '#${table.occupiedOrderNumber}'),
                SizedBox(height: 6),
              ],
              if (table.occupiedCustomer != null) ...[
                _infoRow('Customer', table.occupiedCustomer!),
                SizedBox(height: 6),
              ],
              if (table.occupiedOrderStatus != null) ...[
                _infoRow('Status', table.occupiedOrderStatus!),
                SizedBox(height: 12),
              ],
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFF59E0B), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Color(0xFFD97706),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selecting this table will add items to the existing order',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  // Do NOT clear selected list (allows combination with fresh tables as per rules)
                  _selected.add(table);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalAppColor.ButtonColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                'Add to Order',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Regular toggle
    setState(() {
      if (sel) {
        _selected.removeWhere((t) => t.tableID == table.tableID);
      } else {
        _selected.add(table);
      }
    });
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final dialogW = screenW < 600
        ? screenW * 0.94
        : screenW < 950
        ? 520.0
        : 580.0;
    final maxH = screenH * 0.85;
    final locs = _locations;
    final filtered = _filtered;
    final crossAxisCount = screenW < 480 ? 2 : 3;

    return Dialog(
      backgroundColor: GlobalAppColor.WhiteColorCode,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenW < 600 ? 12.0 : 40.0,
        vertical: 24.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogW, maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Location',
                    style: CommonWidget.CommonTitleTextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: GlobalAppColor.DarkTextColorCode,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 22,
                      color: GlobalAppColor.LightTextColorCode,
                    ),
                    onPressed: () => Navigator.of(context).pop(null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Location Filter Chips ────────────────────────────────────
            if (locs.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: locs.map((loc) {
                      final active = _activeLocation == loc;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _activeLocation = loc),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? GlobalAppColor.ButtonColor
                                  : GlobalAppColor.WhiteColorCode,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? GlobalAppColor.ButtonColor
                                    : GlobalAppColor.LightTextColorCode.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              loc,
                              style: TextStyle(
                                color: active
                                    ? Colors.white
                                    : GlobalAppColor.DarkTextColorCode,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // ── "Select Table" header + selected count ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Table',
                    style: CommonWidget.CommonTitleTextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Selected: ${_selected.length} ${_selected.length == 1 ? 'table' : 'tables'}',
                    style: TextStyle(
                      color: GlobalAppColor.LightTextColorCode,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // ── Selected table chips ─────────────────────────────────────
            if (_selected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selected.map((t) {
                    return Chip(
                      label: Text(
                        t.tableName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: GlobalAppColor.DarkBlueColor,
                        ),
                      ),
                      onDeleted: () => _toggle(t),
                      deleteIcon: Icon(
                        Icons.close,
                        size: 14,
                        color: GlobalAppColor.DarkBlueColor,
                      ),
                      backgroundColor: GlobalAppColor.LightBlueColor,
                      side: BorderSide(
                        color: GlobalAppColor.ButtonColor,
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 0,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ),

            // ── Tables Grid ──────────────────────────────────────────────
            Flexible(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No tables available',
                          style: CommonWidget.CommonTitleTextStyle(
                            color: GlobalAppColor.LightTextColorCode,
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final table = filtered[i];
                          final sel = _isSelected(table.tableID);
                          final isPremium = table.isPremium;
                          final isOccupied = table.isOccupied;
                          final blockedReason = _getBlockedReason(table);
                          final isBlocked = blockedReason != null;

                          return GestureDetector(
                            onTap: () => _toggle(table),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isOccupied
                                    ? (Provider.of<ThemeProvider>(context, listen: false).currentTheme == 'dark' ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2))
                                    : isBlocked
                                    ? (Provider.of<ThemeProvider>(context, listen: false).currentTheme == 'dark' ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB))
                                    : sel
                                    ? (Provider.of<ThemeProvider>(context, listen: false).currentTheme == 'dark' ? const Color(0xFF1E1E38) : const Color(0xFFEFF6FF))
                                    : GlobalAppColor.WhiteColorCode,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isOccupied
                                      ? const Color(0xFFFCA5A5)
                                      : isBlocked
                                      ? (Provider.of<ThemeProvider>(context, listen: false).currentTheme == 'dark' ? const Color(0xFF334155) : const Color(0xFFE5E7EB))
                                      : sel
                                      ? GlobalAppColor.ButtonColor
                                      : GlobalAppColor.LightTextColorCode.withOpacity(0.15),
                                  width: sel ? 2.0 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: sel
                                        ? GlobalAppColor.ButtonColor.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Opacity(
                                opacity: isBlocked ? 0.5 : 1.0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            table.tableName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: isOccupied
                                                  ? (Provider.of<ThemeProvider>(context, listen: false).currentTheme == 'dark' ? const Color(0xFFFECACA) : const Color(0xFF991B1B))
                                                  : GlobalAppColor.DarkTextColorCode,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        if (isPremium)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF7CC),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.workspace_premium,
                                                  size: 11,
                                                  color: Color(0xFFD97706),
                                                ),
                                                SizedBox(width: 2),
                                                Text(
                                                  'Premium',
                                                  style: TextStyle(
                                                    color: Color(0xFFD97706),
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else if (isOccupied)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFDC2626,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Occupied',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(width: 2),
                                        if (isBlocked)
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFE5E7EB),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.lock,
                                                size: 11,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          )
                                        else if (!isOccupied)
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 150,
                                            ),
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: sel
                                                  ? GlobalAppColor.ButtonColor
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: sel
                                                    ? GlobalAppColor.ButtonColor
                                                    : const Color(0xFF22C55E),
                                                width: 2,
                                              ),
                                            ),
                                            child: sel
                                                ? const Center(
                                                    child: Icon(
                                                      Icons.check,
                                                      size: 12,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                          )
                                        else
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(
                                                0xFFDC2626,
                                              ),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.close,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people_outline_rounded,
                                          size: 14,
                                          color: GlobalAppColor.LightTextColorCode,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${table.seatingCapacity} Seats',
                                          style: TextStyle(
                                            color: GlobalAppColor.LightTextColorCode,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: GlobalAppColor.LightTextColorCode,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            table.location,
                                            style: TextStyle(
                                              color: GlobalAppColor.LightTextColorCode,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isPremium &&
                                        table.minimumSpendAmount > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '₺ Min. spend: ${table.minimumSpendAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: GlobalAppColor.ButtonColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ] else if (isPremium &&
                                        table.tableChargeAmount > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '₺ Table charge: ${table.tableChargeAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: GlobalAppColor.ButtonColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (isOccupied) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: GlobalAppColor.WhiteColorCode.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFFFEE2E2).withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (table.occupiedOrderNumber != null || table.occupiedOrderId != null)
                                              Text(
                                                'Order #${table.occupiedOrderNumber ?? table.occupiedOrderId}',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Provider.of<ThemeProvider>(context, listen: false).currentTheme == 'dark' ? const Color(0xFFFECACA) : const Color(0xFF991B1B),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            if (table.occupiedCustomer != null)
                                              Text(
                                                'Guest: ${table.occupiedCustomer}',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: GlobalAppColor.LightTextColorCode,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            if (table.occupiedOrderStatus != null)
                                              Row(
                                                children: [
                                                  const Text(
                                                    'Status: ',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                  Text(
                                                    table.occupiedOrderStatus!,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: GlobalAppColor.ButtonColor,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (isBlocked) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.warning_amber_rounded,
                                              size: 10,
                                              color: Color(0xFFD97706),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                blockedReason,
                                                style: const TextStyle(
                                                  fontSize: 8.5,
                                                  color: Color(0xFFB45309),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),

            Divider(height: 1, thickness: 1, color: GlobalAppColor.LightTextColorCode.withOpacity(0.15)),

            // ── Action buttons ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: GlobalAppColor.LightTextColorCode.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _selected.isEmpty
                          ? null
                          : () => Navigator.of(
                              context,
                            ).pop(List<OrderTableData>.from(_selected)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalAppColor.ButtonColor,
                        disabledBackgroundColor: GlobalAppColor.ButtonColor.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Confirm Selection',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color backgroundColor;

  const _AnimatedActionButton({
    required this.child,
    required this.onTap,
    this.backgroundColor = Colors.transparent,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() {
        _scale = 0.8;
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() {
        _scale = 1.0;
      });
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      setState(() {
        _scale = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: Container(
        height: double.infinity,
        color: widget.backgroundColor,
        alignment: Alignment.center,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 80),
          child: widget.child,
        ),
      ),
    );
  }
}
