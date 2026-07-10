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
      'dashboard.orders': 'Orders',
      'dashboard.current': 'Current',
      'dashboard.draft': 'Draft',
      'dashboard.ordered': 'Ordered',
      'dashboard.preparing': 'Preparing',
      'dashboard.prepared': 'Prepared',
      'dashboard.served': 'Served',
      'dashboard.completed': 'Completed',
      'dashboard.cancelled': 'Cancelled',
      'dashboard.addNewOrder': 'Add New Order',
      'dashboard.searchPlaceholder': 'Search by order ID table',
      'dashboard.today': 'Today',
      'dashboard.noResult': 'No Result Found',
      'app.menu': 'Menu',
      'app.language': 'Language',
      'app.printers': 'Printers',
      'app.printerConfiguration': 'Printer Configuration',
      'app.theme': 'Theme',
      'app.logout': 'Logout',
      'app.welcomeBack': 'Welcome back',
      'app.search': 'Search',
      'app.searchOrders': 'Search orders...',
      'app.drawerOpen': 'Drawer Open',
      'app.drawerClosed': 'Drawer Closed',
      'app.closeDrawer': 'Close Drawer',
      'app.openDrawer': 'Open Drawer',
      'app.undoDrawer': 'Undo Drawer',
      'app.orderTypes': 'Order Types',
      'app.createFirstOrderType': 'Create First Order Type',
      'app.createOrderType': 'Create Order Type',
      'app.editOrderType': 'Edit Order Type',
      'app.deleteOrderType': 'Delete Order Type',
      'app.cancel': 'Cancel',
      'app.create': 'Create',
      'app.update': 'Update',
      'app.delete': 'Delete',
      'app.kitchenDisplay': 'Kitchen Display',
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
      'dashboard.orders': 'आदेश',
      'dashboard.current': 'वर्तमान',
      'dashboard.draft': 'ड्राफ्ट',
      'dashboard.ordered': 'ऑर्डर किया गया',
      'dashboard.preparing': 'तैयार हो रहा है',
      'dashboard.prepared': 'तैयार',
      'dashboard.served': 'परोसा गया',
      'dashboard.completed': 'पूरा हुआ',
      'dashboard.cancelled': 'रद्द',
      'dashboard.addNewOrder': 'नया ऑर्डर जोड़ें',
      'dashboard.searchPlaceholder': 'ऑर्डर आईडी टेबल द्वारा खोजें',
      'dashboard.today': 'आज',
      'dashboard.noResult': 'कोई परिणाम नहीं मिला',
      'app.menu': 'मेन्यू',
      'app.language': 'भाषा',
      'app.printers': 'प्रिंटर',
      'app.printerConfiguration': 'प्रिंटर कॉन्फ़िगरेशन',
      'app.theme': 'थीम',
      'app.logout': 'लॉगआउट',
      'app.welcomeBack': 'स्वागत है',
      'app.search': 'खोजें',
      'app.searchOrders': 'ऑर्डर खोजें...',
      'app.drawerOpen': 'दराज खुला है',
      'app.drawerClosed': 'दराज बंद है',
      'app.closeDrawer': 'दराज बंद करें',
      'app.openDrawer': 'दराज खोलें',
      'app.undoDrawer': 'दराज पूर्ववत करें',
      'app.orderTypes': 'ऑर्डर के प्रकार',
      'app.createFirstOrderType': 'पहला ऑर्डर प्रकार बनाएं',
      'app.createOrderType': 'ऑर्डर प्रकार बनाएं',
      'app.editOrderType': 'ऑर्डर प्रकार संपादित करें',
      'app.deleteOrderType': 'ऑर्डर प्रकार हटाएं',
      'app.cancel': 'रद्द करें',
      'app.create': 'बनाएं',
      'app.update': 'अपडेट करें',
      'app.delete': 'हटाएं',
      'app.kitchenDisplay': 'किचन डिस्प्ले',
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
      'dashboard.orders': 'الطلبات',
      'dashboard.current': 'الحالي',
      'dashboard.draft': 'المسودات',
      'dashboard.ordered': 'المطلوبة',
      'dashboard.preparing': 'قيد التحضير',
      'dashboard.prepared': 'الجاهزة',
      'dashboard.served': 'المقدمة',
      'dashboard.completed': 'المكتملة',
      'dashboard.cancelled': 'الملغاة',
      'dashboard.addNewOrder': 'إضافة طلب جديد',
      'dashboard.searchPlaceholder': 'البحث عن طريق جدول معرف الطلب',
      'dashboard.today': 'اليوم',
      'dashboard.noResult': 'لم يتم العثور على نتائج',
      'app.menu': 'القائمة',
      'app.language': 'اللغة',
      'app.printers': 'الطابعات',
      'app.printerConfiguration': 'إعدادات الطابعة',
      'app.theme': 'المظهر',
      'app.logout': 'تسجيل الخروج',
      'app.welcomeBack': 'مرحباً بك مجدداً',
      'app.search': 'بحث',
      'app.searchOrders': 'البحث عن الطلبات...',
      'app.drawerOpen': 'الدرج مفتوح',
      'app.drawerClosed': 'الدرج مغلق',
      'app.closeDrawer': 'إغلاق الدرج',
      'app.openDrawer': 'فتح الدرج',
      'app.undoDrawer': 'تراجع عن الدرج',
      'app.orderTypes': 'أنواع الطلبات',
      'app.createFirstOrderType': 'إنشاء أول نوع طلب',
      'app.createOrderType': 'إنشاء نوع طلب',
      'app.editOrderType': 'تعديل نوع الطلب',
      'app.deleteOrderType': 'حذف نوع الطلب',
      'app.cancel': 'إلغاء',
      'app.create': 'إنشاء',
      'app.update': 'تحديث',
      'app.delete': 'حذف',
      'app.kitchenDisplay': 'شاشة المطبخ',
    },
  };
}
