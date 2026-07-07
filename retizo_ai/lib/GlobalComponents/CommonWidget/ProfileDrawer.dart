// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:culai/GlobalComponents/CommonWidget/ProfilePage.dart';
import 'package:culai/ScreenSection/PostLogin/Settings/PrinterSettingsScreen.dart';

class ProfileDrawer extends StatelessWidget {
  final VoidCallback? onLogout;

  const ProfileDrawer({super.key, this.onLogout});

  static Future<void> show(BuildContext context, {VoidCallback? onLogout}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "ProfileDrawer",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return ProfileDrawer(onLogout: onLogout);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(anim1),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final drawerWidth = sw > 400 ? 320.0 : sw * 0.8;

    final userProvider = Provider.of<UserInfoProvider>(context);
    final themeCtrl = Provider.of<ThemeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);

    final displayName = userProvider.name ?? 'Admin';
    final userRole = userProvider.type ?? 'Branch Admin';
    final userEmail = userProvider.email ?? '';
    final avatarChar = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
    final orgPicture = userProvider.orgPicture ?? '';

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: drawerWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            color: GlobalAppColor.WhiteColorCode,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              )
            ],
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Close bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
                  child: Row(
                    children: [
                      Text(
                        "Menu",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: GlobalAppColor.DarkTextColorCode,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: GlobalAppColor.DarkTextColorCode),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ── Tappable Profile Section → opens ProfilePage ──
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop(); // close drawer
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(onLogout: onLogout),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.all(14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: GlobalAppColor.BodyBgColorCode,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: GlobalAppColor.ButtonColor.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar / Org logo
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: GlobalAppColor.ButtonColor.withOpacity(0.1),
                            border: Border.all(
                              color: GlobalAppColor.ButtonColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: orgPicture.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(orgPicture,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                            child: Text(avatarChar,
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: GlobalAppColor
                                                        .ButtonColor)),
                                          )),
                                )
                              : Center(
                                  child: Text(
                                    avatarChar,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: GlobalAppColor.ButtonColor,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: GlobalAppColor.DarkTextColorCode,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userRole,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: GlobalAppColor.HomeLightTextColor,
                                ),
                              ),
                              if (userEmail.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  userEmail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: GlobalAppColor.HomeLightTextColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: GlobalAppColor.ButtonColor, size: 22),
                      ],
                    ),
                  ),
                ),

                // ── Scrollable Settings ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Language
                        Text(
                          "Language",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: GlobalAppColor.DarkTextColorCode,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: GlobalAppColor.BodyBgColorCode,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              _buildLangTab(context, langProvider, 'en', 'English'),
                              _buildLangTab(context, langProvider, 'hi', 'Hindi'),
                              _buildLangTab(context, langProvider, 'ar', 'Arabic'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Printers
                        Text(
                          "Printers",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: GlobalAppColor.DarkTextColorCode,
                          ),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop(); // close drawer
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PrinterSettingsScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.print_outlined,
                                  color: GlobalAppColor.DarkTextColorCode,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Printer Configuration",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: GlobalAppColor.DarkTextColorCode,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade400,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Theme
                        Text(
                          "Theme",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: GlobalAppColor.DarkTextColorCode,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildThemeTile(context, themeCtrl, 'light', 'Light Blue', Icons.light_mode_outlined),
                        _buildThemeTile(context, themeCtrl, 'dark', 'Dark Night', Icons.dark_mode_outlined),
                        _buildThemeTile(context, themeCtrl, 'ocean', 'Ocean Breeze', Icons.water_drop_outlined),
                        _buildThemeTile(context, themeCtrl, 'forest', 'Forest Green', Icons.forest_outlined),
                        _buildThemeTile(context, themeCtrl, 'sunset', 'Sunset Orange', Icons.wb_sunny_outlined),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1),

                // ── Logout ──
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onLogout != null) onLogout!();
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "Logout",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangTab(
    BuildContext context,
    LanguageProvider langProvider,
    String code,
    String label,
  ) {
    final isSelected = langProvider.currentLanguage == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => langProvider.changeLanguage(code),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? GlobalAppColor.ButtonColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : GlobalAppColor.DarkTextColorCode,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    ThemeProvider themeCtrl,
    String themeName,
    String label,
    IconData icon,
  ) {
    final isSelected = themeCtrl.currentTheme == themeName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => themeCtrl.changeTheme(themeName),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? GlobalAppColor.ButtonColor.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? GlobalAppColor.ButtonColor : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? GlobalAppColor.ButtonColor
                    : GlobalAppColor.DarkTextColorCode,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? GlobalAppColor.ButtonColor
                        : GlobalAppColor.DarkTextColorCode,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle,
                    color: GlobalAppColor.ButtonColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
