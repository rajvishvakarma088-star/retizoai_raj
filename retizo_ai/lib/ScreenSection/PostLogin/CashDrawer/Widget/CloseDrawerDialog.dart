// ignore_for_file: file_names, use_build_context_synchronously, unnecessary_import
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//-âœ…---------------------------------------------------------------------âœ…-//
class CloseDrawerDialog {
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  Entry point â€” delegates to _CloseDrawerBody (StatefulWidget).
  //
  //  WHY StatefulWidget instead of StatefulBuilder:
  //  TextEditingControllers must survive the dismiss animation. Flutter calls
  //  State.dispose() only after the widget is fully removed from the render
  //  tree (after all animations). StatefulBuilder + Future.microtask() races
  //  with LayoutBuilder layout callbacks that fire during the animation,
  //  causing "_dependents.isEmpty" assertion failures in production.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> show(BuildContext outerCtx) async {
    await showDialog(
      context: outerCtx,
      barrierDismissible: false,
      builder: (_) => _CloseDrawerBody(outerCtx: outerCtx),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> _showClosedSummary(
    BuildContext context,
    CashDrawerProvider drawerCtrl,
  ) async {
    if (!context.mounted) return;
    final drawer = drawerCtrl.currentDrawer;
    if (drawer == null) return;

    final double openingAmt = double.tryParse(drawer.openingAmt ?? '0') ?? 0.0;
    final double cashCollected =
        double.tryParse(drawer.cashCollected ?? '0') ?? 0.0;
    final double pettyOut = double.tryParse(drawer.pettyAmtOut ?? '0') ?? 0.0;
    final double expected =
        double.tryParse(drawer.expectedClosingAmt ?? '0') ?? 0.0;
    final double counted =
        double.tryParse(drawer.countedClosingAmt ?? '0') ?? 0.0;
    final double netDiff = counted - expected;

    // Timing strings
    String openTime = 'N/A';
    String closeTime = 'N/A';
    String sessionDuration = 'N/A';
    try {
      if (drawer.pDate != null) {
        final openDt = DateTime.parse(drawer.pDate!).toLocal();
        openTime = GlobalFunction().formatOrderDate(drawer.pDate);
        if (drawer.closedAt != null) {
          final closeDt = DateTime.parse(drawer.closedAt!).toLocal();
          closeTime = GlobalFunction().formatOrderDate(drawer.closedAt);
          final dur = closeDt.difference(openDt);
          final h = dur.inHours;
          final m = dur.inMinutes % 60;
          final s = dur.inSeconds % 60;
          sessionDuration = '${h}h ${m}m ${s}s';
        }
      }
    } catch (_) {}

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final sw = MediaQuery.of(ctx).size.width;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: sw > 600 ? (sw - 540) / 2 : 16,
            vertical: 24,
          ),
          child: Container(
            width: sw > 600 ? 540 : sw - 32,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // â”€â”€ Title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            size: 26,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Today's Drawer Has Been Closed",
                          textAlign: TextAlign.center,
                          style: CommonWidget.CommonTitleTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "The cash drawer session for today has been closed. No further transactions can be processed until a new drawer is opened or reopen.",
                          textAlign: TextAlign.center,
                          style: CommonWidget.CommonTitleTextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // â”€â”€ Session Summary â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Today's Session Summary",
                              style: CommonWidget.CommonTitleTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              _summaryTile(
                                'Opening Amount',
                                _money(openingAmt),
                              ),
                              _divider(),
                              _summaryTile(
                                'Cash Collected from Orders',
                                _money(cashCollected),
                                valueColor: Colors.green.shade600,
                              ),
                              _divider(),
                              _summaryTile(
                                'Petty Cash Out',
                                _money(pettyOut),
                                valueColor: Colors.red.shade600,
                              ),
                              _divider(),
                              _summaryTile(
                                'Expected Closing Amount',
                                _money(expected),
                                valueColor: Colors.blue.shade700,
                              ),
                              _divider(),
                              _summaryTile(
                                'Counted Closing Amount',
                                _money(counted),
                                valueColor: Colors.blue.shade700,
                              ),
                              _divider(),
                              _summaryTile(
                                'Net Difference (${netDiff >= 0 ? 'Surplus' : 'Shortage'})',
                                _signedMoney(netDiff),
                                valueColor: netDiff >= 0
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // â”€â”€ Timing â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_outlined,
                              size: 13,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Timing Information',
                              style: CommonWidget.CommonTitleTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              _summaryTile('Opening Time', openTime),
                              _divider(),
                              _summaryTile(
                                'Closing Time',
                                closeTime,
                                valueColor: GlobalAppColor.DarkBlueColor,
                              ),
                              _divider(),
                              _summaryTile(
                                'Session Duration',
                                sessionDuration,
                                valueColor: GlobalAppColor.ButtonDarkColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // â”€â”€ Buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlobalAppColor.ButtonColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'I Understand',
                              style: CommonWidget.CommonTitleTextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.bar_chart, size: 15),
                            label: Text(
                              'Report',
                              style: CommonWidget.CommonTitleTextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: GlobalAppColor.DarkBlueColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  Small widget helpers
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // â”€â”€ Currency helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Formats a monetary value with the Saudi Riyal sign (ï·¼) + non-breaking space.
  static String _money(double v) => '\uFDFC\u00A0${v.toStringAsFixed(2)}';

  /// Like [_money] but prefixes a +/âˆ’ sign for difference amounts.
  static String _signedMoney(double v) =>
      '${v >= 0 ? '+' : '\u2212'}\uFDFC\u00A0${v.abs().toStringAsFixed(2)}';

  static Widget _badge(String text, Color bg, Color border, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: CommonWidget.CommonTitleTextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static Widget _fieldLabel(String label) => Text(
    label,
    style: CommonWidget.CommonTitleTextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
  );

  static Widget _amountField(
    TextEditingController ctrl,
    String hint,
    void Function(void Function()) setDialogState,
  ) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        hintText: hint,
        // ðŸ”¹ prefixIcon is ALWAYS rendered regardless of focus state,
        //    unlike prefix/prefixText which only show when the field is active.
        prefixIcon: SizedBox(
          width: 44,
          child: Center(
            child: Text(
              '\uFDFC', // ï·¼ Saudi Riyal sign â€” always visible
              style: CommonWidget.CommonTitleTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: GlobalAppColor.DarkBlueColor,
              ),
            ),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: GlobalAppColor.DarkBlueColor,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (_) => setDialogState(() {}),
    );
  }

  static Widget _summaryTile(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: CommonWidget.CommonTitleTextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: CommonWidget.CommonTitleTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _divider() => Divider(height: 1, color: Colors.grey.shade200);
}

//-✅---------------------------------------------------------------------✅-//
//  Dialog body as a proper StatefulWidget.
//
//  WHY StatefulWidget:
//  TextEditingControllers must survive the dialog's dismiss animation.
//  Flutter calls State.dispose() only after the widget is fully detached from
//  the render tree — which happens AFTER animations complete. Any earlier
//  disposal (Future.microtask, addPostFrameCallback, etc.) can race with
//  LayoutBuilder's layout-phase rebuilds that fire during the animation,
//  causing "_dependents.isEmpty" assertion failures in production.
//-✅---------------------------------------------------------------------✅-//
class _CloseDrawerBody extends StatefulWidget {
  final BuildContext outerCtx;
  const _CloseDrawerBody({required this.outerCtx});

  @override
  State<_CloseDrawerBody> createState() => _CloseDrawerBodyState();
}

class _CloseDrawerBodyState extends State<_CloseDrawerBody> {
  late final TextEditingController cashInCtrl;
  late final TextEditingController cashOutCtrl;
  late final TextEditingController countedCtrl;
  late final double _openingAmt;
  late final double _cashCollected;
  late final int? _drawerId;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    final drawer = Provider.of<CashDrawerProvider>(
      widget.outerCtx,
      listen: false,
    ).currentDrawer;
    _openingAmt = double.tryParse(drawer?.openingAmt ?? '0') ?? 0.0;
    _cashCollected = double.tryParse(drawer?.cashCollected ?? '0') ?? 0.0;
    _drawerId = drawer?.cdId;
    final preIn = double.tryParse(drawer?.pettyAmtIn ?? '0') ?? 0.0;
    final preOut = double.tryParse(drawer?.pettyAmtOut ?? '0') ?? 0.0;
    final preCounted = double.tryParse(drawer?.countedClosingAmt ?? '0') ?? 0.0;
    cashInCtrl = TextEditingController(
      text: preIn > 0 ? preIn.toStringAsFixed(2) : '',
    );
    cashOutCtrl = TextEditingController(
      text: preOut > 0 ? preOut.toStringAsFixed(2) : '',
    );
    countedCtrl = TextEditingController(
      text: preCounted > 0 ? preCounted.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    cashInCtrl.dispose();
    cashOutCtrl.dispose();
    countedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double pettyIn = double.tryParse(cashInCtrl.text) ?? 0.0;
    final double pettyOut = double.tryParse(cashOutCtrl.text) ?? 0.0;
    final double counted = double.tryParse(countedCtrl.text) ?? 0.0;
    final double expected = _openingAmt + _cashCollected + pettyIn - pettyOut;
    final double diff = counted - expected;
    final double sw = MediaQuery.of(context).size.width;
    final String stepLabel = _step == 0
        ? 'Closing Process'
        : 'Review & Confirm';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: sw > 600 ? (sw - 540) / 2 : 16,
        vertical: 24,
      ),
      child: Container(
        width: sw > 600 ? 540 : sw - 32,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              color: GlobalAppColor.DarkBlueColor.withOpacity(0.04),
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: GlobalAppColor.DarkBlueColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Symbols.lock,
                      color: GlobalAppColor.DarkBlueColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Close Drawer',
                      style: CommonWidget.CommonTitleTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: GlobalAppColor.DarkBlueColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    color: Colors.grey.shade600,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Badges
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  if (_drawerId != null) ...[
                    CloseDrawerDialog._badge(
                      'ID: $_drawerId',
                      GlobalAppColor.DarkBlueColor.withOpacity(0.08),
                      GlobalAppColor.DarkBlueColor.withOpacity(0.25),
                      GlobalAppColor.DarkBlueColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  CloseDrawerDialog._badge(
                    stepLabel,
                    Colors.orange.withOpacity(0.08),
                    Colors.orange.withOpacity(0.25),
                    Colors.orange.shade700,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _step == 0
                    ? _buildStep0()
                    : _buildStep1(pettyIn, pettyOut, counted, expected, diff),
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Consumer<CashDrawerProvider>(
                builder: (consumerCtx, dc, _) {
                  if (_step == 0) {
                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: Colors.grey.shade50,
                            ),
                            child: Text(
                              'Cancel',
                              style: CommonWidget.CommonTitleTextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              if (countedCtrl.text.trim().isEmpty) {
                                GlobalFunction().showError(
                                  context,
                                  'Please enter counted closing cash',
                                );
                                return;
                              }
                              setState(() => _step = 1);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlobalAppColor.DarkBlueColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 1,
                              shadowColor:
                                  GlobalAppColor.DarkBlueColor.withOpacity(0.3),
                            ),
                            child: Text(
                              'Next  \u00bb',
                              style: CommonWidget.CommonTitleTextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => setState(() => _step = 0),
                              child: Text(
                                'Back',
                                style: CommonWidget.CommonTitleTextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Cancel',
                                style: CommonWidget.CommonTitleTextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: dc.isDrawerLoading
                                    ? null
                                    : () async {
                                        final ci = cashInCtrl.text.trim();
                                        final co = cashOutCtrl.text.trim();
                                        final cc = countedCtrl.text.trim();
                                        final ok = await dc.saveDrawerState(
                                          consumerCtx,
                                          cashIn: ci.isEmpty ? '0' : ci,
                                          cashOut: co.isEmpty ? '0' : co,
                                          countedClosingCash: cc,
                                        );
                                        if (ok && context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      },
                                icon: const Icon(
                                  Icons.save_outlined,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Save Only',
                                  style: CommonWidget.CommonTitleTextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GlobalAppColor.DarkBlueColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: dc.isDrawerLoading
                                    ? null
                                    : () async {
                                        final ci = cashInCtrl.text.trim();
                                        final co = cashOutCtrl.text.trim();
                                        final cc = countedCtrl.text.trim();
                                        final ok = await dc.closeDrawer(
                                          consumerCtx,
                                          cashIn: ci.isEmpty ? '0' : ci,
                                          cashOut: co.isEmpty ? '0' : co,
                                          countedClosingCash: cc,
                                        );
                                        if (ok && context.mounted) {
                                          Navigator.of(context).pop();
                                          if (widget.outerCtx.mounted) {
                                            await CloseDrawerDialog._showClosedSummary(
                                              widget.outerCtx,
                                              dc,
                                            );
                                          }
                                        }
                                      },
                                icon: dc.isDrawerLoading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.print_outlined,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                label: Text(
                                  'Print & Close',
                                  style: CommonWidget.CommonTitleTextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Opening Amount',
              style: CommonWidget.CommonTitleTextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              CloseDrawerDialog._money(_openingAmt),
              style: CommonWidget.CommonTitleTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(
              Icons.description_outlined,
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              'Enter Petty Cash Details (Override Mode)',
              style: CommonWidget.CommonTitleTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.info_outlined, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Note: These fields show existing drawer petty amounts. Editing will override existing values.',
                  style: CommonWidget.CommonTitleTextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (_, lc) {
            final useTwoCol = lc.maxWidth > 260;
            if (useTwoCol) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CloseDrawerDialog._fieldLabel('Petty Cash In (SAR)'),
                        const SizedBox(height: 6),
                        CloseDrawerDialog._amountField(
                          cashInCtrl,
                          '0.00',
                          setState,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CloseDrawerDialog._fieldLabel('Petty Cash Out (SAR)'),
                        const SizedBox(height: 6),
                        CloseDrawerDialog._amountField(
                          cashOutCtrl,
                          '0.00',
                          setState,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Max: ${CloseDrawerDialog._money(_openingAmt)}',
                          style: CommonWidget.CommonTitleTextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CloseDrawerDialog._fieldLabel('Petty Cash In (SAR)'),
                const SizedBox(height: 6),
                CloseDrawerDialog._amountField(cashInCtrl, '0.00', setState),
                const SizedBox(height: 12),
                CloseDrawerDialog._fieldLabel('Petty Cash Out (SAR)'),
                const SizedBox(height: 6),
                CloseDrawerDialog._amountField(cashOutCtrl, '0.00', setState),
                const SizedBox(height: 4),
                Text(
                  'Max: ${CloseDrawerDialog._money(_openingAmt)}',
                  style: CommonWidget.CommonTitleTextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            CloseDrawerDialog._fieldLabel('Counted Closing Cash (SAR)'),
            const SizedBox(width: 4),
            Tooltip(
              message: 'Physical cash you counted in the drawer',
              child: Icon(Icons.help_outline, size: 13, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 6),
        CloseDrawerDialog._amountField(
          countedCtrl,
          'Enter counted amount',
          setState,
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildStep1(
    double pettyIn,
    double pettyOut,
    double counted,
    double expected,
    double diff,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 15,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Closing Summary (Override Mode)',
                      style: CommonWidget.CommonTitleTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              CloseDrawerDialog._summaryTile(
                'Opening Amount',
                CloseDrawerDialog._money(_openingAmt),
              ),
              CloseDrawerDialog._divider(),
              CloseDrawerDialog._summaryTile(
                'Cash Collected',
                CloseDrawerDialog._money(_cashCollected),
                valueColor: Colors.green.shade600,
              ),
              CloseDrawerDialog._divider(),
              CloseDrawerDialog._summaryTile(
                'Petty Cash In',
                CloseDrawerDialog._money(pettyIn),
                valueColor: Colors.green.shade600,
              ),
              CloseDrawerDialog._divider(),
              CloseDrawerDialog._summaryTile(
                'Petty Cash Out',
                CloseDrawerDialog._money(pettyOut),
                valueColor: Colors.red.shade600,
              ),
              CloseDrawerDialog._divider(),
              CloseDrawerDialog._summaryTile(
                'Expected Closing Cash',
                CloseDrawerDialog._money(expected),
                valueColor: Colors.blue.shade700,
              ),
              CloseDrawerDialog._divider(),
              CloseDrawerDialog._summaryTile(
                'Counted Closing Cash',
                CloseDrawerDialog._money(counted),
              ),
              CloseDrawerDialog._divider(),
              CloseDrawerDialog._summaryTile(
                'Difference (Over/Short)',
                CloseDrawerDialog._signedMoney(diff),
                valueColor: diff >= 0
                    ? Colors.green.shade600
                    : Colors.red.shade600,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
