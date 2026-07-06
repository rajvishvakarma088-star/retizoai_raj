// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/HTTPRepository/Packages.dart';

//-✅---------------------------------------------------------------------✅-//
class AddMobile extends StatelessWidget {
  const AddMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AddOrderProvider, UserInfoProvider>(
      builder: (context, AddOrderCtrl, UserInfoCtrl, child) {
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isLargeScreen = screenWidth > 700;

        final bool isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final double screenHeight = MediaQuery.of(context).size.height;

        return WillPopScope(
          onWillPop: () async {
            if (AddOrderCtrl.isMobileVerificationLoader) {
              return false;
            }
            return true;
          },
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: isLargeScreen ? 600 : double.infinity,

                // ✅ Portrait: Auto height
                // ✅ Landscape: max 75% height to avoid FULL screen stretch
                constraints: BoxConstraints(
                  maxHeight: isLandscape
                      ? screenHeight * 0.75
                      : double.infinity,
                ),

                decoration: BoxDecoration(
                  color: GlobalAppColor.WhiteColorCode,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: GlobalAppColor.ButtonColor.withOpacity(.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 🔹 Title
                      Animate(
                        effects: [
                          FadeEffect(delay: 600.ms),
                          const SlideEffect(
                            begin: Offset(0, 0.3),
                            end: Offset(0, 0),
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 15,
                          ),
                          child: Text(
                            "Add New Customer",
                            textAlign: TextAlign.center,
                            style: CommonWidget.CommonTitleTextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ✅ Scrollable Content (Auto height in portrait, fixed scroll in landscape)
                      Expanded(
                        child: SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: 14,
                            right: 14,
                            bottom: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Name"),
                              CustomTextFormField(
                                enabled:
                                    !AddOrderCtrl.isMobileVerificationLoader,
                                controller: AddOrderCtrl.NameController,
                                focusNode: AddOrderCtrl.myFocusNodeName,
                                keyboardType: TextInputType.name,
                                hintText: "Enter Name",
                              ),
                              const SizedBox(height: 20),

                              _buildLabel("Mobile"),
                              CustomTextFormField(
                                enabled:
                                    !AddOrderCtrl.isMobileVerificationLoader,
                                controller: AddOrderCtrl.MobileController,
                                focusNode: AddOrderCtrl.myFocusNodeMobile,
                                keyboardType: TextInputType.phone,
                                hintText: "Enter Mobile",
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                              ),
                              const SizedBox(height: 20),

                              _buildLabel("Email"),
                              CustomTextFormField(
                                enabled:
                                    !AddOrderCtrl.isMobileVerificationLoader,
                                controller: AddOrderCtrl.EmailController,
                                focusNode: AddOrderCtrl.myFocusNodeEmail,
                                keyboardType: TextInputType.emailAddress,
                                hintText: "Enter Email",
                                inputFormatters:
                                    GlobalFunction.EmailInputFormatters,
                              ),
                              const SizedBox(height: 20),

                              _buildLabel("Address"),
                              CustomTextFormField(
                                enabled:
                                    !AddOrderCtrl.isMobileVerificationLoader,
                                controller: AddOrderCtrl.AddressController,
                                focusNode: AddOrderCtrl.myFocusNodeAddress,
                                keyboardType: TextInputType.streetAddress,
                                hintText: "Enter Address",
                              ),
                              const SizedBox(height: 25),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ✅ Buttons Always Bottom Me
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isLargeScreen ? 15 : 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: CommonWidget().CustomElevatedButton(
                                isLoading:
                                    AddOrderCtrl.isMobileVerificationLoader,
                                title: "Cancel",
                                backgroundColor: GlobalAppColor.WhiteColorCode,
                                borderColor: GlobalAppColor.LightTextColorCode,
                                textColor: GlobalAppColor.HomeDarkTextColor,
                                onPressed:
                                    AddOrderCtrl.isMobileVerificationLoader
                                    ? null
                                    : () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: CommonWidget().CustomElevatedButton(
                                isLoading:
                                    AddOrderCtrl.isMobileVerificationLoader,
                                title: "Add Customer",
                                backgroundColor:
                                    GlobalAppColor.ButtonColor.withOpacity(.6),
                                onPressed:
                                    AddOrderCtrl.isMobileVerificationLoader
                                    ? null
                                    : () {
                                        GlobalFunction.hideKeyboard(context);
                                        ExecuteButtonCondition(context);
                                      },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Text(
      title,
      style: CommonWidget.CommonTitleTextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: GlobalAppColor.LightTextColorCode,
      ),
    ),
  );

  void ExecuteButtonCondition(BuildContext context) async {
    GlobalFunction.hideKeyboard(context);
    final AddNewCtrl = Provider.of<AddOrderProvider>(context, listen: false);
    if (AddNewCtrl.NameController.text.isEmpty) {
      return PopupAlertHelper.showPopupFailedAlert(
        context,
        "Failed",
        "",
        "Enter Name",
      );
    }
    if (AddNewCtrl.MobileController.text.length != 10) {
      return PopupAlertHelper.showPopupFailedAlert(
        context,
        "Failed",
        "",
        "Please Enter Valid Mobile Number",
      );
    }

    final isConnected = await GlobalFunction().checkInternetConnection(context);
    if (isConnected) AddNewCtrl.AddCustomerServiceAPI(context);
  }
}

//-✅---------------------------------------------------------------------✅-//
