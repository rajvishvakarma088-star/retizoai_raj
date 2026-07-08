// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//-✅---------------------------------------------------------------------✅-//
class KdsWidget {
  // ── Priority badge helpers (mirrors web priorityColors) ─────────────────
  Color _priorityBadgeBg(String priority) {
    final p = priority.toLowerCase();
    if (p == 'urgent') return const Color(0xFFFEE2E2); // red-100
    if (p == 'high') return const Color(0xFFFFEDD5); // orange-100
    return const Color(0xFFDCFCE7); // green-100
  }

  Color _priorityBadgeText(String priority) {
    final p = priority.toLowerCase();
    if (p == 'urgent') return const Color(0xFFDC2626); // red-700
    if (p == 'high') return const Color(0xFFF97316); // orange-600
    return const Color(0xFF166534); // green-800
  }

  Color _priorityCardBorder(String priority) {
    final p = priority.toLowerCase();
    if (p == 'urgent') return const Color(0xFFDC2626).withOpacity(.35);
    if (p == 'high') return const Color(0xFFF97316).withOpacity(.35);
    return GlobalAppColor.DarkBlueColor.withOpacity(.3);
  }

  //-✅--OrderListWidget--------------------------------------------------✅-//
  Widget OrderListWidget(BuildContext context) {
    return Consumer<KdsProvider>(
      builder: (context, KdsCtrl, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            double screenWidth = constraints.maxWidth;
            double screenHeight = MediaQuery.of(context).size.height;
            bool isLandscape =
                MediaQuery.of(context).orientation == Orientation.landscape;

            // Card spacing
            double cardSpacing = AppDimensions.sm;

            // ✅ FIX: Ensure minimum height so stats cards are always readable
            // on small phones (screenHeight * 0.08 could be only 51px on 640px screens)
            double cardHeight = isLandscape
                ? screenHeight * 0.16
                : (screenHeight * 0.08).clamp(72.0, 100.0);

            // List of order widgets - 3 CARDS ONLY (like web app)
            List<Widget> orderWidgets = [
              // Card 1: Active Orders
              OrderUIWidget(
                title: "Active Orders",
                value: KdsCtrl.getPendingKitchenOrderCount(),
                icon: Symbols.access_time_filled_rounded,
                iconColor: GlobalAppColor.DarkBlueColor,
                circleColor: GlobalAppColor.LightBlueColor,
                index: 0,
                selectedIndex: KdsCtrl.selectedFilterOrderTab,
              ),

              // Card 2: Completed Orders (opens modal)
              OrderUIWidget(
                title: "Completed Orders",
                value: KdsCtrl.getCompletedOrderCount(),
                icon: Symbols.check_circle_rounded,
                iconColor: GlobalAppColor.AvailableCode,
                circleColor: GlobalAppColor.AvailableCode.withOpacity(.2),
                index: 1,
                selectedIndex: KdsCtrl.selectedFilterOrderTab,
              ),

              // Card 3: Cancelled Orders (opens modal)
              OrderUIWidget(
                title: "Cancelled Orders",
                value: KdsCtrl.getCancelledOrderCount(),
                icon: Symbols.cancel,
                iconColor: GlobalAppColor.RedCode,
                circleColor: GlobalAppColor.RedCode.withOpacity(.1),
                index: 2,
                selectedIndex: KdsCtrl.selectedFilterOrderTab,
              ),
            ];

            return SizedBox(
              height: cardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: cardSpacing / 2),
                itemCount: orderWidgets.length,
                separatorBuilder: (_, __) => SizedBox(width: cardSpacing),
                itemBuilder: (context, index) {
                  // Adaptive card width
                  double cardWidth;

                  if (screenWidth >= 1200) {
                    cardWidth = 300; // Desktop standard width
                  } else if (screenWidth >= 800) {
                    cardWidth = 250; // Tablet standard width
                  } else {
                    cardWidth = isLandscape
                        ? screenWidth * 0.3
                        : screenWidth * 0.5; // Mobile fractional width
                  }

                  return InkWell(
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                    onTap: () async {
                      final isConnected = await GlobalFunction()
                          .checkInternetConnection(context);
                      if (isConnected) {
                        // Update selected tab for visual feedback
                        KdsCtrl.updateSelectedFilterTab(index);

                        if (index == 0) {
                          // Active Orders - close any open modals
                          KdsCtrl.toggleCompletedModal(false);
                          KdsCtrl.toggleCancelledModal(false);
                        } else if (index == 1) {
                          // Completed Orders - fetch data and open modal
                          await KdsCtrl.GetFilterOrderListService(
                            context,
                            "completed",
                            KdsCtrl.selectedKDSDate.toString(),
                          );
                          KdsCtrl.toggleCompletedModal(true);
                          KdsCtrl.toggleCancelledModal(false);
                        } else if (index == 2) {
                          // Cancelled Orders - fetch data and open modal
                          await KdsCtrl.GetFilterOrderListService(
                            context,
                            "cancelled",
                            KdsCtrl.selectedKDSDate.toString(),
                          );
                          KdsCtrl.toggleCancelledModal(true);
                          KdsCtrl.toggleCompletedModal(false);
                        }
                      }
                    },
                    child: SizedBox(
                      width: cardWidth,
                      child: orderWidgets[index],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  //-✅--OrderUIWidget----------------------------------------------------✅-//
  Widget OrderUIWidget({
    required String title,
    required int value,
    IconData? icon, // optional icon
    Color circleColor = const Color(0xFFE5E7EB), // circle bg color
    Color iconColor = Colors.black87, // icon color
    required int index,
    required int selectedIndex,
  }) {
    bool showValueInCircle = icon == null; // Agar icon null → number show

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppDimensions.sm,
        horizontal: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        color: GlobalAppColor.WhiteColorCode,
        border: Border.all(
          color: selectedIndex == index
              ? GlobalAppColor
                    .ButtonDarkColor // SELECTED
              : Colors.grey.shade300, // NORMAL
          width: selectedIndex == index ? 2.5 : 1.5,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CommonWidget.CommonTitleTextStyle(
                      height: 1.2,
                      fontSize: 12,
                      color: GlobalAppColor.DarkTextColorCode,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$value",
                    style: CommonWidget.CommonTitleTextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ✅ Circle/Icon — min 32×32 ensures 2-digit counts don't overflow
            Container(
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
              ),
              child: Center(
                child: showValueInCircle
                    ? Text(
                        "$value",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      )
                    : Icon(icon, size: 18, color: iconColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //-✅--CurrentlyStationWidget-------------------------------------------✅-//
  Widget CurrentlyStationWidget(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: GlobalAppColor.LightBlueColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(
          color: GlobalAppColor.DarkBlueColor.withOpacity(.3),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: AppDimensions.sm,
        horizontal: AppDimensions.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // ✅ LEFT SIDE
          Expanded(
            flex: 1,
            child: Row(
              children: <Widget>[
                Icon(Symbols.chef_hat, color: GlobalAppColor.DarkBlueColor),
                SizedBox(width: 6),
                Flexible(
                  child: Consumer<KdsProvider>(
                    builder: (context, kdsCtrl, _) => Text(
                      "Currently viewing: ${kdsCtrl.selectedStationType ?? 'All'}",
                      style: CommonWidget.CommonTitleTextStyle(
                        color: GlobalAppColor.DarkBlueColor,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      softWrap: true,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 10),

          // ✅ RIGHT SIDE — full text allowed, no overflow
          Expanded(
            flex: 1,
            child: Text(
              "Sequential processing: Completes one order before starting next",
              style: CommonWidget.CommonTitleTextStyle(
                color: GlobalAppColor.DarkBlueColor,
                height: 1.2,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  //-✅--KitchenOrderLayout-----------------------------------------------✅-//
  Widget KitchenOrderLayout(BuildContext context) {
    return Consumer<KdsProvider>(
      builder: (context, KdsCtrl, child) {
        return SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use constraints.maxWidth for breakpoint (this updates on resize)
              final double width = constraints.maxWidth;
              final bool isMobile = width < 700; // mobile breakpoint
              return isMobile
                  ? Column(
                      children: [
                        buildOrderPanel(
                          title: "Kitchen Orders",
                          count: KdsCtrl.getPendingKitchenOrderCount(),
                          child: KitchenOrderListWidget(),
                          icon: Symbols.access_time,
                        ),
                        buildOrderPanel(
                          title: "Ready to Serve",
                          count: KdsCtrl.getReadyToServeOrderCount(),
                          child: ReadyToServeListWidget(),
                          icon: Symbols.check_circle_rounded,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: buildOrderPanel(
                            title: "Kitchen Orders",
                            count: KdsCtrl.getPendingKitchenOrderCount(),
                            child: KitchenOrderListWidget(),
                            icon: Symbols.access_time,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: buildOrderPanel(
                            title: "Ready to Serve",
                            count: KdsCtrl.getReadyToServeOrderCount(),
                            child: ReadyToServeListWidget(),
                            icon: Symbols.check_circle_rounded,
                          ),
                        ),
                      ],
                    );
            },
          ),
        );
      },
    );
  }

  //-✅--buildOrderPanel--------------------------------------------------✅-//
  Widget buildOrderPanel({
    required String title,
    required int count,
    required Widget child,
    required IconData icon, // ✅ icon add
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.md),
      decoration: BoxDecoration(
        color: GlobalAppColor.WhiteColorCode,
        borderRadius: AppBorderRadius.card,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // important
        children: <Widget>[
          // Header
          Container(
            padding: EdgeInsets.symmetric(
              vertical: AppDimensions.xs,
              horizontal: AppDimensions.md,
            ),
            decoration: BoxDecoration(
              color: GlobalAppColor.ButtonColor,
              borderRadius: AppBorderRadius.topOnly(radius: AppBorderRadius.md),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: Colors.white), // ✅ icon
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: CommonWidget.CommonTitleTextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // ✅ Count badge — min 30×30 to prevent 2-digit overflow
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  padding: EdgeInsets.all(AppDimensions.xs),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "$count",
                    style: CommonWidget.CommonTitleTextStyle(
                      color: GlobalAppColor.DarkBlueColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content without Expanded
          Padding(
            padding: EdgeInsets.only(bottom: AppDimensions.xs),
            child: child,
          ),
        ],
      ),
    );
  }

  //-✅--KitchenOrderWidget-----------------------------------------------✅-//
  Widget KitchenOrderListWidget() {
    return Consumer<KdsProvider>(
      builder: (context, KdsCtrl, child) {
        // ✅ Capture screen-level context for async operations.
        // The ListView.builder itemBuilder gets its own context that can be
        // deactivated when an item is removed — using screenCtx (Consumer level)
        // ensures InitializeData + toasts always have a valid mounted context.
        final screenCtx = context;

        // ✅ Only those orders jinke andar preparing/ordered items hon
        final filteredOrders = KdsCtrl.KitchenOrderListing.where((order) {
          final details = order.details ?? [];
          return details.any(
            (d) => d.status == "preparing" || d.status == "ordered",
          );
        }).toList();

        // ✅ Show "No Data" if filtered list empty
        if (filteredOrders.isEmpty) {
          return CommonWidget().NoDatWidget(
            context,
            "No active orders for this station",
            Symbols.check_circle,
          );
        }
        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          // ✅ Ab ye change
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final KitchenOrderData = filteredOrders[index];

            // ✅ Filter order details again for UI
            final filteredDetails = (KitchenOrderData.details ?? [])
                .where((d) => d.status == "preparing" || d.status == "ordered")
                .toList();

            // ✅ If no details inside, skip this order
            // ✅ Aur yahi par ye line EXACT rahegi
            if (filteredDetails.isEmpty) {
              return const SizedBox.shrink();
            }
            return AnimationLimiter(
              child: CommonWidget().buildStaggeredAnimation(
                index: index,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                    vertical: AppDimensions.md,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: GlobalAppColor.WhiteColorCode,
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      border: Border.all(
                        // ✅ Priority-based border (urgent=red, high=orange, normal=blue)
                        color: _priorityCardBorder(
                          KitchenOrderData.priority?.toString() ?? 'normal',
                        ),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: 0.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: 10),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                // LEFT SIDE
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Flexible(
                                        child: Text(
                                          "#${KitchenOrderData.orderNo ?? KitchenOrderData.orderId}",
                                          style:
                                              CommonWidget.CommonTitleTextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            // ✅ Priority-based badge (urgent=red, high=orange, normal=green)
                                            color: _priorityBadgeBg(
                                              KitchenOrderData.priority
                                                      ?.toString() ??
                                                  'normal',
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Icon(
                                                Symbols.check_circle_rounded,
                                                color: _priorityBadgeText(
                                                  KitchenOrderData.priority
                                                          ?.toString() ??
                                                      'normal',
                                                ),
                                                size: 16,
                                              ),
                                              SizedBox(width: 3),
                                              Flexible(
                                                child: Text(
                                                  GlobalFunction()
                                                      .capitalizeFirst(
                                                        KitchenOrderData
                                                            .priority
                                                            .toString(),
                                                      ),
                                                  style: CommonWidget.CommonTitleTextStyle(
                                                    color: _priorityBadgeText(
                                                      KitchenOrderData.priority
                                                              ?.toString() ??
                                                          'normal',
                                                    ),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // ✅ CURRENT chip removed — redundant in Kitchen Orders panel
                                    ],
                                  ),
                                ),

                                SizedBox(width: 5),

                                // RIGHT SIDE
                                Flexible(
                                  child: InkWell(
                                    overlayColor: MaterialStateProperty.all(
                                      Colors.transparent,
                                    ),
                                    onTap: KdsCtrl.isOrderLoader
                                        ? null
                                        : () async {
                                            // ✅ Use screenCtx (Consumer-level) not item context.
                                            // Item context is deactivated when the card is removed
                                            // from the list after marking all items prepared.
                                            final ctx = screenCtx;

                                            // ✅ Filter only items still preparing/ordered
                                            final itemsToPrepare =
                                                filteredDetails
                                                    .where(
                                                      (d) =>
                                                          d.status ==
                                                              "preparing" ||
                                                          d.status == "ordered",
                                                    )
                                                    .toList();

                                            if (itemsToPrepare.isEmpty) {
                                              if (ctx.mounted) {
                                                showCustomToast(
                                                  context: ctx,
                                                  message:
                                                      "⚠️ No items to prepare",
                                                );
                                              }
                                              return;
                                            }

                                            int successCount = 0;
                                            int failCount = 0;

                                            // ✅ Sequentially process all items
                                            for (final detail
                                                in itemsToPrepare) {
                                              if (!ctx.mounted) break;
                                              final bool result =
                                                  await KdsCtrl.OrderPreparedService(
                                                    ctx,
                                                    "prepared",
                                                    detail.orderId.toString(),
                                                    detail.orderDetId
                                                        .toString(),
                                                  );

                                              if (!result) {
                                                failCount++;
                                                continue; // ❌ API failed → skip
                                              }

                                              // ✅ API Success → remove item from UI & timers
                                              KdsCtrl.markDetailOrderItemAsServed(
                                                detail.orderId!,
                                                detail.orderDetId!,
                                              );

                                              // ✅ Remove timers explicitly
                                              KdsCtrl.detailTimers.remove(
                                                detail.orderDetId,
                                              );
                                              KdsCtrl.autoExtended.remove(
                                                detail.orderDetId,
                                              );
                                              KdsCtrl.detailEndTimes.remove(
                                                detail.orderDetId,
                                              );

                                              successCount++;
                                            }

                                            // ✅ Save timer state & update UI once
                                            KdsCtrl.saveTimerState();
                                            KdsCtrl.notifyListeners();

                                            // ✅ Refresh BOTH active + ready lists
                                            if (successCount > 0 &&
                                                ctx.mounted) {
                                              await KdsCtrl.GetKitchenOrderListService(
                                                ctx,
                                                KdsCtrl.selectedKDSDate,
                                                silent: true,
                                              );
                                              await KdsCtrl.GetReadyOrderListService(
                                                ctx,
                                                KdsCtrl.selectedKDSDate,
                                                silent: true,
                                              );
                                            }

                                            // ✅ Show proper toast for batch result
                                            if (!ctx.mounted) return;
                                            if (successCount > 0 &&
                                                failCount == 0) {
                                              showCustomToast(
                                                context: ctx,
                                                message:
                                                    "✅ All items prepared successfully",
                                              );
                                            } else if (successCount > 0 &&
                                                failCount > 0) {
                                              showCustomToast(
                                                context: ctx,
                                                message:
                                                    "⚠️ Some items prepared, some failed",
                                              );
                                            } else {
                                              showCustomToast(
                                                context: ctx,
                                                message:
                                                    "❌ No items could be prepared",
                                              );
                                            }
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: GlobalAppColor.AvailableCode,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            Symbols.check_box_sharp,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              "Select All Prepared",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    color: Colors.white,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        GlobalFunction().capitalizeFirst(
                                          KitchenOrderData.type.toString(),
                                        ),
                                        style:
                                            CommonWidget.CommonTitleTextStyle(),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        KitchenOrderData.tableName != null &&
                                                KitchenOrderData
                                                    .tableName!
                                                    .isNotEmpty
                                            ? KitchenOrderData.tableName!
                                            : (KitchenOrderData.tableId !=
                                                          null &&
                                                      KitchenOrderData
                                                          .tableId!
                                                          .isNotEmpty &&
                                                      KitchenOrderData
                                                              .tableId !=
                                                          'N/A'
                                                  ? 'Table ${KitchenOrderData.tableId}'
                                                  : 'Table —'),
                                        style:
                                            CommonWidget.CommonTitleTextStyle(
                                              fontSize: 15,
                                            ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        DateFormat('hh:mm a').format(
                                          DateTime.parse(
                                            KitchenOrderData.orderDate!,
                                          ).toLocal(), // ✅ local timezone (was .toUtc())
                                        ),
                                        style:
                                            CommonWidget.CommonTitleTextStyle(),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        "\u2022 ${(KitchenOrderData.customerName ?? '').isNotEmpty && KitchenOrderData.customerName != 'N/A' ? KitchenOrderData.customerName! : 'Guest'}",
                                        style:
                                            CommonWidget.CommonTitleTextStyle(
                                              fontSize: 15,
                                            ),
                                      ),
                                      SizedBox(width: 6),
                                      // ✅ Live elapsed time chip — rebuilds every 1s via KdsProvider
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          KdsCtrl.getElapsedTime(
                                            KitchenOrderData.orderDate,
                                          ),
                                          style:
                                              CommonWidget.CommonTitleTextStyle(
                                                fontSize: 11,
                                                height: 1.2,
                                                color: const Color(0xFF6B7280),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(width: 10),
                              // ✅ Dynamic color timer — green → orange → red
                              Consumer<KdsProvider>(
                                builder: (context, kdsCtrl, child) {
                                  final maxTime = kdsCtrl.getMaxTimerOfOrder(
                                    KitchenOrderData,
                                  );
                                  // Compute total expected seconds for this order
                                  int totalSecs = 0;
                                  for (final d
                                      in KitchenOrderData.details ?? []) {
                                    if (d.status != "prepared") {
                                      final t =
                                          (d.product?.dishPrepTime ?? 0) *
                                          (d.qty ?? 1) *
                                          60;
                                      if (t > totalSecs) totalSecs = t;
                                    }
                                  }
                                  final timerColor = kdsCtrl.getTimerColor(
                                    maxTime,
                                    totalSecs == 0 ? maxTime.abs() : totalSecs,
                                  );
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: timerColor.withOpacity(.1),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            "Max Time",
                                            style:
                                                CommonWidget.CommonTitleTextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.2,
                                                  color: timerColor.withOpacity(
                                                    .8,
                                                  ),
                                                ),
                                          ),
                                          Text(
                                            kdsCtrl.formatTime(maxTime),
                                            style:
                                                CommonWidget.CommonTitleTextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.2,
                                                  color: timerColor,
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

                          SizedBox(height: 10),
                          // ---------- Order Details ----------
                          Column(
                            children: filteredDetails.map<Widget>((detail) {
                              final product = detail.product!;
                              final totalPrep =
                                  (product.dishPrepTime ?? 0) *
                                  (detail.qty ?? 0);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Dismissible(
                                  key: ValueKey(detail.orderDetId),
                                  direction: DismissDirection.startToEnd,

                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Icon(
                                      Symbols.access_time,
                                      color: Colors.white,
                                    ),
                                  ),

                                  // 🔥 Yahi swipe ko control karega
                                  confirmDismiss: KdsCtrl.isOrderLoader
                                      ? null
                                      : (_) async {
                                          // ✅ CRITICAL: use Consumer-level screenCtx — the
                                          // itemBuilder's own `context` is deactivated as soon as
                                          // the card is removed, making ctx.mounted == false and
                                          // silently skipping the refresh.
                                          final ctx = screenCtx;

                                          // 🔹 Step 1: Call API to mark item prepared
                                          final bool apiResult =
                                              await KdsCtrl.OrderPreparedService(
                                                ctx,
                                                "prepared",
                                                detail.orderId.toString(),
                                                detail.orderDetId.toString(),
                                              );

                                          // ❌ API fail → cancel swipe
                                          if (!apiResult) return false;

                                          // 🔹 Step 2: Remove item from UI and timers
                                          KdsCtrl.markDetailOrderItemAsServed(
                                            KitchenOrderData.orderId!,
                                            detail.orderDetId!,
                                          );
                                          KdsCtrl.detailTimers.remove(
                                            detail.orderDetId,
                                          );
                                          KdsCtrl.autoExtended.remove(
                                            detail.orderDetId,
                                          );
                                          KdsCtrl.detailEndTimes.remove(
                                            detail.orderDetId,
                                          );

                                          // 🔹 Step 3: Rebuild List instantly
                                          KdsCtrl.saveTimerState();
                                          KdsCtrl.notifyListeners();

                                          // 🔹 Step 4: Refresh BOTH active + ready from server
                                          if (ctx.mounted) {
                                            await KdsCtrl.GetKitchenOrderListService(
                                              ctx,
                                              KdsCtrl.selectedKDSDate,
                                              silent: true,
                                            );
                                          }
                                          if (ctx.mounted) {
                                            await KdsCtrl.GetReadyOrderListService(
                                              ctx,
                                              KdsCtrl.selectedKDSDate,
                                              silent: true,
                                            );
                                          }

                                          // 🔹 Step 5: Show success snackbar
                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(
                                              ctx,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "✅ ${product.mPName} Prepared",
                                                ),
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                              ),
                                            );
                                          }

                                          // ✅ Swipe successful
                                          return true;
                                        },

                                  child: Container(
                                    decoration: BoxDecoration(
                                      // ✅ Status-based background (web: preparing=blue-50, ordered=gray-50)
                                      color: detail.status == 'preparing'
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: detail.status == 'preparing'
                                            ? const Color(
                                                0xFF3B82F6,
                                              ).withOpacity(.25)
                                            : const Color(0xFFD1D5DB),
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                        vertical: 10.0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // ── Status dot (color mirrors item status) ──
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                              right: 8,
                                            ),
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    detail.status == 'preparing'
                                                    ? GlobalAppColor
                                                          .DarkBlueColor
                                                    : const Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ),

                                          // ── Name + prep info + note ──
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Product name — bold, prominent
                                                Text(
                                                  "${detail.qty}× ${product.mPName}",
                                                  style:
                                                      CommonWidget.CommonTitleTextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                        color: const Color(
                                                          0xFF111827,
                                                        ),
                                                        height: 1.25,
                                                      ),
                                                ),
                                                const SizedBox(height: 3),
                                                // Prep time formula — secondary / dimmer
                                                Text(
                                                  "${detail.qty}× ${product.dishPrepTime} min = $totalPrep min",
                                                  style:
                                                      CommonWidget.CommonTitleTextStyle(
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: 12,
                                                        color: const Color(
                                                          0xFF6B7280,
                                                        ),
                                                        height: 1.2,
                                                      ),
                                                ),
                                                // Note — highlighted in red if present
                                                if (detail.note != null &&
                                                    detail.note!
                                                        .trim()
                                                        .isNotEmpty &&
                                                    detail.note!
                                                            .trim()
                                                            .toUpperCase() !=
                                                        "N/A")
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.notes,
                                                          size: 11,
                                                          color: Color(
                                                            0xFFDC2626,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 3,
                                                        ),
                                                        Flexible(
                                                          child: Text(
                                                            detail.note!.trim(),
                                                            style: CommonWidget.CommonTitleTextStyle(
                                                              fontSize: 11,
                                                              color:
                                                                  const Color(
                                                                    0xFFDC2626,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              height: 1.2,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(width: 8),

                                          // ── 🆕 START BUTTON (ordered items only) ──
                                          if (detail.status == 'ordered')
                                            GestureDetector(
                                              onTap: KdsCtrl.isOrderLoader
                                                  ? null
                                                  : () async {
                                                      final ctx = screenCtx;
                                                      if (!ctx.mounted) return;

                                                      // ✅ Call start service
                                                      final bool success =
                                                          await KdsCtrl.startItemPreparation(
                                                            ctx,
                                                            KitchenOrderData
                                                                .orderId
                                                                .toString(),
                                                            detail.orderDetId
                                                                .toString(),
                                                          );

                                                      if (!success) return;

                                                      // ✅ Refresh both lists
                                                      if (ctx.mounted) {
                                                        await KdsCtrl.GetKitchenOrderListService(
                                                          ctx,
                                                          KdsCtrl
                                                              .selectedKDSDate,
                                                          silent: true,
                                                        );
                                                      }

                                                      // ✅ Show feedback
                                                      if (ctx.mounted) {
                                                        showCustomToast(
                                                          context: ctx,
                                                          message:
                                                              "▶️ ${product.mPName} started",
                                                        );
                                                      }
                                                    },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: GlobalAppColor.WhiteColorCode,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF16A34A,
                                                    ),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: KdsCtrl.isOrderLoader
                                                    ? const SizedBox(
                                                        width: 14,
                                                        height: 14,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: Color(
                                                                0xFF16A34A,
                                                              ),
                                                            ),
                                                      )
                                                    : Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons.play_arrow,
                                                            color: Color(
                                                              0xFF16A34A,
                                                            ),
                                                            size: 16,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            "Start",
                                                            style: CommonWidget.CommonTitleTextStyle(
                                                              color:
                                                                  const Color(
                                                                    0xFF16A34A,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),

                                          // Spacing after Start button or before timer
                                          if (detail.status == 'ordered')
                                            const SizedBox(width: 6),

                                          // ── Dynamic colour timer ──
                                          Builder(
                                            builder: (ctx) {
                                              final secs =
                                                  KdsCtrl.getDisplaySecondsForDetail(
                                                    KitchenOrderData,
                                                    detail,
                                                  );
                                              final totalSecs =
                                                  (detail
                                                          .product
                                                          ?.dishPrepTime ??
                                                      0) *
                                                  (detail.qty ?? 1) *
                                                  60;
                                              final tColor =
                                                  KdsCtrl.getTimerColor(
                                                    secs,
                                                    totalSecs,
                                                  );
                                              // ✅ Responsive padding — tighter on small phones
                                              final double sw = MediaQuery.of(
                                                ctx,
                                              ).size.width;
                                              final double hPad = sw < 380
                                                  ? 6.0
                                                  : 10.0;
                                              return Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: hPad,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: tColor.withOpacity(
                                                    .12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: tColor.withOpacity(
                                                      .35,
                                                    ),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  KdsCtrl.formatTime(secs),
                                                  style:
                                                      CommonWidget.CommonTitleTextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 1.2,
                                                        color: tColor,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),

                                          // ── 🆕 UNDO and DONE BUTTONS (preparing items only) ──
                                          if (detail.status == 'preparing') ...[
                                            const SizedBox(width: 6),
                                            // ── UNDO BUTTON ──
                                            GestureDetector(
                                              onTap:
                                                  KdsCtrl.isItemUndoing(
                                                    detail.orderDetId ?? -1,
                                                  )
                                                  ? null
                                                  : () async {
                                                      final ctx = screenCtx;
                                                      if (!ctx.mounted) return;

                                                      // ✅ Call undo to ordered service
                                                      final bool result =
                                                          await KdsCtrl.undoItemToOrderedService(
                                                            ctx,
                                                            KitchenOrderData
                                                                .orderId
                                                                .toString(),
                                                            detail.orderDetId
                                                                .toString(),
                                                          );

                                                      if (!result) {
                                                        if (ctx.mounted) {
                                                          showCustomToast(
                                                            context: ctx,
                                                            message:
                                                                "❌ Undo failed",
                                                          );
                                                        }
                                                        return;
                                                      }

                                                      // ✅ Refresh kitchen list
                                                      if (ctx.mounted) {
                                                        await KdsCtrl.GetKitchenOrderListService(
                                                          ctx,
                                                          KdsCtrl
                                                              .selectedKDSDate,
                                                          silent: true,
                                                        );
                                                      }

                                                      // ✅ Show feedback
                                                      if (ctx.mounted) {
                                                        showCustomToast(
                                                          context: ctx,
                                                          message:
                                                              "↩️ Moved back to ordered",
                                                        );
                                                      }
                                                    },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      KdsCtrl.isItemUndoing(
                                                        detail.orderDetId ?? -1,
                                                      )
                                                      ? const Color(
                                                          0xFFCA8A04,
                                                        ).withOpacity(.6)
                                                      : const Color(0xFFCA8A04),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child:
                                                    KdsCtrl.isItemUndoing(
                                                      detail.orderDetId ?? -1,
                                                    )
                                                    ? const SizedBox(
                                                        width: 14,
                                                        height: 14,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                    : Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons.undo,
                                                            color: Colors.white,
                                                            size: 14,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            "Undo",
                                                            style:
                                                                CommonWidget.CommonTitleTextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontSize: 13,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // ── DONE BUTTON ──
                                            GestureDetector(
                                              onTap: KdsCtrl.isOrderLoader
                                                  ? null
                                                  : () async {
                                                      final ctx = screenCtx;
                                                      if (!ctx.mounted) return;

                                                      // ✅ Call prepared service
                                                      final bool result =
                                                          await KdsCtrl.OrderPreparedService(
                                                            ctx,
                                                            "prepared",
                                                            KitchenOrderData
                                                                .orderId
                                                                .toString(),
                                                            detail.orderDetId
                                                                .toString(),
                                                          );

                                                      if (!result) return;

                                                      // ✅ Mark as served locally
                                                      KdsCtrl.markDetailOrderItemAsServed(
                                                        KitchenOrderData
                                                            .orderId!,
                                                        detail.orderDetId!,
                                                      );

                                                      // ✅ Remove timers
                                                      KdsCtrl.detailTimers
                                                          .remove(
                                                            detail.orderDetId,
                                                          );
                                                      KdsCtrl.autoExtended
                                                          .remove(
                                                            detail.orderDetId,
                                                          );
                                                      KdsCtrl.detailEndTimes
                                                          .remove(
                                                            detail.orderDetId,
                                                          );

                                                      KdsCtrl.saveTimerState();
                                                      KdsCtrl.notifyListeners();

                                                      // ✅ Refresh both lists
                                                      if (ctx.mounted) {
                                                        await KdsCtrl.GetKitchenOrderListService(
                                                          ctx,
                                                          KdsCtrl
                                                              .selectedKDSDate,
                                                          silent: true,
                                                        );
                                                        await KdsCtrl.GetReadyOrderListService(
                                                          ctx,
                                                          KdsCtrl
                                                              .selectedKDSDate,
                                                          silent: true,
                                                        );
                                                      }

                                                      // ✅ Show feedback
                                                      if (ctx.mounted) {
                                                        showCustomToast(
                                                          context: ctx,
                                                          message:
                                                              "✅ ${product.mPName} prepared",
                                                        );
                                                      }
                                                    },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF16A34A,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: KdsCtrl.isOrderLoader
                                                    ? const SizedBox(
                                                        width: 14,
                                                        height: 14,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                    : Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons.check,
                                                            color: Colors.white,
                                                            size: 16,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            "Done",
                                                            style:
                                                                CommonWidget.CommonTitleTextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 13,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (KitchenOrderData.order_des != null &&
                              KitchenOrderData.order_des != "N/A" &&
                              KitchenOrderData.order_des!
                                  .trim()
                                  .isNotEmpty) ...[
                            Text(
                              "Description:",
                              style: CommonWidget.CommonTitleTextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              KitchenOrderData.order_des!.trim(),
                              style: CommonWidget.CommonTitleTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  //-✅--RightListWidget--------------------------------------------------✅-//
  Widget ReadyToServeListWidget() {
    return Consumer<KdsProvider>(
      builder: (context, KdsCtrl, child) {
        // ✅ Capture Consumer-level context. The ListView.builder itemBuilder
        // context is deactivated when its card is removed, causing
        // InitializeData / showCustomToast to crash or silently abort.
        final screenCtx = context;

        // ✅ FIXED: Use dedicated list from /kitchen/ready endpoint
        final filteredOrders = KdsCtrl.ReadyToServeOrderListing;

        // ✅ Show "No Data" if filtered list empty
        if (filteredOrders.isEmpty) {
          return CommonWidget().NoDatWidget(
            context,
            "No ready orders for this station",
            Symbols.access_time,
          );
        }
        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          // ✅ Ab ye change
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final KitchenOrderData = filteredOrders[index];

            // ✅ Filter order details again for UI
            final filteredDetails = (KitchenOrderData.details ?? [])
                .where((d) => d.status == "prepared")
                .toList();

            // ✅ If no details inside, skip this order
            // ✅ Aur yahi par ye line EXACT rahegi
            if (filteredDetails.isEmpty) {
              return const SizedBox.shrink();
            }
            return AnimationLimiter(
              child: CommonWidget().buildStaggeredAnimation(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 12.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: GlobalAppColor.WhiteColorCode,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF16A34A).withOpacity(.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withOpacity(.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 0.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: 12),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                // LEFT SIDE
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Flexible(
                                        child: Text(
                                          "#${KitchenOrderData.orderNo ?? KitchenOrderData.orderId}",
                                          style:
                                              CommonWidget.CommonTitleTextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF16A34A,
                                            ).withOpacity(.15),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Icon(
                                                Symbols.check_circle_rounded,
                                                color: const Color(0xFF16A34A),
                                                size: 14,
                                              ),
                                              SizedBox(width: 3),
                                              Flexible(
                                                child: Text(
                                                  "Prepared",
                                                  style:
                                                      CommonWidget.CommonTitleTextStyle(
                                                        color: const Color(
                                                          0xFF16A34A,
                                                        ),
                                                        fontSize: 11,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            // ✅ Priority-based badge (ready panel)
                                            color: _priorityBadgeBg(
                                              KitchenOrderData.priority
                                                      ?.toString() ??
                                                  'normal',
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Icon(
                                                Symbols.check_circle_rounded,
                                                color: _priorityBadgeText(
                                                  KitchenOrderData.priority
                                                          ?.toString() ??
                                                      'normal',
                                                ),
                                                size: 14,
                                              ),
                                              SizedBox(width: 3),
                                              Flexible(
                                                child: Text(
                                                  GlobalFunction()
                                                      .capitalizeFirst(
                                                        KitchenOrderData
                                                            .priority
                                                            .toString(),
                                                      ),
                                                  style: CommonWidget.CommonTitleTextStyle(
                                                    color: _priorityBadgeText(
                                                      KitchenOrderData.priority
                                                              ?.toString() ??
                                                          'normal',
                                                    ),
                                                    fontSize: 11,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(width: 5),

                                // RIGHT SIDE
                                Flexible(
                                  child: InkWell(
                                    overlayColor: MaterialStateProperty.all(
                                      Colors.transparent,
                                    ),
                                    onTap: KdsCtrl.isOrderLoader
                                        ? null
                                        : () async {
                                            // ✅ Use screenCtx (Consumer-level) not itemBuilder context.
                                            // Item context is deactivated when its card disappears.
                                            final ctx = screenCtx;

                                            final itemsToServe = filteredDetails
                                                .where(
                                                  (d) => d.status == "prepared",
                                                )
                                                .toList();

                                            int successCount = 0;
                                            int failCount = 0;

                                            for (final detail in itemsToServe) {
                                              if (!ctx.mounted) break;
                                              final bool result =
                                                  await KdsCtrl.OrderServedService(
                                                    ctx,
                                                    "served",
                                                    detail.orderId.toString(),
                                                    detail.orderDetId
                                                        .toString(),
                                                  );

                                              if (!result) {
                                                failCount++;
                                                continue;
                                              }

                                              KdsCtrl.markDetailOrderItemAsServed(
                                                detail.orderId!,
                                                detail.orderDetId!,
                                              );

                                              KdsCtrl.detailTimers.remove(
                                                detail.orderDetId,
                                              );
                                              KdsCtrl.autoExtended.remove(
                                                detail.orderDetId,
                                              );
                                              KdsCtrl.detailEndTimes.remove(
                                                detail.orderDetId,
                                              );

                                              successCount++;
                                            }

                                            KdsCtrl.saveTimerState();
                                            KdsCtrl.notifyListeners();

                                            // ✅ Refresh BOTH ready + active lists
                                            if (successCount > 0 &&
                                                ctx.mounted) {
                                              await KdsCtrl.GetReadyOrderListService(
                                                ctx,
                                                KdsCtrl.selectedKDSDate,
                                                silent: true,
                                              );
                                              await KdsCtrl.GetKitchenOrderListService(
                                                ctx,
                                                KdsCtrl.selectedKDSDate,
                                                silent: true,
                                              );
                                            }

                                            if (!ctx.mounted) return;
                                            if (successCount > 0 &&
                                                failCount == 0) {
                                              showCustomToast(
                                                context: ctx,
                                                message:
                                                    "✅ All items served successfully",
                                              );
                                            } else if (successCount > 0 &&
                                                failCount > 0) {
                                              showCustomToast(
                                                context: ctx,
                                                message:
                                                    "⚠️ Some items served, some failed",
                                              );
                                            } else {
                                              showCustomToast(
                                                context: ctx,
                                                message:
                                                    "❌ No items could be served",
                                              );
                                            }
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            Symbols.check_box_sharp,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 5),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Select All Served",
                                                  style:
                                                      CommonWidget.CommonTitleTextStyle(
                                                        color: Colors.white,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                GlobalFunction().capitalizeFirst(
                                  KitchenOrderData.type.toString(),
                                ),
                                style: CommonWidget.CommonTitleTextStyle(),
                              ),
                              SizedBox(width: 5),
                              Text(
                                KitchenOrderData.tableName != null &&
                                        KitchenOrderData.tableName!.isNotEmpty
                                    ? KitchenOrderData.tableName!
                                    : (KitchenOrderData.tableId != null &&
                                              KitchenOrderData
                                                  .tableId!
                                                  .isNotEmpty &&
                                              KitchenOrderData.tableId != 'N/A'
                                          ? 'Table ${KitchenOrderData.tableId}'
                                          : 'Table —'),
                                style: CommonWidget.CommonTitleTextStyle(
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                DateFormat('hh:mm a').format(
                                  DateTime.parse(
                                    KitchenOrderData.orderDate!,
                                  ).toLocal(), // ✅ local timezone (was .toUtc())
                                ),
                                style: CommonWidget.CommonTitleTextStyle(),
                              ),
                              SizedBox(width: 5),
                              Text(
                                "\u2022 ${(KitchenOrderData.customerName ?? '').isNotEmpty && KitchenOrderData.customerName != 'N/A' ? KitchenOrderData.customerName! : 'Guest'}",
                                style: CommonWidget.CommonTitleTextStyle(
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(width: 6),
                              // ✅ Live elapsed time — green tint (ready orders)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF16A34A,
                                  ).withOpacity(.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  KdsCtrl.getElapsedTime(
                                    KitchenOrderData.orderDate,
                                  ),
                                  style: CommonWidget.CommonTitleTextStyle(
                                    fontSize: 11,
                                    height: 1.2,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          // ---------- Order Details ----------
                          Column(
                            children: filteredDetails.map<Widget>((detail) {
                              final product = detail.product!;
                              final totalPrep =
                                  (product.dishPrepTime ?? 0) *
                                  (detail.qty ?? 0);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Dismissible(
                                  key: ValueKey(detail.orderDetId),
                                  direction: DismissDirection.startToEnd,
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Icon(
                                      Symbols.access_time,
                                      color: Colors.white,
                                    ),
                                  ),

                                  confirmDismiss: KdsCtrl.isOrderLoader
                                      ? null
                                      : (_) async {
                                          final ctx = screenCtx;

                                          final bool result =
                                              await KdsCtrl.OrderServedService(
                                                ctx,
                                                "served",
                                                detail.orderId.toString(),
                                                detail.orderDetId.toString(),
                                              );

                                          if (!result) {
                                            return false;
                                          }

                                          KdsCtrl.markDetailOrderItemAsServed(
                                            KitchenOrderData.orderId!,
                                            detail.orderDetId!,
                                          );

                                          KdsCtrl.detailTimers.remove(
                                            detail.orderDetId,
                                          );
                                          KdsCtrl.autoExtended.remove(
                                            detail.orderDetId,
                                          );
                                          KdsCtrl.detailEndTimes.remove(
                                            detail.orderDetId,
                                          );

                                          KdsCtrl.saveTimerState();
                                          KdsCtrl.notifyListeners();

                                          if (ctx.mounted) {
                                            await KdsCtrl.GetReadyOrderListService(
                                              ctx,
                                              KdsCtrl.selectedKDSDate,
                                              silent: true,
                                            );
                                          }

                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(
                                              ctx,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "${product.mPName} served",
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }

                                          return true;
                                        },

                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF16A34A,
                                        ).withOpacity(.3),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 10.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          // Left side: Product + Qty
                                          Expanded(
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                ),
                                                SizedBox(width: 5),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        product.mPName
                                                            .toString(),
                                                        style: CommonWidget.CommonTitleTextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: const Color(
                                                            0xFF374151,
                                                          ),
                                                          height: 1.2,
                                                          decoration:
                                                              TextDecoration
                                                                  .lineThrough,
                                                        ),
                                                      ),
                                                      // ✅ Special note (mirrors web special_instructions)
                                                      if (detail.note != null &&
                                                          detail.note!
                                                              .trim()
                                                              .isNotEmpty &&
                                                          detail.note!
                                                                  .trim()
                                                                  .toUpperCase() !=
                                                              "N/A")
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 2,
                                                              ),
                                                          child: Row(
                                                            children: [
                                                              const Icon(
                                                                Icons.notes,
                                                                size: 11,
                                                                color: Color(
                                                                  0xFFDC2626,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 3,
                                                              ),
                                                              Flexible(
                                                                child: Text(
                                                                  detail.note!
                                                                      .trim(),
                                                                  style: CommonWidget.CommonTitleTextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: const Color(
                                                                      0xFFDC2626,
                                                                    ),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    height: 1.2,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFF3F4F6,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          5,
                                                        ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      "x${detail.qty}",
                                                      style:
                                                          CommonWidget.CommonTitleTextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          SizedBox(width: 6),

                                          // Right side: Undo & Served buttons
                                          Flexible(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: <Widget>[
                                                // —— Undo button ——
                                                GestureDetector(
                                                  // ✅ Disable only this item's undo while it's processing
                                                  onTap:
                                                      (KdsCtrl.isOrderLoader ||
                                                          KdsCtrl.isItemUndoing(
                                                            detail.orderDetId ??
                                                                -1,
                                                          ))
                                                      ? null
                                                      : () async {
                                                          final ctx = screenCtx;
                                                          if (!ctx.mounted) {
                                                            return;
                                                          }
                                                          final bool result =
                                                              await KdsCtrl.undoItemToPreparingService(
                                                                ctx,
                                                                detail.orderId
                                                                    .toString(),
                                                                detail
                                                                    .orderDetId
                                                                    .toString(),
                                                              );
                                                          if (!result) {
                                                            if (ctx.mounted) {
                                                              showCustomToast(
                                                                context: ctx,
                                                                message:
                                                                    "❌ Undo failed",
                                                              );
                                                            }
                                                            return;
                                                          }
                                                          if (ctx.mounted) {
                                                            await KdsCtrl.GetReadyOrderListService(
                                                              ctx,
                                                              KdsCtrl
                                                                  .selectedKDSDate,
                                                              silent: true,
                                                            );
                                                          }
                                                          if (ctx.mounted) {
                                                            await KdsCtrl.GetKitchenOrderListService(
                                                              ctx,
                                                              KdsCtrl
                                                                  .selectedKDSDate,
                                                              silent: true,
                                                            );
                                                          }
                                                          if (ctx.mounted) {
                                                            showCustomToast(
                                                              context: ctx,
                                                              message:
                                                                  "↩️ Moved back to preparing",
                                                            );
                                                          }
                                                        },
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          KdsCtrl.isItemUndoing(
                                                            detail.orderDetId ??
                                                                -1,
                                                          )
                                                          ? const Color(
                                                              0xFFCA8A04,
                                                            ).withOpacity(.6)
                                                          : const Color(
                                                              0xFFCA8A04,
                                                            ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child:
                                                          KdsCtrl.isItemUndoing(
                                                            detail.orderDetId ??
                                                                -1,
                                                          )
                                                          ? const SizedBox(
                                                              width: 14,
                                                              height: 14,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                            )
                                                          : Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                const Icon(
                                                                  Icons.undo,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 14,
                                                                ),
                                                                const SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Text(
                                                                  "Undo",
                                                                  style: CommonWidget.CommonTitleTextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 6),
                                                // ── Served button ──
                                                GestureDetector(
                                                  onTap: KdsCtrl.isOrderLoader
                                                      ? null
                                                      : () async {
                                                          final ctx = screenCtx;
                                                          if (!ctx.mounted) {
                                                            return;
                                                          }
                                                          final bool result =
                                                              await KdsCtrl.OrderServedService(
                                                                ctx,
                                                                "served",
                                                                detail.orderId
                                                                    .toString(),
                                                                detail
                                                                    .orderDetId
                                                                    .toString(),
                                                              );
                                                          if (!result) return;
                                                          KdsCtrl.markDetailOrderItemAsServed(
                                                            detail.orderId!,
                                                            detail.orderDetId!,
                                                          );
                                                          KdsCtrl.saveTimerState();
                                                          KdsCtrl.notifyListeners();
                                                          if (ctx.mounted) {
                                                            await KdsCtrl.GetReadyOrderListService(
                                                              ctx,
                                                              KdsCtrl
                                                                  .selectedKDSDate,
                                                              silent: true,
                                                            );
                                                          }
                                                          if (ctx.mounted) {
                                                            showCustomToast(
                                                              context: ctx,
                                                              message:
                                                                  "✅ ${product.mPName} served",
                                                            );
                                                          }
                                                        },
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF16A34A,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "Served",
                                                        style:
                                                            CommonWidget.CommonTitleTextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
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
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          // ✅ Order description (mirrors kitchen panel order_des block)
                          if (KitchenOrderData.order_des != null &&
                              KitchenOrderData.order_des != "N/A" &&
                              KitchenOrderData.order_des!
                                  .trim()
                                  .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Divider(
                              color: const Color(0xFF16A34A).withOpacity(.2),
                              height: 1,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Description:",
                              style: CommonWidget.CommonTitleTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              KitchenOrderData.order_des!.trim(),
                              style: CommonWidget.CommonTitleTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 1.2,
                                color: const Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  //-✅--OrderFilterWidget------------------------------------------------✅-//
  Widget OrderFilterWidget(BuildContext context) {
    return Consumer<KdsProvider>(
      builder: (context, KdsCtrl, child) {
        bool isSameDate(DateTime a, DateTime b) =>
            a.year == b.year && a.month == b.month && a.day == b.day;

        double controlHeight = 48; // Fixed height to avoid layout issues
        bool isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        double spacing = 5;

        // 🔹 Calendar + Today button widget
        Widget calendarWidget = Flexible(
          child: Container(
            padding: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: GlobalAppColor.BodyBgColorCode,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: GlobalAppColor.DarkTextColorCode.withOpacity(.1),
                width: 2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                    onTap: () async {
                      bool isConnected = await GlobalFunction()
                          .checkInternetConnection(context);
                      if (!isConnected) return;
                      await KdsCtrl.selectKDSDate(context);
                    },
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Symbols.calendar_today,
                          color: GlobalAppColor.LightTextColorCode,
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            "${KdsCtrl.selectedKDSDate.day}-${KdsCtrl.selectedKDSDate.month}-${KdsCtrl.selectedKDSDate.year}",
                            style: CommonWidget.CommonTitleTextStyle(
                              color: GlobalAppColor
                                  .DarkTextColorCode.withOpacity(.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  onTap: () async {
                    bool isConnected = await GlobalFunction()
                        .checkInternetConnection(context);
                    if (!isConnected) return;

                    // ⛔ Already today's date selected → no need to reload
                    if (KdsCtrl.selectedKDSDate.toString().substring(0, 10) ==
                        DateTime.now().toString().substring(0, 10)) {
                      return;
                    }

                    // ✅ Now update date once
                    KdsCtrl.selectedKDSDate = DateTime.now();
                    GlobalFunction.hideKeyboard(context);
                    KdsCtrl.SearchKDSController.clear();
                    await KdsCtrl.GetKitchenOrderListService(
                      context,
                      KdsCtrl.selectedKDSDate,
                    );
                    // ✅ Always refresh ready list too (Today button)
                    await KdsCtrl.GetReadyOrderListService(
                      context,
                      KdsCtrl.selectedKDSDate,
                      silent: false,
                    );
                    // API calls
                    if (KdsCtrl.selectedFilterOrderTab == 0) {
                      await KdsCtrl.GetFilterOrderListService(
                        context,
                        "active",
                        KdsCtrl.selectedKDSDate.toString(),
                      );
                    }
                    if (KdsCtrl.selectedFilterOrderTab == 1) {
                      // ✅ NEW: Ready tab
                      await KdsCtrl.GetFilterOrderListService(
                        context,
                        "ready",
                        KdsCtrl.selectedKDSDate.toString(),
                      );
                    }
                    if (KdsCtrl.selectedFilterOrderTab == 2) {
                      await KdsCtrl.GetFilterOrderListService(
                        context,
                        "completed",
                        KdsCtrl.selectedKDSDate.toString(),
                      );
                    }
                    if (KdsCtrl.selectedFilterOrderTab == 3) {
                      await KdsCtrl.GetFilterOrderListService(
                        context,
                        "cancelled",
                        KdsCtrl.selectedKDSDate.toString(),
                      );
                    }
                  },

                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSameDate(KdsCtrl.selectedKDSDate, DateTime.now())
                          ? GlobalAppColor.ButtonDarkColor
                          : GlobalAppColor.BodyBgColorCode,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                    child: Text(
                      "Today",
                      style: CommonWidget.CommonTitleTextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color:
                            isSameDate(KdsCtrl.selectedKDSDate, DateTime.now())
                            ? Colors.white
                            : GlobalAppColor.DarkTextColorCode.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // 🔹 Dropdown widget
        Widget dropdownWidget = Flexible(
          child: HomeWidget().buildDropdown(
            hintText: "Select Station",
            iconPadding: 0,
            decoration: BoxDecoration(
              color: GlobalAppColor.BodyBgColorCode,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: GlobalAppColor.DarkTextColorCode.withOpacity(.1),
                width: 2,
              ),
            ),
            showTextLeft: true,
            showIconRight: true,
            items: KdsCtrl.StationListing.map((e) => e.stationName).toList(),
            value: KdsCtrl.selectedStationType,
            onChanged: KdsCtrl.isOrderLoader
                ? null
                : (value) async {
                    KdsCtrl.updateStation(value);
                    // ✅ Re-fetch both active and ready orders for newly selected station
                    await KdsCtrl.GetKitchenOrderListService(
                      context,
                      KdsCtrl.selectedKDSDate,
                    );
                    await KdsCtrl.GetReadyOrderListService(
                      context,
                      KdsCtrl.selectedKDSDate,
                      silent: false,
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
        );

        // 🔹 Search TextField widget
        Widget searchWidget = Flexible(
          child: CommonWidget().CustomSearchTextField(
            enabled: !KdsCtrl.isKdsLoader,
            hintText: 'Search Station',
            controller: KdsCtrl.SearchKDSController,
            focusNode: KdsCtrl.myFocusNodeSearchKDS,
          ),
        );

        // 🔹 Refresh widget
        Widget refreshWidget = Flexible(
          child: InkWell(
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            onTap: KdsCtrl.isKdsLoader
                ? null // ✅ Disable tap while loading (prevents double refresh)
                : () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      KdsCtrl.InitializeData(context);
                      KdsCtrl.FilterOrderListing = [];
                      KdsCtrl.selectedFilterOrderTab = -1;
                    });
                  },
            child: Container(
              decoration: BoxDecoration(
                color: GlobalAppColor.BodyBgColorCode,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: GlobalAppColor.DarkTextColorCode.withOpacity(.1),
                  width: 2,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Refresh",
                      style: CommonWidget.CommonTitleTextStyle(
                        fontWeight: FontWeight.w500,
                        color: GlobalAppColor.DarkTextColorCode,
                      ),
                    ),
                    const SizedBox(width: 5),
                    // ✅ Spinner when loading (mirrors web RefreshCw animate-spin)
                    KdsCtrl.isKdsLoader
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey,
                            ),
                          )
                        : Icon(Icons.refresh, color: GlobalAppColor.DarkTextColorCode),
                  ],
                ),
              ),
            ),
          ),
        );

        // 🔹 Portrait: 2x2, Landscape: single row
        if (isLandscape) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                calendarWidget,
                SizedBox(width: spacing),
                dropdownWidget,
                SizedBox(width: spacing),
                searchWidget,
                SizedBox(width: spacing),
                refreshWidget,
              ],
            ),
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    calendarWidget,
                    SizedBox(width: spacing),
                    dropdownWidget,
                  ],
                ),
              ),
              SizedBox(height: spacing),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchWidget,
                    SizedBox(width: spacing),
                    refreshWidget,
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }

  //-✅--OrderSearchFilterListWidget--------------------------------------✅-//
  Widget OrderSearchFilterListWidget(BuildContext context) {
    return Consumer<KdsProvider>(
      builder: (context, KdsCtrl, child) {
        String title = GetOrderListTitle(KdsCtrl.selectedFilterOrderTab);

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: GlobalAppColor.WhiteColorCode,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GlobalAppColor.DarkTextColorCode.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CommonWidget.CommonTitleTextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 5),

              // ALWAYS HORIZONTAL SCROLL
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(
                      context,
                    ).size.width, // ⬅️ दोनों orientation me FULL WIDTH
                  ),
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,

                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: IntrinsicColumnWidth(),
                      2: IntrinsicColumnWidth(),
                      3: IntrinsicColumnWidth(),
                      4: IntrinsicColumnWidth(),
                      5: IntrinsicColumnWidth(),
                      6: IntrinsicColumnWidth(),
                      7: IntrinsicColumnWidth(),
                    },

                    border: TableBorder(
                      horizontalInside: BorderSide(color: Colors.grey.shade300),
                    ),

                    children: [
                      //---------------------------------------------------------------
                      // HEADER ROW  (Unchanged)
                      //---------------------------------------------------------------
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Color(0xfff7f9fc),
                        ),
                        children: [
                          TableHeader("Order"), // order_no / order_id
                          TableHeader("Type"),
                          TableHeader("Table"), // table_name / table_id
                          TableHeader("Customer"),
                          TableHeader("Time"),
                          TableHeader("Priority"),
                          TableHeader("Items"), // name + nameArb + modifiers
                          TableHeader("Status"),
                        ],
                      ),

                      //---------------------------------------------------------------
                      // DATA ROWS (Aligned fix)
                      //---------------------------------------------------------------
                      ...KdsCtrl.FilterOrderListing.reversed.map((order) {
                        return TableRow(
                          children: [
                            // ✅ Use orderNo when available, fallback to orderId
                            TableCell(
                              "#${order.orderNo ?? order.orderId}",
                              isBold: true,
                            ),
                            TableCell(order.type.toString()),
                            // ✅ Use tableName when available, fallback to tableId
                            TableCell(
                              order.tableName != null &&
                                      order.tableName!.isNotEmpty
                                  ? order.tableName!
                                  : order.tableId,
                            ),
                            TableCell(order.customerName.toString()),
                            TableCell(FormatTime(order.orderDate)),
                            // ⭐ PRIORITY COLUMN — Padding wrapper prevents left-edge clipping ⭐
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 60),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: getPriorityColor(
                                    order.priority,
                                  ).withOpacity(.2),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Center(
                                  child: Text(
                                    order.priority.toString().toUpperCase(),
                                    style: CommonWidget.CommonTitleTextStyle(
                                      color: getPriorityColor(order.priority),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // CANCELLED ITEMS COLUMN (Properly aligned)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 5,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: order.items.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ITEM NAME AND QTY
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // ✅ English name
                                                  Text(
                                                    item.name,
                                                    style:
                                                        CommonWidget.CommonTitleTextStyle(
                                                          height: 1.2,
                                                        ),
                                                  ),
                                                  // ✅ Arabic name (if present)
                                                  if (item.nameArb != null &&
                                                      item.nameArb!.isNotEmpty)
                                                    Text(
                                                      item.nameArb!,
                                                      style:
                                                          CommonWidget.CommonTitleTextStyle(
                                                            fontSize: 12,
                                                            height: 1.2,
                                                            color: const Color(
                                                              0xFF6B7280,
                                                            ),
                                                          ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              "x${item.quantity}",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    height: 1.2,
                                                  ),
                                            ),
                                          ],
                                        ),

                                        // ✅ MODIFIERS (indented addons)
                                        if (item.modifiers != null &&
                                            item.modifiers!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 3,
                                              left: 8,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: item.modifiers!
                                                  .map(
                                                    (mod) => Row(
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .subdirectory_arrow_right,
                                                          size: 14,
                                                          color: Color(
                                                            0xFF6B7280,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 3,
                                                        ),
                                                        Text(
                                                          "${mod.name} x${mod.quantity}",
                                                          style:
                                                              CommonWidget.CommonTitleTextStyle(
                                                                fontSize: 12,
                                                                height: 1.2,
                                                                color:
                                                                    const Color(
                                                                      0xFF6B7280,
                                                                    ),
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ),

                                        // ✅ SHOW NOTE ONLY IF NOT EMPTY
                                        if (item.note.trim().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              "Note: ${item.note}",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    color:
                                                        GlobalAppColor.RedCode,
                                                    fontSize: 12,
                                                    height: 1.2,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            // STATUS COLUMN + order_des below it
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 5,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Builder(
                                    builder: (_) {
                                      // ✅ Map status → semantic colour (matches web app statusColors)
                                      Color statusColor;
                                      switch (order.orderStatus.toLowerCase()) {
                                        case 'ordered':
                                          statusColor = const Color(0xFFCA8A04);
                                          break;
                                        case 'preparing':
                                          statusColor =
                                              GlobalAppColor.DarkBlueColor;
                                          break;
                                        case 'prepared':
                                          statusColor = const Color(0xFFDB2777);
                                          break;
                                        case 'served':
                                        case 'completed':
                                          statusColor =
                                              GlobalAppColor.AvailableCode;
                                          break;
                                        case 'cancelled':
                                          statusColor = GlobalAppColor.RedCode;
                                          break;
                                        default:
                                          statusColor = const Color(0xFF6B7280);
                                      }
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(.12),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                          border: Border.all(
                                            color: statusColor.withOpacity(.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            order.orderStatus
                                                .toString()
                                                .toUpperCase(),
                                            style:
                                                CommonWidget.CommonTitleTextStyle(
                                                  fontSize: 11,
                                                  color: statusColor,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // ✅ order_des (special instructions) below status
                                  if (order.orderDes != null &&
                                      order.orderDes!.trim().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        order.orderDes!.trim(),
                                        textAlign: TextAlign.center,
                                        style:
                                            CommonWidget.CommonTitleTextStyle(
                                              fontSize: 11,
                                              height: 1.2,
                                              color: const Color(0xFF6B7280),
                                              fontStyle: FontStyle.italic,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //-✅--TableHeader------------------------------------------------------✅-//
  Widget TableHeader(String text) {
    return Padding(
      // ✅ Slightly more horizontal padding so column boundaries never clip text
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: CommonWidget.CommonTitleTextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF374151),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  //-✅--TableCell--------------------------------------------------------✅-//
  Widget TableCell(String text, {bool isBold = false}) {
    return Padding(
      // ✅ Match TableHeader horizontal padding to prevent misalignment
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: CommonWidget.CommonTitleTextStyle(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          color: isBold ? const Color(0xFF111827) : const Color(0xFF374151),
          height: 1.3,
        ),
      ),
    );
  }

  //-✅--GetOrderListTitle------------------------------------------------✅-//
  String GetOrderListTitle(int tab) {
    switch (tab) {
      case 1:
        return "Ready Orders List";
      case 2:
        return "Completed Orders List";
      case 3:
        return "Cancelled Orders List";
      default:
        return "Active Orders List";
    }
  }

  //-✅--FormatTime------------------------------------------------------✅-//
  String FormatTime(dynamic date) {
    try {
      DateTime dt;

      if (date is DateTime) {
        dt = date.toLocal(); // ✅ always display in local timezone
      } else {
        dt = DateTime.parse(date.toString()).toLocal(); // ✅ ISO → local
      }

      // Format: 12:56 PM
      return "${dt.hour % 12 == 0 ? 12 : dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? "PM" : "AM"}";
    } catch (e) {
      return date.toString();
    }
  }

  //-✅--FormatTime------------------------------------------------------✅-//
  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case "normal": // id = 1
        return GlobalAppColor.AvailableCode; // Green

      case "high": // id = 2
        return Colors.orangeAccent; // Orange

      case "urgent": // id = 3
        return Colors.redAccent; // Red

      default:
        return Colors.grey; // safety fallback
    }
  }

  //-✅--CompletedOrdersModal---------------------------------------------✅-//
  Widget CompletedOrdersModal(BuildContext context) {
    return Consumer<KdsProvider>(
      builder: (context, KdsCtrl, child) {
        if (!KdsCtrl.showCompletedModal) return SizedBox.shrink();

        return Material(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GlobalAppColor.ButtonDarkColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Symbols.check_circle_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Completed Orders List",
                                style: CommonWidget.CommonTitleTextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${KdsCtrl.completedOrdersList.length} orders • ${KdsCtrl.completedOrdersList.fold<int>(0, (sum, order) => sum + (order.items.length))} items",
                                style: CommonWidget.CommonTitleTextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => KdsCtrl.toggleCompletedModal(false),
                          icon: Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: KdsCtrl.completedOrdersList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade100,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 32,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No completed orders found",
                                  style: CommonWidget.CommonTitleTextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Orders that have been completed will appear here",
                                  style: CommonWidget.CommonTitleTextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: KdsCtrl.completedOrdersList.length,
                            itemBuilder: (context, index) {
                              final order = KdsCtrl.completedOrdersList[index];
                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Order Header
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    "Order #${order.orderNo ?? order.orderId}",
                                                    style:
                                                        CommonWidget.CommonTitleTextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _priorityBadgeBg(
                                                        order.priority,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      order.priority
                                                          .toUpperCase(),
                                                      style: CommonWidget.CommonTitleTextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            _priorityBadgeText(
                                                              order.priority,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "${order.type.toString().toUpperCase()} • Table ${order.tableName ?? order.tableId} • ${FormatTime(order.orderDate)}",
                                                style:
                                                    CommonWidget.CommonTitleTextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                              ),
                                              if (order.customerName != null &&
                                                  order.customerName.isNotEmpty)
                                                Text(
                                                  "Customer: ${order.customerName}",
                                                  style:
                                                      CommonWidget.CommonTitleTextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey
                                                            .shade700,
                                                      ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "${order.items.length} items",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Text(
                                              "Completed",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade500,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    Divider(height: 24),

                                    // Items
                                    Text(
                                      "Menu Items:",
                                      style: CommonWidget.CommonTitleTextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ...order.items.map((item) {
                                      return Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    GlobalAppColor
                                                        .AvailableCode.withOpacity(
                                                      0.1,
                                                    ),
                                              ),
                                              child: Icon(
                                                Icons.check,
                                                size: 14,
                                                color: GlobalAppColor
                                                    .AvailableCode,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${item.quantity}x ${item.name}",
                                                    style:
                                                        CommonWidget.CommonTitleTextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                  if (item.note
                                                      .trim()
                                                      .isNotEmpty)
                                                    Text(
                                                      "Note: ${item.note}",
                                                      style:
                                                          CommonWidget.CommonTitleTextStyle(
                                                            fontSize: 11,
                                                            color: GlobalAppColor
                                                                .ButtonDarkColor,
                                                          ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              "Station ${item.stationId}",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),

                                    // Order Description
                                    if (order.orderDes != null &&
                                        order.orderDes!.trim().isNotEmpty) ...[
                                      Divider(height: 24),
                                      Text(
                                        "Order #${order.orderNo ?? order.orderId} Description:",
                                        style:
                                            CommonWidget.CommonTitleTextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        order.orderDes!,
                                        style:
                                            CommonWidget.CommonTitleTextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade700,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Footer
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Text(
                      "Showing ${KdsCtrl.completedOrdersList.length} completed orders",
                      style: CommonWidget.CommonTitleTextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
  }

  //-✅--CancelledOrdersModal---------------------------------------------✅-//
  Widget CancelledOrdersModal(BuildContext context) {
    return Consumer<KdsProvider>(
      builder: (context, KdsCtrl, child) {
        if (!KdsCtrl.showCancelledModal) return SizedBox.shrink();

        return Material(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GlobalAppColor.RedCode,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Symbols.cancel, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Cancelled Orders List",
                                style: CommonWidget.CommonTitleTextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${KdsCtrl.cancelledOrdersList.length} orders • ${KdsCtrl.cancelledOrdersList.fold<int>(0, (sum, order) => sum + (order.items.length))} items",
                                style: CommonWidget.CommonTitleTextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => KdsCtrl.toggleCancelledModal(false),
                          icon: Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: KdsCtrl.cancelledOrdersList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade100,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 32,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No cancelled orders found",
                                  style: CommonWidget.CommonTitleTextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Cancelled orders will appear here",
                                  style: CommonWidget.CommonTitleTextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: KdsCtrl.cancelledOrdersList.length,
                            itemBuilder: (context, index) {
                              final order = KdsCtrl.cancelledOrdersList[index];
                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Order Header
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    "Order #${order.orderNo ?? order.orderId}",
                                                    style:
                                                        CommonWidget.CommonTitleTextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _priorityBadgeBg(
                                                        order.priority,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      order.priority
                                                          .toUpperCase(),
                                                      style: CommonWidget.CommonTitleTextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            _priorityBadgeText(
                                                              order.priority,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "${order.type.toString().toUpperCase()} • Table ${order.tableName ?? order.tableId} • ${FormatTime(order.orderDate)}",
                                                style:
                                                    CommonWidget.CommonTitleTextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                              ),
                                              if (order.customerName != null &&
                                                  order.customerName.isNotEmpty)
                                                Text(
                                                  "Customer: ${order.customerName}",
                                                  style:
                                                      CommonWidget.CommonTitleTextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey
                                                            .shade700,
                                                      ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "${order.items.length} items",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Text(
                                              "Cancelled",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        GlobalAppColor.RedCode,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    Divider(height: 24),

                                    // Items
                                    Text(
                                      "Menu Items:",
                                      style: CommonWidget.CommonTitleTextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ...order.items.map((item) {
                                      return Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: GlobalAppColor
                                                    .RedCode.withOpacity(0.1),
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                size: 14,
                                                color: GlobalAppColor.RedCode,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${item.quantity}x ${item.name}",
                                                    style:
                                                        CommonWidget.CommonTitleTextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          decoration:
                                                              TextDecoration
                                                                  .lineThrough,
                                                        ),
                                                  ),
                                                  if (item.note
                                                      .trim()
                                                      .isNotEmpty)
                                                    Text(
                                                      "Note: ${item.note}",
                                                      style:
                                                          CommonWidget.CommonTitleTextStyle(
                                                            fontSize: 11,
                                                            color: GlobalAppColor
                                                                .ButtonDarkColor,
                                                          ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              "Station ${item.stationId} • Cancelled",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),

                                    // Order Description
                                    if (order.orderDes != null &&
                                        order.orderDes!.trim().isNotEmpty) ...[
                                      Divider(height: 24),
                                      Text(
                                        "Order Description:",
                                        style:
                                            CommonWidget.CommonTitleTextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        order.orderDes!,
                                        style:
                                            CommonWidget.CommonTitleTextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade700,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Footer
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Text(
                      "Showing ${KdsCtrl.cancelledOrdersList.length} cancelled orders",
                      style: CommonWidget.CommonTitleTextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
  }
}

//-✅---------------------------------------------------------------------✅-//
