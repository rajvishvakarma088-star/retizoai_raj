// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
//  ** Main Method: Entry Point of the Application **
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//-✅---------------------------------------------------------------------✅-//
Future<void> main() async {
  // Ensure that widget binding is initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  // Override HTTP security settings (Ignore SSL Certificate errors)
  HttpOverrides.global = MyHttpOverrides();
  // Set the app to Portrait mode only
  await GlobalFunction().setPortrait();
  // Request necessary permissions
  // Enable resampling for better touch event handling
  GestureBinding.instance.resamplingEnabled = true;
  // Run the application
  runApp(const MyApp());
}

//-✅---------------------------------------------------------------------✅-//
// ** MyApp Widget: Root Widget of the Application **
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //-✅-------------------------------------------------------------------✅-//
  // ** Build Method: Returns the MaterialApp Widget **
  //-✅-------------------------------------------------------------------✅-//
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: CommonProviders(context),
      child: Consumer4<CheckInternetProvider, BackGroundApiProvider, ThemeProvider, LanguageProvider>(
        builder: (context, CheckInternetCtrl, BackGroundApiCtrl, themeCtrl, langCtrl, child) {
          return MaterialApp(
            builder: (context, child) => ResponsiveBreakpoints.builder(
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
              child: Builder(
                builder: (context) {
                  return Directionality(
                    textDirection: langCtrl.isRtl ? TextDirection.rtl : TextDirection.ltr,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                      child: child!,
                    ),
                  );
                },
              ),
            ),
            useInheritedMediaQuery: true,
            scrollBehavior: MyCustomScrollBehavior(),
            theme: ThemeData(
              fontFamily: 'openSans',
              textTheme: const TextTheme(
                displayLarge: TextStyle(fontFamily: 'RoobertPRO'),
                displayMedium: TextStyle(fontFamily: 'RoobertPRO'),
                displaySmall: TextStyle(fontFamily: 'RoobertPRO'),
                headlineLarge: TextStyle(fontFamily: 'RoobertPRO'),
                headlineMedium: TextStyle(fontFamily: 'RoobertPRO'),
                headlineSmall: TextStyle(fontFamily: 'RoobertPRO'),
                titleLarge: TextStyle(fontFamily: 'RoobertPRO'),
                titleMedium: TextStyle(fontFamily: 'RoobertPRO'),
                titleSmall: TextStyle(fontFamily: 'RoobertPRO'),
                bodyLarge: TextStyle(fontFamily: 'RoobertPRO'),
                bodyMedium: TextStyle(fontFamily: 'RoobertPRO'),
                bodySmall: TextStyle(fontFamily: 'RoobertPRO'),
                labelLarge: TextStyle(fontFamily: 'RoobertPRO'),
                labelMedium: TextStyle(fontFamily: 'RoobertPRO'),
                labelSmall: TextStyle(fontFamily: 'RoobertPRO'),
              ),
              // ✅ Web consistency
              visualDensity: VisualDensity.adaptivePlatformDensity,
              splashFactory: NoSplash.splashFactory,
              // 👈 ripple/splash remove globally
              highlightColor: Colors.transparent,
              // long press color bhi remove
              splashColor: Colors.transparent, // extra safety
            ),
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            home: InternetStatusHandler(
              onInternetReconnect: () async {
                final session = Provider.of<SessionProvider>(
                  context,
                  listen: false,
                );
                if (session.isSessionActive) {
                  await BackGroundApiCtrl.BackGroundApiService(context);
                } else {
                  debugPrint(
                    "⚠️ Skipping API call — user is logged out/session expired.",
                  );
                }
              },
              child: SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
