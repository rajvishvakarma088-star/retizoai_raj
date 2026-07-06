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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start background KDS refresh timer
    _startKdsTimer();
  }

  void _startKdsTimer() {
    _kdsRefreshTimer?.cancel();
    _kdsRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;

      final userInfo = context.read<UserInfoProvider>();
      if (userInfo.appAccess == "kds" || userInfo.appAccess == "both") {
        final kds = context.read<KdsProvider>();

        kds.GetKitchenOrderListService(context, kds.selectedKDSDate, silent: true);
        kds.GetReadyOrderListService(context, kds.selectedKDSDate);

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
        kds.GetKitchenOrderListService(context, kds.selectedKDSDate);
        kds.GetReadyOrderListService(context, kds.selectedKDSDate);
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
        body: Stack(
          children: [
            screens[provider.SELECTED_INDEX],
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
class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BottomNavProvider>(context);
    final media = MediaQuery.of(context);

    final double safeBottom =
        media.padding.bottom; // iOS notch / Android gestures
    final double barHeight = 60.0;

    return Container(
      width: double.infinity,
      height: barHeight + safeBottom,
      padding: EdgeInsets.only(bottom: safeBottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: navItem(
              context,
              Icons.shopping_cart,
              "ORDER",
              BottomNavProvider.TabOrder,
            ),
          ),
          // Center: Add New Order Button
          GestureDetector(
            onTap: () async {
              final drawerCtrl = context.read<CashDrawerProvider>();
              if (!drawerCtrl.isDrawerOpen) {
                GlobalFunction().showError(
                  context,
                  "Open the cash drawer first to create orders.",
                );
                return;
              }
              if (await GlobalFunction().checkInternetConnection(context)) {
                Navigator.push(
                  context,
                  SlideTransitionRoute(page: const AddNewOrder()),
                ).then((_) {
                  final home = context.read<HomeProvider>();
                  home.InitializeData(context);
                });
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GlobalAppColor.ButtonColor,
                boxShadow: [
                  BoxShadow(
                    color: GlobalAppColor.ButtonColor.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          Expanded(
            child: navItem(
              context,
              Icons.child_care,
              "KDS",
              BottomNavProvider.TabKds,
            ),
          ),
        ],
      ),
    );
  }

  Widget navItem(BuildContext context, IconData icon, String label, int index) {
    final provider = Provider.of<BottomNavProvider>(context);
    bool selected = provider.SELECTED_INDEX == index;

    return GestureDetector(
      onTap: () => provider.changeTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected
                ? GlobalAppColor.ButtonDarkColor
                : GlobalAppColor.DarkTextColorCode.withOpacity(.6),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: CommonWidget.CommonTitleTextStyle(
              color: selected
                  ? GlobalAppColor.ButtonDarkColor
                  : GlobalAppColor.DarkTextColorCode.withOpacity(.6),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
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
