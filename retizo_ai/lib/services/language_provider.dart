import 'package:flutter/material.dart';
import 'package:culai/HTTPRepository/UserInfo/SecureStorageService.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  bool get isBaseLanguage => _currentLanguage == 'en';
  bool get isRtl => _currentLanguage == 'ar';

  LanguageProvider() {
    _loadLanguage();
  }

  // Loaded at startup
  Future<void> _loadLanguage() async {
    try {
      final savedLang = await SecureStorageService.Read('app_language');
      if (savedLang != null && savedLang is String && savedLang.isNotEmpty) {
        // Strip out quotes if jsonEncode/Decode added them
        final cleanLang = savedLang.replaceAll('"', '');
        if (cleanLang == 'en' || cleanLang == 'hi' || cleanLang == 'ar') {
          _currentLanguage = cleanLang;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading language preference: $e");
    }
  }

  // Change language dynamically
  Future<void> changeLanguage(String code) async {
    if (code == _currentLanguage) return;
    if (code == 'en' || code == 'hi' || code == 'ar') {
      _currentLanguage = code;
      notifyListeners();
      await SecureStorageService.Write('app_language', code);
    }
  }

  // Get secondary text if language is not base language (English)
  String? getSecondaryText(String key) {
    if (isBaseLanguage) return null;
    return translate(key);
  }

  // Translate helper method
  String translate(String key) {
    final languageMap = _translations[_currentLanguage] ?? _translations['en']!;
    return languageMap[key] ?? _translations['en']![key] ?? key;
  }

  // Translation maps
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'loginPage.title': 'Organization Login',
      'loginPage.subtitle': "Please enter your organization's credentials below to continue",
      'loginPage.email': 'Email',
      'loginPage.emailPlaceholder': 'Enter your email',
      'loginPage.password': 'Password',
      'loginPage.passwordPlaceholder': 'Enter your password',
      'loginPage.rememberMe': 'Remember me',
      'loginPage.forgotPassword': 'Forgot Password?',
      'loginPage.loggingIn': 'Logging in...',
      'loginPage.showPassword': 'Show password',
      'loginPage.hidePassword': 'Hide password',
      'loginPage.failed': 'Login failed. Please try again.',
      'loginPage.login': 'Login',
      'validation.pleaseEnterEmail': 'Please Enter Email',
      'validation.pleaseEnterValidEmail': 'Please Enter Valid Email',
      'validation.pleaseEnterPassword': 'Please Enter Password',
      'validation.somethingWrong': 'Something went wrong. Please try again!',
    },
    'hi': {
      'loginPage.title': 'संगठन लॉगिन',
      'loginPage.subtitle': 'जारी रखने के लिए कृपया अपने संगठन की जानकारी दर्ज करें',
      'loginPage.email': 'ईमेल',
      'loginPage.emailPlaceholder': 'अपना ईमेल दर्ज करें',
      'loginPage.password': 'पासवर्ड',
      'loginPage.passwordPlaceholder': 'अपना पासवर्ड दर्ज करें',
      'loginPage.rememberMe': 'मुझे याद रखें',
      'loginPage.forgotPassword': 'पासवर्ड भूल गए?',
      'loginPage.loggingIn': 'लॉगिन हो रहा है...',
      'loginPage.showPassword': 'पासवर्ड दिखाएं',
      'loginPage.hidePassword': 'पासवर्ड छिपाएं',
      'loginPage.failed': 'लॉगिन विफल रहा। कृपया फिर से प्रयास करें।',
      'loginPage.login': 'लॉगिन करें',
      'validation.pleaseEnterEmail': 'कृपया ईमेल दर्ज करें',
      'validation.pleaseEnterValidEmail': 'कृपया सही ईमेल दर्ज करें',
      'validation.pleaseEnterPassword': 'कृपया पासवर्ड दर्ज करें',
      'validation.somethingWrong': 'कुछ गलत हो गया। कृपया फिर से प्रयास करें!',
    },
    'ar': {
      'loginPage.title': 'تسجيل دخول المؤسسة',
      'loginPage.subtitle': 'يرجى إدخال معلومات مؤسستك للمتابعة',
      'loginPage.email': 'البريد الإلكتروني',
      'loginPage.emailPlaceholder': 'أدخل بريدك الإلكتروني',
      'loginPage.password': 'كلمة المرور',
      'loginPage.passwordPlaceholder': 'أدخل كلمة المرور',
      'loginPage.rememberMe': 'تذكرني',
      'loginPage.forgotPassword': 'نسيت كلمة المرور؟',
      'loginPage.loggingIn': 'جاري تسجيل الدخول...',
      'loginPage.showPassword': 'إظهار كلمة المرور',
      'loginPage.hidePassword': 'إخفاء كلمة المرور',
      'loginPage.failed': 'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.',
      'loginPage.login': 'تسجيل الدخول',
      'validation.pleaseEnterEmail': 'يرجى إدخال البريد الإلكتروني',
      'validation.pleaseEnterValidEmail': 'يرجى إدخال بريد إلكتروني صحيح',
      'validation.pleaseEnterPassword': 'يرجى إدخال كلمة المرور',
      'validation.somethingWrong': 'حدث خطأ ما. يرجى المحاولة مرة أخرى!',
    },
  };
}
