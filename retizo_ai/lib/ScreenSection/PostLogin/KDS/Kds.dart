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
    final themeCtrl = Provider.of<ThemeProvider>(context); // Watch theme changes
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
                  top: true,
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
                              ? Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: kToolbarHeight,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: GlobalAppColor.DarkTextColorCode.withOpacity(0.08),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Kitchen Display",
                                        style: CommonWidget.CommonTitleTextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.logout_rounded, color: GlobalAppColor.RedCode),
                                        onPressed: () async {
                                          bool isConnected = await GlobalFunction()
                                              .checkInternetConnection(context);
                                          if (isConnected) {
                                            await GlobalFunction.LogOutApplication(
                                              context: context,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),

                          Expanded(
                            child: SingleChildScrollView(
                              physics: BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  //--✅ Kitchen Display + Stats + Currently Viewing ✅-----//
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: GlobalAppColor.WhiteColorCode,
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
                                        children: <Widget>[
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: <Widget>[
                                              Icon(
                                                Symbols.chef_hat,
                                                color: GlobalAppColor.DarkTextColorCode,
                                              ),
                                              const SizedBox(width: 12),
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
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                    Text(
                                                      KdsCtrl.formattedDateTime,
                                                      style:
                                                          CommonWidget.CommonTitleTextStyle(
                                                            height: 1.2,
                                                            fontSize: 12,
                                                            color: GlobalAppColor.DarkTextColorCode.withOpacity(0.6),
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          KdsWidget().OrderFilterWidget(context),
                                          const SizedBox(height: 8),
                                          KdsWidget().OrderListWidget(context),
                                          if (KdsCtrl.isFilterDisplay == true) ...[
                                            const SizedBox(height: 8),
                                            KdsWidget().OrderSearchFilterListWidget(context),
                                          ],
                                        ],
                                      ),
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
