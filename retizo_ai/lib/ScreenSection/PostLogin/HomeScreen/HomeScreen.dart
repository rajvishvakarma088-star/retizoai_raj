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

  //-✅-------------------------------------------------------------------✅-//
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().InitializeData(context);

      // ✅ Check drawer status after initialization
      _checkDrawerStatus();

      // Note: Printer must be configured manually in Settings
      // Auto-initialization disabled for testing phase
    });
    // ✅ Periodic auto-refresh every 8 seconds — refresh order list + counts + drawer status
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      final home = context.read<HomeProvider>();
      // ✅ Check if a new order was created and full refresh is needed
      if (home.pendingRefresh) {
        home.setPendingRefresh(false);
        home.InitializeData(context);
        return;
      }
      // ✅ Sync drawer state with server (detects if web closed the drawer)
      _checkDrawerStatus(silent: true);
      // Refresh order list for current filter + counts (non-destructive)
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
        home.InitializeData(context);
      } else {
        home.GetOrderCountService(context);
      }
    }
  }

  //-✅-------------------------------------------------------------------✅-//
  @override
  Widget build(BuildContext context) {
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
              bottom: true,
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
                          onCloseDrawer: () async {
                            // Show Close Drawer Dialog
                            await CloseDrawerDialog.show(context);

                            // Refresh order list after closing drawer
                            if (mounted) {
                              HomeCtrl.GetOrderCountService(context);
                            }
                          },
                          onOpenDrawer: () async {
                            await OpenDrawerDialog.show(context);
                            if (mounted) {
                              HomeCtrl.GetOrderCountService(context);
                            }
                          },
                          onUndoDrawer: () async {
                            final drawerCtrl = context
                                .read<CashDrawerProvider>();
                            await drawerCtrl.reopenDrawer(context);
                            if (mounted) {
                              HomeCtrl.GetOrderCountService(context);
                            }
                          },
                        ),

                        //--✅--Add-Orders-------------------✅--//
                        Padding(
                          padding: EdgeInsets.only(
                            left: 10,
                            right: 10,
                            top: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "Orders",
                                style: CommonWidget.CommonTitleTextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                              ),
                              Spacer(),
                              // Printer Settings Button (Testing)
                              IconButton(
                                icon: Icon(
                                  Icons.print_outlined,
                                  color: GlobalAppColor.DarkBlueColor,
                                ),
                                onPressed: HomeCtrl.isHomeLoader
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const PrinterSettingsScreen(),
                                          ),
                                        );
                                      },
                                tooltip: "Printer Settings",
                              ),
                              // Manage Order Types Button
                              IconButton(
                                icon: Icon(
                                  Symbols.settings,
                                  color: GlobalAppColor.DarkBlueColor,
                                ),
                                onPressed: HomeCtrl.isHomeLoader
                                    ? null
                                    : () async {
                                        bool isConnected =
                                            await GlobalFunction()
                                                .checkInternetConnection(
                                                  context,
                                                );
                                        if (isConnected) {
                                          await CommonWidget().navigateToScreen(
                                            context,
                                            const OrderTypesScreen(),
                                          );
                                        }
                                      },
                                tooltip: "Manage Order Types",
                              ),
                              SizedBox(width: 8),
                              // Add New Order Button
                              Consumer<CashDrawerProvider>(
                                builder: (context, drawerCtrl, _) {
                                  final canCreate = drawerCtrl.isDrawerOpen;
                                  return CommonWidget().customElevatedButtonWithIcon(
                                    backgroundColor:
                                        GlobalAppColor.ButtonDarkColor,
                                    title: GlobalFlag.AddNewOrder,
                                    icon: Symbols.add,
                                    onPressed:
                                        (HomeCtrl.isHomeLoader || !canCreate)
                                        ? () {
                                            if (!canCreate) {
                                              GlobalFunction().showError(
                                                context,
                                                "Open the cash drawer first to create orders.",
                                              );
                                            }
                                          }
                                        : () async {
                                            bool isConnected =
                                                await GlobalFunction()
                                                    .checkInternetConnection(
                                                      context,
                                                    );
                                            if (isConnected) {
                                              Navigator.push(
                                                context,
                                                SlideTransitionRoute(
                                                  page: const AddNewOrder(),
                                                ),
                                              ).then((_) {
                                                if (!mounted) return;
                                                final home = context
                                                    .read<HomeProvider>();
                                                if (home.pendingRefresh) {
                                                  home.setPendingRefresh(false);
                                                  home.InitializeData(context);
                                                }
                                              });
                                            }
                                          },
                                    padding: EdgeInsets.symmetric(
                                      vertical: 5,
                                      horizontal: 12,
                                    ),
                                  );
                                },
                              ),
                            ],
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
                                    color: const Color(0xFFFCE7F3),
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xs,
                                    ),
                                    border: Border.all(
                                      color: GlobalAppColor.RedCode.withOpacity(
                                        .3,
                                      ),
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
                                          color: GlobalAppColor
                                              .RedCode.withOpacity(.1),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: GlobalAppColor
                                                .RedCode.withOpacity(.3),
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
                        //--✅--SearchDateWise---------------✅--//
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.sm,
                            vertical: AppDimensions.sm,
                          ),
                          child: CommonWidget().buildSearchDateWiseRow(
                            context,
                            HomeCtrl,
                          ),
                        ),

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
                                          GlobalFlag.NoDataFound,
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
}

//-✅---------------------------------------------------------------------✅-//