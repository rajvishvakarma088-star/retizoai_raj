// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_calls, deprecated_member_use, unused_local_variable, strict_top_level_inference, use_super_parameters, library_private_types_in_public_api
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
void showCustomToast({
  required BuildContext context,
  required String message,
  Color? backgroundColor,
  Color textColor = Colors.white,
  IconData? icon,
  Duration duration = const Duration(seconds: 5),
}) {
  // Create overlay entry
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: Platform.isIOS ? 15 : 10,
      left: Platform.isIOS ? 15 : 10,
      right: Platform.isIOS ? 15 : 10,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToastWidget(
            message: message,
            backgroundColor: backgroundColor ?? GlobalAppColor.AvailableCode,
            textColor: textColor,
            icon: icon ?? Icons.check_circle,
            onClose: () => overlayEntry.remove(),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // Auto dismiss
  Future.delayed(duration, () {
    if (overlayEntry.mounted) overlayEntry.remove();
  });
}

class ToastWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final VoidCallback onClose;

  const ToastWidget({
    Key? key,
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.onClose,
  }) : super(key: key);

  @override
  _ToastWidgetState createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Mobile threshold
    final toastWidth = isSmallScreen
        ? screenWidth - 20
        : 400.0; // max width for larger screens
    return SafeArea(
      top: false,
      child: FadeTransition(
        opacity: _controller,
        child: Center(
          child: Container(
            width: toastWidth,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: widget.textColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.message,
                    style: CommonWidget.CommonTitleTextStyle(
                      color: widget.textColor,
                      fontSize: 13,
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  onTap: widget.onClose,
                  child: Icon(Icons.close, color: widget.textColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
