// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late LoginProvider loginProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loginProvider.ClearData(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loginProvider = context.read<LoginProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LoginProvider, LanguageProvider>(
      builder: (context, LoginCtrl, langCtrl, child) {
        final currentLang = langCtrl.currentLanguage;
        final isBaseLanguage = langCtrl.isBaseLanguage;
        final isRtl = langCtrl.isRtl;

        return WillPopScope(
          onWillPop: () async {
            if (LoginCtrl.isLoginLoader) {
              return false;
            }
            GlobalFunction.ExitApplication(context: context);
            return false;
          },
          child: Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              body: Stack(
                children: [
                  // 1. Beautiful Gradient Background matching screenshot
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFEFF6FF), // Light bluish background
                          Color(0xFFDBEAFE), // Soft wave blue tint
                        ],
                      ),
                    ),
                  ),

                  // 2. Custom Painted Wave Background at Bottom
                  Positioned.fill(
                    child: CustomPaint(
                      painter: BottomWavesPainter(
                        primaryColor: GlobalAppColor.ButtonColor,
                      ),
                    ),
                  ),

                  // 3. Main Login Card
                  SafeArea(
                    child: Center(
                      child: GestureDetector(
                        onTap: () => GlobalFunction.hideKeyboard(context),
                        child: OrientationBuilder(
                          builder: (context, orientation) {
                            bool isPortrait = orientation == Orientation.portrait;

                            return SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                vertical: isPortrait ? 10 : 15,
                                horizontal: isPortrait ? 16 : 40,
                              ),
                              child: LayoutBuilder(
                                builder: (ctx, constraints) {
                                  final isWide = constraints.maxWidth > 800;
                                  final cardWidth = isWide
                                      ? 520.0
                                      : constraints.maxWidth *
                                          (isPortrait ? 0.95 : 0.75);

                                  return Container(
                                    width: cardWidth,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isPortrait ? 20 : 35,
                                      vertical: isPortrait ? 24 : 30,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: GlobalAppColor.ButtonColor.withOpacity(0.3),
                                        width: 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // 4. Language Switcher (always aligned to top right)
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: Directionality(
                                            textDirection: TextDirection.ltr,
                                            child: _buildLanguageSwitcher(context, langCtrl),
                                          ),
                                        ),
                                        const SizedBox(height: 15),

                                        // 5. Logo
                                        Center(
                                          child: Image.asset(
                                            GlobalImage.Icon,
                                            height: isPortrait ? 90 : 70,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        // 6. Title: Organization Login
                                        Center(
                                          child: Text(
                                            langCtrl.translate('loginPage.title'),
                                            style: CommonWidget.CommonTitleTextStyle(
                                              fontSize: isPortrait ? 22 : 19,
                                              fontWeight: FontWeight.bold,
                                              color: GlobalAppColor.DarkTextColorCode,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // 7. Subtitle / Prompt
                                        Center(
                                          child: Text(
                                            langCtrl.translate('loginPage.subtitle'),
                                            textAlign: TextAlign.center,
                                            style: CommonWidget.CommonTitleTextStyle(
                                              fontSize: isPortrait ? 14 : 12,
                                              color: GlobalAppColor.LightTextColorCode.withOpacity(0.8),
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 25),

                                        // 8. Email Input Label
                                        _buildFieldLabel(
                                          label: langCtrl.translate('loginPage.email'),
                                          isPortrait: isPortrait,
                                        ),
                                        const SizedBox(height: 6),
                                        CustomTextFormField(
                                          enabled: !LoginCtrl.isLoginLoader,
                                          controller: LoginCtrl.EmailController,
                                          focusNode: LoginCtrl.myFocusNodeEmail,
                                          keyboardType: TextInputType.emailAddress,
                                          hintText: langCtrl.translate('loginPage.emailPlaceholder'),
                                        ),
                                        const SizedBox(height: 20),

                                        // 9. Password Input Label
                                        _buildFieldLabel(
                                          label: langCtrl.translate('loginPage.password'),
                                          isPortrait: isPortrait,
                                        ),
                                        const SizedBox(height: 6),
                                        CustomTextFormField(
                                          enabled: !LoginCtrl.isLoginLoader,
                                          controller: LoginCtrl.PasswordController,
                                          focusNode: LoginCtrl.myFocusNodePassword,
                                          keyboardType: TextInputType.visiblePassword,
                                          hintText: langCtrl.translate('loginPage.passwordPlaceholder'),
                                          isPassword: true,
                                        ),
                                        const SizedBox(height: 12),

                                        // 10. Remember Me & Forgot Password
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: ValueListenableBuilder<bool>(
                                                valueListenable: LoginCtrl.toggleCredential,
                                                builder: (context, value, child) {
                                                  return Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      SizedBox(
                                                        height: 24,
                                                        width: 24,
                                                        child: Checkbox(
                                                          value: value,
                                                          activeColor: GlobalAppColor.ButtonColor,
                                                          checkColor: Colors.white,
                                                          onChanged: LoginCtrl.isLoginLoader
                                                              ? null
                                                              : (newValue) {
                                                                  GlobalFunction.hideKeyboard(context);
                                                                  LoginCtrl.toggleCredential.value = newValue ?? false;
                                                                },
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Flexible(
                                                        child: GestureDetector(
                                                          onTap: LoginCtrl.isLoginLoader
                                                              ? null
                                                              : () {
                                                                  GlobalFunction.hideKeyboard(context);
                                                                  LoginCtrl.toggleCredential.value = !value;
                                                                },
                                                          child: Text(
                                                            langCtrl.translate('loginPage.rememberMe'),
                                                            style: CommonWidget.CommonTitleTextStyle(
                                                              fontSize: isPortrait ? 14 : 12,
                                                              fontWeight: FontWeight.w500,
                                                              color: GlobalAppColor.LightTextColorCode,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            TextButton(
                                              onPressed: LoginCtrl.isLoginLoader
                                                  ? null
                                                  : () {
                                                      GlobalFunction.hideKeyboard(context);
                                                      PopupAlertHelper.showPopupFailedAlert(
                                                        context,
                                                        "WorkInProgress",
                                                        "",
                                                        GlobalFlag.WorkInProgress,
                                                      );
                                                    },
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                langCtrl.translate('loginPage.forgotPassword'),
                                                style: CommonWidget.CommonTitleTextStyle(
                                                  color: GlobalAppColor.ButtonColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: isPortrait ? 14 : 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 25),

                                        // 11. Login Button
                                        Center(
                                          child: SizedBox(
                                            width: isPortrait
                                                ? cardWidth / 1.8
                                                : cardWidth / 1.7,
                                            child: CommonWidget().CustomElevatedButton(
                                              isLoading: LoginCtrl.isLoginLoader,
                                              title: LoginCtrl.isLoginLoader
                                                  ? langCtrl.translate('loginPage.loggingIn')
                                                  : langCtrl.translate('loginPage.login'),
                                              onPressed: LoginCtrl.isLoginLoader
                                                  ? null
                                                  : () => LoginCtrl.SubmitValidation(context),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
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
  }

  // Helper method for rendering label
  Widget _buildFieldLabel({
    required String label,
    required bool isPortrait,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: CommonWidget.CommonTitleTextStyle(
            fontSize: isPortrait ? 15 : 13,
            fontWeight: FontWeight.w600,
            color: GlobalAppColor.LightTextColorCode,
          ),
        ),
      ],
    );
  }

  // Helper method for language switcher capsule
  Widget _buildLanguageSwitcher(BuildContext context, LanguageProvider langCtrl) {
    final currentLang = langCtrl.currentLanguage;
    final languages = [
      {'code': 'en', 'label': 'English'},
      {'code': 'hi', 'label': 'Hindi'},
      {'code': 'ar', 'label': 'Arabic'},
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: languages.map((lang) {
          final isSelected = currentLang == lang['code'];
          return GestureDetector(
            onTap: () {
              langCtrl.changeLanguage(lang['code']!);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? GlobalAppColor.ButtonColor : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                lang['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 12. Bottom Wave Painter
class BottomWavesPainter extends CustomPainter {
  final Color primaryColor;

  BottomWavesPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Wave 1: Lighter Background Wave
    var paint1 = Paint()
      ..color = primaryColor.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    var path1 = Path();
    path1.moveTo(0, size.height * 0.82);
    
    // Wave 1 Bezier curve mimicking SVG
    path1.cubicTo(
      size.width * 0.25, size.height * 0.72,
      size.width * 0.60, size.height * 0.94,
      size.width, size.height * 0.78,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Wave 2: Foreground Darker Wave
    var paint2 = Paint()
      ..color = primaryColor.withOpacity(0.60)
      ..style = PaintingStyle.fill;

    var path2 = Path();
    path2.moveTo(0, size.height * 0.88);
    
    // Wave 2 Bezier curve mimicking SVG
    path2.cubicTo(
      size.width * 0.35, size.height * 0.80,
      size.width * 0.70, size.height * 0.98,
      size.width, size.height * 0.84,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
