// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:culai/ScreenSection/PostLogin/Settings/PrinterSettingsScreen.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

//-✅---------------------------------------------------------------------✅-//
class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _autoRefreshTimer;
  bool _isAutoRefreshActive = true;
  bool _isCardExpanded = true;

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || !_isAutoRefreshActive) return;
      final home = context.read<HomeProvider>();
      if (home.pendingRefresh) {
        home.setPendingRefresh(false);
        home.InitializeData(context, silent: true);
        return;
      }
      _checkDrawerStatus(silent: true);
      final formattedDate =
          "${home.selectedDate.year}-${home.selectedDate.month.toString().padLeft(2, '0')}-${home.selectedDate.day.toString().padLeft(2, '0')}";
      home.getOrderListService(
        context,
        home.selectedFilter,
        formattedDate,
        silent: true,
      );
      home.GetOrderCountService(context);
    });
  }

  //-✅-------------------------------------------------------------------✅-//
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeCtrl = context.read<HomeProvider>();
      homeCtrl.InitializeData(context);
      _checkDrawerStatus();
      // Listen to search focus to automatically expand/minimize card
      homeCtrl.myFocusNodeSearchOrder.addListener(_handleSearchFocusChange);
    });
    _startAutoRefreshTimer();
  }

  void _handleSearchFocusChange() {
    if (!mounted) return;
    final homeCtrl = context.read<HomeProvider>();
    if (homeCtrl.myFocusNodeSearchOrder.hasFocus) {
      setState(() {
        _isCardExpanded = true;
      });
    }
  }

  //-✅---Check Drawer Status---------------------------------------------✅-//
  Future<void> _checkDrawerStatus({bool silent = false}) async {
    if (!mounted) return;

    final drawerCtrl = context.read<CashDrawerProvider>();
    await drawerCtrl.checkDrawerStatus(context, silent: silent);
    // no forced popup — button in app bar reflects current status
  }

  //-✅-------------------------------------------------------------------✅-//
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    try {
      context.read<HomeProvider>().myFocusNodeSearchOrder.removeListener(_handleSearchFocusChange);
    } catch (_) {}
    super.dispose();
  }

  //-✅---App Lifecycle: refresh on foreground resume---------------------✅-//
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      // re-fetch drawer status so button label is always in sync
      context.read<CashDrawerProvider>().checkDrawerStatus(context);

      final home = context.read<HomeProvider>();
      if (home.pendingRefresh) {
        home.setPendingRefresh(false);
        home.InitializeData(context, silent: true);
      } else {
        home.GetOrderCountService(context);
      }
    }
  }

  //-✅-------------------------------------------------------------------✅-//
  @override
  Widget build(BuildContext context) {
    // Watch providers to trigger rebuild on language or theme change
    final langCtrl = Provider.of<LanguageProvider>(context);
    Provider.of<ThemeProvider>(context);

    return Consumer<HomeProvider>(
      builder: (context, HomeCtrl, child) {
        final userData = Provider.of<UserInfoProvider>(
          context,
          listen: false,
        ).getUserData;
        return WillPopScope(
          onWillPop: () async {
            // HomeScreen back behavior: always exit app
            GlobalFunction.ExitApplication(context: context);
            return false;
          },
          child: Scaffold(
            backgroundColor: GlobalAppColor.HomeBgColorCode,
            body: SafeArea(
              top: false,
              // AppBar ke liye
              left: true,
              // Landscape me left margin ke liye
              right: true,
              // Landscape me right margin ke liye
              bottom: false,
              // Gesture/navigation bar ke upar content rakhe
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Stack(
                  children: <Widget>[
                    // Main Content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        //--✅ Custom AppBar ✅--//
                        CommonWidget().CustomAppBar(
                          context: context,
                          isLoading: HomeCtrl.isHomeLoader,
                          onLogout: () async {
                            bool isConnected = await GlobalFunction()
                                .checkInternetConnection(context);
                            if (isConnected) {
                              await GlobalFunction.LogOutApplication(
                                context: context,
                              );
                            }
                          },
                          onNotificationTap: () async {
                            if (await GlobalFunction().checkInternetConnection(context)) {
                              await HomeCtrl.GetNotificationListService(context);
                              HomeCtrl.openNotificationPanelWithData();
                            }
                          },
                        ),

                        //--✅ Modern unified POS Bar Card ✅--//
                        //--✅ Modern unified POS Bar Card ✅--//
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              color: GlobalAppColor.WhiteColorCode, // Match theme
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: GlobalAppColor.DarkTextColorCode.withOpacity(0.08),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Row 1: Title (left) & Expand Chevron & Search/Drawer (when minimized) or Search Field (when maximized)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isCardExpanded = !_isCardExpanded;
                                        });
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            Provider.of<LanguageProvider>(context).translate("dashboard.orders"),
                                            style: CommonWidget.CommonTitleTextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: GlobalAppColor.DarkTextColorCode,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            _isCardExpanded
                                                ? Icons.keyboard_arrow_up_rounded
                                                : Icons.keyboard_arrow_down_rounded,
                                            color: Colors.grey.shade600,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    if (_isCardExpanded)
                                      Expanded(
                                        child: SizedBox(
                                          height: 38,
                                          child: CommonWidget().CustomSearchTextField(
                                            controller: HomeCtrl.SearchOrderController,
                                            focusNode: HomeCtrl.myFocusNodeSearchOrder,
                                            hintText: langCtrl.translate('app.searchOrders'),
                                            onChanged: (value) {
                                              HomeCtrl.SearchFilteredOrders(searchQuery: value);
                                            },
                                          ),
                                        ),
                                      )
                                    else
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _isCardExpanded = true;
                                              });
                                              Future.delayed(const Duration(milliseconds: 100), () {
                                                HomeCtrl.myFocusNodeSearchOrder.requestFocus();
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: Colors.grey.shade200, width: 1),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 16),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    langCtrl.translate('app.search'),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Consumer<CashDrawerProvider>(
                                            builder: (context, drawerCtrl, _) {
                                              final isOpen = drawerCtrl.isDrawerOpen;
                                              final hasClosed = !isOpen && drawerCtrl.currentDrawer != null;

                                              final label = isOpen
                                                  ? langCtrl.translate('app.drawerOpen')
                                                  : langCtrl.translate('app.drawerClosed');
                                              final dotColor = isOpen ? Colors.green : Colors.red;
                                              final bgColor = isOpen ? Colors.green.shade50 : Colors.red.shade50;
                                              final textColor = isOpen ? Colors.green.shade800 : Colors.red.shade800;
                                              final borderColor = isOpen ? Colors.green.shade200 : Colors.red.shade200;

                                              return PopupMenuButton<String>(
                                                offset: const Offset(0, 44),
                                                tooltip: "Drawer Action",
                                                onSelected: (String action) async {
                                                  if (action == 'close') {
                                                    await CloseDrawerDialog.show(context);
                                                  } else if (action == 'open') {
                                                    await OpenDrawerDialog.show(context);
                                                  } else if (action == 'undo') {
                                                    await drawerCtrl.reopenDrawer(context);
                                                  }
                                                  HomeCtrl.GetOrderCountService(context);
                                                },
                                                itemBuilder: (context) => [
                                                  if (isOpen)
                                                    PopupMenuItem(
                                                      value: 'close',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.exit_to_app, color: Colors.red.shade700, size: 18),
                                                          const SizedBox(width: 8),
                                                          Text(langCtrl.translate('app.closeDrawer')),
                                                        ],
                                                      ),
                                                    ),
                                                  if (!isOpen && !hasClosed)
                                                    PopupMenuItem(
                                                      value: 'open',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.login, color: GlobalAppColor.ButtonColor, size: 18),
                                                          const SizedBox(width: 8),
                                                          Text(langCtrl.translate('app.openDrawer')),
                                                        ],
                                                      ),
                                                    ),
                                                  if (hasClosed)
                                                    PopupMenuItem(
                                                      value: 'undo',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.undo, color: Colors.green.shade700, size: 18),
                                                          const SizedBox(width: 8),
                                                          Text(langCtrl.translate('app.undoDrawer')),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: bgColor,
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(color: borderColor, width: 1),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: dotColor,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        label,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: textColor,
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
                                  ],
                                ),
                                if (_isCardExpanded) ...[
                                  const SizedBox(height: 12),
                                  // Row 2: Pills (stretching horizontally)
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildPillButton(
                                              context: context,
                                              icon: Icons.calendar_today_outlined,
                                              label: "${HomeCtrl.selectedDate.day}-${HomeCtrl.selectedDate.month}-${HomeCtrl.selectedDate.year}",
                                              onTap: () async {
                                                if (await GlobalFunction().checkInternetConnection(context)) {
                                                  await HomeCtrl.selectDate(context);
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildPillButton(
                                              context: context,
                                              hasDot: true,
                                              dotColor: _isAutoRefreshActive ? Colors.green : Colors.grey,
                                              label: "Auto",
                                              onTap: () {
                                                setState(() {
                                                  _isAutoRefreshActive = !_isAutoRefreshActive;
                                                  if (_isAutoRefreshActive) {
                                                    _startAutoRefreshTimer();
                                                  } else {
                                                    _autoRefreshTimer?.cancel();
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Consumer<CashDrawerProvider>(
                                              builder: (context, drawerCtrl, _) {
                                                final isOpen = drawerCtrl.isDrawerOpen;
                                                final hasClosed = !isOpen && drawerCtrl.currentDrawer != null;

                                                final label = isOpen
                                                    ? langCtrl.translate('app.drawerOpen')
                                                    : langCtrl.translate('app.drawerClosed');

                                                final dotColor = isOpen ? Colors.green : Colors.red;
                                                final bgColor = isOpen
                                                    ? Colors.green.shade50
                                                    : Colors.red.shade50;
                                                final textColor = isOpen
                                                    ? Colors.green.shade800
                                                    : Colors.red.shade800;
                                                final borderColor = isOpen
                                                    ? Colors.green.shade200
                                                    : Colors.red.shade200;

                                                return PopupMenuButton<String>(
                                                  offset: const Offset(0, 44),
                                                  tooltip: "Drawer Action",
                                                  onSelected: (String action) async {
                                                    if (action == 'close') {
                                                      await CloseDrawerDialog.show(context);
                                                    } else if (action == 'open') {
                                                      await OpenDrawerDialog.show(context);
                                                    } else if (action == 'undo') {
                                                      await drawerCtrl.reopenDrawer(context);
                                                    }
                                                    HomeCtrl.GetOrderCountService(context);
                                                  },
                                                  itemBuilder: (context) => [
                                                    if (isOpen)
                                                      PopupMenuItem(
                                                        value: 'close',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.exit_to_app, color: Colors.red.shade700, size: 18),
                                                            const SizedBox(width: 8),
                                                            Text(langCtrl.translate('app.closeDrawer')),
                                                          ],
                                                        ),
                                                      ),
                                                    if (!isOpen && !hasClosed)
                                                      PopupMenuItem(
                                                        value: 'open',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.login, color: GlobalAppColor.ButtonColor, size: 18),
                                                            const SizedBox(width: 8),
                                                            Text(langCtrl.translate('app.openDrawer')),
                                                          ],
                                                        ),
                                                      ),
                                                    if (hasClosed)
                                                      PopupMenuItem(
                                                        value: 'undo',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.undo, color: Colors.green.shade700, size: 18),
                                                            const SizedBox(width: 8),
                                                            Text(langCtrl.translate('app.undoDrawer')),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: bgColor,
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(color: borderColor, width: 1),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 7,
                                                          height: 7,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            color: dotColor,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          label,
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            fontWeight: FontWeight.bold,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildPillButton(
                                              context: context,
                                              icon: Icons.notifications_none_rounded,
                                              label: "Prepared (${HomeCtrl.PreparedCount ?? '0'})",
                                              onTap: () async {
                                                if (await GlobalFunction().checkInternetConnection(context)) {
                                                  await HomeCtrl.GetNotificationListService(context);
                                                  HomeCtrl.openNotificationPanelWithData();
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildPillButton(
                                              context: context,
                                              icon: Icons.filter_list_rounded,
                                              label: "Filters",
                                              onTap: () => _openFiltersBottomSheet(context, HomeCtrl),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        //--✅--View-Orders-------------------✅--//
                        (HomeCtrl.PreparedCount != null &&
                                int.tryParse(HomeCtrl.PreparedCount!) != null &&
                                int.parse(HomeCtrl.PreparedCount!) > 0)
                            ? Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppDimensions.sm,
                                  vertical: AppDimensions.xs,
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(AppDimensions.sm),
                                  decoration: BoxDecoration(
                                    color: GlobalAppColor.ButtonColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xs,
                                    ),
                                    border: Border.all(
                                      color: GlobalAppColor.ButtonColor.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // 🔹 Icon Circle
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: GlobalAppColor.ButtonColor.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: GlobalAppColor.ButtonColor.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Symbols.chef_hat,
                                            size: 20,
                                            color: GlobalAppColor
                                                .RedCode.withOpacity(.5),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      // 🔹 Texts (Expanded for responsive)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "${HomeCtrl.PreparedCount ?? '0'} items prepared and ready to serve.",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    height: 1.2,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Click the bell icon to view all prepared items",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    height: 1.2,
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 13,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      // 🔹 View All Button
                                      InkWell(
                                        onTap: () async {
                                          if (await GlobalFunction()
                                              .checkInternetConnection(
                                                context,
                                              )) {
                                            await HomeCtrl.GetNotificationListService(
                                              context,
                                            );
                                            HomeCtrl.openNotificationPanelWithData();
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                GlobalAppColor.ButtonDarkColor,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: GlobalAppColor
                                                  .RedCode.withOpacity(.3),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "View All",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SizedBox.shrink(),

                        //--✅--Stats Cards------------------✅--//
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.sm,
                          ),
                          child: _buildNumbersTabsRow(
                            context,
                            HomeCtrl,
                          ),
                        ),

                        //--✅--Filter-----------------------✅--//
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.sm,
                          ),
                          child: CommonWidget().buildOrderFilterRow(
                            context,
                            HomeCtrl,
                          ),
                        ),
                        // SearchDateWise row is now unified in the modern POS Bar above

                        //--✅--SearchList-------------------✅--//
                        Flexible(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                // hamesha scrollable
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      if (HomeCtrl.isHomeLoader) {
                                        return CommonShimmer.OrderListShimmer(
                                          context,
                                          10,
                                        );
                                      }

                                      if (HomeCtrl
                                          .filteredOrderListing
                                          .isEmpty) {
                                        return CommonWidget().NoDataFoundWidget(
                                          context,
                                          Provider.of<LanguageProvider>(context).translate("dashboard.noResult"),
                                          "",
                                        );
                                      }

                                      return HomeWidget().OrderListWidget(
                                        context,
                                        HomeCtrl.filteredOrderListing,
                                        HomeCtrl,
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        //--✅-------------------------------✅--//
                      ],
                    ),
                    // Pay Bill Panel
                    if (HomeCtrl.isPanelOpen)
                      HomeWidget().OPayBillWidget(
                        context,
                        HomeCtrl.OrderListing,
                        HomeCtrl,
                      ),
                    // Notification Panel
                    if (HomeCtrl.isNotificationPanelOpen)
                      HomeWidget().ViewAllNotificationWidget(context, HomeCtrl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillButton({
    required BuildContext context,
    IconData? icon,
    bool hasDot = false,
    Color? dotColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: GlobalAppColor.WhiteColorCode,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: GlobalAppColor.DarkTextColorCode.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: GlobalAppColor.DarkTextColorCode.withOpacity(0.6)),
              const SizedBox(width: 6),
            ],
            if (hasDot) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor ?? Colors.grey,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: GlobalAppColor.DarkTextColorCode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumbersTabsRow(BuildContext context, HomeProvider HomeCtrl) {
    final tabs = [
      {
        "label": "All Orders",
        "icon": Icons.inventory_2_outlined,
        "count": HomeCtrl.countAllOrders,
      },
      {
        "label": "Preparing",
        "icon": Icons.soup_kitchen_outlined,
        "count": HomeCtrl.countPreparing,
      },
      {
        "label": "Prepared",
        "icon": Icons.check_circle_outline_rounded,
        "count": HomeCtrl.countPrepared,
      },
      {
        "label": "Active",
        "icon": Icons.watch_later_outlined,
        "count": HomeCtrl.countActive,
      },
      {
        "label": "Paid Orders",
        "icon": Icons.monetization_on_outlined,
        "count": HomeCtrl.countPaidOrders,
      },
      {
        "label": "Total Today",
        "icon": Icons.receipt_long_outlined,
        "count": HomeCtrl.countTotalToday,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: tabs.map((tab) {
          final label = tab["label"] as String;
          final icon = tab["icon"] as IconData;
          final count = tab["count"] as int;

          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(12),
            width: 140,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: GlobalAppColor.LightBlueColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 16,
                        color: GlobalAppColor.ButtonColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: GlobalAppColor.DarkTextColorCode,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: GlobalAppColor.LightTextColorCode,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ),
    );
  }

  void _openFiltersBottomSheet(BuildContext context, HomeProvider HomeCtrl) {
    String localStatus = HomeCtrl.selectedFilterStatus;
    String localPriority = HomeCtrl.selectedFilterPriority;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlobalAppColor.WhiteColorCode,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final statuses = [
              {"label": "Current", "value": "current"},
              {"label": "Draft", "value": "draft"},
              {"label": "Ordered", "value": "ordered"},
              {"label": "Preparing", "value": "preparing"},
              {"label": "Prepared", "value": "prepared"},
              {"label": "Served", "value": "served"},
              {"label": "Completed", "value": "completed"},
            ];

            final priorities = ["All", "Normal", "High", "Urgent"];

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).padding.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filters",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: GlobalAppColor.DarkTextColorCode,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: GlobalAppColor.LightTextColorCode),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Order Status",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: GlobalAppColor.LightTextColorCode,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 3.8,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: statuses.map((status) {
                      final label = status["label"]!;
                      final val = status["value"]!;
                      final isSel = localStatus == val;

                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            localStatus = val;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSel ? GlobalAppColor.ButtonColor : GlobalAppColor.WhiteColorCode,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? GlobalAppColor.ButtonColor : GlobalAppColor.LightTextColorCode.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSel ? Colors.white : GlobalAppColor.DarkTextColorCode,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Priority",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: GlobalAppColor.LightTextColorCode,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 3.0,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: priorities.map((p) {
                      final isSel = localPriority.toLowerCase() == p.toLowerCase();

                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            localPriority = p;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSel ? GlobalAppColor.ButtonColor : GlobalAppColor.WhiteColorCode,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? GlobalAppColor.ButtonColor : GlobalAppColor.LightTextColorCode.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              color: isSel ? Colors.white : GlobalAppColor.DarkTextColorCode,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        
                        HomeCtrl.selectedFilterStatus = localStatus;
                        HomeCtrl.selectedFilter = localStatus;
                        HomeCtrl.selectedFilterPriority = localPriority;
                        HomeCtrl.activeNumberTab = "All Orders";
                        
                        final formattedDate =
                            "${HomeCtrl.selectedDate.year}-${HomeCtrl.selectedDate.month.toString().padLeft(2, '0')}-${HomeCtrl.selectedDate.day.toString().padLeft(2, '0')}";
                        
                        await HomeCtrl.getOrderListService(
                          context,
                          localStatus,
                          formattedDate,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalAppColor.ButtonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Apply Filters",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

//-✅---------------------------------------------------------------------✅-//