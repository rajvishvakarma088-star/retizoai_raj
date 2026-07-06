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
                backgroundColor: const Color(0xFFE5E7EB),
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
                          // Custom AppBar
                          CommonWidget().CustomAppBar(
                            context: context,
                            isLoading: AddOrderCtrl.isAddOrderLoader,
                            onLogout: () async {
                              if (await GlobalFunction()
                                  .checkInternetConnection(context)) {
                                GlobalFunction.LogOutApplication(
                                  context: context,
                                );
                              }
                            },
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
                                    // Mobile Layout (Stack + Slide Panel)
                                    return Stack(
                                      children: [
                                        SizedBox(
                                          height: contentHeight,
                                          child: UIWidget(context),
                                        ),
                                        if (AddOrderCtrl
                                            .isOrderSummaryPanelOpen)
                                          AnimatedPositioned(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeOutBack,
                                            right:
                                                AddOrderCtrl
                                                    .isOrderSummaryPanelOpen
                                                ? 0
                                                : -screenWidth * 0.82,
                                            top: 5,
                                            bottom: 0,
                                            width: screenWidth * 0.82 > 450
                                                ? 450
                                                : screenWidth * 0.82,
                                            child: Material(
                                              elevation: 12,
                                              color: Colors.white,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(
                                                      10,
                                                    ),
                                                    bottomLeft: Radius.circular(
                                                      10,
                                                    ),
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

  //-✅---------------------------------------------------------------------✅-//
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
              color: const Color(0xFFF3F4F6),
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
                      children: [
                        CommonWidget().PanelTitle(
                          title: "Categories".toUpperCase(),
                        ),
                        Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.sm,
                            ),
                          ),
                          child: Text(
                            (() {
                              // 🔹 All Brands Select nahi → Categories list original show → count normal
                              if (AddOrderCtrl.selectedBrandId == null) {
                                return "${AddOrderCtrl.CategoriesListing.length} categories";
                              }

                              // 🔹 Brand selected and list empty → 0
                              if (AddOrderCtrl
                                  .filteredCategoriesListing
                                  .isEmpty) {
                                return '0 categories';
                              }

                              // 🔹 Brand selected → All option include → +1
                              return "${(AddOrderCtrl.filteredCategoriesListing.length + 1).toString()} categories";
                            })(),
                            style: CommonWidget.CommonTitleTextStyle(
                              fontWeight: FontWeight.w400,
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
                            color: const Color(0xFFE5E7EB),
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
