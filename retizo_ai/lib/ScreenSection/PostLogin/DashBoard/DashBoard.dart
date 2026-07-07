// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
import 'dart:async';
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
//----------------- DASHBOARD -----------------//
class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> with WidgetsBindingObserver {
  Timer? _kdsRefreshTimer;
  final List<Widget> screens = const [HomeScreen(), Kds()];
  late PageController _pageController;
  late BottomNavProvider _bottomNavProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _bottomNavProvider = Provider.of<BottomNavProvider>(context, listen: false);
    _bottomNavProvider.addListener(_handleTabChange);
    _pageController = PageController(initialPage: _bottomNavProvider.SELECTED_INDEX);

    // Start background KDS refresh timer
    _startKdsTimer();
  }

  void _handleTabChange() {
    if (_pageController.hasClients) {
      final targetPage = _bottomNavProvider.SELECTED_INDEX;
      if (_pageController.page?.round() != targetPage) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _startKdsTimer() {
    _kdsRefreshTimer?.cancel();
    _kdsRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;

      final userInfo = context.read<UserInfoProvider>();
      if (userInfo.appAccess == "kds" || userInfo.appAccess == "both") {
        final kds = context.read<KdsProvider>();

        kds.GetKitchenOrderListService(context, kds.selectedKDSDate, silent: true);
        kds.GetReadyOrderListService(context, kds.selectedKDSDate, silent: true);

        kds.GetFilterOrderListService(
          context,
          "completed",
          kds.selectedKDSDate.toString(),
          silent: true,
        );
        kds.GetFilterOrderListService(
          context,
          "cancelled",
          kds.selectedKDSDate.toString(),
          silent: true,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bottomNavProvider.removeListener(_handleTabChange);
    _pageController.dispose();
    _kdsRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _startKdsTimer();
      final userInfo = context.read<UserInfoProvider>();
      if (userInfo.appAccess == "kds" || userInfo.appAccess == "both") {
        final kds = context.read<KdsProvider>();
        kds.resetPreparedTracking();
        kds.GetKitchenOrderListService(context, kds.selectedKDSDate, silent: true);
        kds.GetReadyOrderListService(context, kds.selectedKDSDate, silent: true);
        kds.restoreTimerState().then((_) {
          if (kds.activeOrderId != null) {
            kds.initializeActiveOrderTimers();
            kds.startGlobalTimer();
          }
        });
      }
    } else if (state == AppLifecycleState.paused) {
      _kdsRefreshTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BottomNavProvider>(context);
    final UserInfoCtrl = Provider.of<UserInfoProvider>(context);
    final BottomNavCtrl = Provider.of<BottomNavProvider>(context);
    bool isLargeScreen = MediaQuery.of(context).size.width > 900;

    return WillPopScope(
      onWillPop: () async {
        if (UserInfoCtrl.appAccess == "both") {
          if (BottomNavCtrl.SELECTED_INDEX == BottomNavProvider.TabKds) {
            BottomNavCtrl.changeTab(BottomNavProvider.TabOrder);
            return false;
          } else if (BottomNavCtrl.SELECTED_INDEX ==
              BottomNavProvider.TabOrder) {
            GlobalFunction.ExitApplication(context: context);
            return false;
          }
        } else {
          GlobalFunction.ExitApplication(context: context);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: GlobalAppColor.HomeBgColorCode,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: screens,
            ),
            if (!isLargeScreen)
              Align(
                alignment: Alignment.bottomCenter,
                child: const CustomBottomNavigationBar(),
              ),
          ],
        ),
        floatingActionButton: isLargeScreen ? const DesktopFloatingNav() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      ),
    );
  }
}

//----------------- MOBILE/TABLET NAV -----------------//
class CustomBottomNavigationBar extends StatefulWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  late HomeProvider _homeCtrl;

  @override
  void initState() {
    super.initState();
    _homeCtrl = Provider.of<HomeProvider>(context, listen: false);
    _homeCtrl.myFocusNodeSearchOrder.addListener(_onStateUpdate);
    _homeCtrl.SearchOrderController.addListener(_onStateUpdate);
  }

  @override
  void dispose() {
    _homeCtrl.myFocusNodeSearchOrder.removeListener(_onStateUpdate);
    _homeCtrl.SearchOrderController.removeListener(_onStateUpdate);
    super.dispose();
  }

  void _onStateUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BottomNavProvider>(context);
    final themeCtrl = Provider.of<ThemeProvider>(context); // Listen to theme updates
    final media = MediaQuery.of(context);

    final double safeBottom = media.padding.bottom;
    final double barHeight = 64.0;

    final bool isSearchSelected = provider.SELECTED_INDEX == BottomNavProvider.TabOrder &&
        (_homeCtrl.myFocusNodeSearchOrder.hasFocus || _homeCtrl.SearchOrderController.text.isNotEmpty);

    final bool isHomeSelected = provider.SELECTED_INDEX == BottomNavProvider.TabOrder && !isSearchSelected;

    debugPrint("🎨 CustomBottomNavigationBar built with theme: ${themeCtrl.currentTheme}, color: ${GlobalAppColor.WhiteColorCode}");

    return Container(
      margin: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: safeBottom > 0 ? safeBottom : 16,
      ),
      height: barHeight,
      decoration: BoxDecoration(
        color: GlobalAppColor.WhiteColorCode,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: GlobalAppColor.DarkTextColorCode.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Home / Orders Button
          _navItem(
            context,
            icon: Icons.home_rounded,
            isSelected: isHomeSelected,
            onTap: () {
              // Clear focus and query if active
              _homeCtrl.myFocusNodeSearchOrder.unfocus();
              _homeCtrl.SearchOrderController.clear();
              _homeCtrl.SearchFilteredOrders(searchQuery: '');
              provider.changeTab(BottomNavProvider.TabOrder);
            },
          ),
          // 2. Search Button
          _navItem(
            context,
            icon: Icons.search_rounded,
            isSelected: isSearchSelected,
            onTap: () {
              provider.changeTab(BottomNavProvider.TabOrder);
              Future.delayed(const Duration(milliseconds: 100), () {
                _homeCtrl.myFocusNodeSearchOrder.requestFocus();
              });
            },
          ),
          // 3. Center Create New Order Button (+)
          Expanded(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -8), // Position the button slightly upwards
                child: GestureDetector(
                  onTap: () {
                    CommonWidget().navigateToScreen(context, const AddNewOrder()).then((_) {
                      if (_homeCtrl.pendingRefresh) {
                        _homeCtrl.setPendingRefresh(false);
                        _homeCtrl.InitializeData(context, silent: true);
                      }
                    });
                  },
                  child: Container(
                    width: 52, // Slightly larger size
                    height: 52,
                    decoration: BoxDecoration(
                      color: GlobalAppColor.ButtonColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: GlobalAppColor.ButtonColor.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 30, // Highlighted icon size
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 4. KDS Button
          _navItem(
            context,
            icon: Icons.child_care_rounded,
            isSelected: provider.SELECTED_INDEX == BottomNavProvider.TabKds,
            onTap: () {
              provider.changeTab(BottomNavProvider.TabKds);
            },
          ),
          // 5. Person / Profile Button
          _navItem(
            context,
            icon: Icons.person_rounded,
            isSelected: false,
            onTap: () {
              ProfileDrawer.show(context, onLogout: () async {
                await GlobalFunction.LogOutApplication(context: context);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected
                  ? GlobalAppColor.ButtonColor
                  : GlobalAppColor.DarkTextColorCode.withOpacity(0.5), // Inactive color
            ),
          ],
        ),
      ),
    );
  }
}

//----------------- DESKTOP/WEB NAV -----------------//
class DesktopFloatingNav extends StatelessWidget {
  const DesktopFloatingNav({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BottomNavProvider>(context);

    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical: AppDimensions.sm,
        ),
        margin: EdgeInsets.all(AppDimensions.lg), // always margin from edges
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            desktopNavItem(
              context,
              Icons.shopping_cart,
              "ORDER",
              BottomNavProvider.TabOrder,
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                CommonWidget().navigateToScreen(context, const AddNewOrder()).then((_) {
                  final homeCtrl = Provider.of<HomeProvider>(context, listen: false);
                  if (homeCtrl.pendingRefresh) {
                    homeCtrl.setPendingRefresh(false);
                    homeCtrl.InitializeData(context, silent: true);
                  }
                });
              },
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline_rounded, color: Colors.blue),
                  const SizedBox(width: 5),
                  Text(
                    "NEW ORDER",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            desktopNavItem(
              context,
              Icons.child_care,
              "KDS",
              BottomNavProvider.TabKds,
            ),
          ],
        ),
      ),
    );
  }

  Widget desktopNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final provider = Provider.of<BottomNavProvider>(context);
    bool selected = provider.SELECTED_INDEX == index;

    return GestureDetector(
      onTap: () => provider.changeTab(index),
      child: Row(
        children: [
          Icon(icon, color: selected ? Colors.blue : Colors.grey),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: selected ? Colors.blue : Colors.grey),
          ),
        ],
      ),
    );
  }
}
