// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, strict_top_level_inference, avoid_web_libraries_in_flutter, unnecessary_import, curly_braces_in_flow_control_structures, dead_code

import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅-InternetStatusHandler-----------------------------------------------✅-//
class InternetStatusHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback? onInternetReconnect;

  const InternetStatusHandler({
    super.key,
    required this.child,
    this.onInternetReconnect,
  });

  @override
  State<InternetStatusHandler> createState() => _InternetStatusHandlerState();
}

class _InternetStatusHandlerState extends State<InternetStatusHandler>
    with WidgetsBindingObserver {
  bool _wasPreviouslyConnected = true;
  OverlayEntry? _currentOverlay;
  late CheckInternetProvider _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _provider = context.read<CheckInternetProvider>();

    // Listen to connectivity changes
    _provider.addListener(_handleConnectivityChange);

    // Check initial status after first frame
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkInitialInternet(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _provider.removeListener(_handleConnectivityChange);
    _removeCurrentOverlay();
    super.dispose();
  }

  void _handleConnectivityChange() {
    if (!mounted) return;

    final isConnected = _provider.isConnected;

    if (!isConnected && _wasPreviouslyConnected) {
      _wasPreviouslyConnected = false;
      _showCustomOverlay(
        messageKey: "NotConnected",
        backgroundColor: GlobalAppColor.RedCode,
        showConnect: true,
      );
    } else if (isConnected && !_wasPreviouslyConnected) {
      _wasPreviouslyConnected = true;
      _showCustomOverlay(
        messageKey: "InternetReConnected",
        backgroundColor: GlobalAppColor.AvailableCode,
        showConnect: false,
      );
      if (widget.onInternetReconnect != null) widget.onInternetReconnect!();
    }
  }

  void _checkInitialInternet() {
    final initialStatus = _provider.initialStatus;
    if (initialStatus == null) return; // wait until provider updates
    _wasPreviouslyConnected = initialStatus;

    if (!initialStatus) {
      _showCustomOverlay(
        messageKey: "NotConnected",
        backgroundColor: GlobalAppColor.RedCode,
        showConnect: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckInternetProvider>(
      builder: (context, provider, child) {
        // Ensure initial connectivity check
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkInitialInternet();
        });
        return SafeArea(top: false, child: widget.child);
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _handleConnectivityChange();
  }

  void _showCustomOverlay({
    required String messageKey,
    required Color backgroundColor,
    bool showConnect = false,
  }) {
    _removeCurrentOverlay();

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final overlayWidth = screenWidth < 600 ? screenWidth - 20 : 400.0;
    final horizontalMargin = screenWidth < 600
        ? 10.0
        : (screenWidth - overlayWidth) / 2;

    // 👇 AppLocalizations हटा दिया गया है
    String translatedMessage = "";
    if (messageKey == "NotConnected") {
      translatedMessage = GlobalFlag.NotConnected;
    } else if (messageKey == "InternetReConnected") {
      translatedMessage = GlobalFlag.InternetReConnected;
    }

    _currentOverlay = OverlayEntry(
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return Positioned(
          bottom: bottomPadding + 10,
          left: horizontalMargin,
          right: horizontalMargin,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    showConnect ? Icons.wifi_off : Icons.wifi,
                    color: Colors.white,
                    size: 35,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      translatedMessage,
                      style: CommonWidget.CommonTitleTextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (showConnect)
                    InkWell(
                      overlayColor: MaterialStateProperty.all(
                        Colors.transparent,
                      ),
                      onTap: () async {
                        _removeCurrentOverlay();
                        await _provider.openDeviceInternetSettings();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white38,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          GlobalFlag.Close,
                          style: CommonWidget.CommonTitleTextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
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

    overlay.insert(_currentOverlay!);

    if (!showConnect) {
      Future.delayed(const Duration(seconds: 5), _removeCurrentOverlay);
    }
  }

  void _removeCurrentOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

//-✅---------------------------------------------------------------------✅-//
