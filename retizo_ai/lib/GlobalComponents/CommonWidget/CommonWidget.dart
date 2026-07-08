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
        final langCtrl = Provider.of<LanguageProvider>(context);
        final String displayTitle = langCtrl.translate("dashboard.${title.toLowerCase()}");

        return InkWell(
          onTap: onTap,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected
                      ? GlobalAppColor.ButtonColor
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: Text(
              displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CommonWidget.CommonTitleTextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
                color: isSelected
                    ? GlobalAppColor.ButtonColor
                    : Colors.grey.shade600,
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

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            children: List.generate(filters.length, (index) {
              final title = filters[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
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
              );
            }),
          ),
        ),
      ),
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
                              Provider.of<LanguageProvider>(context).translate("dashboard.today"),
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
    Color? cursorColor,
    TextStyle? textStyle,
    Color? fillColor,
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
          cursorColor: cursorColor ?? GlobalAppColor.DarkTextColorCode,
          textCapitalization: TextCapitalization.words,
          style: textStyle ?? CommonWidget.CommonTitleTextStyle(),
          // 🔹 Trigger optional onTap if provided
          onTap: ontap,
          decoration: InputDecoration(
            isDense: isDense,
            contentPadding: contentPadding,
            hintText: Provider.of<LanguageProvider>(context).translate(
              hintText == "Search by order ID table"
                  ? "dashboard.searchPlaceholder"
                  : hintText,
            ),
            hintStyle: CommonWidget.CommonTitleTextStyle(
              color: GlobalAppColor.DarkTextColorCode.withOpacity(.7),
            ),
            filled: true,
            fillColor: fillColor ?? GlobalAppColor.BodyBgColorCode,
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
        color: GlobalAppColor.DarkTextColorCode,
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
    final userInfo = Provider.of<UserInfoProvider>(context, listen: false);
    final displayName = userInfo.name ?? 'Admin';
    final userRole = userInfo.type ?? 'Branch Admin';
    final avatarChar = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

    final topPadding = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: MediaQuery.of(context).size.width,
      height: kToolbarHeight + topPadding + 34,
      padding: EdgeInsets.only(top: topPadding + 4, left: 14, right: 14, bottom: 4),
      decoration: BoxDecoration(
        color: GlobalAppColor.WhiteColorCode, // Match theme
        border: Border(
          bottom: BorderSide(
            color: GlobalAppColor.DarkTextColorCode.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          // ── Left: Greeting + Role Badge ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome back",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: GlobalAppColor.DarkTextColorCode.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  "$displayName 👋",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: GlobalAppColor.DarkTextColorCode,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: GlobalAppColor.ButtonColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: GlobalAppColor.ButtonColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 11,
                        color: GlobalAppColor.ButtonColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        userRole,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: GlobalAppColor.ButtonColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Right: Notification Bell ──
          if (onNotificationTap != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: isLoading ? null : onNotificationTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GlobalAppColor.BodyBgColorCode,
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: GlobalAppColor.DarkTextColorCode.withOpacity(0.8),
                    size: 20,
                  ),
                ),
              ),
            ),

          // ── Right: Avatar Initials ──
          GestureDetector(
            onTap: () {
              ProfileDrawer.show(context, onLogout: onLogout);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: GlobalAppColor.ButtonColor.withOpacity(0.25),
                  width: 1.5,
                ),
                color: GlobalAppColor.ButtonColor.withOpacity(0.08),
              ),
              child: Center(
                child: Text(
                  avatarChar,
                  style: TextStyle(
                    color: GlobalAppColor.ButtonColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
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
    Color? cursorColor,
    TextStyle? textStyle,
    TextStyle? hintStyle,
    Color? fillColor,
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
          cursorColor: cursorColor ?? GlobalAppColor.DarkTextColorCode,
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
            fillColor: fillColor ?? GlobalAppColor.WhiteColorCode,
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
                color: GlobalAppColor.LightTextColorCode,
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
              color: GlobalAppColor.WhiteColorCode,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: GlobalAppColor.DarkTextColorCode,
                ),
                const SizedBox(width: 5),
                Text(
                  "Back",
                  style: CommonWidget.CommonTitleTextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: GlobalAppColor.DarkTextColorCode,
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
