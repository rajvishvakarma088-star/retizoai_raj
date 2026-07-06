// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
class Kds extends StatefulWidget {
  const Kds({super.key});

  @override
  KdsState createState() => KdsState();
}

//-✅---------------------------------------------------------------------✅-//
class KdsState extends State<Kds>
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();

    // ✅ Initial load after widget mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<KdsProvider>().InitializeData(context);
      }
    });
  }

  //-✅-------------------------------------------------------------------✅-//
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Consumer3<KdsProvider, UserInfoProvider, BottomNavProvider>(
          builder: (context, KdsCtrl, UserInfoCtrl, BottomNavCtrl, child) {
            final userData = UserInfoCtrl.getUserData;
            return WillPopScope(
              onWillPop: () async {
                // 🔹 Step 1: Loader check
                if (KdsCtrl.isOrderLoader) {
                  // Loader chal raha hai → back disable
                  return false;
                }

                // 🔹 Step 2: KDS user check
                if (UserInfoCtrl.appAccess == "kds") {
                  // App exit
                  GlobalFunction.ExitApplication(context: context);
                  return false; // back action handled by ExitApplication
                }

                // 🔹 Step 3: Normal back
                return true;
              },
              child: Scaffold(
                backgroundColor: GlobalAppColor.HomeBgColorCode,
                body: SafeArea(
                  top: false,
                  left: true,
                  right: true,
                  bottom: false,
                  child: Stack(
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          //--✅ Custom AppBar ✅-----//
                          UserInfoCtrl.appAccess == "kds"
                              ? CommonWidget().CustomAppBar(
                                  context: context,
                                  isLoading: KdsCtrl.isOrderLoader,
                                  onLogout: () async {
                                    bool isConnected = await GlobalFunction()
                                        .checkInternetConnection(context);
                                    if (isConnected) {
                                      await GlobalFunction.LogOutApplication(
                                        context: context,
                                      );
                                    }
                                  },
                                )
                              : Container(
                                  width: MediaQuery.of(context).size.width,
                                  height:
                                      kToolbarHeight +
                                      MediaQuery.of(context).padding.top,
                                  padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).padding.top,
                                    left: AppDimensions.sm,
                                    right: AppDimensions.sm,
                                  ),
                                  color: Colors.white,
                                  child: Row(
                                    children: <Widget>[
                                      Text(
                                        "Welcome back ${UserInfoCtrl.name ?? ""} 👋",
                                        style:
                                            CommonWidget.CommonTitleTextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 18,
                                            ),
                                      ),
                                      Spacer(),
                                      UserInfoCtrl.appAccess == "both"
                                          ? SizedBox.shrink()
                                          : CommonWidget().BackWidget(context),
                                    ],
                                  ),
                                ),

                          Expanded(
                            child: SingleChildScrollView(
                              physics: BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  //--✅ Kitchen Display + Stats + Currently Viewing ✅-----//
                                  Container(
                                    width: MediaQuery.of(context).size.width,
                                    color: const Color(0xFFF3F4F6),
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppDimensions.sm,
                                      horizontal: AppDimensions.sm,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        SizedBox(height: 5),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Icon(
                                              Symbols.chef_hat,
                                              color: GlobalAppColor
                                                  .DarkTextColorCode,
                                            ),
                                            SizedBox(width: 15),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    "Kitchen Display",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        CommonWidget.CommonTitleTextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                  Text(
                                                    KdsCtrl.formattedDateTime,
                                                    style:
                                                        CommonWidget.CommonTitleTextStyle(
                                                          height: 1.2,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        KdsWidget().OrderFilterWidget(context),
                                        SizedBox(height: 5),
                                        KdsWidget().OrderListWidget(context),
                                        SizedBox(
                                          height:
                                              KdsCtrl.isFilterDisplay == false
                                              ? 0
                                              : 5,
                                        ),
                                        KdsCtrl.isFilterDisplay == false
                                            ? SizedBox.shrink()
                                            : KdsWidget()
                                                  .OrderSearchFilterListWidget(
                                                    context,
                                                  ),
                                      ],
                                    ),
                                  ),

                                  // ✅ Kitchen Orders Section - ALWAYS scroll here
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppDimensions.sm,
                                    ),
                                    child: KdsWidget().KitchenOrderLayout(
                                      context,
                                    ),
                                  ),

                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).padding.bottom +
                                        100,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ✅ Modal Overlays (Web App Pattern)
                      if (context.watch<KdsProvider>().showCompletedModal)
                        KdsWidget().CompletedOrdersModal(context),
                      if (context.watch<KdsProvider>().showCancelledModal)
                        KdsWidget().CancelledOrdersModal(context),

                      if (context.watch<KdsProvider>().isKdsLoader ||
                          context.watch<KdsProvider>().isOrderLoader)
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
}

//-✅---------------------------------------------------------------------✅-//
