// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:culai/HTTPRepository/Packages.dart';

class ProfilePage extends StatelessWidget {
  final VoidCallback? onLogout;

  const ProfilePage({super.key, this.onLogout});

  // ─── Edit Profile Dialog ───────────────────────────────────────────────────
  static Future<void> _showEditProfileDialog(
    BuildContext context,
    UserInfoProvider userProvider,
    HttpServiceProvider httpCtrl,
  ) async {
    final nameCtrl =
        TextEditingController(text: userProvider.name ?? '');
    final emailCtrl =
        TextEditingController(text: userProvider.email ?? '');
    final addressCtrl =
        TextEditingController(text: userProvider.address ?? '');
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: GlobalAppColor.WhiteColorCode,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.edit_outlined,
                  color: GlobalAppColor.ButtonColor, size: 20),
              const SizedBox(width: 8),
              Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: GlobalAppColor.DarkTextColorCode,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogField(
                    controller: nameCtrl,
                    label: "Full Name",
                    hint: "Enter your full name",
                    icon: Icons.person_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? "Name cannot be empty"
                            : null,
                  ),
                  const SizedBox(height: 14),
                  _DialogField(
                    controller: emailCtrl,
                    label: "Email Address",
                    hint: "Enter your email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Email cannot be empty";
                      }
                      if (!v.contains('@')) return "Enter a valid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _DialogField(
                    controller: addressCtrl,
                    label: "Address",
                    hint: "Enter your address",
                    icon: Icons.location_on_outlined,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.of(ctx).pop(),
              child: Text("Cancel",
                  style:
                      TextStyle(color: GlobalAppColor.HomeLightTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalAppColor.ButtonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => loading = true);
                      final res = await userProvider.updateProfile(
                        context,
                        httpCtrl,
                        name: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        address: addressCtrl.text.trim(),
                      );
                      setState(() => loading = false);

                      final success = res['success'] == true;
                      final msg = res['message']?.toString() ??
                          (success
                              ? 'Profile updated!'
                              : 'Update failed');
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: success
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                        ),
                      );
                    },
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text("Save Changes",
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Update Password Dialog ────────────────────────────────────────────────
  static Future<void> _showUpdatePasswordDialog(
    BuildContext context,
    UserInfoProvider userProvider,
    HttpServiceProvider httpCtrl,
  ) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: GlobalAppColor.WhiteColorCode,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  color: GlobalAppColor.ButtonColor, size: 20),
              const SizedBox(width: 8),
              Text(
                "Update Password",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: GlobalAppColor.DarkTextColorCode,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PasswordField(
                  controller: currentCtrl,
                  label: "Current Password",
                  show: showCurrent,
                  onToggle: () =>
                      setState(() => showCurrent = !showCurrent),
                  validator: (v) =>
                      (v == null || v.isEmpty)
                          ? "Enter current password"
                          : null,
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: newCtrl,
                  label: "New Password",
                  show: showNew,
                  onToggle: () =>
                      setState(() => showNew = !showNew),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Enter new password";
                    }
                    if (v.length < 6) {
                      return "Minimum 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: confirmCtrl,
                  label: "Confirm New Password",
                  show: showConfirm,
                  onToggle: () =>
                      setState(() => showConfirm = !showConfirm),
                  validator: (v) =>
                      v != newCtrl.text
                          ? "Passwords do not match"
                          : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.of(ctx).pop(),
              child: Text("Cancel",
                  style:
                      TextStyle(color: GlobalAppColor.HomeLightTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalAppColor.ButtonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => loading = true);
                      final res = await userProvider.changePassword(
                        context,
                        httpCtrl,
                        currentPassword: currentCtrl.text,
                        newPassword: newCtrl.text,
                      );
                      setState(() => loading = false);

                      final success = res['success'] == true;
                      final msg = res['message']?.toString() ??
                          (success
                              ? 'Password updated!'
                              : 'Update failed');
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: success
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                        ),
                      );
                    },
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text("Update",
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserInfoProvider>(context);
    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);

    final displayName = userProvider.name ?? 'Admin';
    final userRole = userProvider.type ?? 'Branch Admin';
    final userEmail = userProvider.email ?? '';
    final orgName = userProvider.orgName ?? '';
    final branchName = userProvider.branchName ?? '';
    final vatNo = userProvider.vatNo ?? '';
    final branchAddress = userProvider.branchAddress ?? '';
    final userAddress = userProvider.address ?? '';
    final userStatus = userProvider.status ?? 'active';
    final orgPicture = userProvider.orgPicture ?? '';
    final avatarChar =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
    final bool isActive = userStatus.toLowerCase() == 'active';

    return Scaffold(
      backgroundColor: GlobalAppColor.HomeBgColorCode,
      appBar: AppBar(
        backgroundColor: GlobalAppColor.WhiteColorCode,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: GlobalAppColor.DarkTextColorCode, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "My Profile",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: GlobalAppColor.DarkTextColorCode,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: GlobalAppColor.LightTextColorCode.withOpacity(0.15)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Card 1 · Personal Information ───
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Personal Information",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: GlobalAppColor.DarkTextColorCode,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Update your profile details and password",
                        style: TextStyle(
                          fontSize: 12,
                          color: GlobalAppColor.HomeLightTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Action buttons ──
                  Row(
                    children: [
                      Expanded(
                        child: _PillButton(
                          icon: Icons.lock_outline_rounded,
                          label: "Update Password",
                          onTap: () => _showUpdatePasswordDialog(
                              context, userProvider, httpCtrl),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PillButton(
                          icon: Icons.edit_outlined,
                          label: "Edit Profile",
                          onTap: () => _showEditProfileDialog(
                              context, userProvider, httpCtrl),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // ── Avatar + info ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: GlobalAppColor.BodyBgColorCode,
                          border: Border.all(
                              color: GlobalAppColor.LightTextColorCode.withOpacity(0.2), width: 1.5),
                        ),
                        child: orgPicture.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  orgPicture,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _avatarLetter(avatarChar),
                                ),
                              )
                            : _avatarLetter(avatarChar),
                      ),
                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: GlobalAppColor.DarkTextColorCode,
                                  ),
                                ),
                                _RolePill(label: userRole),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (orgName.isNotEmpty)
                              _InfoRow(
                                  label: "Organization:", value: orgName),
                            if (branchName.isNotEmpty)
                              _InfoRow(
                                  label: "Branch:",
                                  value: branchName,
                                  chip: true),
                            if (vatNo.isNotEmpty)
                              _InfoRow(label: "VAT:", value: vatNo),
                            if (branchAddress.isNotEmpty)
                              _InfoRow(
                                  label: "Branch Address:",
                                  value: branchAddress),
                          ],
                        ),
                      ),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFDCFCE7)
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF86EFAC)
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          isActive ? "Active" : "Inactive",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? const Color(0xFF16A34A)
                                : Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ─── Card 2 · Personal Details ───
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Personal Details",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: GlobalAppColor.DarkTextColorCode,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _ReadField(
                              label: "Full Name *", value: displayName)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _ReadField(
                              label: "Email Address *", value: userEmail)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ReadField(
                    label: "Address",
                    value: userAddress,
                    minLines: 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _avatarLetter(String letter) {
    return Center(
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: GlobalAppColor.ButtonColor,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ──────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GlobalAppColor.WhiteColorCode,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
        decoration: BoxDecoration(
          color: GlobalAppColor.ButtonColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;
  const _RolePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: GlobalAppColor.ButtonColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GlobalAppColor.ButtonColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GlobalAppColor.ButtonColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool chip;

  const _InfoRow({
    required this.label,
    required this.value,
    this.chip = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: GlobalAppColor.HomeLightTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: chip
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: GlobalAppColor.ButtonColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GlobalAppColor.ButtonColor,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: GlobalAppColor.DarkTextColorCode,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReadField extends StatelessWidget {
  final String label;
  final String value;
  final int minLines;

  const _ReadField({
    required this.label,
    required this.value,
    this.minLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: GlobalAppColor.HomeLightTextColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              horizontal: 14, vertical: minLines > 1 ? 14 : 13),
          decoration: BoxDecoration(
            color: GlobalAppColor.BodyBgColorCode,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GlobalAppColor.LightTextColorCode.withOpacity(0.2), width: 1),
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              fontSize: 13.5,
              color: value.isEmpty
                  ? GlobalAppColor.HomeLightTextColor
                  : GlobalAppColor.DarkTextColorCode,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Dialog input fields ──────────────────────────────────────────────────────

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: GlobalAppColor.DarkTextColorCode,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
              fontSize: 14, color: GlobalAppColor.DarkTextColorCode),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: GlobalAppColor.ButtonColor),
            hintStyle: TextStyle(
                fontSize: 13, color: GlobalAppColor.HomeLightTextColor),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            filled: true,
            fillColor: GlobalAppColor.BodyBgColorCode,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: GlobalAppColor.LightTextColorCode.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: GlobalAppColor.LightTextColorCode.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: GlobalAppColor.ButtonColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: GlobalAppColor.DarkTextColorCode,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: !show,
          validator: validator,
          style: TextStyle(
              fontSize: 14, color: GlobalAppColor.DarkTextColorCode),
          decoration: InputDecoration(
            hintText: "••••••••",
            prefixIcon: Icon(Icons.lock_outline,
                size: 18, color: GlobalAppColor.ButtonColor),
            suffixIcon: IconButton(
              icon: Icon(
                show ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: GlobalAppColor.HomeLightTextColor,
              ),
              onPressed: onToggle,
            ),
            hintStyle: TextStyle(
                fontSize: 13, color: GlobalAppColor.HomeLightTextColor),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            filled: true,
            fillColor: GlobalAppColor.BodyBgColorCode,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: GlobalAppColor.LightTextColorCode.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: GlobalAppColor.LightTextColorCode.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: GlobalAppColor.ButtonColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
