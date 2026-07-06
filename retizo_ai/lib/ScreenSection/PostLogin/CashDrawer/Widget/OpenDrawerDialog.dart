// ignore_for_file: file_names, use_build_context_synchronously, unnecessary_import
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//-✅---------------------------------------------------------------------✅-//
class OpenDrawerDialog {
  static Future<void> show(BuildContext context) async {
    // 🔹 Get drawer status to determine if this is a reopen scenario
    final drawerCtrl = Provider.of<CashDrawerProvider>(context, listen: false);
    final isReopenScenario = drawerCtrl.lastDrawerAction == "OPEN_NEXT_DAY";

    final TextEditingController openingAmtController = TextEditingController(
      text: "1000",
    );
    final FocusNode amountFocusNode = FocusNode();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return PopScope(
          canPop: true,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(
                  Symbols.lock_open,
                  color: GlobalAppColor.ButtonDarkColor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isReopenScenario
                        ? "Reopen Cash Drawer"
                        : "Open Cash Drawer",
                    style: CommonWidget.CommonTitleTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Info Message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GlobalAppColor.ButtonDarkColor.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: GlobalAppColor.ButtonDarkColor.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Symbols.info,
                          color: GlobalAppColor.ButtonDarkColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isReopenScenario
                                ? "The drawer was closed earlier today. Click 'Reopen' to continue taking orders."
                                : "You must open the cash drawer before taking any orders",
                            style: CommonWidget.CommonTitleTextStyle(
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🔹 Only show amount input if NOT reopen scenario
                  if (!isReopenScenario) ...[
                    const SizedBox(height: 20),

                    // 🔹 Opening Amount Label
                    Text(
                      "Opening Cash Amount",
                      style: CommonWidget.CommonTitleTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 🔹 Amount Input Field
                    CustomTextFormField(
                      controller: openingAmtController,
                      focusNode: amountFocusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      hintText: "Enter amount (e.g., 1000)",
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              // 🔹 Cancel Button (Logout option)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Show logout confirmation
                  _showLogoutConfirmation(context);
                },
                child: Text(
                  "Logout",
                  style: CommonWidget.CommonTitleTextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 🔹 Open Drawer Button
              Consumer<CashDrawerProvider>(
                builder: (context, drawerCtrl, _) {
                  // 🔹 Check if this is a reopen scenario
                  final isReopenScenario =
                      drawerCtrl.lastDrawerAction == "OPEN_NEXT_DAY";

                  return ElevatedButton(
                    onPressed: drawerCtrl.isDrawerLoading
                        ? null
                        : () async {
                            bool success = false;

                            // 🔹 If drawer was closed today and needs reopening
                            if (isReopenScenario) {
                              success = await drawerCtrl.reopenDrawer(context);
                            } else {
                              // 🔹 Normal open for first time today
                              final amount = openingAmtController.text.trim();
                              if (amount.isEmpty) {
                                GlobalFunction().showError(
                                  context,
                                  "Please enter opening amount",
                                );
                                return;
                              }

                              final amountValue = double.tryParse(amount);
                              if (amountValue == null || amountValue <= 0) {
                                GlobalFunction().showError(
                                  context,
                                  "Please enter a valid amount",
                                );
                                return;
                              }

                              success = await drawerCtrl.openDrawer(
                                context,
                                amount,
                              );
                            }

                            if (success && context.mounted) {
                              Navigator.of(context).pop();

                              // Success message already shown by reopenDrawer if reopen
                              if (!isReopenScenario) {
                                showCustomToast(
                                  context: context,
                                  message: "Cash drawer opened successfully",
                                  backgroundColor: GlobalAppColor.ButtonColor,
                                );
                              }

                              // Refresh home screen data
                              final homeCtrl = Provider.of<HomeProvider>(
                                context,
                                listen: false,
                              );
                              await homeCtrl.InitializeData(context);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalAppColor.ButtonDarkColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: drawerCtrl.isDrawerLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isReopenScenario ? "Reopen Drawer" : "Open Drawer",
                            style: CommonWidget.CommonTitleTextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    // Dispose controllers
    openingAmtController.dispose();
    amountFocusNode.dispose();
  }

  static void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Confirm Logout",
          style: CommonWidget.CommonTitleTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          "You cannot take orders without opening the drawer. Are you sure you want to logout?",
          style: CommonWidget.CommonTitleTextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: CommonWidget.CommonTitleTextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await GlobalFunction.LogOutApplication(context: context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Logout",
              style: CommonWidget.CommonTitleTextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
