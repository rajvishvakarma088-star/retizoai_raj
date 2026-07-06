// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
/// Splash Screen - Displays the initial loading screen with logo animation.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

//-✅---------------------------------------------------------------------✅-//
class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  //-✅-------------------------------------------------------------------✅-//
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  //-✅-------------------------------------------------------------------✅-//
  /// Initializes the app configurations and starts necessary providers.
  void _initializeApp() {
    final context = this.context;
    context.read<SplashProvider>().StartTimeout(context);
  }

  //-✅-------------------------------------------------------------------✅-//
  @override
  Widget build(BuildContext context) {
    return Consumer<SplashProvider>(
      builder: (context, SplashCtrl, child) {
        final media = MediaQuery.of(context);

        final double safeBottom = media.padding.bottom; // iPhone / Navbar
        final bool gestureNav = safeBottom == 0; // Samsung Gesture Nav
        final double extraPadding = gestureNav
            ? 16
            : 0; // Always above gesture bar

        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            backgroundColor: GlobalAppColor.BodyBgColorCode,
            body: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// Center Logo Animation
                  Expanded(
                    child: Center(
                      child: Animate(
                        effects: [
                          FadeEffect(duration: 1000.ms),
                          ScaleEffect(delay: 600.ms, duration: 1000.ms),
                        ],
                        child: Image.asset(
                          GlobalImage.Logo,
                          fit: BoxFit.contain,
                          width: 200,
                          height: 200,
                        ),
                      ),
                    ),
                  ),

                  /// Bottom Text - Always visible above gesture handle
                  Padding(
                    padding: EdgeInsets.only(
                      left: 18,
                      right: 18,
                      bottom: extraPadding + safeBottom,
                    ),
                    child: AnimatedTextKit(
                      isRepeatingAnimation: false,
                      animatedTexts: [
                        TypewriterAnimatedText(
                          GlobalFlag.AppDeveloperCompany,
                          textAlign: TextAlign.center,
                          textStyle: CommonWidget.CommonTitleTextStyle(
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                          speed: const Duration(milliseconds: 80),
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
}

//-✅---------------------------------------------------------------------✅-//
