// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
class AddNewOrder extends StatefulWidget {
  final Map<String, dynamic>? EditOrderData; // ✅ optional parameter for edit

  const AddNewOrder({super.key, this.EditOrderData});

  @override
  AddNewOrderState createState() => AddNewOrderState();
}

//-✅---------------------------------------------------------------------✅-//
class AddNewOrderState extends State<AddNewOrder>
    with SingleTickerProviderStateMixin {
  //-✅-------------------------------------------------------------------✅-//
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final AddOrderCtrl = context.read<AddOrderProvider>();
      await AddOrderCtrl.ClearData(context);

      // Agar edit ke liye orderData pass hua hai
      if (widget.EditOrderData != null) {
        await AddOrderCtrl.loadOrderForEdit(context, widget.EditOrderData!);
      }
    });
  }

  //-✅---------------------------------------------------------------------✅-//
  @override
  Widget build(BuildContext context) {
    return Consumer2<AddOrderProvider, UserInfoProvider>(
      builder: (context, AddOrderCtrl, UserInfoCtrl, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final topPadding = MediaQuery.of(context).padding.top;
            final bool isMobile = screenWidth < 600;
            final double verticalSpacing = screenHeight * 0.01;
            final double contentHeight =
                screenHeight - (kToolbarHeight + topPadding) - verticalSpacing;

            return WillPopScope(
              onWillPop: () async {
                if (AddOrderCtrl.isBookingLoader) return false;
                if (AddOrderCtrl.isOrderSummaryPanelOpen && isMobile) {
                  AddOrderCtrl.closeOrderSummaryPanel();
                  return false;
                }
                return true;
              },
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                backgroundColor: GlobalAppColor.BodyBgColorCode,
                body: SafeArea(
                  top: false,
                  // AppBar ke liye
                  left: true,
                  // Landscape me left margin ke liye
                  right: true,
                  // Landscape me right margin ke liye
                  bottom: true,
                  // gesture / notch safe fix for Samsung
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Premium Add New Order Custom Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: GlobalAppColor.WhiteColorCode,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: SafeArea(
                              bottom: false,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (!AddOrderCtrl.isBookingLoader) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: GlobalAppColor.WhiteColorCode,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 18,
                                        color: GlobalAppColor.DarkTextColorCode,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Add New Order",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: GlobalAppColor.DarkTextColorCode,
                                    ),
                                  ),
                                  if (AddOrderCtrl.isAddOrderLoader) ...[
                                    const SizedBox(width: 12),
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Content
                          Expanded(
                            child: SizedBox(
                              height: contentHeight,
                              child: OrientationBuilder(
                                builder: (context, orientation) {
                                  final bool isPortrait =
                                      orientation == Orientation.portrait;

                                  if (isMobile) {
                                    // Mobile Layout (Stack + Bottom Sheet Slide Panel)
                                    return Stack(
                                      children: [
                                        SizedBox(
                                          height: contentHeight,
                                          child: UIWidget(context),
                                        ),
                                        if (AddOrderCtrl.isOrderSummaryPanelOpen)
                                          Positioned.fill(
                                            child: GestureDetector(
                                              onTap: () => AddOrderCtrl.closeOrderSummaryPanel(),
                                              child: Container(
                                                color: Colors.black.withOpacity(0.5),
                                              ),
                                            ),
                                          ),
                                        AnimatedPositioned(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeOutCubic,
                                          left: 0,
                                          right: 0,
                                          bottom: AddOrderCtrl.isOrderSummaryPanelOpen
                                              ? 0
                                              : -screenHeight * 0.82,
                                          height: screenHeight * 0.82,
                                          child: Material(
                                            elevation: 16,
                                            color: GlobalAppColor.WhiteColorCode,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.circular(16),
                                            ),
                                            child: AddOrderWidget()
                                                .OrderSummaryPanel(
                                                  context,
                                                  AddOrderCtrl.MenuListing,
                                                  AddOrderCtrl,
                                                  true,
                                                ),
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Desktop/Tablet Layout (Side by Side)
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 7,
                                          child: UIWidget(context),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              top: Platform.isIOS
                                                  ? verticalSpacing
                                                  : verticalSpacing + 2,
                                              bottom: Platform.isIOS
                                                  ? verticalSpacing
                                                  : 0,
                                            ),
                                            child: AddOrderWidget()
                                                .OrderSummaryPanel(
                                                  context,
                                                  AddOrderCtrl.MenuListing,
                                                  AddOrderCtrl,
                                                  false,
                                                ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (context.watch<AddOrderProvider>().isAddOrderLoader ||
                          context.watch<AddOrderProvider>().isAddOrderLoader)
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: GlobalAppColor.ButtonDarkColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAllCategoriesBottomSheet(BuildContext context, AddOrderProvider AddOrderCtrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GlobalAppColor.WhiteColorCode,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            List<CategoryModel> categories = AddOrderCtrl.selectedBrandId != null
                ? AddOrderCtrl.CategoriesListing.where(
                    (e) => e.brandid != null && e.brandid.toString() == AddOrderCtrl.selectedBrandId.toString(),
                  ).toList()
                : AddOrderCtrl.CategoriesListing;

            if (AddOrderCtrl.SearchCategoriesController.text.isNotEmpty) {
              final query = AddOrderCtrl.SearchCategoriesController.text.toLowerCase();
              categories = categories.where((cat) {
                return cat.mCatName.toLowerCase().contains(query) ||
                    (cat.mCatArbName != null && cat.mCatArbName.toLowerCase().contains(query)) ||
                    (cat.status != null && cat.status.toLowerCase().contains(query));
              }).toList();
            }

            if (AddOrderCtrl.selectedBrandId != null && categories.isNotEmpty) {
              if (!categories.any((c) => c.mCatId == -1)) {
                categories = [
                  CategoryModel(
                    mCatId: -1,
                    mCatName: "All",
                    mCatArbName: "الكل",
                    mCatIcon: "https://www.pngitem.com/pimgs/m/141-1412195_menu-icon-png-transparent-png.png",
                    status: '', brandid: '', creationDatetime: '', createdBy: '', modificationDatetime: '', modifiedBy: '', orgId: '',
                  ),
                  ...categories,
                ];
              }
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Select Category",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final item = categories[index];
                          final bool isSelected = AddOrderCtrl.selectedCategoryIndex == index;

                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CommonWidget().RectangleCachedImage(
                                  context: context,
                                  imageUrl: item.mCatIcon.startsWith("https")
                                      ? item.mCatIcon
                                      : "${GlobalServiceURL.ImageBaseUrl}${item.mCatIcon}",
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                            ),
                            title: Text(
                              item.mCatName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? GlobalAppColor.ButtonColor : const Color(0xFF374151),
                              ),
                            ),
                            trailing: isSelected 
                                ? Icon(Icons.check_circle, color: GlobalAppColor.ButtonColor)
                                : null,
                            onTap: () {
                              if (item.mCatId == -1) {
                                AddOrderCtrl.setCategory(null);
                              } else {
                                AddOrderCtrl.setCategory(item.mCatId);
                              }
                              AddOrderCtrl.onCategorySelected(index, item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  //-✅---------------------------------------------------------------------//
  Widget UIWidget(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Consumer2<AddOrderProvider, UserInfoProvider>(
      builder: (context, AddOrderCtrl, UserInfoCtrl, child) {
        return Padding(
          padding: EdgeInsets.only(
            top: Platform.isIOS ? 12 : 5,
            bottom: Platform.isIOS ? 15 : 0,
            left: Platform.isIOS ? 10 : 5,
            right: 5,
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: GlobalAppColor.BodyBgColorCode,
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: SingleChildScrollView(
                physics: isMobile
                    ? const BouncingScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AddOrderWidget().AddNewOrders(context, UserInfoCtrl),
                    const SizedBox(height: 15),
                    AddOrderWidget().SearchCategoriesOrders(
                      context,
                      AddOrderCtrl,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CommonWidget().PanelTitle(
                              title: "Categories".toUpperCase(),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: GlobalAppColor.LightTextColorCode.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (() {
                                  List<CategoryModel> list = AddOrderCtrl.selectedBrandId != null
                                      ? AddOrderCtrl.CategoriesListing.where(
                                          (e) => e.brandid != null && e.brandid.toString() == AddOrderCtrl.selectedBrandId.toString(),
                                        ).toList()
                                      : AddOrderCtrl.CategoriesListing;

                                  if (AddOrderCtrl.SearchCategoriesController.text.isNotEmpty) {
                                    final query = AddOrderCtrl.SearchCategoriesController.text.toLowerCase();
                                    list = list.where((cat) {
                                      return cat.mCatName.toLowerCase().contains(query) ||
                                          (cat.mCatArbName != null && cat.mCatArbName.toLowerCase().contains(query)) ||
                                          (cat.status != null && cat.status.toLowerCase().contains(query));
                                    }).toList();
                                  }
                                  
                                  if (AddOrderCtrl.selectedBrandId != null && list.isNotEmpty) {
                                    return "${list.length + 1}";
                                  }
                                  return "${list.length}";
                                })(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: GlobalAppColor.LightTextColorCode,
                                ),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _showAllCategoriesBottomSheet(context, AddOrderCtrl),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  "View All",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: GlobalAppColor.ButtonColor,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: GlobalAppColor.ButtonColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AddOrderWidget().CategoriesListWidget(
                      context,
                      AddOrderCtrl.CategoriesListing,
                      AddOrderCtrl,
                    ),
                    CommonWidget().menuDivider(),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: AddOrderWidget().SearchMenuOrders(
                            context,
                            AddOrderCtrl,
                          ),
                        ),
                        if (isMobile) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () async {
                              if (AddOrderCtrl.selectedItems.isEmpty) {
                                PopupAlertHelper.showPopupFailedAlert(
                                  context,
                                  "Failed",
                                  "",
                                  "Select at least one item for the order",
                                );
                              } else {
                                bool isConnected = await GlobalFunction()
                                    .checkInternetConnection(context);
                                if (isConnected) {
                                  for (var item in AddOrderCtrl.selectedItems) {
                                    GlobalFunction().debugFunction(
                                      item.toString(),
                                    );
                                  }
                                  AddOrderCtrl.openOrderSummaryPanelWithData(
                                    false,
                                  );
                                  AddOrderCtrl.recalculateAmounts(context);
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.sm,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: GlobalAppColor.ButtonColor,
                                borderRadius: BorderRadius.circular(
                                  AppBorderRadius.sm,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    "Order Now",
                                    style: CommonWidget.CommonTitleTextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_right_sharp,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        CommonWidget().PanelTitle(
                          title:
                              (AddOrderCtrl.SelectedCategory?.mCatName ??
                                      "All") ==
                                  "All"
                              ? "All Menu Items".toUpperCase()
                              : "Selected Category Items".toUpperCase(),
                        ),
                        Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: GlobalAppColor.LightTextColorCode.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.sm,
                            ),
                          ),
                          child: Text(
                            AddOrderCtrl.filteredMenuListing.isNotEmpty
                                ? "${AddOrderCtrl.MenusCount} items"
                                : '0',
                            style: CommonWidget.CommonTitleTextStyle(
                              fontWeight: FontWeight.w400,
                              color: GlobalAppColor.LightTextColorCode,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AddOrderWidget().MenuListWidget(
                      context,
                      AddOrderCtrl.MenuListing,
                      AddOrderCtrl,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
