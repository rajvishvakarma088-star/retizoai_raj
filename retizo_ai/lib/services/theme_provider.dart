import 'package:flutter/material.dart';
import 'package:culai/HTTPRepository/UserInfo/SecureStorageService.dart';
import 'package:culai/GlobalComponents/Constant/GlobalAppColor.dart';

class ThemeProvider with ChangeNotifier {
  String _currentTheme = 'light';

  String get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final savedTheme = await SecureStorageService.Read('app_theme');
      if (savedTheme != null && savedTheme is String && savedTheme.isNotEmpty) {
        final cleanTheme = savedTheme.replaceAll('"', '');
        if (['light', 'dark', 'ocean', 'forest', 'sunset'].contains(cleanTheme)) {
          _currentTheme = cleanTheme;
          _applyColors();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading theme: $e");
    }
  }

  Future<void> changeTheme(String themeName) async {
    if (themeName == _currentTheme) return;
    if (['light', 'dark', 'ocean', 'forest', 'sunset'].contains(themeName)) {
      _currentTheme = themeName;
      _applyColors();
      notifyListeners();
      await SecureStorageService.Write('app_theme', themeName);
    }
  }

  void _applyColors() {
    switch (_currentTheme) {
      case 'dark':
        GlobalAppColor.WhiteColorCode = const Color(0xFF121A2B); // Card bg
        GlobalAppColor.DarkTextColorCode = const Color(0xFFE2E8F0);
        GlobalAppColor.LightTextColorCode = const Color(0xFF94A3B8);
        GlobalAppColor.BodyBgColorCode = const Color(0xFF0E1422);
        GlobalAppColor.ButtonColor = const Color(0xFF6366F1); // Indigo
        GlobalAppColor.ButtonDarkColor = const Color(0xFF4F46E5);
        GlobalAppColor.HomeBgColorCode = const Color(0xFF0B0F19);
        GlobalAppColor.HomeLightTextColor = const Color(0xFF94A3B8);
        GlobalAppColor.HomeDarkTextColor = const Color(0xFFE2E8F0);
        GlobalAppColor.LightBlueColor = const Color(0xFF1E1E38);
        GlobalAppColor.DarkBlueColor = const Color(0xFF818CF8);
        break;
      case 'ocean':
        GlobalAppColor.WhiteColorCode = const Color(0xFFF7FCFF);
        GlobalAppColor.DarkTextColorCode = const Color(0xFF0C2638);
        GlobalAppColor.LightTextColorCode = const Color(0xFF0E7490);
        GlobalAppColor.BodyBgColorCode = const Color(0xFFECFEFF);
        GlobalAppColor.ButtonColor = const Color(0xFF0891B2); // Teal
        GlobalAppColor.ButtonDarkColor = const Color(0xFF0E7490);
        GlobalAppColor.HomeBgColorCode = const Color(0xFFF2FBFD);
        GlobalAppColor.HomeLightTextColor = const Color(0xFF0E7490);
        GlobalAppColor.HomeDarkTextColor = const Color(0xFF0C2638);
        GlobalAppColor.LightBlueColor = const Color(0xFFE0F7FA);
        GlobalAppColor.DarkBlueColor = const Color(0xFF006064);
        break;
      case 'forest':
        GlobalAppColor.WhiteColorCode = const Color(0xFFF2FBF4);
        GlobalAppColor.DarkTextColorCode = const Color(0xFF14301C);
        GlobalAppColor.LightTextColorCode = const Color(0xFF166534);
        GlobalAppColor.BodyBgColorCode = const Color(0xFFF0FDF4);
        GlobalAppColor.ButtonColor = const Color(0xFF16A34A); // Green
        GlobalAppColor.ButtonDarkColor = const Color(0xFF15803D);
        GlobalAppColor.HomeBgColorCode = const Color(0xFFF4FBF7);
        GlobalAppColor.HomeLightTextColor = const Color(0xFF166534);
        GlobalAppColor.HomeDarkTextColor = const Color(0xFF14301C);
        GlobalAppColor.LightBlueColor = const Color(0xFFE8F5E9);
        GlobalAppColor.DarkBlueColor = const Color(0xFF1B5E20);
        break;
      case 'sunset':
        GlobalAppColor.WhiteColorCode = const Color(0xFFFFFAF5);
        GlobalAppColor.DarkTextColorCode = const Color(0xFF431407);
        GlobalAppColor.LightTextColorCode = const Color(0xFF9A3412);
        GlobalAppColor.BodyBgColorCode = const Color(0xFFFFF7ED);
        GlobalAppColor.ButtonColor = const Color(0xFFEA580C); // Orange
        GlobalAppColor.ButtonDarkColor = const Color(0xFFC2410C);
        GlobalAppColor.HomeBgColorCode = const Color(0xFFFFFBF7);
        GlobalAppColor.HomeLightTextColor = const Color(0xFF9A3412);
        GlobalAppColor.HomeDarkTextColor = const Color(0xFF431407);
        GlobalAppColor.LightBlueColor = const Color(0xFFFFE0B2);
        GlobalAppColor.DarkBlueColor = const Color(0xFFE65100);
        break;
      case 'light':
      default:
        GlobalAppColor.WhiteColorCode = const Color(0xFFFFFFFF);
        GlobalAppColor.DarkTextColorCode = const Color(0xFF111827);
        GlobalAppColor.LightTextColorCode = const Color(0xFF4B5563);
        GlobalAppColor.BodyBgColorCode = const Color(0xFFEFF6FF);
        GlobalAppColor.ButtonColor = const Color(0xFF2563EB); // Blue
        GlobalAppColor.ButtonDarkColor = const Color(0xFF1D4ED8);
        GlobalAppColor.HomeBgColorCode = const Color(0xFFF7F8FA);
        GlobalAppColor.HomeLightTextColor = const Color(0xFF4B5563);
        GlobalAppColor.HomeDarkTextColor = const Color(0xFF111827);
        GlobalAppColor.LightBlueColor = const Color(0xFFEFF6FF);
        GlobalAppColor.DarkBlueColor = const Color(0xFF1E40AF);
        break;
    }
  }
}
