// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, strict_top_level_inference, invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//-✅---------------------------------------------------------------------✅-//
class CommonWidget {
  //--🔹--CommonTitleTextStyle**-----------------------------------------🔹--//
  static TextStyle CommonTitleTextStyle({
    String? fontFamily, // ✅ No removal
    Color? color,
    double fontSize = 14,
    FontWeight? fontWeight,
    double? height,
    double letterSpacing = 0,
    FontStyle fontStyle = FontStyle.normal,
    TextDecoration decoration = TextDecoration.none,
    Color? TextDecorationColor,
  }) {
    // ✅ Use GoogleFonts.roboto only for Web
    if (kIsWeb) {
      return GoogleFonts.notoSans(
        fontStyle: fontStyle,
        color: color ?? GlobalAppColor.DarkTextColorCode,
        fontWeight: fontWeight ?? FontWeight.w400,
        fontSize: fontSize,
        height: height,
        letterSpacing: letterSpacing,
        decoration: decoration,
        decorationColor: TextDecorationColor,
      );
    } else {
      return TextStyle(
        fontFamily: fontFamily ?? GlobalFlag.GoogleFonts,
        fontStyle: fontStyle,
        color: color ?? GlobalAppColor.DarkTextColorCode,
        fontWeight: fontWeight ?? FontWeight.w400,
        fontSize: fontSize,
        height: height,
        letterSpacing: letterSpacing,
        decoration: decoration,
        decorationColor: TextDecorationColor,
      );
    }
  }

  //--🔹--FadeInUpWidget**-----------------------------------------------🔹--//
  Widget FadeInUpWidget({required Duration duration, required Widget child}) {
    return FadeInUp(duration: duration, child: child);
  }

  //--🔹--buildButtons**-------------------------------------------------🔹--//
  static Widget buildButtons({
    required BuildContext context,
    required String button1Text,
    required VoidCallback onButton1Pressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: CommonWidget().CustomElevatedButton(
                height: 45,
                title: button1Text,
                onPressed: onButton1Pressed,
              ),
            ),
            const SizedBox(width: 25),
            Expanded(
              child: CommonWidget().CustomElevatedButton(
                backgroundColor: GlobalAppColor.ButtonColor.withOpacity(.6),
                height: 45,
                title: GlobalFlag.Close,
                onPressed: () {
                  GlobalFunction.hideKeyboard(context);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  //--🔹-animatedImage**------------------------------------------------🔹--//
  Future<void> navigateToScreen(BuildContext context, Widget screen) async {
    if (!context.mounted) return;
    GlobalFunction.hideKeyboard(context);
    Navigator.push(context, SlideTransitionRoute(page: screen));
  }

  //--🔹-OutlineInputBorder**--------------------------------------------🔹--//
  OutlineInputBorder buildBorder() {
    return OutlineInputBorder(
      borderRadius: AppBorderRadius.input,
      borderSide: BorderSide(
        color: GlobalAppColor.DarkTextColorCode.withOpacity(.1),
        width: 2,
      ),
    );
  }

  //--🔹-customElevatedButton**-----------------------------------------🔹--//
  Widget CustomElevatedButton({
    required VoidCallback? onPressed,
    String? title,
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    TextStyle? textStyle,
    double? fontSize,
    FontWeight? fontWeight,
    bool noSplash = false,
    double? width,
    double? height,
    bool isLoading = false,
    BuildContext? context,
  }) {
    // Button child: loader या text
    Widget buttonChild = isLoading
        ? CupertinoActivityIndicator(
            radius: 12,
            color: textColor ?? Colors.white,
            animating: true,
          )
        : Text(
            title ?? '',
            style:
                textStyle ??
                CommonWidget.CommonTitleTextStyle(
                  color: textColor ?? Colors.white,
                  fontWeight: fontWeight ?? FontWeight.w500,
                  fontSize: fontSize ?? 15,
                  letterSpacing: 0.5,
                ),
            textAlign: TextAlign.center,
          );

    Widget button = ElevatedButton(
      onPressed: () {
        if (!isLoading) {
          onPressed?.call();
        }
      }, // never null
      style:
          ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? GlobalAppColor.ButtonColor,
            // always fix
            splashFactory: noSplash ? NoSplash.splashFactory : null,
            foregroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppBorderRadius.md,
              ),
              side: BorderSide(
                color: borderColor ?? Colors.transparent,
                width: borderWidth ?? 1,
              ),
            ),
            padding:
                padding ??
                EdgeInsets.symmetric(
                  vertical: AppDimensions.md,
                  horizontal: AppDimensions.lg,
                ),
          ).copyWith(
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            mouseCursor: MaterialStateProperty.all(SystemMouseCursors.click),
          ),
      child: buttonChild,
    );

    if (width != null || height != null) {
      button = SizedBox(width: width, height: height, child: button);
    }

    return button;
  }

  //--🔹-customElevatedButtonWithIcon**----------------------------------🔹--//
  Widget customElevatedButtonWithIcon({
    required VoidCallback? onPressed,
    String? title,
    IconData? icon, // <-- 🔹 New Optional Icon
    Color? iconColor,
    double? iconSize,
    bool iconRight = false, // <-- 🔹 If true → icon right side
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    TextStyle? textStyle,
    double? fontSize,
    FontWeight? fontWeight,
    bool noSplash = false,
    double? width,
    double? height,
    bool isLoading = false,
    BuildContext? context,
  }) {
    // ✅ Button child: loader या text + icon
    Widget buttonChild;

    if (isLoading) {
      buttonChild = CupertinoActivityIndicator(
        radius: 12,
        color: textColor ?? Colors.white,
        animating: true,
      );
    } else {
      // 🔹 Text widget
      final textWidget = Text(
        title ?? '',
        style:
            textStyle ??
            CommonWidget.CommonTitleTextStyle(
              color: textColor ?? Colors.white,
              fontWeight: fontWeight ?? FontWeight.w500,
              fontSize: fontSize ?? 15,
              letterSpacing: 0.5,
            ),
        textAlign: TextAlign.center,
      );

      // 🔹 If icon provided → use Row
      if (icon != null) {
        final iconWidget = Icon(
          icon,
          color: iconColor ?? textColor ?? Colors.white,
          size: iconSize ?? 20,
        );

        buttonChild = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: iconRight
              ? [textWidget, const SizedBox(width: 0), iconWidget]
              : [iconWidget, const SizedBox(width: 0), textWidget],
        );
      } else {
        buttonChild = textWidget;
      }
    }

    // ✅ Base ElevatedButton
    Widget button = ElevatedButton(
      onPressed: () {
        if (!isLoading) {
          onPressed?.call();
        }
      },
      style:
          ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? GlobalAppColor.ButtonColor,
            splashFactory: noSplash ? NoSplash.splashFactory : null,
            foregroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppBorderRadius.md,
              ),
              side: BorderSide(
                color: borderColor ?? Colors.transparent,
                width: borderWidth ?? 1,
              ),
            ),
            padding:
                padding ??
                EdgeInsets.symmetric(
                  vertical: AppDimensions.sm,
                  horizontal: AppDimensions.md,
                ),
          ).copyWith(
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            mouseCursor: MaterialStateProperty.all(SystemMouseCursors.click),
          ),
      child: buttonChild,
    );

    if (width != null || height != null) {
      button = SizedBox(width: width, height: height, child: button);
    }

    return button;
  }

  //--🔹-buildIconButton**-----------------------------------------------🔹--//
  Widget buildIconButton(
    BuildContext context,
    IconData icon, [
    VoidCallback? onPressed,
  ]) {
    return IconButton(
      icon: Icon(icon, color: GlobalAppColor.DarkTextColorCode),
      color: GlobalAppColor.DarkTextColorCode,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      disabledColor: Colors.transparent,
      visualDensity: VisualDensity.compact,
      onPressed:
          onPressed ??
          () async {
            bool isConnected = await GlobalFunction().checkInternetConnection(
              context,
            );
            if (isConnected) {
              PopupAlertHelper.showPopupFailedAlert(
                context,
                "WorkInProgress",
                "",
                GlobalFlag.WorkInProgress,
              );
            }
          },
    );
  }

  //--🔹-buildOrderFilterBox**-------------------------------------------🔹--//
  Widget buildOrderFilterBox({
    required String title,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Consumer<HomeProvider>(
      builder: (context, HomeCtrl, child) {
        // ⚠️ NOTE: PreparingCount / PreparedCount come from the KDS-stats endpoint
        // which counts individual ITEMS with that status, NOT orders.
        // The "Preparing" / "Prepared" order-filter tabs call
        // /filter/orders?status=preparing|prepared which filters by
        // order_master.order_status. The backend currently does NOT
        // auto-update order_master.order_status when KDS marks items as
        // prepared (status_match: false in backend response).
        // Showing the KDS item-count as a badge on these tabs would falsely
        // imply there are N matching orders — so the badge is intentionally
        // suppressed to avoid misleading the user.
        // Fix required on backend: auto-update order_master.order_status when
        // all detail items are marked prepared/served via KDS.

        final String displayTitle = title;

        return InkWell(
          onTap: onTap,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          borderRadius: BorderRadius.circular(5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: isSelected
                    ? GlobalAppColor.ButtonDarkColor
                    : GlobalAppColor.DarkTextColorCode.withOpacity(.1),
                width: 2,
              ),
              color: isSelected ? GlobalAppColor.ButtonDarkColor : Colors.white,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CommonWidget.CommonTitleTextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isSelected
                        ? GlobalAppColor.WhiteColorCode
                        : GlobalAppColor.LightTextColorCode,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  //--🔹-buildOrderFilterRow**-------------------------------------------🔹--//
  Widget buildOrderFilterRow(BuildContext context, HomeProvider homeCtrl) {
    final filters = [
      "Current",
      "Draft",
      "Ordered",
      "Preparing",
      "Prepared",
      "Served",
      "Completed",
      "Cancelled",
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;

        // 🔹 Responsive width setup
        double itemWidth = screenWidth >= 1200
            ? 140
            : screenWidth >= 800
            ? 130
            : 120;

        const double itemHeight = 40;

        return Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: IntrinsicHeight(
              child: IntrinsicWidth(
                child: Row(
                  children: List.generate(filters.length, (index) {
                    final title = filters[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == filters.length - 1 ? 0 : 6,
                      ),
                      child: SizedBox(
                        width: itemWidth,
                        height: itemHeight,
                        child: CommonWidget().buildOrderFilterBox(
                          title: title,
                          isSelected:
                              homeCtrl.selectedFilter == title.toLowerCase(),
                          onTap: () async {
                            final newValue = title.toLowerCase();

                            // 🔥 पहले से selected है? — बिल्कुल कोई action नहीं
                            if (homeCtrl.selectedFilter == newValue) return;

                            // Not selected → update
                            homeCtrl.updateSelectedFilter(newValue);

                            bool isConnected = await GlobalFunction()
                                .checkInternetConnection(context);
                            if (!isConnected) return;

                            GlobalFunction.hideKeyboard(context);
                            homeCtrl.SearchOrderController.clear();

                            // Format date to YYYY-MM-DD
                            final formattedDate =
                                "${homeCtrl.selectedDate.year}-${homeCtrl.selectedDate.month.toString().padLeft(2, '0')}-${homeCtrl.selectedDate.day.toString().padLeft(2, '0')}";

                            await homeCtrl.getOrderListService(
                              context,
                              homeCtrl.selectedFilter,
                              formattedDate,
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  //--🔹-buildSearchDateWiseRow**----------------------------------------🔹--//
  Widget buildSearchDateWiseRow(BuildContext context, HomeProvider homeCtrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;

        // 🔹 Set max width for large screens
        double maxRowWidth = screenWidth >= 1200
            ? 800
            : screenWidth >= 800
            ? 700
            : screenWidth; // mobile full width
        bool isSameDate(DateTime a, DateTime b) {
          return a.year == b.year && a.month == b.month && a.day == b.day;
        }

        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxRowWidth),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch, // 🔹 ensure same height
                children: <Widget>[
                  // 🔹 Search Field
                  Expanded(
                    child: CustomSearchTextField(
                      enabled:
                          !homeCtrl.isHomeLoader &&
                          homeCtrl.OrderListing.isNotEmpty,
                      controller: homeCtrl.SearchOrderController,
                      focusNode: homeCtrl.myFocusNodeSearchOrder,
                      onChanged: (value) {
                        homeCtrl.SearchFilteredOrders(searchQuery: value);
                      },
                    ),
                  ),

                  const SizedBox(width: 6),

                  // 🔹 Date + Today container (same height as text field)
                  Container(
                    // ⚡ remove fixed vertical padding so it can stretch naturally
                    padding: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: GlobalAppColor.DarkTextColorCode.withOpacity(.1),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch, // 🔹 ensures equal height
                      children: <Widget>[
                        InkWell(
                          overlayColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                          onTap: () async {
                            bool isConnected = await GlobalFunction()
                                .checkInternetConnection(context);
                            if (!isConnected) return;
                            await homeCtrl.selectDate(context);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Symbols.calendar_today,
                                color: GlobalAppColor.LightTextColorCode,
                                size: 20,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "${homeCtrl.selectedDate.day}-${homeCtrl.selectedDate.month}-${homeCtrl.selectedDate.year}",
                                style: CommonWidget.CommonTitleTextStyle(
                                  color: GlobalAppColor
                                      .DarkTextColorCode.withOpacity(.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          overlayColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                          onTap: () async {
                            // ✅ 1. Today already selected ho to dobara click block
                            final today = DateTime.now();
                            final todayOnly = DateTime(
                              today.year,
                              today.month,
                              today.day,
                            );
                            final selectedOnly = DateTime(
                              homeCtrl.selectedDate.year,
                              homeCtrl.selectedDate.month,
                              homeCtrl.selectedDate.day,
                            );

                            if (homeCtrl.selectedFilter ==
                                    homeCtrl.selectedFilter &&
                                selectedOnly == todayOnly) {
                              return; // 🚫 double click block
                            }

                            // ✅ 2. Internet check
                            bool isConnected = await GlobalFunction()
                                .checkInternetConnection(context);
                            if (!isConnected) return;

                            // ✅ 3. Update date to today
                            homeCtrl.selectedDate = DateTime.now();

                            // ✅ 4. Update selected filter
                            homeCtrl.updateSelectedFilter(
                              homeCtrl.selectedFilter,
                            );

                            // ✅ 5. Clear search + hide keyboard
                            GlobalFunction.hideKeyboard(context);
                            homeCtrl.SearchOrderController.clear();

                            // ✅ 6. Fetch new orders
                            await homeCtrl.getOrderListService(
                              context,
                              homeCtrl.selectedFilter,
                              homeCtrl.selectedDate.toString(),
                            );
                          },
                          child: Container(
                            alignment: Alignment.center, // 🔹 vertically center
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color:
                                  isSameDate(
                                        homeCtrl.selectedDate,
                                        DateTime.now(),
                                      ) &&
                                      homeCtrl.selectedFilter == "current"
                                  ? GlobalAppColor.ButtonDarkColor
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.zero, // sirf top-left rounded
                                topRight: Radius.circular(
                                  3,
                                ), // top-right slightly rounded
                                bottomLeft:
                                    Radius.zero, // bottom-left sharp corner
                                bottomRight: Radius.circular(
                                  3,
                                ), // bottom-right rounded
                              ),
                            ),
                            child: Text(
                              "Today",
                              style: CommonWidget.CommonTitleTextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color:
                                    isSameDate(
                                          homeCtrl.selectedDate,
                                          DateTime.now(),
                                        ) &&
                                        homeCtrl.selectedFilter == "current"
                                    ? Colors.white
                                    : GlobalAppColor
                                          .DarkTextColorCode.withOpacity(0.7),
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
        );
      },
    );
  }

  //-✅--NoDataFoundWidget-----------------------------------------------✅-//
  Widget NoDataFoundWidget(
    BuildContext context,
    String TextOne,
    String TextTwo,
  ) {
    return CommonListNoData(
      imagePath: GlobalImage.NoOrder,
      children: <Widget>[
        Text(
          TextOne,
          textAlign: TextAlign.center,
          style: CommonWidget.CommonTitleTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          TextTwo,
          textAlign: TextAlign.center,
          style: CommonWidget.CommonTitleTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  //--🔹--buildStaggeredAnimation**--------------------------------------🔹--//
  Widget buildStaggeredAnimation({
    required int index,
    required Widget child,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: duration,
      columnCount: 1,
      child: ScaleAnimation(
        scale: 0.95,
        curve: Curves.fastOutSlowIn,
        child: FadeInAnimation(curve: Curves.easeIn, child: child),
      ),
    );
  }

  //--🔹--CustomSearchTextField--**--------------------------------------🔹--//
  Widget CustomSearchTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
    String hintText = "Search by order ID table",
    TextAlign textAlign = TextAlign.left,
    TextAlignVertical textAlignVertical = TextAlignVertical.center,
    Color cursorColor = Colors.black,
    TextStyle? textStyle,
    Color fillColor = Colors.white,
    bool isDense = true,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      vertical: 13,
      horizontal: 5,
    ),
    InputBorder? enabledBorder,
    InputBorder? focusedBorder,
    InputBorder? disabledBorder,
    Function(String)? onChanged,
    Function()? ontap,
    bool enabled = true,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          enabled: enabled,
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textAlign: textAlign,
          textAlignVertical: textAlignVertical,
          cursorColor: cursorColor,
          textCapitalization: TextCapitalization.words,
          style: textStyle ?? CommonWidget.CommonTitleTextStyle(),
          // 🔹 Trigger optional onTap if provided
          onTap: ontap,
          decoration: InputDecoration(
            isDense: isDense,
            contentPadding: contentPadding,
            hintText: hintText,
            hintStyle: CommonWidget.CommonTitleTextStyle(
              color: GlobalAppColor.DarkTextColorCode.withOpacity(.7),
            ),
            filled: true,
            fillColor: fillColor,
            enabledBorder: enabledBorder ?? CommonWidget().buildBorder(),
            focusedBorder: focusedBorder ?? CommonWidget().buildBorder(),
            disabledBorder: disabledBorder ?? CommonWidget().buildBorder(),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(CupertinoIcons.clear_circled_solid),
                    onPressed: () {
                      GlobalFunction.hideKeyboard(context);
                      controller.clear();
                      setState(() {}); // to refresh the suffixIcon
                      if (onChanged != null) onChanged(''); // 🔹 clear filter
                    },
                  ),
          ),
          onChanged: (value) {
            setState(() {}); // update suffix icon
            if (onChanged != null) onChanged(value);
          },
        );
      },
    );
  }

  //-✅--shimmerLine------------------------------------------------------✅-//
  Widget shimmerLine({double width = double.infinity, double height = 12}) {
    return Container(width: width, height: height, color: Colors.white);
  }

  //-✅--DividerWidget----------------------------------------------------✅-//
  Widget DividerWidget({double height = 16}) {
    return Divider(
      color: GlobalAppColor.DarkTextColorCode.withOpacity(.1),
      thickness: 1,
      height: height,
    );
  }

  //--🔹--AlertSessionBottomSheet-----------------------------------------🔹--//
  /// Guard: only one session-expired sheet may be open at a time.
  /// Multiple concurrent 401 responses (e.g. from parallel API calls) would
  /// otherwise open several sheets and ultimately crash the Navigator when
  /// each one tries to call pushAndRemoveUntil on an already-empty history.
  static bool _isSessionSheetShowing = false;

  static Future<void> AlertSessionBottomSheet({
    required BuildContext context,
  }) async {
    if (_isSessionSheetShowing) return;
    _isSessionSheetShowing = true;
    try {
      await showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: navigatorKey.currentContext!,
        builder: (_) => ShowSessionBottomSheet(
          msgTitle: GlobalFlag.SessionExpired,
          button1Text: GlobalFlag.Close,
          button2Text: GlobalFlag.LogOut,
          BtnCondition: "SessionExpired",
          icon: Icons.logout_sharp,
          iconColor: GlobalAppColor.WhiteColorCode,
          iconSize: 20,
        ),
      );
    } finally {
      _isSessionSheetShowing = false;
    }
  }

  //--🔹--FadeInUpWidget**-----------------------------------------------🔹--//
  Widget PanelTitle({required String title}) {
    return Text(
      title,
      maxLines: 1,
      softWrap: false,
      textAlign: TextAlign.left,
      style: CommonWidget.CommonTitleTextStyle(
        color: const Color(0xFF1F2937),
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
    );
  }

  //--🔹--CustomAppBar**-------------------------------------------------🔹--//
  Widget CustomAppBar({
    required BuildContext context,
    required bool isLoading,
    VoidCallback? onLogout,
    VoidCallback? onNotificationTap,
    VoidCallback? onCloseDrawer,
    VoidCallback? onOpenDrawer,
    VoidCallback? onUndoDrawer,
  }) {
    final userName = context.read<UserInfoProvider>().name ?? '';
    final displayName = userName.isNotEmpty
        ? '${userName[0].toUpperCase()}${userName.substring(1)}'
        : '';

    final topPadding = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;

    // ✅ Responsive text sizing - smaller font on small screens
    final fontSize = screenWidth < 360 ? 13.0 : 15.0;

    // ✅ For very small screens, show shorter greeting
    final greeting = screenWidth < 360
        ? "Welcome $displayName 👋"
        : "Welcome back $displayName 👋";

    return Container(
      width: MediaQuery.of(context).size.width,
      height: kToolbarHeight + topPadding,
      color: Colors.white,
      padding: EdgeInsets.only(top: topPadding, left: 10, right: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              greeting,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CommonWidget.CommonTitleTextStyle(fontSize: fontSize),
            ),
          ),
          // drawer action button — always visible, switches label by state
          Consumer<CashDrawerProvider>(
            builder: (context, drawerCtrl, _) {
              final isOpen = drawerCtrl.isDrawerOpen;
              // Drawer is CLOSED but a session exists today → show Undo
              final hasClosed = !isOpen && drawerCtrl.currentDrawer != null;

              final String btnLabel = isOpen
                  ? 'Close Drawer'
                  : hasClosed
                  ? 'Undo Drawer'
                  : 'Open Drawer';
              final Color btnColor = isOpen
                  ? const Color(0xFFDC2626)
                  : hasClosed
                  ? Colors.green.shade600
                  : GlobalAppColor.DarkBlueColor;
              final IconData btnIcon = isOpen
                  ? Icons.exit_to_app
                  : hasClosed
                  ? Icons.undo
                  : Icons.login;
              final VoidCallback? onTap = isLoading
                  ? null
                  : isOpen
                  ? onCloseDrawer
                  : hasClosed
                  ? onUndoDrawer
                  : onOpenDrawer;

              // compact icon-only on very small screens to preserve greeting space
              if (screenWidth < 360) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: btnColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: btnColor.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Icon(btnIcon, color: btnColor, size: 20),
                    ),
                  ),
                );
              }

              // Responsive font + padding: scale up slightly on wider screens
              final double btnFontSize = screenWidth < 400 ? 11.5 : 13.0;
              final EdgeInsets btnPadding = screenWidth < 400
                  ? const EdgeInsets.symmetric(vertical: 9, horizontal: 11)
                  : const EdgeInsets.symmetric(vertical: 10, horizontal: 14);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: Icon(btnIcon, color: Colors.white, size: 15),
                  label: Text(
                    btnLabel,
                    style: CommonWidget.CommonTitleTextStyle(
                      color: Colors.white,
                      fontSize: btnFontSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    foregroundColor: Colors.white,
                    padding: btnPadding,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                    shadowColor: btnColor.withOpacity(0.45),
                  ),
                ),
              );
            },
          ),
          CommonWidget().buildIconButton(
            context,
            Symbols.account_circle,
            isLoading ? null : onLogout,
          ),
        ],
      ),
    );
  }

  //--🔹--AddOrderSearchTextField--**------------------------------------🔹--//
  Widget AddOrderSearchTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
    String hintText = "Search Categories...",
    TextAlign textAlign = TextAlign.left,
    TextAlignVertical textAlignVertical = TextAlignVertical.center,
    Color cursorColor = Colors.black,
    TextStyle? textStyle,
    TextStyle? hintStyle,
    Color fillColor = Colors.white,
    bool isDense = true,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      vertical: 12, // slightly tighter
      horizontal: 4, // reduced horizontal padding
    ),
    InputBorder? enabledBorder,
    InputBorder? focusedBorder,
    InputBorder? disabledBorder,
    Function(String)? onChanged,
    Function()? ontap,
    bool enabled = true,

    /// 🔹 Optional prefix search icon
    bool showPrefixIcon = true,

    /// Optional suffix clear icon
    bool showSuffixIcon = true, // ✅ new parameter
    List<TextInputFormatter>? inputFormatters,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          enabled: enabled,
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textAlign: textAlign,
          textAlignVertical: textAlignVertical,
          cursorColor: cursorColor,
          textCapitalization: TextCapitalization.words,
          style: textStyle ?? CommonWidget.CommonTitleTextStyle(),
          inputFormatters: inputFormatters,
          // ✅ optional formatters
          onTap: ontap,
          decoration: InputDecoration(
            isDense: isDense,
            contentPadding: contentPadding,
            hintText: hintText,
            hintStyle:
                hintStyle ??
                CommonWidget.CommonTitleTextStyle(
                  color: GlobalAppColor.DarkTextColorCode.withOpacity(.7),
                ),
            filled: true,
            fillColor: fillColor,
            enabledBorder: enabledBorder ?? CommonWidget().buildBorder(),
            focusedBorder: focusedBorder ?? CommonWidget().buildBorder(),
            disabledBorder: disabledBorder ?? CommonWidget().buildBorder(),

            /// ✅ Compact prefix search icon
            prefixIcon: showPrefixIcon
                ? Padding(
                    padding: const EdgeInsets.only(left: 6, right: 2),
                    // tight spacing
                    child: const Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 20,
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 30, // reduce default spacing
              minHeight: 30,
            ),

            /// ✅ Optional suffix icon (clear)
            suffixIcon: (showSuffixIcon && controller.text.isNotEmpty)
                ? IconButton(
                    icon: const Icon(CupertinoIcons.clear_circled_solid),
                    onPressed: () {
                      GlobalFunction.hideKeyboard(context);
                      controller.clear();
                      setState(() {}); // refresh suffixIcon
                      if (onChanged != null) onChanged('');
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {}); // update suffix icon
            if (onChanged != null) onChanged(value);
          },
        );
      },
    );
  }

  //--🔹--Universal Cached Image Widget----------------------------------🔹--//
  Widget RectangleCachedImage({
    required BuildContext context,
    String? imageUrl, // Network image URL (optional)
    double width = 50,
    double height = 50,
    BoxDecoration? decoration,
    BoxFit fit = BoxFit.cover,
  }) {
    final bool isCircle = decoration?.shape == BoxShape.circle;
    final String fallbackImage = GlobalServiceURL.noImage;

    // 🔹 Helper: returns fallback widget (handles asset or network)
    Widget fallbackWidget() {
      if (fallbackImage.startsWith('https')) {
        // 🌐 Network fallback
        return Image.network(
          fallbackImage,
          width: width,
          height: height,
          fit: fit,
        );
      } else {
        // 📦 Local asset fallback
        return Image.asset(
          fallbackImage,
          width: width,
          height: height,
          fit: fit,
        );
      }
    }

    // 🔹 Cached image builder
    Widget buildImage(String? url) {
      final validUrl = (url != null && url.isNotEmpty);

      return CachedNetworkImage(
        imageUrl: validUrl ? url : fallbackImage,
        cacheKey: validUrl ? url : fallbackImage,
        width: width,
        height: height,
        fit: fit,
        useOldImageOnUrlChange: true,
        placeholder: (_, __) => globalPlaceholder(),
        errorWidget: (_, __, ___) => fallbackWidget(),
      );
    }

    final Widget imageWidget = buildImage(imageUrl);

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.hardEdge,
      decoration:
          decoration ??
          BoxDecoration(
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle
                ? BorderRadius.zero
                : BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
      child: ClipRRect(
        borderRadius: isCircle ? BorderRadius.zero : BorderRadius.circular(6),
        child: imageWidget,
      ),
    );
  }

  //-✅--globalPlaceholder**----------------------------------------------✅-//
  Widget globalPlaceholder() {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: GlobalAppColor.ButtonColor,
      ),
    );
  }

  //-✅--menuDivider**----------------------------------------------------✅-//
  Widget menuDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "Menu Items",
              style: CommonWidget.CommonTitleTextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
        ],
      ),
    );
  }

  //-✅--MultilineTextFormField**-----------------------------------------✅-//
  Widget MultilineTextFormField({
    required TextEditingController controller,
    FocusNode? focusNode,
    String? hintText,
    TextStyle? style,
    TextStyle? hintStyle,
    bool enabled = true,
    int minLines = 3,
    int maxLines = 6,
    int? maxLength,
    TextInputType keyboardType = TextInputType.multiline,
    Color? fillColor,
    InputBorder? enabledBorder,
    InputBorder? focusedBorder,
    InputBorder? disabledBorder,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      vertical: 10,
      horizontal: 8,
    ),
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.sentences,
      textAlignVertical: TextAlignVertical.top,
      style: style ?? CommonWidget.CommonTitleTextStyle(),
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      cursorColor: GlobalAppColor.DarkTextColorCode,
      decoration: InputDecoration(
        hintText: hintText ?? "Enter details",
        hintStyle:
            hintStyle ??
            CommonWidget.CommonTitleTextStyle(
              fontWeight: FontWeight.w500,
              color: GlobalAppColor.LightTextColorCode.withOpacity(0.8),
            ),
        filled: true,
        fillColor: fillColor ?? Colors.white,
        enabledBorder: enabledBorder ?? CommonWidget().buildBorder(),
        focusedBorder: focusedBorder ?? CommonWidget().buildBorder(),
        disabledBorder: disabledBorder ?? CommonWidget().buildBorder(),
        contentPadding: contentPadding,
        isDense: true,
        counterText: "", // hide maxLength counter
      ),
    );
  }

  //-✅--BackWidget**----------------------------------------------------✅-//
  Widget BackWidget(BuildContext context) {
    return Consumer2<BottomNavProvider, UserInfoProvider>(
      builder: (context, BottomNavCtrl, UserInfoCtrl, child) {
        return InkWell(
          onTap: () {
            final isLoader = context.read<KdsProvider>().isOrderLoader;
            if (isLoader) return;
            final userData = UserInfoCtrl.getUserData;
            if (userData!.appAccess == "both" ||
                userData.appAccess == "order") {
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Colors.black87,
                ),
                const SizedBox(width: 5),
                Text(
                  "Back",
                  style: CommonWidget.CommonTitleTextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //-✅--BackWidget**----------------------------------------------------✅-//
  Widget NoDatWidget(BuildContext context, String title, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 5,
          children: <Widget>[
            Icon(icon, color: GlobalAppColor.LightTextColorCode, size: 35),
            Text(
              title,
              style: CommonWidget.CommonTitleTextStyle(
                fontSize: 15,
                color: GlobalAppColor.LightTextColorCode,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
