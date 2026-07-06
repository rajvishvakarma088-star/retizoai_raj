// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, unused_element
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:culai/ScreenSection/PostLogin/AddNewOrder/Widget/CashAmount.dart';
import 'package:culai/ScreenSection/PostLogin/HomeScreen/Model/MultiPaymentEntry.dart';
import 'package:culai/ScreenSection/PostLogin/HomeScreen/Model/PaymentMethodsPayBillModel.dart';
import 'package:culai/ScreenSection/PostLogin/AddNewOrder/Model/NoteModel.dart';
import 'package:culai/ScreenSection/PostLogin/KDS/Controller/PrinterIntegrationProvider.dart';
import 'package:culai/services/printer_models.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

//-✅---------------------------------------------------------------------✅-//
class HomeWidget {
  bool isValid(dynamic value) {
    if (value == null) return false;
    final str = value.toString().trim();
    return str.isNotEmpty && str != "0.00" && str != "0.0" && str != "0";
  }

  String _tableDisplayNameFromMetadata(BuildContext context, OrderData order) {
    if (order.tableName != 'N/A' && order.tableName.trim().isNotEmpty) {
      return order.tableName;
    }
    if (order.tableId > 0) {
      final tables = context.read<AddOrderProvider>().OrderTableListing;
      final matches = tables.where((table) => table.tableID == order.tableId);
      if (matches.isNotEmpty &&
          matches.first.tableName != 'N/A' &&
          matches.first.tableName.trim().isNotEmpty) {
        return matches.first.tableName;
      }
      return 'T${order.tableId.toString().padLeft(2, '0')}';
    }
    return 'N/A';
  }

  String _nullableTableDisplayNameFromMetadata(
    BuildContext context,
    OrderData? order,
  ) {
    if (order == null) return 'N/A';
    return _tableDisplayNameFromMetadata(context, order);
  }

  bool _isPremiumTable(BuildContext context, OrderData order) {
    if (order.tableCharge > 0) return true;
    // Handle both 'Dine In' (app-created) and 'dine-in' (web-created) order types.
    if (!order.type.toLowerCase().contains('dine') || order.tableId <= 0) {
      return false;
    }
    final tables = context.read<AddOrderProvider>().OrderTableListing;
    final matches = tables.where((table) => table.tableID == order.tableId);
    return matches.isNotEmpty && matches.first.isPremium;
  }

  //-✅---------------------------------------------------------------------✅-//
  Widget _buildChip(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  //-✅---------------------------------------------------------------------✅-//
  Widget buildTag(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: CommonWidget.CommonTitleTextStyle(color: textColor),
      ),
    );
  }

  //-✅---------------------------------------------------------------------✅-//
  Widget buildAmountRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.start,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: CommonWidget.CommonTitleTextStyle(
                color: color ?? GlobalAppColor.HomeLightTextColor,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: isBold ? 15 : 15,
              ),
            ),
          ),
          buildIconValueRow(value, color: color, isBold: isBold),
        ],
      ),
    );
  }

  //-✅---------------------------------------------------------------------✅-//
  Widget buildIconValueRow(String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          textAlign: TextAlign.start,
          maxLines: 1,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: CommonWidget.CommonTitleTextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 15 : 14,
            color: color ?? const Color(0xFF374151),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Symbols.credit_card, color: Color(0xFF374151), size: 18),
      ],
    );
  }

  //-✅---------------------------------------------------------------------✅-//
  /// Builds a compact payment breakdown panel for PAID orders.
  /// Mirrors the web app's green "Payment Information" section on the order card.
  /// Data priority: payments[] array → cashout/cardout fields → paymentMethodName fallback.
  /// ✅ UPDATED: Now shows for BOTH 'paid' and 'partial' orders
  Widget buildPaymentBreakdown(OrderData item) {
    final status = item.paymentStatus.toLowerCase();

    // ✅ Show payment breakdown for both 'paid' and 'partial' orders
    if (status != 'paid' && status != 'partial') {
      return const SizedBox.shrink();
    }

    final List<Map<String, dynamic>> rows = [];

    // Primary: use payments[] from API (multi-payment / partial-completion support)
    if (item.payments.isNotEmpty) {
      for (final p in item.payments) {
        if (p.amount > 0) {
          rows.add({
            'label': p.methodName.isEmpty ? 'Payment' : p.methodName,
            'amount': p.amount,
          });
        }
      }
    }

    // Special case: single generic "Split Payment" entry — use cashout/cardout for detailed breakdown
    if (rows.length == 1) {
      final entryLabel = (rows.first['label'] as String).toUpperCase();
      if (entryLabel == 'SPLIT PAYMENT' || entryLabel == 'SPLIT') {
        final cash = double.tryParse(item.cashout) ?? 0.0;
        final card = double.tryParse(item.cardout) ?? 0.0;
        if (cash > 0 && card > 0) {
          rows.clear();
          rows.add({'label': 'Cash', 'amount': cash});
          rows.add({'label': 'Card', 'amount': card});
        }
      }
    }

    // Fallback: cashout / cardout fields (simple pay-bill flow)
    if (rows.isEmpty) {
      final cash = double.tryParse(item.cashout) ?? 0.0;
      final card = double.tryParse(item.cardout) ?? 0.0;
      // Use specific method name for card if available (e.g. "Visa Card", "STC Pay")
      final specificCardName =
          (item.paymentMethodName != 'N/A' &&
              item.paymentMethodName.isNotEmpty &&
              card > 0 &&
              cash == 0)
          ? item.paymentMethodName
          : 'Card';
      if (cash > 0) rows.add({'label': 'Cash', 'amount': cash});
      if (card > 0) rows.add({'label': specificCardName, 'amount': card});
      // Last resort: payment method name with grand total
      if (rows.isEmpty &&
          item.paymentMethodName != 'N/A' &&
          item.paymentMethodName.isNotEmpty) {
        rows.add({'label': item.paymentMethodName, 'amount': item.grandTotal});
      }
    }

    // ✅ For partial orders, show even if no payment methods breakdown
    // (we'll show Total Paid and Remaining Balance)
    final isPartial = status == 'partial';
    if (!isPartial && rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final label = isPartial ? 'PARTIAL' : item.paymentTypeLabel;
    final Color labelBg;
    // label may be 'SPLIT', 'SPLIT PAYMENT', or parent method name containing SPLIT
    if (label.contains('SPLIT')) {
      labelBg = const Color(0xFF0284C7); // sky-600
    } else if (label == 'MULTI') {
      labelBg = const Color(0xFF7C3AED); // violet-600
    } else if (label == 'PARTIAL') {
      labelBg = const Color(0xFFF59E0B); // amber-500 (matches web app)
    } else {
      labelBg = const Color(0xFF059669); // emerald-600
    }

    // ✅ Calculate totals for partial orders
    final totalPaid = item.totalPaidAmount;
    final remainingBalance = item.remainingBalance;
    final grandTotal = item.fullPayableTotal;

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isPartial
            ? const Color(0xFFFFFBEB)
            : const Color(
                0xFFF0FDF4,
              ), // amber-50 for partial, green-50 for paid
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPartial
              ? const Color(0xFFFDE68A)
              : const Color(
                  0xFFBBF7D0,
                ), // amber-200 for partial, green-200 for paid
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: labelBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label.isEmpty ? 'PAID' : label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isPartial ? 'Partial Payment' : 'Payment Breakdown',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPartial
                        ? const Color(0xFF78350F)
                        : const Color(
                            0xFF065F46,
                          ), // amber-900 for partial, green-900 for paid
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // ✅ Show individual payment methods (if available)
          if (rows.isNotEmpty) ...[
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        row['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isPartial
                              ? const Color(0xFF92400E)
                              : const Color(
                                  0xFF047857,
                                ), // amber-800 for partial
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'SAR ${(row['amount'] as double).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isPartial
                            ? const Color(0xFF78350F)
                            : const Color(0xFF065F46), // amber-900 for partial
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isPartial)
              const Divider(
                height: 12,
                thickness: 0.5,
                color: Color(0xFFFDE68A),
              ), // amber-200
          ],

          // ✅ For partial orders: Show Total Paid and Remaining Balance (like web app)
          if (isPartial) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Total Paid:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF059669), // green-700
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'SAR ${totalPaid.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF047857), // green-800
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Remaining Balance:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDC2626), // red-600
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'SAR ${remainingBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFB91C1C), // red-700
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  //-✅---------------------------------------------------------------------✅-//
  /// Payment breakdown panel for FULLY CANCELLED orders.
  /// Shows how the customer originally paid (payment methods + amounts).
  Widget buildCancelledPaymentBreakdown(OrderData item) {
    final totalPaid = item.totalPaidAmount;
    if (totalPaid <= 0) return const SizedBox.shrink();

    final List<Map<String, dynamic>> rows = [];
    if (item.payments.isNotEmpty) {
      for (final p in item.payments) {
        if (p.amount > 0) {
          rows.add({
            'label': p.methodName.isEmpty ? 'Payment' : p.methodName,
            'amount': p.amount,
          });
        }
      }
    }
    if (rows.length == 1) {
      final entryLabel = (rows.first['label'] as String).toUpperCase();
      if (entryLabel == 'SPLIT PAYMENT' || entryLabel == 'SPLIT') {
        final cash = double.tryParse(item.cashout) ?? 0.0;
        final card = double.tryParse(item.cardout) ?? 0.0;
        if (cash > 0 && card > 0) {
          rows.clear();
          rows.add({'label': 'Cash', 'amount': cash});
          rows.add({'label': 'Card', 'amount': card});
        }
      }
    }
    if (rows.isEmpty) {
      final cash = double.tryParse(item.cashout) ?? 0.0;
      final card = double.tryParse(item.cardout) ?? 0.0;
      final specificCardName =
          (item.paymentMethodName != 'N/A' &&
              item.paymentMethodName.isNotEmpty &&
              card > 0 &&
              cash == 0)
          ? item.paymentMethodName
          : 'Card';
      if (cash > 0) rows.add({'label': 'Cash', 'amount': cash});
      if (card > 0) rows.add({'label': specificCardName, 'amount': card});
      if (rows.isEmpty &&
          item.paymentMethodName != 'N/A' &&
          item.paymentMethodName.isNotEmpty) {
        rows.add({'label': item.paymentMethodName, 'amount': totalPaid});
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'PAYMENT BREAKDOWN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      row['label'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'SAR ${(row['amount'] as double).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF065F46),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //-✅---------------------------------------------------------------------✅-//
  /// Refund amount panel for FULLY CANCELLED orders.
  /// Shows the total refund amount (what the customer will receive back).
  Widget buildCancelledRefundAmount(OrderData item) {
    final totalPaid = item.totalPaidAmount;
    if (totalPaid <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'REFUND AMOUNT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Total Refund:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'SAR ${totalPaid.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7F1D1D),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //-✅---------------------------------------------------------------------✅-//
  Widget buildDropdown({
    required List<String> items,
    required String? value,
    Function(String)? onChanged,
    bool showTextLeft = false, // optional
    bool showIconRight = true, // optional
    final TextStyle? hintStyle,
    final TextStyle? itemStyle,
    final BoxDecoration? decoration,
    final double? iconPadding,
    final String? hintText,
  }) {
    return SizedBox(
      height: 40,
      child: CommonDropdown(
        decoration: decoration,
        enabled: true,
        IconSize: 20,
        dropDownHeight: 40,
        textPadding: const EdgeInsets.symmetric(horizontal: 6.0),
        hintText: hintText ?? GlobalFlag.SelectValue,
        removeDropdownBorder: false,
        selectedValue: value,
        items: items,
        iconPadding: iconPadding,
        onChanged: (String? v) {
          if (v != null && onChanged != null) onChanged(v); // check null
        },
        hintStyle:
            hintStyle ??
            CommonWidget.CommonTitleTextStyle(
              color: GlobalAppColor.DarkTextColorCode.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
        itemStyle:
            itemStyle ??
            CommonWidget.CommonTitleTextStyle(
              color: GlobalAppColor.DarkTextColorCode.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
        textIconSpacing: EdgeInsets.zero,
        textIconAlignment: MainAxisAlignment.spaceBetween,
        showTextLeft: showTextLeft,
        // pass to CommonDropdown
        showIconRight: showIconRight, // pass to CommonDropdown
      ),
    );
  }

  //-✅---------------------------------------------------------------------✅-//
  Widget buildIconButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(child: Icon(icon, color: color, size: 20)),
      ),
    );
  }

  //-✅--OrderListWidget-------------------------------------------------✅-//
  Widget OrderListWidget(
    BuildContext context,
    List<OrderData> data,
    HomeProvider HomeCtrl,
  ) {
    const double itemSize = 50.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // 🔹 Responsive items per row
        int itemsPerRow;
        if (screenWidth < 600) {
          itemsPerRow = 1; // mobile
        } else if (screenWidth < 1000) {
          itemsPerRow = 2; // tablet
        } else {
          itemsPerRow = 3; // desktop / web
        }

        final rowCount = (data.length / itemsPerRow).ceil();

        return ListView.separated(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 100,
            left: 8,
            right: 8,
          ),
          itemCount: rowCount,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, rowIndex) {
            List<Widget> rowItems = [];
            for (int i = 0; i < itemsPerRow; i++) {
              if (rowIndex >= rowCount) {
                return const SizedBox.shrink(); // Out of bounds check
              }
              final itemIndex = rowIndex * itemsPerRow + i;
              if (itemIndex < data.length) {
                final item = data[itemIndex];
                // 🔹 DropdownOne value
                String selectedOneValue =
                    item.selectedDropDownOne ??
                    HomeCtrl.DropDownOne.firstWhere(
                      (e) =>
                          e.title!.toLowerCase() ==
                          item.orderStatus.toLowerCase(),
                      orElse: () => HomeCtrl.DropDownOne[0],
                    ).title!;

                // 🔹 DropdownOne value
                String selectedTwoValue =
                    item.selectedDropDownTwo ??
                    HomeCtrl.DropDownTwo.firstWhere(
                      (e) =>
                          e.title!.toLowerCase() == item.priority.toLowerCase(),
                      orElse: () => HomeCtrl.DropDownTwo[0],
                    ).title!;

                // ✅ Prepared items ring — matches web app hasPreparedItems logic
                final bool hasPreparedItems = item.details.any(
                  (d) => d.status.toLowerCase() == 'prepared',
                );

                rowItems.add(
                  Expanded(
                    child: AnimationLimiter(
                      child: CommonWidget().buildStaggeredAnimation(
                        index: rowIndex,
                        child: IntrinsicHeight(
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: hasPreparedItems
                                    ? const Color(0xFFF9A8D4)
                                    : const Color(0xFFE2E8F0),
                                width: hasPreparedItems ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  // ── Header band ──────────────────────────
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hasPreparedItems
                                          ? const Color(0xFFFFF1F5)
                                          : const Color(0xFFF9FAFB),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(13),
                                        topRight: Radius.circular(13),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Order number
                                        Text(
                                          "#${item.orderNo.toString().padLeft(4, '0')}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: Color(0xFF111827),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // ✅ Group parent badge
                                        if (item.isGroup)
                                          _buildChip(
                                            'Grouped',
                                            const Color(0xFF7C3AED),
                                            const Color(0xFFEDE9FE),
                                          )
                                        else if (item.groupId != 0 &&
                                            item.groupId != item.orderId)
                                          _buildChip(
                                            'With #${item.groupId.toString().padLeft(4, '0')}',
                                            const Color(0xFFD97706),
                                            const Color(0xFFFEF3C7),
                                          ),
                                        const Spacer(),
                                        // Status badge
                                        HomeWidget().buildTag(
                                          item.orderStatus[0].toUpperCase() +
                                              item.orderStatus
                                                  .substring(1)
                                                  .toLowerCase(),
                                          getStatusColor(item.orderStatus),
                                          getStatusBgColor(item.orderStatus),
                                        ),
                                        // Priority badge (non-normal only)
                                        if (item.priority.toLowerCase() !=
                                                'normal' &&
                                            item.priority != 'N/A') ...[
                                          const SizedBox(width: 6),
                                          HomeWidget().buildTag(
                                            item.priority[0].toUpperCase() +
                                                item.priority
                                                    .substring(1)
                                                    .toLowerCase(),
                                            getPriorityColor(item.priority),
                                            getPriorityBgColor(item.priority),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // ── Body ─────────────────────────────────
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      10,
                                      12,
                                      0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ── Primary row: customer + amount ──
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.person_outline_rounded,
                                              size: 14,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                item.customer != 'N/A'
                                                    ? item.customer
                                                    : 'Guest Customer',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: Color(0xFF111827),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Payment status badge
                                            HomeWidget().buildTag(
                                              GlobalFunction()
                                                  .capitalizeEachPart(
                                                    item.paymentStatus,
                                                  ),
                                              getPriorityColor(
                                                item.paymentStatus,
                                              ),
                                              getPriorityBgColor(
                                                item.paymentStatus,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Grand total
                                            Text(
                                              "SAR ${item.calculatedTotalAmtStr}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        // ── Secondary row: type · table | time ──
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.table_restaurant_outlined,
                                              size: 12,
                                              color: Color(0xFFB0B8C8),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      "${GlobalFunction().capitalizeEachPart(item.type.toString())} · Table:",
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Color(
                                                          0xFF6B7280,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  if (_isPremiumTable(
                                                    context,
                                                    item,
                                                  ))
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 5,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFF8B5CF6,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .workspace_premium,
                                                            size: 10,
                                                            color: Colors.white,
                                                          ),
                                                          const SizedBox(
                                                            width: 2,
                                                          ),
                                                          Text(
                                                            _tableDisplayNameFromMetadata(
                                                              context,
                                                              item,
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  else
                                                    Flexible(
                                                      child: Text(
                                                        _tableDisplayNameFromMetadata(
                                                          context,
                                                          item,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Color(
                                                            0xFF6B7280,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 88,
                                              child: Builder(
                                                builder: (context) {
                                                  final raw = GlobalFunction()
                                                      .formatOrderDate(
                                                        item.orderDate.toString(),
                                                      );
                                                  final parts = raw.split(' | ');
                                                  final datePart = parts.isNotEmpty ? parts[0] : raw;
                                                  final timePart = parts.length > 1 ? parts[1] : '';
                                                  return Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        datePart,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Color(0xFF9CA3AF),
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                        textAlign: TextAlign.right,
                                                      ),
                                                      if (timePart.isNotEmpty)
                                                        Text(
                                                          timePart,
                                                          style: const TextStyle(
                                                            fontSize: 10,
                                                            color: Color(0xFF9CA3AF),
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                          textAlign: TextAlign.right,
                                                        ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        // ── Inline payment breakdown text (mirrors web card) ──
                                        // Only shown for paid/partial orders, backend-driven from payments[]/cashout/cardout
                                        if (item.paymentStatus.toLowerCase() ==
                                                'paid' ||
                                            item.paymentStatus.toLowerCase() ==
                                                'partial') ...[
                                          Builder(
                                            builder: (context) {
                                              // Build breakdown rows using same priority as buildPaymentBreakdown
                                              final List<Map<String, dynamic>>
                                              pRows = [];
                                              if (item.payments.isNotEmpty) {
                                                for (final p in item.payments) {
                                                  if (p.amount > 0) {
                                                    pRows.add({
                                                      'label':
                                                          p.methodName.isEmpty
                                                          ? 'Payment'
                                                          : p.methodName,
                                                      'amount': p.amount,
                                                    });
                                                  }
                                                }
                                              }
                                              // Single generic "Split Payment" → decompose into Cash/Card
                                              if (pRows.length == 1) {
                                                final lbl =
                                                    (pRows.first['label']
                                                            as String)
                                                        .toUpperCase();
                                                if (lbl == 'SPLIT PAYMENT' ||
                                                    lbl == 'SPLIT') {
                                                  final cash =
                                                      double.tryParse(
                                                        item.cashout,
                                                      ) ??
                                                      0.0;
                                                  final card =
                                                      double.tryParse(
                                                        item.cardout,
                                                      ) ??
                                                      0.0;
                                                  if (cash > 0 && card > 0) {
                                                    pRows.clear();
                                                    pRows.add({
                                                      'label': 'Cash',
                                                      'amount': cash,
                                                    });
                                                    pRows.add({
                                                      'label': 'Card',
                                                      'amount': card,
                                                    });
                                                  }
                                                }
                                              }
                                              // Fallback to cashout/cardout fields
                                              if (pRows.isEmpty) {
                                                final cash =
                                                    double.tryParse(
                                                      item.cashout,
                                                    ) ??
                                                    0.0;
                                                final card =
                                                    double.tryParse(
                                                      item.cardout,
                                                    ) ??
                                                    0.0;
                                                if (cash > 0)
                                                  pRows.add({
                                                    'label': 'Cash',
                                                    'amount': cash,
                                                  });
                                                if (card > 0)
                                                  pRows.add({
                                                    'label': 'Card',
                                                    'amount': card,
                                                  });
                                                if (pRows.isEmpty &&
                                                    item.paymentMethodName !=
                                                        'N/A' &&
                                                    item
                                                        .paymentMethodName
                                                        .isNotEmpty) {
                                                  pRows.add({
                                                    'label':
                                                        item.paymentMethodName,
                                                    'amount': item.grandTotal,
                                                  });
                                                }
                                              }
                                              if (pRows.isEmpty)
                                                return const SizedBox.shrink();
                                              final typeLabel =
                                                  item.paymentStatus
                                                          .toLowerCase() ==
                                                      'partial'
                                                  ? 'PARTIAL'
                                                  : item.paymentTypeLabel;
                                              final detailStr = pRows
                                                  .map(
                                                    (r) =>
                                                        '${r['label']} ${(r['amount'] as double).toStringAsFixed(2)}',
                                                  )
                                                  .join(', ');
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 3,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      typeLabel.isEmpty
                                                          ? ''
                                                          : '$typeLabel ',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFF2563EB,
                                                        ),
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        '($detailStr)',
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Color(
                                                            0xFF6B7280,
                                                          ),
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                        // ── Note row (conditional) ──
                                        if (item.orderDes != null &&
                                            item.orderDes
                                                .toString()
                                                .trim()
                                                .isNotEmpty &&
                                            item.orderDes
                                                    .toString()
                                                    .trim()
                                                    .toLowerCase() !=
                                                "null") ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.notes_rounded,
                                                size: 12,
                                                color: Color(0xFFD1D5DB),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  GlobalFunction()
                                                      .capitalizeEachPart(
                                                        item.orderDes
                                                            .toString(),
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF9CA3AF),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        // ── Due / Refunded indicator ──
                                        if (item.paymentStatus.toLowerCase() !=
                                            'paid') ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFFBEB),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFFFDE68A),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.hourglass_top_rounded,
                                                  size: 11,
                                                  color: Color(0xFFD97706),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  "SAR ${item.remainingBalance.toStringAsFixed(2)} remaining",
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF92400E),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ] else if (item.hasRefund) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF2F2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFFFECACA),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.undo_rounded,
                                                  size: 11,
                                                  color: Color(0xFFEF4444),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  "Refunded SAR ${item.calculatedRefund.toStringAsFixed(2)}",
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFFDC2626),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ] else ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFFBBF7D0),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons
                                                      .check_circle_outline_rounded,
                                                  size: 11,
                                                  color: Color(0xFF059669),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  "Paid SAR ${item.calculatedTotalAmtStr}",
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF047857),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        const Divider(
                                          color: Color(0xFFE5E7EB),
                                          height: 1,
                                          thickness: 1,
                                        ),
                                        const SizedBox(height: 8),
                                        // ── Items section header ──
                                        Row(
                                          children: [
                                            const Text(
                                              "ITEMS",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF9CA3AF),
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                "${item.details.where((d) => d.itemType.toLowerCase() != 'modifier').length}",
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                    ),
                                  ),

                                  // ── Items list (flush padding) ────────────
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 🔹 Item Row — modifiers grouped under parent (matches web app)
                                        Column(
                                          children: item.details
                                              .where(
                                                (detail) =>
                                                    detail.itemType
                                                        .toLowerCase() !=
                                                    'modifier',
                                              )
                                              .map((detail) {
                                                final cancelledQty = (detail.cancelledQty > (detail.originalQty - detail.quantity))
                                                    ? detail.cancelledQty
                                                    : (detail.originalQty - detail.quantity);
                                                final isCancelled =
                                                    detail.status
                                                        .toLowerCase() ==
                                                    'cancelled';
                                                final unitPrice =
                                                    double.tryParse(
                                                      detail.rate.isNotEmpty &&
                                                              detail.rate != '0'
                                                          ? detail.rate
                                                          : detail.price,
                                                    ) ??
                                                    0.0;
                                                final quantity =
                                                    detail.quantity;
                                                final itemTotal =
                                                    double.tryParse(
                                                      detail.subtotal,
                                                    ) ??
                                                    0.0;
                                                // When the whole order is cancelled, suppress partial-cancel
                                                // indicators — show all items as fully cancelled
                                                final isOrderFullyCancelled =
                                                    item.orderStatus
                                                        .toLowerCase() ==
                                                    'cancelled';

                                                // ✅ Modifiers linked to this item
                                                // The server may return either:
                                                //   • numeric order_det_id as "link" → compare to orderDetId.toString()
                                                //   • original cart_uuid as "link"   → compare to detail.cartUuid
                                                final linkedMods = item.details
                                                    .where(
                                                      (d) =>
                                                          d.itemType
                                                                  .toLowerCase() ==
                                                              'modifier' &&
                                                          (d.link ==
                                                                  detail
                                                                      .orderDetId
                                                                      .toString() ||
                                                              (detail.cartUuid !=
                                                                      null &&
                                                                  d.link ==
                                                                      detail
                                                                          .cartUuid)),
                                                    )
                                                    .toList();

                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 6,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 9,
                                                        vertical: 7,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        (isCancelled &&
                                                                quantity ==
                                                                    0) ||
                                                            isOrderFullyCancelled
                                                        ? const Color(
                                                            0xFFFEF2F2,
                                                          )
                                                        : const Color(
                                                            0xFFFAFAFC,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          (isCancelled &&
                                                                  quantity ==
                                                                      0) ||
                                                              isOrderFullyCancelled
                                                          ? const Color(
                                                              0xFFFECACA,
                                                            )
                                                          : const Color(
                                                              0xFFE2E8F0,
                                                            ),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          /// LEFT SIDE (Product Name + Price + Quantity)
                                                          Expanded(
                                                            child: Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              children: [
                                                                /// Product display
                                                                Expanded(
                                                                  child: RichText(
                                                                    maxLines: 2,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    text: TextSpan(
                                                                      style: CommonWidget.CommonTitleTextStyle(
                                                                        color: GlobalAppColor
                                                                            .HomeDarkTextColor,
                                                                      ),
                                                                      children: [
                                                                        if (!(isCancelled &&
                                                                                quantity ==
                                                                                    0) &&
                                                                            !isOrderFullyCancelled)
                                                                          // Quantity in front (e.g. 1x )
                                                                          TextSpan(
                                                                            text: "${quantity}x ",
                                                                            style: TextStyle(
                                                                              fontWeight: FontWeight.w600,
                                                                              color: GlobalAppColor.ButtonColor,
                                                                            ),
                                                                          ),
                                                                        // Product name — strikethrough if fully cancelled (qty == 0)
                                                                        TextSpan(
                                                                          text:
                                                                              detail.name !=
                                                                                  'N/A'
                                                                              ? detail.name
                                                                              : detail.product.mPName,
                                                                          style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            decoration:
                                                                                (isCancelled &&
                                                                                        quantity ==
                                                                                            0) ||
                                                                                    isOrderFullyCancelled
                                                                                ? TextDecoration.lineThrough
                                                                                : TextDecoration.none,
                                                                            color:
                                                                                (isCancelled &&
                                                                                        quantity ==
                                                                                            0) ||
                                                                                    isOrderFullyCancelled
                                                                                ? GlobalAppColor.RedCode
                                                                                : GlobalAppColor.HomeDarkTextColor,
                                                                          ),
                                                                        ),
                                                                        if (!(isCancelled &&
                                                                                quantity ==
                                                                                    0) &&
                                                                            !isOrderFullyCancelled) ...[
                                                                          // Unit price
                                                                          TextSpan(
                                                                            text:
                                                                                " (SAR ${unitPrice.toStringAsFixed(2)})",
                                                                            style: TextStyle(
                                                                              color: GlobalAppColor.HomeLightTextColor,
                                                                              fontSize: 13,
                                                                            ),
                                                                          ),
                                                                          // ✅ Cancelled qty badge (matches web app "(X cancelled)")
                                                                          if (cancelledQty >
                                                                              0)
                                                                            TextSpan(
                                                                              text: ' ($cancelledQty cancelled)',
                                                                              style: const TextStyle(
                                                                                fontSize: 11,
                                                                                color: Color(
                                                                                  0xFFEF4444,
                                                                                ),
                                                                                fontWeight: FontWeight.w500,
                                                                              ),
                                                                            ),
                                                                        ],
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),

                                                                /// Status Tag
                                                                SizedBox(
                                                                  child: HomeWidget().buildTag(
                                                                    isOrderFullyCancelled
                                                                        ? 'Cancelled'
                                                                        : detail.status[0].toUpperCase() +
                                                                              detail.status.substring(1).toLowerCase(),
                                                                    getStatusColor(
                                                                      isOrderFullyCancelled
                                                                          ? 'cancelled'
                                                                          : detail.status,
                                                                    ),
                                                                    getStatusBgColor(
                                                                      isOrderFullyCancelled
                                                                          ? 'cancelled'
                                                                          : detail.status,
                                                                    ),
                                                                  ),
                                                                ),

                                                                SizedBox(
                                                                  width:
                                                                      detail.status ==
                                                                              "cancelled" ||
                                                                          isOrderFullyCancelled
                                                                      ? 0
                                                                      : 5,
                                                                ),

                                                                /// Note Icon
                                                                SizedBox(
                                                                  width: 28,
                                                                  child:
                                                                      detail.status !=
                                                                              "cancelled" &&
                                                                          item.orderStatus.toLowerCase() !=
                                                                              'completed' &&
                                                                          !isOrderFullyCancelled
                                                                      ? InkWell(
                                                                          onTap: () async {
                                                                            GlobalFunction.hideKeyboard(
                                                                              context,
                                                                            );
                                                                            if (await GlobalFunction().checkInternetConnection(
                                                                              context,
                                                                            )) {
                                                                              await showModalBottomSheet(
                                                                                context: context,
                                                                                isScrollControlled: true,
                                                                                backgroundColor: Colors.transparent,
                                                                                builder:
                                                                                    (
                                                                                      _,
                                                                                    ) => _ItemNoteSheet(
                                                                                      detail: detail,
                                                                                      orderId: item.orderId,
                                                                                      homeCtrl: HomeCtrl,
                                                                                    ),
                                                                              );
                                                                            }
                                                                          },
                                                                          child: Icon(
                                                                            Icons.note_alt_outlined,
                                                                            color: GlobalAppColor.DarkBlueColor.withOpacity(
                                                                              .6,
                                                                            ),
                                                                            size:
                                                                                20,
                                                                          ),
                                                                        )
                                                                      : SizedBox.shrink(),
                                                                ),

                                                                SizedBox(
                                                                  width:
                                                                      detail.status ==
                                                                              "cancelled" ||
                                                                          isOrderFullyCancelled
                                                                      ? 0
                                                                      : 5,
                                                                ),

                                                                /// Cancel Icon
                                                                SizedBox(
                                                                  width: 28,
                                                                  child:
                                                                      detail.status !=
                                                                              "cancelled" &&
                                                                          item.orderStatus.toLowerCase() !=
                                                                              'completed' &&
                                                                          !isOrderFullyCancelled
                                                                      ? InkWell(
                                                                          onTap: () async {
                                                                            GlobalFunction.hideKeyboard(
                                                                              context,
                                                                            );
                                                                            if (await GlobalFunction().checkInternetConnection(
                                                                              context,
                                                                            )) {
                                                                              await HomeWidget()._showCancelItemDialog(
                                                                                context,
                                                                                HomeCtrl,
                                                                                detail,
                                                                                item.orderStatus,
                                                                              );
                                                                            }
                                                                          },
                                                                          child: Icon(
                                                                            Symbols.block,
                                                                            color: GlobalAppColor.RedCode.withOpacity(
                                                                              .6,
                                                                            ),
                                                                            size:
                                                                                20,
                                                                          ),
                                                                        )
                                                                      : SizedBox.shrink(),
                                                                ),
                                                              ],
                                                            ),
                                                          ),

                                                          const SizedBox(
                                                            width: 10,
                                                          ),

                                                          /// RIGHT SIDE
                                                          SizedBox(
                                                            width: 90,
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .end,
                                                              children: [
                                                                if ((isCancelled &&
                                                                        quantity ==
                                                                            0) ||
                                                                    isOrderFullyCancelled)
                                                                  // Fully cancelled: strikethrough original price
                                                                  Text(
                                                                    "SAR ${(unitPrice * detail.originalQty).toStringAsFixed(2)}",
                                                                    style:
                                                                        CommonWidget.CommonTitleTextStyle(
                                                                          color:
                                                                              GlobalAppColor.HomeLightTextColor,
                                                                          fontSize:
                                                                              13,
                                                                        ).copyWith(
                                                                          decoration:
                                                                              TextDecoration.lineThrough,
                                                                        ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                  )
                                                                else if (cancelledQty >
                                                                        0 &&
                                                                    !isOrderFullyCancelled) ...[
                                                                  // Partial cancel: strikethrough original + orange current
                                                                  Text(
                                                                    "SAR ${(unitPrice * detail.originalQty).toStringAsFixed(2)}",
                                                                    style:
                                                                        CommonWidget.CommonTitleTextStyle(
                                                                          color:
                                                                              GlobalAppColor.HomeLightTextColor,
                                                                          fontSize:
                                                                              11,
                                                                        ).copyWith(
                                                                          decoration:
                                                                              TextDecoration.lineThrough,
                                                                        ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                  ),
                                                                  Text(
                                                                    "SAR ${itemTotal.toStringAsFixed(2)}",
                                                                    style: CommonWidget.CommonTitleTextStyle(
                                                                      color: const Color(
                                                                        0xFFEA580C,
                                                                      ), // orange-600
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                  ),
                                                                ] else
                                                                  Text(
                                                                    "SAR ${itemTotal.toStringAsFixed(2)}",
                                                                    style: CommonWidget.CommonTitleTextStyle(
                                                                      color: GlobalAppColor
                                                                          .HomeDarkTextColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          15,
                                                                    ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      // ✅ Cancel reason badge (matches web app red badge with reason)
                                                      if (cancelledQty > 0 &&
                                                          !isOrderFullyCancelled) ...[
                                                        const SizedBox(
                                                          height: 3,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 3,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(
                                                              0xFFFEF2F2,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                Icons.block,
                                                                size: 10,
                                                                color: Color(
                                                                  0xFFEF4444,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Flexible(
                                                                child: Text(
                                                                  detail
                                                                          .cancelReason
                                                                          .isNotEmpty
                                                                      ? '$cancelledQty qty cancelled · ${detail.cancelReason}'
                                                                      : '$cancelledQty qty cancelled',
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Color(
                                                                      0xFFEF4444,
                                                                    ),
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                  ),
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],

                                                      // ✅ Modifiers indented below item (matches web app linkedModifiers)
                                                      if (linkedMods
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                left: 12.0,
                                                              ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: linkedMods.map((
                                                              mod,
                                                            ) {
                                                              final modIsCancelled =
                                                                  mod.status
                                                                      .toLowerCase() ==
                                                                  'cancelled';
                                                              final modPrice =
                                                                  double.tryParse(
                                                                    mod.rate.isNotEmpty &&
                                                                            mod.rate !=
                                                                                '0'
                                                                        ? mod.rate
                                                                        : mod.price,
                                                                  ) ??
                                                                  0.0;
                                                              final modQty =
                                                                  mod.quantity;
                                                              final modOrigQty =
                                                                  mod.originalQty;
                                                              final modCancelledQty =
                                                                  modOrigQty -
                                                                  modQty;
                                                              final modTotal =
                                                                  modPrice *
                                                                  modQty;
                                                              if (modIsCancelled &&
                                                                  modQty == 0) {
                                                                return const SizedBox.shrink();
                                                              }
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets.only(
                                                                      bottom:
                                                                          2.0,
                                                                    ),
                                                                child: Row(
                                                                  children: [
                                                                    const Text(
                                                                      '+ ',
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        color: Color(
                                                                          0xFF6B7280,
                                                                        ),
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child: Text(
                                                                        '${modQty}x ${mod.name != 'N/A' && mod.name.isNotEmpty ? mod.name : (mod.product.mPName != 'N/A' ? mod.product.mPName : (mod.note != 'N/A' ? mod.note : ''))}${modCancelledQty > 0 ? ' ($modCancelledQty cancelled)' : ''}',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              11,
                                                                          color:
                                                                              modIsCancelled
                                                                              ? const Color(
                                                                                  0xFFF97316,
                                                                                )
                                                                              : const Color(
                                                                                  0xFF6B7280,
                                                                                ),
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      'SAR ${modTotal.toStringAsFixed(2)}',
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        color:
                                                                            modIsCancelled
                                                                            ? const Color(
                                                                                0xFFF97316,
                                                                              )
                                                                            : const Color(
                                                                                0xFF6B7280,
                                                                              ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }).toList(),
                                                          ),
                                                        ),
                                                      ],
                                                      // ✅ Modifier indicator from note OR price inflation (items added to existing order via merge flow)
                                                      // The backend's POST /order-details/ endpoint does not persist the note field,
                                                      // so the note is always empty for merge-flow items. We fall back to showing
                                                      // the price difference as a generic add-on indicator.
                                                      ...() {
                                                        if (linkedMods
                                                            .isNotEmpty)
                                                          return <Widget>[];
                                                        final rawNote =
                                                            detail.note;
                                                        final double itemRate =
                                                            double.tryParse(
                                                              detail.price,
                                                            ) ??
                                                            0;
                                                        final double basePrice =
                                                            double.tryParse(
                                                              detail
                                                                  .product
                                                                  .price,
                                                            ) ??
                                                            0;

                                                        // ── Resolve modifier label ──
                                                        // Priority 1: ||MOD|| note (new format)
                                                        // Priority 2: plain note with inflated rate (old format)
                                                        // Priority 3: no note but inflated rate (backend dropped note)
                                                        List<String> modNames =
                                                            [];
                                                        bool useGenericAddon =
                                                            false;

                                                        if (rawNote != 'N/A' &&
                                                            rawNote
                                                                .isNotEmpty) {
                                                          if (rawNote.contains(
                                                            '||MOD||',
                                                          )) {
                                                            final modPart =
                                                                rawNote
                                                                    .split(
                                                                      '||MOD||',
                                                                    )
                                                                    .last;
                                                            modNames = modPart
                                                                .split(',')
                                                                .map(
                                                                  (s) =>
                                                                      s.trim(),
                                                                )
                                                                .where(
                                                                  (s) => s
                                                                      .isNotEmpty,
                                                                )
                                                                .toList();
                                                          } else if (itemRate >
                                                              basePrice) {
                                                            final modPart =
                                                                rawNote
                                                                    .contains(
                                                                      ' | ',
                                                                    )
                                                                ? rawNote
                                                                      .split(
                                                                        ' | ',
                                                                      )
                                                                      .last
                                                                      .trim()
                                                                : rawNote;
                                                            if (modPart
                                                                .isNotEmpty) {
                                                              modNames = [
                                                                modPart,
                                                              ];
                                                            }
                                                          }
                                                        } else if (itemRate >
                                                            basePrice) {
                                                          // Backend dropped note — use price inflation indicator
                                                          useGenericAddon =
                                                              true;
                                                        }

                                                        if (modNames.isEmpty &&
                                                            !useGenericAddon) {
                                                          return <Widget>[];
                                                        }

                                                        final double
                                                        addonPerUnit =
                                                            itemRate -
                                                            basePrice;

                                                        return <Widget>[
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  left: 12.0,
                                                                ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children:
                                                                  useGenericAddon
                                                                  ? [
                                                                      Padding(
                                                                        padding: const EdgeInsets.only(
                                                                          bottom:
                                                                              2.0,
                                                                        ),
                                                                        child: Row(
                                                                          children: [
                                                                            const Text(
                                                                              '+ ',
                                                                              style: TextStyle(
                                                                                fontSize: 11,
                                                                                color: Color(
                                                                                  0xFF6B7280,
                                                                                ),
                                                                                fontWeight: FontWeight.w500,
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              '${detail.quantity}x add-on  SAR ${(addonPerUnit * detail.quantity).toStringAsFixed(2)}',
                                                                              style: const TextStyle(
                                                                                fontSize: 11,
                                                                                color: Color(
                                                                                  0xFF6B7280,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ]
                                                                  : modNames
                                                                        .map(
                                                                          (
                                                                            mName,
                                                                          ) => Padding(
                                                                            padding: const EdgeInsets.only(
                                                                              bottom: 2.0,
                                                                            ),
                                                                            child: Row(
                                                                              children: [
                                                                                const Text(
                                                                                  '+ ',
                                                                                  style: TextStyle(
                                                                                    fontSize: 11,
                                                                                    color: Color(
                                                                                      0xFF6B7280,
                                                                                    ),
                                                                                    fontWeight: FontWeight.w500,
                                                                                  ),
                                                                                ),
                                                                                Expanded(
                                                                                  child: Text(
                                                                                    '${detail.quantity}x $mName',
                                                                                    style: const TextStyle(
                                                                                      fontSize: 11,
                                                                                      color: Color(
                                                                                        0xFF6B7280,
                                                                                      ),
                                                                                    ),
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        )
                                                                        .toList(),
                                                            ),
                                                          ),
                                                        ];
                                                      }(),
                                                    ],
                                                  ),
                                                );
                                              })
                                              .toList(),
                                        ), // closes item rows Column
                                      ], // end items list children
                                    ),
                                  ), // end items Padding
                                  // ── Financial summary ─────────────────────────
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      2,
                                      12,
                                      12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ── Financial breakdown: tinted container ──
                                        // Hidden for fully cancelled orders (no breakdown needed)
                                        if (item.orderStatus.toLowerCase() !=
                                            'cancelled')
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF9FAFB),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFFE5E7EB),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // ✅ Net Amount (pre-tax base) — mirrors web app Financial Summary order
                                                if (item.displayNetAmount > 0)
                                                  HomeWidget().buildAmountRow(
                                                    "Net Amount:",
                                                    item.displayNetAmount
                                                        .toStringAsFixed(2),
                                                    color: const Color(
                                                      0xFF2563EB,
                                                    ),
                                                  ),

                                                // ─── TAX BREAKDOWN SECTION (collapsible — mirrors web %) ─
                                                _CollapsibleTaxSection(
                                                  item: item,
                                                ),
                                                // ✅ Total Amount (totalAmt from DB, pre-refund) — mirrors web app "Total Amount" row
                                                HomeWidget().buildAmountRow(
                                                  "Total Amount:",
                                                  formatAmount(
                                                    item.calculatedSubtotal,
                                                  ),
                                                ),
                                                if (item.tableCharge > 0 &&
                                                    (item.paymentStatus
                                                                .toLowerCase() ==
                                                            'paid' ||
                                                        item.paymentStatus
                                                                .toLowerCase() ==
                                                            'partial'))
                                                  HomeWidget().buildAmountRow(
                                                    "Table Charge:",
                                                    item.tableCharge
                                                        .toStringAsFixed(2),
                                                  ),
                                                if (HomeWidget().isValid(
                                                  item.chargeAmt,
                                                ))
                                                  HomeWidget().buildAmountRow(
                                                    "Other Charges:",
                                                    (double.tryParse(
                                                              item.chargeAmt
                                                                  .toString(),
                                                            ) ??
                                                            0.0)
                                                        .toStringAsFixed(2),
                                                  ),
                                                if (HomeWidget().isValid(
                                                      item.discountPer,
                                                    ) &&
                                                    double.tryParse(
                                                          item.discountPer
                                                              .toString(),
                                                        ) !=
                                                        0)
                                                  HomeWidget().buildAmountRow(
                                                    "Discount (${double.tryParse(item.discountPer.toString())?.toStringAsFixed(2) ?? "0.00"}%):",
                                                    "- ${(double.tryParse(item.discountAmt.toString()) ?? 0.0).toStringAsFixed(2)}",
                                                    color: GlobalAppColor
                                                        .AvailableCode,
                                                  ),
                                                // ✅ Adjustment: show Addition (yellow) or Deduction (red) with reason
                                                if (double.tryParse(
                                                          item.adjustAmt,
                                                        ) !=
                                                        null &&
                                                    (double.tryParse(
                                                                  item.adjustAmt,
                                                                ) ??
                                                                0)
                                                            .abs() >
                                                        0.001) ...[
                                                  Builder(
                                                    builder: (_) {
                                                      final adj = double.parse(
                                                        item.adjustAmt,
                                                      );
                                                      final isAddition =
                                                          adj > 0;
                                                      final adjLabel =
                                                          isAddition
                                                          ? 'Addition'
                                                          : 'Deduction';
                                                      final adjColor =
                                                          isAddition
                                                          ? const Color(
                                                              0xFFB45309,
                                                            ) // amber-700
                                                          : GlobalAppColor
                                                                .RedCode;
                                                      final displayAmt =
                                                          isAddition
                                                          ? '+${adj.toStringAsFixed(2)}'
                                                          : '- ${(-adj).toStringAsFixed(2)}';
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 3,
                                                            ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Flexible(
                                                              child: Row(
                                                                children: [
                                                                  Text(
                                                                    '$adjLabel:',
                                                                    style:
                                                                        CommonWidget.CommonTitleTextStyle(
                                                                          fontSize:
                                                                              13,
                                                                        ).copyWith(
                                                                          color:
                                                                              adjColor,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                  ),
                                                                  if (item
                                                                      .adjustReason
                                                                      .isNotEmpty) ...[
                                                                    const SizedBox(
                                                                      width: 4,
                                                                    ),
                                                                    Flexible(
                                                                      child: Text(
                                                                        '(${item.adjustReason})',
                                                                        style:
                                                                            CommonWidget.CommonTitleTextStyle(
                                                                              fontSize: 10,
                                                                            ).copyWith(
                                                                              color: Colors.grey.shade500,
                                                                            ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        maxLines:
                                                                            1,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ],
                                                              ),
                                                            ),
                                                            Text(
                                                              displayAmt,
                                                              style:
                                                                  CommonWidget.CommonTitleTextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ).copyWith(
                                                                    color:
                                                                        adjColor,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                                if (item
                                                        .calculateCancelledAmount() >
                                                    0)
                                                  HomeWidget().buildAmountRow(
                                                    "Cancelled Amount:",
                                                    "- ${item.calculateCancelledAmount().toStringAsFixed(2)}",
                                                    color:
                                                        GlobalAppColor.RedCode,
                                                  ),
                                                if (item.calculatedRefund > 0)
                                                  HomeWidget().buildAmountRow(
                                                    "Refund Amount:",
                                                    "${item.calculatedRefund.toStringAsFixed(2)}",
                                                    color:
                                                        GlobalAppColor.RedCode,
                                                  ),
                                              ], // end breakdown Container Column children
                                            ), // end breakdown Container Column
                                          ), // end breakdown Container
                                        if (item.orderStatus.toLowerCase() !=
                                            'cancelled')
                                          const SizedBox(height: 12),
                                        // ── Grand Total banner ──
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFBFDBFE),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Expanded(
                                                child: Text(
                                                  "Grand Total",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF1D4ED8),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                item.orderStatus
                                                            .toLowerCase() ==
                                                        'cancelled'
                                                    ? 'SAR 0'
                                                    : 'SAR ${item.formattedGrandTotal}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF1D4ED8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        item.orderStatus.toLowerCase() ==
                                                'cancelled'
                                            ? _CollapsibleCancelledPaymentBreakdown(
                                                item: item,
                                              )
                                            : _CollapsiblePaymentBreakdown(
                                                item: item,
                                              ),
                                        // 🔹 Controls
                                        const Divider(
                                          color: Color(0xFFE9EBF0),
                                          height: 16,
                                          thickness: 1,
                                        ),
                                        Column(
                                          children: [
                                            const SizedBox(height: 4),

                                            // ═══════════════════════════════════════
                                            // ROW 1 — cancel/delete icon + dropdowns
                                            // Hidden for fully cancelled and completed orders
                                            // ═══════════════════════════════════════
                                            if (item.orderStatus
                                                        .toLowerCase() !=
                                                    'cancelled' &&
                                                item.orderStatus
                                                        .toLowerCase() !=
                                                    'completed')
                                              Row(
                                                children: <Widget>[
                                                  item.orderStatus == "draft"
                                                      ? HomeWidget().buildIconButton(
                                                          icon: Symbols.delete,
                                                          color: GlobalAppColor
                                                              .ButtonColor,
                                                          bgColor: const Color(
                                                            0xFFFCE7F3,
                                                          ),
                                                          onTap: () async {
                                                            if (await GlobalFunction()
                                                                .checkInternetConnection(
                                                                  context,
                                                                )) {
                                                              await GlobalFunction.DeleteOrder(
                                                                context:
                                                                    context,
                                                                Msg:
                                                                    "Do you want to delete this order #${item.orderId}",
                                                                OrderID: item
                                                                    .orderId
                                                                    .toString(),
                                                              );
                                                            }
                                                          },
                                                        )
                                                      : HomeWidget().buildIconButton(
                                                          icon: Symbols.block,
                                                          color: GlobalAppColor
                                                              .ButtonColor,
                                                          bgColor: const Color(
                                                            0xFFFCE7F3,
                                                          ),
                                                          onTap: () async {
                                                            GlobalFunction.hideKeyboard(
                                                              context,
                                                            );
                                                            if (await GlobalFunction()
                                                                .checkInternetConnection(
                                                                  context,
                                                                )) {
                                                              await HomeWidget()
                                                                  ._showCancelOrderDialog(
                                                                    context,
                                                                    HomeCtrl,
                                                                    item,
                                                                  );
                                                            }
                                                          },
                                                        ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: HomeWidget().buildDropdown(
                                                      items:
                                                          HomeCtrl.DropDownOne.map(
                                                            (e) => e.title!,
                                                          ).toList(),
                                                      value: selectedOneValue,
                                                      onChanged: (v) async {
                                                        final previousOne = item
                                                            .selectedDropDownOne;
                                                        item.selectedDropDownOne =
                                                            v;
                                                        HomeCtrl.notifyListeners();
                                                        final isConnected =
                                                            await GlobalFunction()
                                                                .checkInternetConnection(
                                                                  context,
                                                                );
                                                        if (isConnected) {
                                                          final success =
                                                              await HomeCtrl.UpdatePriorityOrderStatusService(
                                                                context,
                                                                item.orderId
                                                                    .toString(),
                                                                item.selectedDropDownOne
                                                                    .toString(),
                                                                "OrderStatus",
                                                              );
                                                          if (!success) {
                                                            item.selectedDropDownOne =
                                                                previousOne;
                                                            HomeCtrl.notifyListeners();
                                                          }
                                                        } else {
                                                          item.selectedDropDownOne =
                                                              previousOne;
                                                          HomeCtrl.notifyListeners();
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: HomeWidget().buildDropdown(
                                                      items:
                                                          HomeCtrl.DropDownTwo.map(
                                                            (e) => e.title!,
                                                          ).toList(),
                                                      value: selectedTwoValue,
                                                      onChanged: (v) async {
                                                        final previousTwo = item
                                                            .selectedDropDownTwo;
                                                        item.selectedDropDownTwo =
                                                            v;
                                                        HomeCtrl.notifyListeners();
                                                        final isConnected =
                                                            await GlobalFunction()
                                                                .checkInternetConnection(
                                                                  context,
                                                                );
                                                        if (isConnected) {
                                                          final success =
                                                              await HomeCtrl.UpdatePriorityOrderStatusService(
                                                                context,
                                                                item.orderId
                                                                    .toString(),
                                                                item.selectedDropDownTwo
                                                                    .toString(),
                                                                "priority",
                                                              );
                                                          if (!success) {
                                                            item.selectedDropDownTwo =
                                                                previousTwo;
                                                            HomeCtrl.notifyListeners();
                                                          }
                                                        } else {
                                                          item.selectedDropDownTwo =
                                                              previousTwo;
                                                          HomeCtrl.notifyListeners();
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),

                                            // ═══════════════════════════════════════
                                            // ROW 2 — action buttons (Pay Bill /
                                            //   Partial / Refund / Group)
                                            // Only rendered when at least one is visible
                                            // ═══════════════════════════════════════
                                            Builder(
                                              builder: (_) {
                                                final bool isPaid =
                                                    item.paymentStatus
                                                        .toLowerCase() ==
                                                    'paid';
                                                final bool isCompleted =
                                                    item.orderStatus
                                                        .toLowerCase() ==
                                                    'completed';
                                                final bool isCancelled =
                                                    item.orderStatus
                                                        .toLowerCase() ==
                                                    'cancelled';

                                                // Fully cancelled: only Print Bill + Reconnect (full-width row)
                                                if (isCancelled) {
                                                  return Builder(
                                                    builder: (context) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 8,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: _OrderActionButton(
                                                              label:
                                                                  'Print Bill',
                                                              color:
                                                                  const Color(
                                                                    0xFF059669,
                                                                  ),
                                                              icon: Icons
                                                                  .receipt_long,
                                                              onTap: () async {
                                                                await _handlePrintBill(
                                                                  context,
                                                                  item,
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Expanded(
                                                            child: _OrderActionButton(
                                                              label:
                                                                  'Reconnect',
                                                              color:
                                                                  const Color(
                                                                    0xFF2563EB,
                                                                  ),
                                                              icon: Icons.sync,
                                                              onTap: () async {
                                                                final printerProvider =
                                                                    Provider.of<
                                                                      PrinterIntegrationProvider
                                                                    >(
                                                                      context,
                                                                      listen:
                                                                          false,
                                                                    );
                                                                final success =
                                                                    await printerProvider
                                                                        .reconnectPrinter();
                                                                if (!context
                                                                    .mounted)
                                                                  return;
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      success
                                                                          ? '✅ Printer reconnected'
                                                                          : '❌ Reconnect failed — check printer is on & on same WiFi',
                                                                    ),
                                                                    backgroundColor:
                                                                        success
                                                                        ? Colors
                                                                              .green
                                                                        : Colors
                                                                              .red,
                                                                    duration:
                                                                        const Duration(
                                                                          seconds:
                                                                              3,
                                                                        ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }

                                                final bool showGroup = (() {
                                                  if (_isPremiumTable(context, item)) return false;
                                                  if (isPaid ||
                                                      isCompleted ||
                                                      isCancelled)
                                                    return false;
                                                  if (item.groupId != 0)
                                                    return false;
                                                  try {
                                                    final d = DateTime.parse(
                                                      item.orderDate.split(
                                                        ' ',
                                                      )[0],
                                                    );
                                                    final now = DateTime.now();
                                                    return d.year == now.year &&
                                                        d.month == now.month &&
                                                        d.day == now.day;
                                                  } catch (_) {
                                                    return false;
                                                  }
                                                })();

                                                // No action buttons needed if paid and no group
                                                final bool hasActions =
                                                    !isPaid || isPaid;
                                                if (!hasActions) {
                                                  return const SizedBox.shrink();
                                                }

                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8,
                                                      ),
                                                  child: Builder(
                                                    builder: (context) {
                                                      final List<Widget>
                                                      actionButtons = [];

                                                      if (!isPaid) {
                                                        actionButtons.add(
                                                          _OrderActionButton(
                                                            label: "Pay Bill",
                                                            color: GlobalAppColor
                                                                .ButtonDarkColor,
                                                            icon: Icons
                                                                .receipt_long,
                                                            onTap: () async {
                                                              if (await GlobalFunction()
                                                                  .checkInternetConnection(
                                                                    context,
                                                                  )) {
                                                                await HomeCtrl.getPayBillPaymentMethodsListService(
                                                                  context,
                                                                );
                                                                HomeCtrl.openPanelWithData(
                                                                  item,
                                                                );
                                                                // Async: compute table charge for this order.
                                                                // Panel opens immediately; charge updates on completion.
                                                                HomeCtrl.computePayBillTableCharge(
                                                                  context,
                                                                  item,
                                                                );
                                                              }
                                                            },
                                                          ),
                                                        );

                                                        actionButtons.add(
                                                          _OrderActionButton(
                                                            label: "Partial",
                                                            color: const Color(
                                                              0xFF2563EB,
                                                            ),
                                                            icon: Icons
                                                                .splitscreen,
                                                            isLoading: HomeCtrl
                                                                .isHomeLoader,
                                                            onTap: () async {
                                                              if (HomeCtrl
                                                                  .isHomeLoader) {
                                                                return;
                                                              }
                                                              if (await GlobalFunction()
                                                                  .checkInternetConnection(
                                                                    context,
                                                                  )) {
                                                                if (HomeCtrl
                                                                    .PayBillPaymentListing
                                                                    .isEmpty) {
                                                                  await HomeCtrl.getPayBillPaymentMethodsListService(
                                                                    context,
                                                                  );
                                                                }
                                                                _showPartialPaymentDialog(
                                                                  context,
                                                                  HomeCtrl,
                                                                  item,
                                                                );
                                                              }
                                                            },
                                                          ),
                                                        );
                                                      }

                                                      if (showGroup) {
                                                        actionButtons.add(
                                                          _OrderActionButton(
                                                            label: "Group",
                                                            color: const Color(
                                                              0xFF7C3AED,
                                                            ),
                                                            icon: Icons
                                                                .group_work,
                                                            isLoading: HomeCtrl
                                                                .isHomeLoader,
                                                            onTap: () {
                                                              if (!HomeCtrl
                                                                  .isHomeLoader) {
                                                                _showGroupOrdersDialog(
                                                                  context,
                                                                  HomeCtrl,
                                                                );
                                                              }
                                                            },
                                                          ),
                                                        );
                                                      }

                                                      actionButtons.addAll([
                                                        _OrderActionButton(
                                                          label: "Print Bill",
                                                          color: const Color(
                                                            0xFF059669,
                                                          ),
                                                          icon: Icons
                                                              .receipt_long,
                                                          onTap: () async {
                                                            await _handlePrintBill(
                                                              context,
                                                              item,
                                                            );
                                                          },
                                                        ),
                                                        _OrderActionButton(
                                                          label: "Print KDS",
                                                          color: const Color(
                                                            0xFFF59E0B,
                                                          ),
                                                          icon:
                                                              Icons.restaurant,
                                                          onTap: () async {
                                                            await _handlePrintToKDS(
                                                              context,
                                                              item,
                                                            );
                                                          },
                                                        ),
                                                        _OrderActionButton(
                                                          label: "Adjust",
                                                          color: const Color(
                                                            0xFF5C5C8A,
                                                          ),
                                                          icon: Icons.tune,
                                                          onTap: () async {
                                                            if (HomeCtrl
                                                                .isHomeLoader) {
                                                              return;
                                                            }
                                                            if (await GlobalFunction()
                                                                .checkInternetConnection(
                                                                  context,
                                                                )) {
                                                              if (HomeCtrl
                                                                  .PayBillPaymentListing
                                                                  .isEmpty) {
                                                                await HomeCtrl.getPayBillPaymentMethodsListService(
                                                                  context,
                                                                );
                                                              }
                                                              _showOrderAdjustDialog(
                                                                context,
                                                                HomeCtrl,
                                                                item,
                                                              );
                                                            }
                                                          },
                                                        ),
                                                        _OrderActionButton(
                                                          label: "Reconnect",
                                                          color: const Color(
                                                            0xFF2563EB,
                                                          ),
                                                          icon: Icons.sync,
                                                          onTap: () async {
                                                            final printerProvider =
                                                                Provider.of<
                                                                  PrinterIntegrationProvider
                                                                >(
                                                                  context,
                                                                  listen: false,
                                                                );
                                                            final success =
                                                                await printerProvider
                                                                    .reconnectPrinter();
                                                            if (!context
                                                                .mounted)
                                                              return;
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  success
                                                                      ? '✅ Printer reconnected'
                                                                      : '❌ Reconnect failed — check printer is on & on same WiFi',
                                                                ),
                                                                backgroundColor:
                                                                    success
                                                                    ? Colors
                                                                          .green
                                                                    : Colors
                                                                          .red,
                                                                duration:
                                                                    const Duration(
                                                                      seconds:
                                                                          3,
                                                                    ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ]);

                                                      if (actionButtons
                                                          .isEmpty) {
                                                        return const SizedBox.shrink();
                                                      }

                                                      // Full-width 2-column grid: each row stretches buttons
                                                      // to fill available width for a clean, consistent layout.
                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          for (
                                                            int i = 0;
                                                            i <
                                                                actionButtons
                                                                    .length;
                                                            i += 2
                                                          )
                                                            Padding(
                                                              padding:
                                                                  EdgeInsets.only(
                                                                    top: i == 0
                                                                        ? 8
                                                                        : 6,
                                                                  ),
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    child:
                                                                        actionButtons[i],
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  if (i + 1 <
                                                                      actionButtons
                                                                          .length)
                                                                    Expanded(
                                                                      child:
                                                                          actionButtons[i +
                                                                              1],
                                                                    )
                                                                  else
                                                                    const Expanded(
                                                                      child:
                                                                          SizedBox(),
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ], // ── close card Column children ──
                              ), // ── close card Column ──
                            ), // ── close card SingleChildScrollView ──
                          ), // ── close card Container ──
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                rowItems.add(const Expanded(child: SizedBox()));
              }
              if (i < itemsPerRow - 1) {
                rowItems.add(const SizedBox(width: 6));
              }
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rowItems,
              ),
            );
          },
        );
      },
    );
  }

  //-✅--Responsive Pay Bill Panel-----------------------------------------✅-//
  Widget OPayBillWidget(
    BuildContext context,
    List<OrderData> data,
    HomeProvider HomeCtrl,
  ) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isPortrait = screenHeight >= screenWidth;

    final order = HomeCtrl.selectedOrder;
    final bool isRefund = (() {
      if (order == null) return false;
      final grandTotal = HomeCtrl.payableTotalForOrder(context, order);
      final double refundAmt = (order.totalPaidAmount - grandTotal).clamp(0.0, double.infinity);
      return refundAmt > 0.01;
    })();

    double panelWidth;
    if (screenWidth >= 1200) {
      panelWidth = screenWidth * 0.25;
    } else if (screenWidth >= 800) {
      panelWidth = screenWidth * 0.35;
    } else {
      panelWidth = screenWidth * 0.8;
    }

    // Max width for web
    panelWidth = panelWidth > 500 ? 500 : panelWidth;

    return Stack(
      children: [
        // 🔒 Overlay
        if (HomeCtrl.isPanelOpen)
          AbsorbPointer(
            absorbing: true,
            child: Container(color: Colors.black45),
          ),

        // 2️⃣ Side panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          right: HomeCtrl.isPanelOpen ? 0 : -panelWidth,
          top: MediaQuery.of(context).padding.top,
          bottom: screenWidth > 900 ? 0 : (60.0 + MediaQuery.of(context).padding.bottom),
          width: panelWidth,
          child: Material(
            elevation: 16,
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              bottomLeft: Radius.circular(5),
            ),
            child: Column(
              children: [
                SizedBox(height: 5),
                // Header
                Container(
                  height: kToolbarHeight,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  color: GlobalAppColor.WhiteColorCode,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Payment",
                        style: CommonWidget.CommonTitleTextStyle(
                          fontSize: isPortrait ? 18 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: GlobalAppColor.DarkTextColorCode.withOpacity(
                            .6,
                          ),
                        ),
                        onPressed: HomeCtrl.isHomeLoader
                            ? null
                            : () => HomeCtrl.closePanel(),
                      ),
                    ],
                  ),
                ),
                CommonWidget().DividerWidget(),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //-✅--Mockup-style Top Header Bar-----------------✅-//
                        Consumer<HomeProvider>(
                          builder: (context, ctrl, _) {
                            final String ps =
                                ctrl.selectedOrder?.paymentStatus
                                    .toLowerCase() ??
                                'unknown';
                            final String os =
                                ctrl.selectedOrder?.orderStatus.toLowerCase() ??
                                'unknown';

                            Color psColor = const Color(0xFFC0392B);
                            String psLabel = 'Unpaid';
                            if (ps == 'paid') {
                              psColor = const Color(0xFF1E7E34);
                              psLabel = 'Paid';
                            } else if (ps == 'partial') {
                              psColor = const Color(0xFFE07B00);
                              psLabel = 'Partial';
                            }

                            Color osColor = const Color(0xFF2471A3);
                            String osLabel = os.isNotEmpty ? (os[0].toUpperCase() + os.substring(1)) : 'Unknown';

                            final isPremium = ctrl.selectedOrder != null && _isPremiumTable(context, ctrl.selectedOrder!);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        // Payment status pill
                                        _statusPill(label: psLabel, color: psColor),
                                        const SizedBox(width: 6),
                                        // Order status pill
                                        _statusPill(
                                          label: osLabel,
                                          color: osColor,
                                        ),
                                        // Live refresh indicator
                                        if (ctrl.isFetchingOrderStatus || ctrl.isFetchingTableStatus) ...[
                                          const SizedBox(width: 8),
                                          const SizedBox(
                                            height: 12,
                                            width: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: Color(0xFF5C5C8A),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    // Service type & Table display
                                    GestureDetector(
                                      onLongPress: () async {
                                        final oid = ctrl.selectedOrder?.orderId;
                                        if (oid != null && oid > 0) {
                                          await ctrl.getOrderPaymentStatusService(context, oid);
                                        }
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "${(ctrl.selectedOrder?.type ?? 'DINE IN').toUpperCase()} · ${_nullableTableDisplayNameFromMetadata(context, ctrl.selectedOrder).toUpperCase()}",
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF64748B),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          if (isPremium) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.workspace_premium,
                                              color: Color(0xFFF59E0B),
                                              size: 14,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Subtitle/Order Info Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Order #${ctrl.selectedOrder?.orderNo ?? ctrl.selectedOrder?.orderId ?? 'N/A'}",
                                      style: CommonWidget.CommonTitleTextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      "Guest Customer",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),

                        //-✅--Ordered Items Container Card Removed----------------✅-//

                        //-✅--Order Summary Container Card----------------✅-//
                        buildOrderSummaryRow(context, HomeCtrl),

                        // Ledger and warnings
                        _buildAlreadyPaidTransactions(context, HomeCtrl),
                        _buildRefundWarningSection(context, HomeCtrl),

                        //-✅--Edit Discount Section Card-----------------✅-//
                        _buildPayBillDiscountSection(context, HomeCtrl),

                        //-✅--Payment Method Section Container Card-----✅-//
                        if (!isRefund)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.015),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "PAYMENT METHOD",
                                style: CommonWidget.CommonTitleTextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF475569),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final int crossAxisCount = constraints.maxWidth < 280 ? 2 : 3;
                                  final double childAspectRatio = crossAxisCount == 2 ? 1.8 : 1.4;

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      childAspectRatio: childAspectRatio,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: HomeCtrl.PayBillPayment.length,
                                    itemBuilder: (context, index) {
                                      final item = HomeCtrl.PayBillPayment[index];
                                      final name = item.name;
                                      final isSelected = HomeCtrl.PayMethodName == name;
                                      final type = HomeCtrl.PayBillPaymentListing.firstWhere(
                                        (p) => p.name == name,
                                        orElse: () => PaymentMethodsPayBillModel(),
                                      ).type;

                                      final nameLower = name.toLowerCase();
                                      final isCash = nameLower.contains("cash");
                                      final isCard = (nameLower.contains("card") || nameLower.contains("visa")) && !nameLower.contains("mada");
                                      final isMada = nameLower.contains("mada");
                                      final isSplit = nameLower.contains("split");
                                      final isMulti = nameLower.contains("multi");

                                      String displayTitle = name;
                                      String displaySubtitle = name;
                                      Color activeColor = const Color(0xFF3B82F6);
                                      Color bgLight = const Color(0xFFEFF6FF);
                                      Color textColor = const Color(0xFF1E293B);
                                      Color subtitleColor = const Color(0xFF64748B);
                                      Widget iconWidget = const Icon(Icons.payment_outlined, size: 20, color: Color(0xFF64748B));

                                      if (isCash) {
                                        displayTitle = "Cash";
                                        displaySubtitle = "Cash";
                                        activeColor = const Color(0xFF10B981);
                                        bgLight = const Color(0xFFECFDF5);
                                        textColor = isSelected ? const Color(0xFF065F46) : const Color(0xFF1E293B);
                                        subtitleColor = isSelected ? const Color(0xFF047857) : const Color(0xFF64748B);
                                        iconWidget = Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 20,
                                          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                        );
                                      } else if (isCard) {
                                        displayTitle = "Card";
                                        displaySubtitle = "Card";
                                        activeColor = const Color(0xFF8B5CF6);
                                        bgLight = const Color(0xFFF5F3FF);
                                        textColor = isSelected ? const Color(0xFF5B21B6) : const Color(0xFF1E293B);
                                        subtitleColor = isSelected ? const Color(0xFF6D28D9) : const Color(0xFF64748B);
                                        iconWidget = Icon(
                                          Icons.credit_card_outlined,
                                          size: 20,
                                          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF64748B),
                                        );
                                      } else if (isSplit) {
                                        displayTitle = "Split Payment";
                                        displaySubtitle = "Split Payment";
                                        activeColor = const Color(0xFFEAB308);
                                        bgLight = const Color(0xFFFEFCE8);
                                        textColor = isSelected ? const Color(0xFF854D0E) : const Color(0xFF1E293B);
                                        subtitleColor = isSelected ? const Color(0xFFA16207) : const Color(0xFF64748B);
                                        // Beautiful custom division symbol widget (÷)
                                        iconWidget = Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 3.5,
                                              height: 3.5,
                                              decoration: BoxDecoration(
                                                color: isSelected ? activeColor : const Color(0xFF64748B),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              width: 10,
                                              height: 1.5,
                                              color: isSelected ? activeColor : const Color(0xFF64748B),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              width: 3.5,
                                              height: 3.5,
                                              decoration: BoxDecoration(
                                                color: isSelected ? activeColor : const Color(0xFF64748B),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        );
                                      } else if (isMada) {
                                        displayTitle = "MADA";
                                        displaySubtitle = "بطاقة خصم";
                                        activeColor = const Color(0xFF06B6D4);
                                        bgLight = const Color(0xFFECFEFF);
                                        textColor = isSelected ? const Color(0xFF164E63) : const Color(0xFF1E293B);
                                        subtitleColor = isSelected ? const Color(0xFF155E75) : const Color(0xFF64748B);
                                        iconWidget = Icon(
                                          Icons.credit_card_outlined,
                                          size: 20,
                                          color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF64748B),
                                        );
                                      } else if (isMulti) {
                                        displayTitle = "MULTI";
                                        displaySubtitle = "Multi Payment";
                                        activeColor = const Color(0xFF3B82F6);
                                        bgLight = const Color(0xFFEFF6FF);
                                        textColor = isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B);
                                        subtitleColor = isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF64748B);
                                        iconWidget = Icon(
                                          Icons.local_atm_outlined,
                                          size: 20,
                                          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                                        );
                                      }

                                      return InkWell(
                                        onTap: HomeCtrl.isHomeLoader
                                            ? null
                                            : () {
                                                HomeCtrl.updatedDPOrderPaymentMethods(name);

                                                if (type.toUpperCase() == "SPLIT") {
                                                  final isPartial = HomeCtrl.selectedOrder?.paymentStatus.toLowerCase() == 'partial';
                                                  final payableAmount = isPartial
                                                      ? HomeCtrl.remainingPayableForOrder(context, HomeCtrl.selectedOrder)
                                                      : HomeCtrl.payableTotalForOrder(context, HomeCtrl.selectedOrder);

                                                  context.read<PayBillCashAmountProvider>().setFromNetAmt(payableAmount);
                                                  context.read<PayBillCardAmountProvider>().setFromNetAmt(payableAmount);
                                                }
                                              },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          decoration: BoxDecoration(
                                            color: isSelected ? bgLight : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected ? activeColor : const Color(0xFFE2E8F0),
                                              width: isSelected ? 1.5 : 1.0,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          child: Stack(
                                            children: [
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    // Left Icon
                                                    iconWidget,
                                                    const SizedBox(width: 6),
                                                    // Center Column
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          FittedBox(
                                                            fit: BoxFit.scaleDown,
                                                            alignment: Alignment.centerLeft,
                                                            child: Text(
                                                              displayTitle,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                                color: textColor,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 1),
                                                          FittedBox(
                                                            fit: BoxFit.scaleDown,
                                                            alignment: Alignment.centerLeft,
                                                            child: Text(
                                                              displaySubtitle,
                                                              style: TextStyle(
                                                                fontSize: 9,
                                                                fontWeight: FontWeight.w600,
                                                                color: subtitleColor,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Positioned(
                                                  top: 0,
                                                  right: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(1.5),
                                                    decoration: BoxDecoration(
                                                      color: activeColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 8,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              if (HomeCtrl.PayMethodType.toString().toUpperCase() != "SPLIT" &&
                                  HomeCtrl.PayMethodType.toString().toUpperCase() != "MULTI-PAYMENT" &&
                                  HomeCtrl.PayMethodName.toString().toUpperCase() != "MULTI") ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Selected: ${HomeCtrl.PayMethodName}",
                                            style: CommonWidget.CommonTitleTextStyle(
                                              color: const Color(0xFF64748B),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.credit_card_outlined,
                                          color: Color(0xFF4F46E5),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "SAR ${(() {
                                            final order = HomeCtrl.selectedOrder;
                                            if (order == null) return "0.00";
                                            final isPartial = order.paymentStatus.toLowerCase() == 'partial';
                                            final amount = isPartial ? HomeCtrl.remainingPayableForOrder(context, order) : HomeCtrl.payableTotalForOrder(context, order);
                                            return amount.toStringAsFixed(2);
                                          })()}",
                                          style: CommonWidget.CommonTitleTextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                              if (HomeCtrl.PayMethodType.toString().toUpperCase() == "SPLIT") ...[
                                const SizedBox(height: 8),
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Cash Amount (SAR)",
                                              style: CommonWidget.CommonTitleTextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF64748B),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            PayBillCashAmount(),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Card Amount (SAR)",
                                              style: CommonWidget.CommonTitleTextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF64748B),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            PayBillCardAmount(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.balance, size: 12, color: Color(0xFFEA580C)),
                                    label: const Text(
                                      "Split 50/50",
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFEA580C),
                                      ),
                                    ),
                                    onPressed: () {
                                      final isPartial = HomeCtrl.selectedOrder?.paymentStatus.toLowerCase() == 'partial';
                                      final payableAmount = isPartial
                                          ? HomeCtrl.remainingPayableForOrder(context, HomeCtrl.selectedOrder)
                                          : HomeCtrl.payableTotalForOrder(context, HomeCtrl.selectedOrder);

                                      context.read<PayBillCashAmountProvider>().setFromNetAmt(payableAmount);
                                      context.read<PayBillCardAmountProvider>().setFromNetAmt(payableAmount);
                                    },
                                  ),
                                ),
                              ],
                              if (HomeCtrl.PayMethodType.toString().toUpperCase() == "MULTI-PAYMENT" ||
                                  HomeCtrl.PayMethodName.toString().toUpperCase() == "MULTI") ...[
                                const SizedBox(height: 8),
                                _MultiPaymentWidget(
                                  payableAmount: HomeCtrl.selectedOrder?.paymentStatus.toLowerCase() == 'partial'
                                      ? HomeCtrl.remainingPayableForOrder(context, HomeCtrl.selectedOrder)
                                      : HomeCtrl.payableTotalForOrder(context, HomeCtrl.selectedOrder),
                                  paymentMethods: HomeCtrl.PayBillPaymentListing,
                                  isLoading: HomeCtrl.isHomeLoader,
                                ),
                              ],
                            ],
                          ),
                        ),
                        //-✅--End Adjust Order Section-----------------✅-//
                        //..
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Bottom fixed buttons (Pay + Pay & Mark Completed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
                    ),
                  ),
                  child: Builder(
                    builder: (context) {
                      final order = HomeCtrl.selectedOrder;
                      if (order == null) return const SizedBox.shrink();

                      final grandTotal = HomeCtrl.payableTotalForOrder(context, order);
                      final double refundAmt = (order.totalPaidAmount - grandTotal).clamp(0.0, double.infinity);
                      final bool isRefund = refundAmt > 0.01;

                      final isPartial = order.paymentStatus.toLowerCase() == 'partial';
                      final amount = isPartial
                          ? HomeCtrl.remainingPayableForOrder(context, order)
                          : grandTotal;
                      final amtStr = amount.toStringAsFixed(2);

                      if (isRefund) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFEDD5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Refund to Customer",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFC2410C),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Paid ﷼ ${order.totalPaidAmount.toStringAsFixed(2)} · Owed ﷼ ${grandTotal.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFFF97316),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "﷼ ${refundAmt.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFC2410C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF97316),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.rotate_left, size: 18),
                                    label: const Text(
                                      "Process Refund",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: HomeCtrl.isHomeLoader
                                        ? null
                                        : () async {
                                            bool isConnected = await GlobalFunction()
                                                .checkInternetConnection(context);
                                            if (isConnected) {
                                              HomeCtrl.PayBillPaymentServiceAPI(
                                                context,
                                                markCompleted: false, // 🔴 Set false so the refund doesn't complete the order!
                                              );
                                            }
                                          },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      foregroundColor: const Color(0xFF475569),
                                    ),
                                    onPressed: () {
                                      HomeCtrl.closePanel();
                                    },
                                    child: const Text(
                                      "Close",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Amount to collect",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                "﷼ $amtStr",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD01B69),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD01B69),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: HomeCtrl.isPayBillPayLoading
                                      ? const SizedBox.shrink()
                                      : const Icon(Icons.payments_outlined, size: 18),
                                  label: HomeCtrl.isPayBillPayLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2))
                                      : Text(
                                          "Pay $amtStr",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                  onPressed: HomeCtrl.isHomeLoader
                                      ? null
                                      : () async {
                                          bool isConnected = await GlobalFunction()
                                              .checkInternetConnection(context);
                                          if (isConnected) {
                                            HomeCtrl.PayBillPaymentServiceAPI(
                                              context,
                                              markCompleted: false,
                                            );
                                          }
                                        },
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: HomeCtrl.isPayBillCompleteLoading
                                      ? const SizedBox.shrink()
                                      : const Icon(Icons.check, size: 18),
                                  label: HomeCtrl.isPayBillCompleteLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2))
                                      : const Text(
                                          "Pay & Complete",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                  onPressed: HomeCtrl.isHomeLoader
                                      ? null
                                      : () async {
                                          bool isConnected = await GlobalFunction()
                                              .checkInternetConnection(context);
                                          if (isConnected) {
                                            HomeCtrl.PayBillPaymentServiceAPI(
                                              context,
                                              markCompleted: true,
                                            );
                                          }
                                        },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Platform.isIOS ? const SizedBox(height: 15) : const SizedBox(height: 5),
                Platform.isIOS ? SizedBox(height: 15) : SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🔹 Helper methods for order rows
  Widget buildOrderItemsRow(HomeProvider HomeCtrl) {
    final order = HomeCtrl.selectedOrder;
    if (order == null || order.details.isEmpty) {
      return Text(
        "N/A",
        style: CommonWidget.CommonTitleTextStyle(
          color: GlobalAppColor.HomeLightTextColor,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // ✅ Show ALL non-modifier items — same filter as the expanded order card
    final items = order.details
        .where((d) => d.itemType.toLowerCase() != 'modifier')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((detail) {
        final name = detail.name != 'N/A' ? detail.name : detail.product.mPName;
        final qty = detail.quantity;
        final subtotal = double.tryParse(detail.subtotal) ?? 0.0;
        final isCancelled = detail.status.toLowerCase() == 'cancelled';

        // ✅ Modifiers linked to this item (same dual-key logic as expanded order card)
        // Handles both numeric order_det_id link and cart_uuid link from server
        final linkedMods = order.details
            .where(
              (d) =>
                  d.itemType.toLowerCase() == 'modifier' &&
                  (d.link == detail.orderDetId.toString() ||
                      (detail.cartUuid != null && d.link == detail.cartUuid)),
            )
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      // Show modifier info in Pay Bill name:
                      // Priority 1: linked modifier rows (new orders)
                      // Priority 2: ||MOD|| note (new merge format)
                      // Priority 3: plain note with inflated rate (old merge format)
                      // Priority 4: no note but rate > catalog (backend dropped note — show "+ add-on")
                      linkedMods.isNotEmpty
                          ? "$name + ${linkedMods.map((m) => m.name != 'N/A' && m.name.isNotEmpty ? m.name : (m.product.mPName != 'N/A' ? m.product.mPName : (m.note != 'N/A' ? m.note : ''))).join(', ')}"
                          : () {
                              final rawNote = detail.note;
                              final double itemRate =
                                  double.tryParse(detail.price) ?? 0;
                              final double basePrice =
                                  double.tryParse(detail.product.price) ?? 0;

                              if (rawNote != 'N/A' && rawNote.isNotEmpty) {
                                if (rawNote.contains('||MOD||')) {
                                  final modPart = rawNote
                                      .split('||MOD||')
                                      .last
                                      .trim();
                                  if (modPart.isNotEmpty) {
                                    return '$name + $modPart';
                                  }
                                } else if (itemRate > basePrice) {
                                  final modPart = rawNote.contains(' | ')
                                      ? rawNote.split(' | ').last.trim()
                                      : rawNote;
                                  if (modPart.isNotEmpty) {
                                    return '$name + $modPart';
                                  }
                                }
                              } else if (itemRate > basePrice) {
                                // Backend dropped the note field —
                                // price inflation confirms an add-on was selected
                                return '$name + add-on';
                              }
                              return name;
                            }(),
                      style: CommonWidget.CommonTitleTextStyle(
                        color: isCancelled
                            ? GlobalAppColor.HomeLightTextColor
                            : GlobalAppColor.HomeDarkTextColor,
                        fontWeight: FontWeight.w500,
                        decoration: isCancelled && qty == 0
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "× $qty",
                    style: CommonWidget.CommonTitleTextStyle(
                      color: GlobalAppColor.ButtonColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isCancelled && qty == 0
                        ? "—"
                        : "SAR ${subtotal.toStringAsFixed(2)}",
                    style: CommonWidget.CommonTitleTextStyle(
                      color: isCancelled && qty == 0
                          ? GlobalAppColor.HomeLightTextColor
                          : GlobalAppColor.HomeDarkTextColor,
                      fontWeight: FontWeight.w600,
                      decoration: isCancelled && qty == 0
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildOrderSummaryRow(BuildContext context, HomeProvider HomeCtrl) {
    final order = HomeCtrl.selectedOrder;
    if (order == null) {
      return const SizedBox.shrink();
    }
    final tableCharge = HomeCtrl.paymentTableChargeForOrder(context, order);
    final payableTotal = HomeCtrl.payableTotalForOrder(context, order);

    // Pre-discount subtotal (recover original if backend stored it post-discount).
    final double origSubtotal = order.calculatedSubtotal +
        (double.tryParse(order.discountAmt) ?? 0.0);
    final bool hasDiscount = HomeCtrl.payBillDiscountPer > 0;
    final double discountAmt = hasDiscount
        ? (origSubtotal * HomeCtrl.payBillDiscountPer) / 100.0
        : 0.0;
    final double subtotalAfterDiscount =
        hasDiscount ? origSubtotal - discountAmt : order.calculatedSubtotal;
    final double adjust = double.tryParse(order.adjustAmt) ?? 0.0;

    // Scale taxes based on live discount
    final double discountScale = (100.0 - HomeCtrl.payBillDiscountPer) / 100.0;
    final double liveTotalTax = order.displayTotalTax * discountScale;

    // Net Amount = Total After Discount - Total Tax
    final double netAmount = subtotalAfterDiscount - liveTotalTax;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header title
          Text(
            "ORDER SUMMARY",
            style: CommonWidget.CommonTitleTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF475569),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),

           // ── Items Total ──────────────────────────────────────────
          _buildSummaryRow(
            label: "Items Total",
            amount: origSubtotal.toStringAsFixed(2),
            labelColor: const Color(0xFF64748B),
            amountColor: const Color(0xFF334155),
          ),
          const SizedBox(height: 12),

          // ── Active Discount Row (Green text & pill badge) ────────
          if (hasDiscount) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      "Discount",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
                      ),
                      child: Text(
                        "${HomeCtrl.payBillDiscountPer.toInt()}%",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  "﷼ -${discountAmt.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── Net Amount (Blue) ────────────────────────────────────
          _buildSummaryRow(
            label: "Net Amount",
            amount: netAmount.toStringAsFixed(2),
            labelColor: const Color(0xFF2563EB),
            amountColor: const Color(0xFF2563EB),
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 12),

          // ── Collapsible Tax Section (Purple, Collapsible) ────────
          if (liveTotalTax > 0.01) ...[
            _CollapsibleTaxRow(
              order: order,
              scale: discountScale,
              liveTotalTax: liveTotalTax,
            ),
            const SizedBox(height: 12),
          ],

          // ── Adjustment (if != 0) ───────────────────────────────────────
          if (adjust.abs() >= 0.01) ...[
            _buildSummaryRow(
              label: adjust > 0 ? "Addition" : "Deduction",
              amount: adjust.abs().toStringAsFixed(2),
              labelColor: adjust > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              amountColor: adjust > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              prefix: adjust > 0 ? "+ " : "- ",
            ),
            const SizedBox(height: 12),
          ],

          // ── Table Charge ──
          if (tableCharge > 0) ...[
            _buildSummaryRow(
              label: "Table Charge",
              amount: tableCharge.toStringAsFixed(2),
              labelColor: const Color(0xFFF59E0B),
              amountColor: const Color(0xFFF59E0B),
              prefix: '+ ',
            ),
            const SizedBox(height: 12),
          ],

          // Divider
          const Divider(height: 24, thickness: 1.5, color: Color(0xFFF1F5F9)),

          // ── Total (after discount) ───────────────────────────────
          _buildSummaryRow(
            label: "Total (after discount)",
            amount: subtotalAfterDiscount.toStringAsFixed(2),
            labelColor: const Color(0xFF64748B),
            amountColor: const Color(0xFF334155),
          ),

          // Divider
          const Divider(height: 24, thickness: 1.5, color: Color(0xFFF1F5F9)),

          // ── Grand Total (Pink) ───────────────────────────────────
          _buildSummaryRow(
            label: "Grand Total",
            amount: payableTotal.toStringAsFixed(2),
            labelColor: const Color(0xFF1E293B),
            amountColor: const Color(0xFFD01B69),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  //-✅--PayBill Discount Section Widget-----------------------------------✅-//
  Widget _buildPayBillDiscountSection(
    BuildContext context,
    HomeProvider HomeCtrl,
  ) {
    final isLocked = !HomeCtrl.payBillDiscountUnlocked;
    final discountPer = HomeCtrl.payBillDiscountPer;
    final _postDiscountSubtotal = HomeCtrl.selectedOrder?.calculatedSubtotal ?? 0.0;
    final _storedDiscountAmt = double.tryParse(
          HomeCtrl.selectedOrder?.discountAmt ?? '0',
        ) ?? 0.0;
    final subtotal = _postDiscountSubtotal + _storedDiscountAmt;
    final discountAmt = (subtotal * discountPer) / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: title + lock badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "DISCOUNT",
                style: CommonWidget.CommonTitleTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
              // Dynamic lock badge pill
              GestureDetector(
                onTap: () {
                  if (!isLocked && !HomeCtrl.isHomeLoader) {
                    HomeCtrl.setPayBillDiscountUnlocked(false);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLocked ? const Color(0xFFF1F5F9) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLocked ? const Color(0xFFE2E8F0) : const Color(0xFFA7F3D0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
                        size: 12,
                        color: isLocked ? const Color(0xFF64748B) : const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLocked ? 'Locked' : 'Unlocked',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isLocked ? const Color(0xFF64748B) : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Body Row: central pink input box + Right state card
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Central Pink Input Container
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLocked ? const Color(0xFFF8FAFC) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD01B69),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isLocked) ...[
                        const Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: TextField(
                          controller: HomeCtrl.payBillDiscountController,
                          enabled: !isLocked && !HomeCtrl.isHomeLoader,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD01B69),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Enter %',
                            hintStyle: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onChanged: (val) {
                            if (isLocked) return;
                            final parsed = double.tryParse(val) ?? 0.0;
                            if (parsed > 100) {
                              HomeCtrl.setPayBillDiscount(100);
                              return;
                            }
                            HomeCtrl.setPayBillDiscount(parsed);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "%",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Right state card (Outlined button when locked, Saving capsule card when unlocked)
              if (isLocked)
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    icon: const Icon(
                      Icons.lock_open_outlined,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    label: const Text(
                      "Unlock",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: HomeCtrl.isHomeLoader
                        ? null
                        : () async {
                            await HomeCtrl.showPayBillDiscountAuthDialog(
                              context,
                              onAuthorized: () {},
                            );
                          },
                  ),
                )
              else
                // Saving capsule card
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD1FAE5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Saving",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "﷼ ${discountAmt.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          // Bottom dynamic caption message
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
                size: 12,
                color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF10B981),
              ),
              const SizedBox(width: 4),
              Text(
                isLocked
                    ? "hit Unlock button to edit discount."
                    : "Unlocked for 30s — modify freely",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper method to build a single summary row
  Widget _buildSummaryRow({
    required String label,
    required String amount,
    Color labelColor = const Color(0xFF6B7280),
    Color amountColor = const Color(0xFF374151),
    FontWeight fontWeight = FontWeight.w500,
    double fontSize = 13,
    String prefix = "",
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontWeight: fontWeight,
              fontSize: fontSize,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          "${prefix}﷼ $amount",
          style: TextStyle(
            color: amountColor,
            fontWeight: fontWeight,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }

  //-✅--getStatusColor---------------------------------------------------✅-//
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "cancelled":
        return Colors.white;
      case "preparing":
        return GlobalAppColor.DarkBlueColor;
      case "prepared":
        return GlobalAppColor.RedCode.withOpacity(.5);
      case "served":
        return GlobalAppColor.AvailableCode;

      case "ordered":
        return const Color(0xFFCA8A04);

      default:
        return const Color(0xFFCA8A04); // fallback
    }
  }

  //-✅--getStatusBgColor-------------------------------------------------✅-//
  Color getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case "cancelled":
        return Colors.red.withOpacity(.6);
      case "preparing":
        return GlobalAppColor.DarkBlueColor.withOpacity(0.15);
      case "prepared":
        return const Color(0xFFFCE7F3);
      case "served":
        return GlobalAppColor.AvailableCode.withOpacity(0.15);

      case "ordered":
        return const Color(0xFFFEF9C3);

      default:
        return const Color(0xFFFEF9C3);
    }
  }

  //-✅--getPriorityColor-------------------------------------------------✅-//
  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case "high":
        return Colors.orange;
      case "normal":
      case "paid":
        return GlobalAppColor.AvailableCode;
      case "urgent":
        return GlobalAppColor.RedCode;
      default:
        return GlobalAppColor.HomeLightTextColor;
    }
  }

  //-✅--getPriorityBgColor-------------------------------------------------✅-//
  Color getPriorityBgColor(String priority) {
    switch (priority.toLowerCase()) {
      case "high":
        return Colors.orange.withOpacity(0.15);
      case "normal":
      case "paid":
        return GlobalAppColor.AvailableCode.withOpacity(0.15);
      case "urgent":
        //paymentStatus
        return GlobalAppColor.RedCode.withOpacity(0.15);
      default:
        return GlobalAppColor.HomeLightTextColor.withOpacity(0.15);
    }
  }

  //-✅--ViewAllNotificationWidget-----------------------------------------✅-//
  Widget ViewAllNotificationWidget(
    BuildContext context,
    HomeProvider HomeCtrl,
  ) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isPortrait = screenHeight >= screenWidth;

    double panelWidth;
    if (screenWidth >= 1200) {
      panelWidth = screenWidth * 0.25;
    } else if (screenWidth >= 800) {
      panelWidth = screenWidth * 0.35;
    } else {
      panelWidth = screenWidth * 0.8;
    }

    // Max width for web
    panelWidth = panelWidth > 500 ? 500 : panelWidth;

    return Stack(
      children: [
        // 🔒 Overlay
        if (HomeCtrl.isNotificationPanelOpen)
          AbsorbPointer(
            absorbing: true,
            child: Container(color: Colors.black45),
          ),

        // 2️⃣ Side panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          right: HomeCtrl.isNotificationPanelOpen ? 0 : -panelWidth,
          top: MediaQuery.of(context).padding.top,
          bottom: screenWidth > 900 ? 0 : (60.0 + MediaQuery.of(context).padding.bottom),
          width: panelWidth,
          child: Material(
            elevation: 16,
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              bottomLeft: Radius.circular(5),
            ),
            child: Column(
              children: [
                SizedBox(height: 5),
                // Header
                Container(
                  height: kToolbarHeight,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  color: GlobalAppColor.WhiteColorCode,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.notifications,
                            color: GlobalAppColor.ButtonDarkColor,
                            size: 20,
                          ),
                          SizedBox(width: 5),
                          Text(
                            "Prepared Items",
                            style: CommonWidget.CommonTitleTextStyle(
                              fontSize: isPortrait ? 18 : 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: GlobalAppColor.BodyBgColorCode,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              HomeCtrl.PreparedCount ?? '0',
                              style: CommonWidget.CommonTitleTextStyle(
                                color: GlobalAppColor.ButtonColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: GlobalAppColor.DarkTextColorCode.withOpacity(
                            .6,
                          ),
                        ),
                        onPressed: () => HomeCtrl.closeNotificationPanel(),
                      ),
                    ],
                  ),
                ),
                CommonWidget().DividerWidget(),

                // Scrollable content
                Expanded(
                  child:
                      (HomeCtrl.NotificationListing != null &&
                          HomeCtrl.NotificationListing.isNotEmpty)
                      ? ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: HomeCtrl.NotificationListing.length,
                          itemBuilder: (context, index) {
                            final item = HomeCtrl.NotificationListing[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: GlobalAppColor.WhiteColorCode,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: GlobalAppColor.ButtonColor.withOpacity(
                                    .5,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ---------- TOP ROW ----------
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        size: 22,
                                        color: Colors.pink,
                                      ),

                                      const SizedBox(width: 6),

                                      Expanded(
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              "#${item.orderId}",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),

                                            _tag(
                                              "Table ${item.tableId}",
                                              Colors.pink.shade50,
                                              Colors.pink.shade400,
                                            ),

                                            _tag(
                                              item.priority,
                                              Colors.orange.shade50,
                                              Colors.orange.shade500,
                                            ),
                                          ],
                                        ),
                                      ),

                                      Text(
                                        GlobalFunction().formatTime(
                                          item.preparedAt.toString(),
                                        ),
                                        style:
                                            CommonWidget.CommonTitleTextStyle(
                                              fontSize: 13,
                                              color: GlobalAppColor
                                                  .HomeLightTextColor,
                                            ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    item.customerName.isNotEmpty
                                        ? item.customerName
                                        : 'Guest',
                                    style: CommonWidget.CommonTitleTextStyle(
                                      fontSize: 13,
                                      color: GlobalAppColor.HomeLightTextColor,
                                    ),
                                  ),

                                  // ---------- BOTTOM ROW ----------
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Text(
                                              "${item.quantity}x ${item.itemName}",
                                              style:
                                                  CommonWidget.CommonTitleTextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),

                                            _tag(
                                              "Station ${item.stationId}",
                                              Colors.blue.shade50,
                                              Colors.blue.shade600,
                                            ),
                                          ],
                                        ),
                                      ),

                                      InkWell(
                                        onTap: HomeCtrl.isHomeLoader
                                            ? null
                                            : () async {
                                                final isConnected =
                                                    await GlobalFunction()
                                                        .checkInternetConnection(
                                                          context,
                                                        );
                                                if (isConnected) {
                                                  await HomeCtrl.OrderServedService(
                                                    context,
                                                    "served",
                                                    item.itemId.toString(),
                                                  );
                                                }
                                              },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            "Mark Served",
                                            style:
                                                CommonWidget.CommonTitleTextStyle(
                                                  fontSize: 13,
                                                  color: Colors.green.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            "No Prepared Items Found",
                            style: CommonWidget.CommonTitleTextStyle(
                              fontSize: 16,
                              color: GlobalAppColor.HomeLightTextColor,
                            ),
                          ),
                        ),
                ),

                Platform.isIOS ? SizedBox(height: 15) : SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tag(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: CommonWidget.CommonTitleTextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  //-✅--Print Bill Handler (Cashier Receipt)----------------------------✅-//
  /// Prints customer bill/receipt for cashier printer
  Future<void> _handlePrintBill(BuildContext context, OrderData order) async {
    // Show printer selection dialog for bill printing
    _showBillPrintDialog(context, order);
  }

  //-✅--Print to KDS Handler (Kitchen Ticket)----------------------------✅-//
  /// Prints kitchen ticket to KDS printer
  Future<void> _handlePrintToKDS(BuildContext context, OrderData order) async {
    // Show KDS print options dialog
    _showKdsPrintDialog(context, order);
  }

  //-✅--Show Bill Print Dialog-------------------------------------------✅-//
  /// Shows dialog to select printer and print customer bill
  void _showBillPrintDialog(BuildContext context, OrderData order) {
    showDialog(
      context: context,
      builder: (context) => _BillPrintDialog(order: order),
    );
  }

  //-✅--Show KDS Print Dialog--------------------------------------------✅-//
  /// Shows dialog to select KDS printer and print format
  void _showKdsPrintDialog(BuildContext context, OrderData order) {
    showDialog(
      context: context,
      builder: (context) => _KdsPrintDialog(order: order),
    );
  }

  //-✅--Refund Dialog------------------------------------------------------✅-//
  /// Supports multiple partial refunds matching web app RefundModal logic exactly.
  /// maxRefund = total_amt + adjust_amt − already_refunded
  /// Sends integer pay_m_id to backend (matches web app behavior).
  Future<void> _showRefundDialog(
    BuildContext context,
    HomeProvider HomeCtrl,
    OrderData order,
  ) async {
    // ── Load payment methods if not already loaded (web app fetches on modal open) ──
    if (HomeCtrl.PayBillPaymentListing.isEmpty) {
      await HomeCtrl.getPayBillPaymentMethodsListService(context);
    }

    // ── Compute limits — use fullPayableTotal (includes modifier prices) + adjust − refund ──
    final double alreadyRefunded = double.tryParse(order.refundAmt) ?? 0.0;
    final double rawTotal =
        order.calculatedSubtotal +
        (double.tryParse(order.adjustAmt) ?? 0.0) +
        order.tableCharge;
    final double maxRefundable = (rawTotal - alreadyRefunded).clamp(
      0.0,
      double.infinity,
    );

    // Pre-fill with remaining refundable (same as web app handleFullRefund default)
    final amountCtrl = TextEditingController(
      text: maxRefundable > 0 ? maxRefundable.toStringAsFixed(2) : '0.00',
    );
    final remarkCtrl = TextEditingController(
      text: 'Refund for Order #${order.orderNo}',
    );

    // ── Payment method selection — use real models with integer IDs ──
    PaymentMethodsPayBillModel? selectedMethod =
        HomeCtrl.PayBillPaymentListing.isNotEmpty
        ? HomeCtrl.PayBillPaymentListing.first
        : null;

    String? amountError;
    String? remarkError;
    String? methodError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          // ── Live calculations inside dialog (recomputed on every setState) ──
          final double enteredAmt =
              double.tryParse(amountCtrl.text.trim()) ?? 0.0;
          // finalTotalAfterRefund = grandTotal − alreadyRefunded − thisRefundAmount
          // Matches web app: grandTotal - alreadyRefunded - parseFloat(refundAmount||0)
          final double finalAfterRefund =
              rawTotal - alreadyRefunded - enteredAmt;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            title: Row(
              children: [
                const Icon(
                  Symbols.currency_exchange,
                  color: Color(0xFFDC2626),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Process Refund',
                    style: CommonWidget.CommonTitleTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Order #${order.orderNo.toString().padLeft(4, '0')}',
                  style: CommonWidget.CommonTitleTextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Order Summary ──
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Summary',
                            style: CommonWidget.CommonTitleTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildRefundSummaryRow(
                            'Grand Total',
                            'SAR ${rawTotal.toStringAsFixed(2)}',
                            valueColor: Colors.black87,
                          ),
                          const SizedBox(height: 4),
                          _buildRefundSummaryRow(
                            'Already Refunded',
                            alreadyRefunded > 0
                                ? '- SAR ${alreadyRefunded.toStringAsFixed(2)}'
                                : 'SAR 0.00',
                            valueColor: const Color(0xFFDC2626),
                          ),
                          const Divider(height: 12),
                          _buildRefundSummaryRow(
                            'Remaining Refundable',
                            'SAR ${maxRefundable.toStringAsFixed(2)}',
                            valueColor: const Color(0xFF16A34A),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Fully Refunded Banner ──
                    if (maxRefundable <= 0) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFFDC2626),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This order has been fully refunded.',
                                style: CommonWidget.CommonTitleTextStyle(
                                  color: const Color(0xFF991B1B),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // ── Refund Amount ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Refund Amount',
                            style: CommonWidget.CommonTitleTextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              amountCtrl.text = maxRefundable.toStringAsFixed(
                                2,
                              );
                              setState(() => amountError = null);
                            },
                            child: const Text(
                              'Refund Full Amount',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2563EB),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() => amountError = null),
                        decoration: InputDecoration(
                          hintText: 'Enter refund amount',
                          prefixText: 'SAR  ',
                          helperText:
                              'Max refundable: SAR ${maxRefundable.toStringAsFixed(2)}',
                          errorText: amountError,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Refund Payment Method — real methods from API with integer IDs ──
                      Text(
                        'Refund Payment Method',
                        style: CommonWidget.CommonTitleTextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (HomeCtrl.PayBillPaymentListing.isEmpty) ...[
                        Text(
                          'No payment methods available.',
                          style: CommonWidget.CommonTitleTextStyle(
                            fontSize: 12,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ] else ...[
                        // Dropdown matching web app select element
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: methodError != null
                                  ? const Color(0xFFDC2626)
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<PaymentMethodsPayBillModel>(
                              value: selectedMethod,
                              isExpanded: true,
                              hint: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('Select Payment Method'),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              items: HomeCtrl.PayBillPaymentListing.map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    m.name.isNotEmpty
                                        ? m.name
                                        : 'Method #${m.payMId}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (m) => setState(() {
                                selectedMethod = m;
                                methodError = null;
                              }),
                            ),
                          ),
                        ),
                        if (methodError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            methodError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Available methods chips (web app style)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Payment Methods:',
                                style: CommonWidget.CommonTitleTextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: HomeCtrl.PayBillPaymentListing.take(5)
                                    .map((m) {
                                      final bool isSelected =
                                          selectedMethod?.payMId == m.payMId;
                                      return GestureDetector(
                                        onTap: () => setState(() {
                                          selectedMethod = m;
                                          methodError = null;
                                        }),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFFDCFCE7)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF16A34A)
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            m.name.isNotEmpty
                                                ? m.name
                                                : 'Method #${m.payMId}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? const Color(0xFF15803D)
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // ── Refund Reason (required — web app validates) ──
                      Text(
                        'Refund Reason',
                        style: CommonWidget.CommonTitleTextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: remarkCtrl,
                        maxLines: 3,
                        maxLength: 255,
                        onChanged: (_) => setState(() => remarkError = null),
                        decoration: InputDecoration(
                          hintText: 'Enter reason for refund...',
                          errorText: remarkError,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Live "Final Amount After Refund" (matches web app green box) ──
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: finalAfterRefund >= 0
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: finalAfterRefund >= 0
                                ? const Color(0xFFBBF7D0)
                                : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Final Amount After Refund:',
                                  style: CommonWidget.CommonTitleTextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: finalAfterRefund >= 0
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF991B1B),
                                  ),
                                ),
                                Text(
                                  'SAR ${finalAfterRefund.toStringAsFixed(2)}',
                                  style: CommonWidget.CommonTitleTextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: finalAfterRefund >= 0
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                finalAfterRefund >= 0
                                    ? 'Customer balance after refund'
                                    : 'Refund exceeds order amount',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: finalAfterRefund >= 0
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              if (maxRefundable > 0)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    // ── Validate (matches web app validateForm) ──
                    bool valid = true;
                    final double? amount = double.tryParse(
                      amountCtrl.text.trim(),
                    );
                    if (amount == null || amount <= 0) {
                      setState(
                        () =>
                            amountError = 'Please enter a valid refund amount',
                      );
                      valid = false;
                    } else if (amount > maxRefundable) {
                      setState(
                        () => amountError =
                            'Cannot refund more than SAR ${maxRefundable.toStringAsFixed(2)}',
                      );
                      valid = false;
                    }
                    if (selectedMethod == null) {
                      setState(
                        () => methodError = 'Please select a payment method',
                      );
                      valid = false;
                    }
                    if (remarkCtrl.text.trim().isEmpty) {
                      setState(
                        () => remarkError = 'Please enter a refund reason',
                      );
                      valid = false;
                    }
                    if (!valid) return;

                    Navigator.pop(ctx);
                    await HomeCtrl.refundOrderService(
                      context,
                      orderId: order.orderId,
                      refundAmount: amount!,
                      refundPaymentMethodId: selectedMethod!.payMId,
                      refundRemark: remarkCtrl.text.trim(),
                    );
                  },
                  child: const Text(
                    'Process Refund',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Helper: builds a label-value row for the refund summary box.
  Widget _buildRefundSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: CommonWidget.CommonTitleTextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: CommonWidget.CommonTitleTextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  //-✅--Partial Payment Dialog-------------------------------------------✅-//
  /// Matches web app PartialPayment modal.
  /// POST /order-master/partial-pay  body: {order_id, amount, pay_method_id, remark?, ref_no?}
  /// Available for unpaid and partially-paid orders.
  Future<void> _showPartialPaymentDialog(
    BuildContext context,
    HomeProvider HomeCtrl,
    OrderData order,
  ) async {
    // ── Calculations ── ✅ PRODUCTION FIX: Use payments array, not Adv_payment
    final double totalAmount = HomeCtrl.payableTotalForOrder(context, order);
    final double totalPaid =
        order.totalPaidAmount; // ✅ Calculated from payments[]
    final double remainingBalance = HomeCtrl.remainingPayableForOrder(
      context,
      order,
    ); // ✅ Live calculation

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 Partial Payment Dialog opened for Order #${order.orderNo}');
    print('   Total Amount: SAR ${totalAmount.toStringAsFixed(2)}');
    print('   Total Paid: SAR ${totalPaid.toStringAsFixed(2)}');
    print('   Remaining Balance: SAR ${remainingBalance.toStringAsFixed(2)}');
    print('   Payments count: ${order.payments.length}');
    if (order.payments.isNotEmpty) {
      print('   Payment breakdown:');
      for (var p in order.payments) {
        print(
          '     - Payment ID ${p.orderPayId}: SAR ${p.amount.toStringAsFixed(2)} (${p.methodName})',
        );
      }
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final referenceCtrl = TextEditingController();

    // Use first available payment method as default
    var selectedMethod = HomeCtrl.PayBillPaymentListing.isNotEmpty
        ? HomeCtrl.PayBillPaymentListing.first
        : null;

    String? amountError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final double enteredAmt =
              double.tryParse(amountCtrl.text.trim()) ?? 0.0;
          final double newRemaining = (remainingBalance - enteredAmt).clamp(
            double.negativeInfinity,
            double.infinity,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            title: Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Partial Payment',
                    style: CommonWidget.CommonTitleTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: order.paymentStatus.toLowerCase() == 'partial'
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.paymentStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: order.paymentStatus.toLowerCase() == 'partial'
                          ? const Color(0xFF92400E)
                          : const Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Order Summary ──
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildRefundSummaryRow(
                            'Order #',
                            order.orderNo.toString().padLeft(4, '0'),
                          ),
                          const SizedBox(height: 6),
                          _buildRefundSummaryRow(
                            'Total Amount',
                            'SAR ${totalAmount.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 6),
                          _buildRefundSummaryRow(
                            'Total Paid',
                            'SAR ${totalPaid.toStringAsFixed(2)}',
                            valueColor: const Color(0xFF16A34A),
                          ),
                          const Divider(height: 12),
                          _buildRefundSummaryRow(
                            'Remaining Balance',
                            'SAR ${remainingBalance.toStringAsFixed(2)}',
                            valueColor: const Color(0xFFDC2626),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Payment Method ──
                    Text(
                      'Payment Method',
                      style: CommonWidget.CommonTitleTextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (HomeCtrl.PayBillPaymentListing.isEmpty)
                      Text(
                        'No payment methods available',
                        style: CommonWidget.CommonTitleTextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      )
                    else
                      DropdownButtonFormField<dynamic>(
                        value: selectedMethod,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: HomeCtrl.PayBillPaymentListing.map(
                          (pm) => DropdownMenuItem<dynamic>(
                            value: pm,
                            child: Text(
                              pm.name,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ).toList(),
                        onChanged: (val) =>
                            setState(() => selectedMethod = val),
                      ),
                    const SizedBox(height: 14),

                    // ── Amount ──
                    Text(
                      'Amount (SAR)',
                      style: CommonWidget.CommonTitleTextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() => amountError = null),
                      decoration: InputDecoration(
                        hintText: 'Enter payment amount',
                        prefixText: 'SAR  ',
                        helperText:
                            'Max: SAR ${remainingBalance.toStringAsFixed(2)}',
                        errorText: amountError,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Reason (Optional) ──
                    Text(
                      'Reason (Optional)',
                      style: CommonWidget.CommonTitleTextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      maxLength: 50,
                      decoration: InputDecoration(
                        hintText: 'Enter reason...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Reference (Optional) ──
                    Text(
                      'Reference (Optional)',
                      style: CommonWidget.CommonTitleTextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: referenceCtrl,
                      maxLength: 50,
                      decoration: InputDecoration(
                        hintText: 'Transaction ID / Reference no.',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // ── Live Calculation Summary ──
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        children: [
                          _buildRefundSummaryRow(
                            'Current Remaining',
                            'SAR ${remainingBalance.toStringAsFixed(2)}',
                            valueColor: Colors.grey.shade700,
                          ),
                          const SizedBox(height: 4),
                          _buildRefundSummaryRow(
                            'This Payment',
                            enteredAmt > 0
                                ? '- SAR ${enteredAmt.toStringAsFixed(2)}'
                                : 'SAR 0.00',
                            valueColor: const Color(0xFF2563EB),
                          ),
                          const Divider(height: 10),
                          _buildRefundSummaryRow(
                            'New Remaining',
                            'SAR ${newRemaining.toStringAsFixed(2)}',
                            valueColor: newRemaining <= 0
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF2563EB),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: HomeCtrl.isHomeLoader
                    ? null
                    : () async {
                        final double? amount = double.tryParse(
                          amountCtrl.text.trim(),
                        );

                        // ── Validate ──
                        if (amount == null || amount <= 0) {
                          setState(
                            () => amountError = 'Please enter a valid amount',
                          );
                          return;
                        }
                        if (amount > remainingBalance && remainingBalance > 0) {
                          setState(
                            () => amountError =
                                'Cannot exceed SAR ${remainingBalance.toStringAsFixed(2)}',
                          );
                          return;
                        }
                        if (selectedMethod == null) {
                          showCustomToast(
                            context: context,
                            message: 'Please select a payment method',
                          );
                          return;
                        }

                        Navigator.pop(ctx);

                        await HomeCtrl.createPartialPaymentService(
                          context,
                          orderId: order.orderId,
                          amount: amount,
                          paymentMethodId:
                              int.tryParse(selectedMethod!.payMId.toString()) ??
                              0,
                          remark: reasonCtrl.text.trim().isNotEmpty
                              ? reasonCtrl.text.trim()
                              : null,
                          refNo: referenceCtrl.text.trim().isNotEmpty
                              ? referenceCtrl.text.trim()
                              : null,
                        );
                      },
                child: const Text(
                  'Add Payment',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  //-✅--Cancel Order Dialog (with password) ----------------------------✅-//
  /// Matches web app initiateCancelOrder → PasswordVerificationModal → handleCancelOrder
  Future<void> _showCancelOrderDialog(
    BuildContext context,
    HomeProvider HomeCtrl,
    OrderData order,
  ) async {
    final passwordCtrl = TextEditingController();
    bool obscure = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          title: Row(
            children: [
              const Icon(Symbols.block, color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cancel Order #${order.orderNo.toString().padLeft(4, '0')}',
                  style: CommonWidget.CommonTitleTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Text(
                    'This action will cancel the entire order. Enter manager password to confirm.',
                    style: CommonWidget.CommonTitleTextStyle(
                      color: const Color(0xFF991B1B),
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  'Manager Password',
                  style: CommonWidget.CommonTitleTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final pwd = passwordCtrl.text.trim();
                if (pwd.isEmpty) {
                  showCustomToast(
                    context: context,
                    message: 'Password is required',
                  );
                  return;
                }
                Navigator.pop(ctx);
                await HomeCtrl.cancelOrderService(context, order.orderId, pwd);
              },
              child: const Text(
                'Cancel Order',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //-✅--Cancel Item Dialog (password → qty + reason) -------------------✅-//
  /// Matches web app 2-step: initiateCancelItem → password → CancelItemDetailsModal → handleCancelOrderItem
  Future<void> _showCancelItemDialog(
    BuildContext context,
    HomeProvider HomeCtrl,
    OrderDetail detail,
    String orderStatus,
  ) async {
    // ── Step 1: Password verification ──
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? verifiedPassword;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Symbols.block, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cancel Item',
                  style: CommonWidget.CommonTitleTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.name != 'N/A' ? detail.name : detail.product.mPName,
                style: CommonWidget.CommonTitleTextStyle(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Manager Password',
                style: CommonWidget.CommonTitleTextStyle(fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final pwd = passwordCtrl.text.trim();
                if (pwd.isEmpty) {
                  showCustomToast(
                    context: context,
                    message: 'Password is required',
                  );
                  return;
                }
                verifiedPassword = pwd;
                Navigator.pop(ctx);
              },
              child: const Text('Next', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (verifiedPassword == null) return; // user closed without entering

    // ── Step 2: Quantity + reason (CancelItemDetailsModal) ──
    final maxQty = detail.quantity > 0 ? detail.quantity : 1;
    int cancelQty = maxQty;
    final reasonCtrl = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Cancel Details',
            style: CommonWidget.CommonTitleTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.name != 'N/A' ? detail.name : detail.product.mPName,
                  style: CommonWidget.CommonTitleTextStyle(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Quantity to cancel (max $maxQty)',
                  style: CommonWidget.CommonTitleTextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (cancelQty > 1) setState(() => cancelQty--);
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$cancelQty',
                      style: CommonWidget.CommonTitleTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (cancelQty < maxQty) setState(() => cancelQty++);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Cancellation Reason',
                  style: CommonWidget.CommonTitleTextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter reason (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Back'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await HomeCtrl.cancelItemService(
                  context,
                  detail.orderDetId,
                  verifiedPassword!,
                  cancelQty,
                  reasonCtrl.text.trim(),
                );
              },
              child: const Text(
                'Cancel Item',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //-✅--Group Orders Dialog-----------------------------------------------✅-//
  void _showGroupOrdersDialog(BuildContext context, HomeProvider HomeCtrl) {
    HomeCtrl.resetGroupOrdersSelection();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Consumer<HomeProvider>(
        builder: (ctx, ctrl, _) {
          // Filter out premium tables where chargeable == "YES" or matches _isPremiumTable
          final eligibleOrders = ctrl.eligibleOrdersForGrouping
              .where((o) => !_isPremiumTable(context, o))
              .toList();

          final childCandidates = eligibleOrders
              .where((o) => o.orderId != ctrl.groupParentOrderId)
              .toList();

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 12,
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: MediaQuery.of(ctx).size.width > 600
                  ? 520
                  : MediaQuery.of(ctx).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gradient Premium Header
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text('🔗', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Group Orders',
                                style: CommonWidget.CommonTitleTextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Combine orders into groups',
                                style: CommonWidget.CommonTitleTextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFFE0E7FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 22),
                          onPressed: () {
                            ctrl.resetGroupOrdersSelection();
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Dialog Body Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEFF6FF), Color(0xFFECFEFF)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ℹ️', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Only today's unpaid orders that aren't completed are available for grouping.",
                                    style: CommonWidget.CommonTitleTextStyle(
                                      color: const Color(0xFF1E40AF),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Step 1: Select Parent Order
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE0E7FF),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '1',
                                  style: TextStyle(
                                    color: Color(0xFF4F46E5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Select Parent Order',
                                style: CommonWidget.CommonTitleTextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                            value: ctrl.groupParentOrderId,
                            isExpanded: true,
                            hint: Text(
                              '── Select parent order ──',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text(
                                  '── Select parent order ──',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ),
                              ...eligibleOrders.map(
                                (o) => DropdownMenuItem<int>(
                                  value: o.orderId,
                                  child: Text(
                                    'Order #${o.orderNo} ${o.tableName != 'N/A' && o.tableName != null ? '• ${o.tableName}' : ''}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: ctrl.setGroupParentOrder,
                          ),
                          if (ctrl.groupParentOrderId != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  '✓',
                                  style: TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Parent order selected',
                                  style: CommonWidget.CommonTitleTextStyle(
                                    color: const Color(0xFF16A34A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Step 2: Select Child Orders
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF3E8FF),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '2',
                                  style: TextStyle(
                                    color: Color(0xFF9333EA),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Select Child Orders',
                                style: CommonWidget.CommonTitleTextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              if (ctrl.groupChildOrderIds.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${ctrl.groupChildOrderIds.length} selected',
                                    style: CommonWidget.CommonTitleTextStyle(
                                      color: const Color(0xFF7E22CE),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          eligibleOrders.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'No eligible orders found',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : childCandidates.isEmpty
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'No other eligible orders available',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      constraints: const BoxConstraints(maxHeight: 220),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFF9FAFB), Colors.white],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: childCandidates.asMap().entries.map((entry) {
                                              final index = entry.key;
                                              final o = entry.value;
                                              final bool isChecked = ctrl.groupChildOrderIds.contains(o.orderId);
                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (index > 0)
                                                    const Divider(
                                                      color: Color(0xFFF3F4F6),
                                                      height: 1,
                                                    ),
                                                  InkWell(
                                                    onTap: () => ctrl.toggleGroupChildOrder(o.orderId),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                      child: Row(
                                                        children: [
                                                          SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child: Checkbox(
                                                              value: isChecked,
                                                              activeColor: const Color(0xFF4F46E5),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(4),
                                                              ),
                                                              onChanged: (_) => ctrl.toggleGroupChildOrder(o.orderId),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: Text(
                                                              'Order #${o.orderNo} ${o.tableName != 'N/A' && o.tableName != null ? '• ${o.tableName}' : ''}',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w500,
                                                                color: isChecked ? const Color(0xFF4F46E5) : const Color(0xFF374151),
                                                              ),
                                                            ),
                                                          ),
                                                          if (o.tableName != 'N/A' && o.tableName != null) ...[
                                                            const SizedBox(width: 8),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFFF3F4F6),
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              child: Text(
                                                                o.tableName ?? '',
                                                                style: const TextStyle(
                                                                  fontSize: 11,
                                                                  color: Color(0xFF4B5563),
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                          if (ctrl.groupParentOrderId != null && ctrl.groupChildOrderIds.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Color(0xFF16A34A),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Ready to combine: Order #${ctrl.groupParentOrderId} with ${ctrl.groupChildOrderIds.length} child order${ctrl.groupChildOrderIds.length > 1 ? 's' : ''}',
                                      style: CommonWidget.CommonTitleTextStyle(
                                        color: const Color(0xFF166534),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Actions Footer Banner
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      border: Border(
                        top: BorderSide(color: Color(0xFFF3F4F6), width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            ctrl.resetGroupOrdersSelection();
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: CommonWidget.CommonTitleTextStyle(
                              color: const Color(0xFF374151),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: (ctrl.groupParentOrderId == null || ctrl.groupChildOrderIds.isEmpty || ctrl.isHomeLoader)
                              ? null
                              : () async {
                                  final bool ok = await ctrl.groupOrdersService(ctx);
                                  if (ok && ctx.mounted) Navigator.pop(ctx);
                                },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: (ctrl.groupParentOrderId == null || ctrl.groupChildOrderIds.isEmpty)
                                  ? null
                                  : const LinearGradient(
                                      colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                              color: (ctrl.groupParentOrderId == null || ctrl.groupChildOrderIds.isEmpty)
                                  ? Colors.grey.shade300
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: (ctrl.groupParentOrderId == null || ctrl.groupChildOrderIds.isEmpty || ctrl.isHomeLoader)
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF4F46E5).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            child: ctrl.isHomeLoader
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Grouping...',
                                        style: CommonWidget.CommonTitleTextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.link, color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Group Orders',
                                        style: CommonWidget.CommonTitleTextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  //-✅--Status Pill Helper---------------------------------------------✅-//
  Widget _statusPill({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: CommonWidget.CommonTitleTextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ).copyWith(color: color),
      ),
    );
  }

  //-✅--Order Adjust Dialog (matches web)-------------------------------✅-//
  void _showOrderAdjustDialog(
    BuildContext context,
    HomeProvider homeCtrl,
    OrderData order,
  ) {
    homeCtrl.resetAdjustState();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        int step = 0; // 0 = password, 1 = tabs
        int tabIndex = 0; // 0 = Adjust Amount, 1 = Update Payment
        String direction = 'addition';
        int? selectedNewPayMId;
        bool isLoading = false;
        final splitCashCtrl = TextEditingController();
        final splitCardCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (ctx, setState) {
            final passwordCtrl = homeCtrl.adjustPasswordController;
            final amtCtrl = homeCtrl.adjustAmtController;
            final reasonCtrl = homeCtrl.adjustReasonController;
            // Use base total (without current adjustment) — backend REPLACES
            // adjust_amt each time, so the preview must be based on the
            // original order total, not fullPayableTotal (which includes the
            // existing adjustment). Matches web app behavior.
            final currentTotal = order.calculatedSubtotal;
            final orderNo = order.orderNo.toString().padLeft(4, '0');

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 420,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Title bar ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5C5C8A),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Order Adjustments - Order #$orderNo',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              homeCtrl.resetAdjustState();
                              Navigator.of(dialogContext).pop();
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Step 0: Password ──
                    if (step == 0)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Manager Authorization',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter manager password to adjust order settings',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Manager Password',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: passwordCtrl,
                              obscureText: true,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                hintText: 'Enter password',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF5C5C8A),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (passwordCtrl.text.trim().isEmpty) {
                                    showCustomToast(
                                      context: ctx,
                                      message: 'Please enter manager password',
                                    );
                                    return;
                                  }
                                  setState(() => step = 1);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5C5C8A),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Authorize & Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Step 1: Tabs ──
                    if (step == 1) ...[
                      // Tab bar
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => tabIndex = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                   bottom: BorderSide(
                                        color: tabIndex == 0
                                            ? const Color(0xFF5C5C8A)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Adjust Amount',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: tabIndex == 0
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: tabIndex == 0
                                          ? const Color(0xFF5C5C8A)
                                          : Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => tabIndex = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: tabIndex == 1
                                            ? const Color(0xFF5C5C8A)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Update Payment',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: tabIndex == 1
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: tabIndex == 1
                                          ? const Color(0xFF5C5C8A)
                                          : Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tab content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: tabIndex == 0
                              ? _buildAdjustAmountTab(
                                  ctx,
                                  setState,
                                  homeCtrl,
                                  order,
                                  direction,
                                  amtCtrl,
                                  reasonCtrl,
                                  currentTotal,
                                  orderNo,
                                  isLoading,
                                  (d) => setState(() => direction = d),
                                  () async {
                                    setState(() => isLoading = true);
                                    homeCtrl.setAdjustDirection(direction);
                                    final success = await homeCtrl
                                        .adjustOrderService(
                                          ctx,
                                          targetOrder: order,
                                        );
                                    if (!ctx.mounted) return;
                                    setState(() => isLoading = false);
                                    if (success) {
                                      Navigator.of(dialogContext).pop();
                                    }
                                  },
                                )
                              : _buildUpdatePaymentTab(
                                  ctx,
                                  setState,
                                  homeCtrl,
                                  order,
                                  selectedNewPayMId,
                                  splitCashCtrl,
                                  splitCardCtrl,
                                  isLoading,
                                  (id) =>
                                      setState(() => selectedNewPayMId = id),
                                  () async {
                                    if (selectedNewPayMId == null) {
                                      showCustomToast(
                                        context: ctx,
                                        message:
                                            'Please select a payment method',
                                      );
                                      return;
                                    }
                                    // Validate split amounts if SPLIT selected
                                    final selMethod =
                                        homeCtrl
                                            .PayBillPaymentListing.firstWhere(
                                          (m) => m.payMId == selectedNewPayMId,
                                          orElse: () =>
                                              PaymentMethodsPayBillModel(),
                                        );
                                    final isSplit = selMethod.type
                                        .toUpperCase()
                                        .contains('SPLIT');
                                    double cashout = 0;
                                    double cardout = 0;
                                    if (isSplit) {
                                      cashout =
                                          double.tryParse(
                                            splitCashCtrl.text.trim(),
                                          ) ??
                                          0;
                                      cardout =
                                          double.tryParse(
                                            splitCardCtrl.text.trim(),
                                          ) ??
                                          0;
                                      final orderTotal = order.fullPayableTotal;
                                      final diff =
                                          (cashout + cardout - orderTotal)
                                              .abs();
                                      if (diff > 0.01) {
                                        showCustomToast(
                                          context: ctx,
                                          message:
                                              'Cash + Card must equal SAR ${orderTotal.toStringAsFixed(2)}',
                                        );
                                        return;
                                      }
                                    }
                                    setState(() => isLoading = true);
                                    final success = await homeCtrl
                                        .updateOrderPaymentMethodService(
                                          ctx,
                                          order: order,
                                          newPayMId: selectedNewPayMId!,
                                          cashout: cashout,
                                          cardout: cardout,
                                        );
                                    if (!ctx.mounted) return;
                                    setState(() => isLoading = false);
                                    if (success) {
                                      Navigator.of(dialogContext).pop();
                                    }
                                  },
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Adjust Amount tab content (matches web layout)
  Widget _buildAdjustAmountTab(
    BuildContext context,
    void Function(void Function()) setState,
    HomeProvider homeCtrl,
    OrderData order,
    String direction,
    TextEditingController amtCtrl,
    TextEditingController reasonCtrl,
    double currentTotal,
    String orderNo,
    bool isLoading,
    void Function(String) onDirectionChanged,
    VoidCallback onApply,
  ) {
    final double enteredAmt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;
    final double adjustAmt = direction == 'deduction'
        ? -enteredAmt
        : enteredAmt;
    final double newTotal = currentTotal + adjustAmt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adjust Order Amount',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        // Current Total + Order No
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Total',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'SAR ${currentTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order No.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '#$orderNo',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Adjustment Type
        const Text(
          'Adjustment Type',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onDirectionChanged('addition'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: direction == 'addition'
                        ? const Color(0xFF5C5C8A)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: direction == 'addition'
                          ? const Color(0xFF5C5C8A)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        direction == 'addition'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 16,
                        color: direction == 'addition'
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Add Amount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: direction == 'addition'
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => onDirectionChanged('deduction'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: direction == 'deduction'
                        ? const Color(0xFF5C5C8A)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: direction == 'deduction'
                          ? const Color(0xFF5C5C8A)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        direction == 'deduction'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 16,
                        color: direction == 'deduction'
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Reduce Amount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: direction == 'deduction'
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Amount field
        const Text(
          'Adjustment Amount (SAR)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: amtCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            hintText: 'e.g. 25.00',
            prefixText: 'SAR ',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF5C5C8A)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Reason field
        const Text(
          'Reason (Optional)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: reasonCtrl,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            hintText: 'e.g. Manager discount',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF5C5C8A)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Preview
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _previewRow(
                'Current Total',
                'SAR ${currentTotal.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 6),
              _previewRow(
                'Adjustment',
                '${direction == 'addition' ? '+' : '-'}SAR ${enteredAmt.toStringAsFixed(2)}',
                color: direction == 'addition'
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
              const Divider(height: 12),
              _previewRow(
                'New Total',
                'SAR ${newTotal.toStringAsFixed(2)}',
                isBold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Apply button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: direction == 'addition'
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    direction == 'addition'
                        ? 'Apply Addition'
                        : 'Apply Reduction',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _previewRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? Colors.grey.shade900,
          ),
        ),
      ],
    );
  }

  /// Update Payment tab content (matches web layout)
  Widget _buildUpdatePaymentTab(
    BuildContext context,
    void Function(void Function()) setState,
    HomeProvider homeCtrl,
    OrderData order,
    int? selectedPayMId,
    TextEditingController splitCashCtrl,
    TextEditingController splitCardCtrl,
    bool isLoading,
    void Function(int) onMethodSelected,
    VoidCallback onUpdate,
  ) {
    final methods = homeCtrl.PayBillPaymentListing;
    final orderTotal = order.fullPayableTotal;

    // Determine currently assigned pay_m_id from the order
    final currentOrderPayMId = int.tryParse(order.payMId) ?? 0;

    // Find selected method to check if SPLIT
    final selectedMethod = selectedPayMId != null
        ? methods.firstWhere(
            (m) => m.payMId == selectedPayMId,
            orElse: () => PaymentMethodsPayBillModel(),
          )
        : null;
    final isSplitSelected =
        selectedMethod?.type.toUpperCase().contains('SPLIT') ?? false;

    // Parse split amounts for live summary
    final cashAmt = double.tryParse(splitCashCtrl.text.trim()) ?? 0.0;
    final cardAmt = double.tryParse(splitCardCtrl.text.trim()) ?? 0.0;

    // Icon per method type
    IconData _iconForType(String type) {
      final t = type.toUpperCase();
      if (t.contains('CASH')) return Icons.payments_outlined;
      if (t.contains('CARD')) return Icons.credit_card_outlined;
      if (t.contains('SPLIT')) return Icons.call_split;
      return Icons.payment;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'Update Payment Method',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Select a new payment method for this order',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        const Text(
          'Select New Payment Method *',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        // Payment method cards
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: methods.map((method) {
            final bool isSelected = selectedPayMId == method.payMId;
            final bool isCurrent = currentOrderPayMId == method.payMId;
            return GestureDetector(
              onTap: () {
                onMethodSelected(method.payMId);
                // Auto split 50-50 when split selected
                if (method.type.toUpperCase().contains('SPLIT')) {
                  final half = (orderTotal / 2);
                  splitCashCtrl.text = half.toStringAsFixed(2);
                  splitCardCtrl.text = half.toStringAsFixed(2);
                  setState(() {});
                }
              },
              child: Container(
                width: 130,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF5C5C8A)
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF5C5C8A).withOpacity(0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _iconForType(method.type),
                            size: 16,
                            color: isSelected
                                ? const Color(0xFF5C5C8A)
                                : Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Color(0xFF5C5C8A),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      method.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF5C5C8A)
                            : Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      method.type.isEmpty ? method.name : method.type,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // Split Payment section
        if (isSplitSelected) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Split Payment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Order Total: SAR ${orderTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cash Amount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: splitCashCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              prefixText: 'SAR ',
                              prefixStyle: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: Color(0xFF5C5C8A),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Card Amount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: splitCardCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              prefixText: 'SAR ',
                              prefixStyle: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: Color(0xFF5C5C8A),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Summary
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _previewRow('Cash', 'SAR ${cashAmt.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      _previewRow('Card', 'SAR ${cardAmt.toStringAsFixed(2)}'),
                      const Divider(height: 12),
                      _previewRow(
                        'Total',
                        'SAR ${(cashAmt + cardAmt).toStringAsFixed(2)}',
                        isBold: true,
                        color: (cashAmt + cardAmt - orderTotal).abs() < 0.01
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Split 50-50 button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      final half = (orderTotal / 2);
                      splitCashCtrl.text = half.toStringAsFixed(2);
                      splitCardCtrl.text = half.toStringAsFixed(2);
                      setState(() {});
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Split 50–50',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        // Update button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Update Payment Method',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  //-✅--Already Paid Transactions Ledger Helper---------------------------✅-//
  Widget _buildAlreadyPaidTransactions(BuildContext context, HomeProvider HomeCtrl) {
    final order = HomeCtrl.selectedOrder;
    if (order == null) return const SizedBox.shrink();

    final payments = order.payments;
    final double totalPaid = order.totalPaidAmount;
    if (totalPaid <= 0.01) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          title: Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 16,
                color: Color(0xFF4F46E5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Already Paid Ledger",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CommonWidget.CommonTitleTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "SAR ${totalPaid.toStringAsFixed(2)}",
                style: CommonWidget.CommonTitleTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            if (payments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Advance Payment",
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Text(
                      "SAR ${totalPaid.toStringAsFixed(2)}",
                      style: CommonWidget.CommonTitleTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...payments.map((p) {
                final nameLower = p.methodName.toLowerCase();
                final isCash = nameLower.contains("cash");
                final isCard = nameLower.contains("card") ||
                               nameLower.contains("visa") ||
                               nameLower.contains("mada");
                final icon = isCash 
                    ? Icons.wallet_outlined 
                    : (isCard ? Icons.credit_card_outlined : Icons.payment_outlined);
                final iconColor = isCash 
                    ? const Color(0xFF16A34A) 
                    : (isCard ? const Color(0xFF2563EB) : const Color(0xFF9333EA));

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(icon, size: 16, color: iconColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.methodName.isEmpty ? "Payment Entry" : p.methodName,
                                  style: CommonWidget.CommonTitleTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  "Transaction ID: #${p.orderPayId}",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "SAR ${p.amount.toStringAsFixed(2)}",
                            style: CommonWidget.CommonTitleTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.5, color: Color(0xFFF3F4F6)),
                  ],
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  //-✅--Refund Warning Section Helper-------------------------------------✅-//
  Widget _buildRefundWarningSection(BuildContext context, HomeProvider HomeCtrl) {
    final order = HomeCtrl.selectedOrder;
    if (order == null) return const SizedBox.shrink();

    final grandTotal = HomeCtrl.payableTotalForOrder(context, order);
    final double refundAmt = (order.totalPaidAmount - grandTotal).clamp(0.0, double.infinity);

    if (refundAmt <= 0.01) return const SizedBox.shrink();

    final double subtotal = order.calculatedSubtotal;
    final double tableCharge = HomeCtrl.paymentTableChargeForOrder(context, order);
    final double adjustAmt = double.tryParse(order.adjustAmt ?? '0') ?? 0.0;

    Widget buildSubRow(String label, double value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFC2410C),
              ),
            ),
            Text(
              "${value > 0 ? '+' : ''}﷼ ${value.abs().toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC2410C),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEA580C),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Refund Required",
                      style: CommonWidget.CommonTitleTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFC2410C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Paid ﷼ ${order.totalPaidAmount.toStringAsFixed(2)} · Owed ﷼ ${grandTotal.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFF97316),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "﷼ ${refundAmt.toStringAsFixed(2)}",
                    style: CommonWidget.CommonTitleTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFC2410C),
                    ),
                  ),
                  const Text(
                    "to refund",
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFFF97316),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (grandTotal > 0) ...[
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFFFEDD5), width: 0.8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Still owed in grand total:",
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (subtotal > 0)
                    buildSubRow("Order (after discount)", subtotal),
                  if (tableCharge > 0)
                    buildSubRow("Table charge", tableCharge),
                  if (adjustAmt.abs() > 0.01)
                    buildSubRow("Adjustment", adjustAmt),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

//-✅--Collapsible Tax Breakdown Row for Sidebar Summary Card-----------✅-//
class _CollapsibleTaxRow extends StatefulWidget {
  final OrderData order;
  final double scale;
  final double liveTotalTax;

  const _CollapsibleTaxRow({
    Key? key,
    required this.order,
    required this.scale,
    required this.liveTotalTax,
  }) : super(key: key);

  @override
  State<_CollapsibleTaxRow> createState() => _CollapsibleTaxRowState();
}

class _CollapsibleTaxRowState extends State<_CollapsibleTaxRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final hasTaxMap = order.displayTaxesMap != null &&
        order.displayTaxesMap!.entries.any(
          (e) => (double.tryParse(e.value.toString()) ?? 0) > 0,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: hasTaxMap ? () => setState(() => _expanded = !_expanded) : null,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "% Total Tax",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9333EA),
                      ),
                    ),
                    if (hasTaxMap) ...[
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 14,
                          color: Color(0xFF9333EA),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  "﷼ ${widget.liveTotalTax.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9333EA),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasTaxMap && _expanded)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                children: order.displayTaxesMap!.entries
                    .where((e) => (double.tryParse(e.value.toString()) ?? 0.0) > 0.0)
                    .map((e) {
                  final val = (double.tryParse(e.value.toString()) ?? 0.0) * widget.scale;
                  final isVat = e.key.toUpperCase().contains("VAT");
                  final color = isVat ? const Color(0xFF2563EB) : const Color(0xFF9333EA);
                  return Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "└ ${e.key}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                        Text(
                          "﷼ ${val.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collapsible tax breakdown section — mirrors the web's "% Total Tax ^" row.
// Header always shows "% Total Tax" + total amount + animated chevron.
// Tap to expand and reveal individual tax rows (VAT, excise, etc.).
// Uses AnimatedSize so IntrinsicHeight always gets the correct card height.
// ─────────────────────────────────────────────────────────────────────────────
class _CollapsibleTaxSection extends StatefulWidget {
  final OrderData item;
  const _CollapsibleTaxSection({required this.item});

  @override
  State<_CollapsibleTaxSection> createState() => _CollapsibleTaxSectionState();
}

class _CollapsibleTaxSectionState extends State<_CollapsibleTaxSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item.displayTotalTax <= 0) return const SizedBox.shrink();

    // Determine if there are individual tax rows to show
    final hasTaxMap =
        item.displayTaxesMap != null &&
        item.displayTaxesMap!.entries.any(
          (e) => (double.tryParse(e.value.toString()) ?? 0) > 0,
        );
    final canExpand = hasTaxMap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Always-visible header row ─────────────────────────────────────
        InkWell(
          onTap: canExpand
              ? () => setState(() => _expanded = !_expanded)
              : null,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.percent,
                        size: 13,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Total Tax',
                          style: CommonWidget.CommonTitleTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: GlobalAppColor.HomeLightTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (canExpand) ...[
                        const SizedBox(width: 3),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  item.displayTotalTax.toStringAsFixed(2),
                  style: CommonWidget.CommonTitleTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GlobalAppColor.HomeLightTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── Expandable individual tax rows (AnimatedSize for correct layout) ──
        if (canExpand)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: item.displayTaxesMap!.entries
                        .where(
                          (e) => (double.tryParse(e.value.toString()) ?? 0) > 0,
                        )
                        .map((e) {
                          final isVatType =
                              e.key.toString().toUpperCase().contains('VAT') ||
                              e.key.toString().toUpperCase().contains('GST');
                          final taxColor = isVatType
                              ? const Color(0xFF2563EB) // blue for VAT/GST
                              : const Color(
                                  0xFFDC2626,
                                ); // red for excise/tobacco
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2, left: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '└ ${e.key}:',
                                    style: CommonWidget.CommonTitleTextStyle(
                                      fontSize: 12,
                                      color: taxColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  double.parse(
                                    e.value.toString(),
                                  ).toStringAsFixed(2),
                                  style: CommonWidget.CommonTitleTextStyle(
                                    fontSize: 12,
                                    color: taxColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  )
                : const SizedBox.shrink(),
          ),
        // ── Divider below tax (matches original spacing before Total Amount) ─
        Divider(color: Colors.grey.shade200, height: 6, thickness: 1),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collapsible payment breakdown panel shown on every paid/partial order card.
// Collapsed by default — shows just the badge + title + chevron.
// Tap anywhere on the header to expand/collapse the detail rows.
// Logic mirrors HomeWidget.buildPaymentBreakdown; that method is left untouched.
// ─────────────────────────────────────────────────────────────────────────────
class _CollapsiblePaymentBreakdown extends StatefulWidget {
  final OrderData item;
  const _CollapsiblePaymentBreakdown({required this.item});

  @override
  State<_CollapsiblePaymentBreakdown> createState() =>
      _CollapsiblePaymentBreakdownState();
}

class _CollapsiblePaymentBreakdownState
    extends State<_CollapsiblePaymentBreakdown> {
  bool _expanded = false;

  String get _label {
    final status = widget.item.paymentStatus.toLowerCase();
    return status == 'partial' ? 'PARTIAL' : widget.item.paymentTypeLabel;
  }

  Color get _labelBg {
    final l = _label;
    if (l.contains('SPLIT')) return const Color(0xFF0284C7);
    if (l == 'MULTI') return const Color(0xFF7C3AED);
    if (l == 'PARTIAL') return const Color(0xFFF59E0B);
    return const Color(0xFF059669);
  }

  List<Map<String, dynamic>> _buildRows() {
    final item = widget.item;
    final List<Map<String, dynamic>> rows = [];
    if (item.payments.isNotEmpty) {
      for (final p in item.payments) {
        if (p.amount > 0) {
          rows.add({
            'label': p.methodName.isEmpty ? 'Payment' : p.methodName,
            'amount': p.amount,
          });
        }
      }
    }
    if (rows.length == 1) {
      final el = (rows.first['label'] as String).toUpperCase();
      if (el == 'SPLIT PAYMENT' || el == 'SPLIT') {
        final cash = double.tryParse(item.cashout) ?? 0.0;
        final card = double.tryParse(item.cardout) ?? 0.0;
        if (cash > 0 && card > 0) {
          rows
            ..clear()
            ..add({'label': 'Cash', 'amount': cash})
            ..add({'label': 'Card', 'amount': card});
        }
      }
    }
    if (rows.isEmpty) {
      final cash = double.tryParse(item.cashout) ?? 0.0;
      final card = double.tryParse(item.cardout) ?? 0.0;
      final cardName =
          (item.paymentMethodName != 'N/A' &&
              item.paymentMethodName.isNotEmpty &&
              card > 0 &&
              cash == 0)
          ? item.paymentMethodName
          : 'Card';
      if (cash > 0) rows.add({'label': 'Cash', 'amount': cash});
      if (card > 0) rows.add({'label': cardName, 'amount': card});
      if (rows.isEmpty &&
          item.paymentMethodName != 'N/A' &&
          item.paymentMethodName.isNotEmpty) {
        rows.add({'label': item.paymentMethodName, 'amount': item.grandTotal});
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.item.paymentStatus.toLowerCase();
    if (status != 'paid' && status != 'partial') return const SizedBox.shrink();

    final isPartial = status == 'partial';
    final rows = _buildRows();
    if (!isPartial && rows.isEmpty) return const SizedBox.shrink();

    final containerColor = isPartial
        ? const Color(0xFFFFFBEB)
        : const Color(0xFFF0FDF4);
    final borderColor = isPartial
        ? const Color(0xFFFDE68A)
        : const Color(0xFFBBF7D0);
    final textColor = isPartial
        ? const Color(0xFF78350F)
        : const Color(0xFF065F46);

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Always-visible tappable header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _labelBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _label.isEmpty ? 'PAID' : _label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isPartial ? 'Partial Payment' : 'Payment Breakdown',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable detail rows.
          // AnimatedSize (not AnimatedCrossFade) is used deliberately:
          // AnimatedSize.getMaxIntrinsicHeight returns the CHILD's full
          // intrinsic height immediately, so the parent IntrinsicHeight
          // always sees the correct card height → no RenderFlex overflow.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Divider(height: 10, thickness: 0.5, color: borderColor),
                        if (rows.isNotEmpty)
                          ...rows.map(
                            (row) => Padding(
                              padding: const EdgeInsets.only(bottom: 3.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      row['label'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isPartial
                                            ? const Color(0xFF92400E)
                                            : const Color(0xFF047857),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      'SAR ${(row['amount'] as double).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isPartial
                                            ? const Color(0xFF78350F)
                                            : const Color(0xFF065F46),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (isPartial) ...[
                          Divider(
                            height: 12,
                            thickness: 0.5,
                            color: borderColor,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Total Paid:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'SAR ${widget.item.totalPaidAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF065F46),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Remaining:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'SAR ${widget.item.remainingBalance.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF991B1B),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collapsible payment breakdown for FULLY CANCELLED orders.
// Shows "PAYMENT BREAKDOWN ▼" header; expands to show individual payment rows
// and refund amount — mirrors _CollapsiblePaymentBreakdown for other statuses.
// ─────────────────────────────────────────────────────────────────────────────
class _CollapsibleCancelledPaymentBreakdown extends StatefulWidget {
  final OrderData item;
  const _CollapsibleCancelledPaymentBreakdown({required this.item});

  @override
  State<_CollapsibleCancelledPaymentBreakdown> createState() =>
      _CollapsibleCancelledPaymentBreakdownState();
}

class _CollapsibleCancelledPaymentBreakdownState
    extends State<_CollapsibleCancelledPaymentBreakdown> {
  bool _expanded = false;

  List<Map<String, dynamic>> _buildRows() {
    final item = widget.item;
    final List<Map<String, dynamic>> rows = [];
    if (item.payments.isNotEmpty) {
      for (final p in item.payments) {
        if (p.amount > 0) {
          rows.add({
            'label': p.methodName.isEmpty ? 'Payment' : p.methodName,
            'amount': p.amount,
          });
        }
      }
    }
    if (rows.length == 1) {
      final el = (rows.first['label'] as String).toUpperCase();
      if (el == 'SPLIT PAYMENT' || el == 'SPLIT') {
        final cash = double.tryParse(item.cashout) ?? 0.0;
        final card = double.tryParse(item.cardout) ?? 0.0;
        if (cash > 0 && card > 0) {
          rows
            ..clear()
            ..add({'label': 'Cash', 'amount': cash})
            ..add({'label': 'Card', 'amount': card});
        }
      }
    }
    if (rows.isEmpty) {
      final cash = double.tryParse(item.cashout) ?? 0.0;
      final card = double.tryParse(item.cardout) ?? 0.0;
      final cardName =
          (item.paymentMethodName != 'N/A' &&
              item.paymentMethodName.isNotEmpty &&
              card > 0 &&
              cash == 0)
          ? item.paymentMethodName
          : 'Card';
      if (cash > 0) rows.add({'label': 'Cash', 'amount': cash});
      if (card > 0) rows.add({'label': cardName, 'amount': card});
      if (rows.isEmpty &&
          item.paymentMethodName != 'N/A' &&
          item.paymentMethodName.isNotEmpty) {
        rows.add({
          'label': item.paymentMethodName,
          'amount': item.totalPaidAmount,
        });
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    final totalPaid = widget.item.totalPaidAmount;
    // Nothing to show if there were no payments
    if (rows.isEmpty && totalPaid <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Payment Breakdown (collapsible) ─────────────────────
        if (rows.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tappable header
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PAYMENT BREAKDOWN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Expandable payment rows
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Divider(
                                height: 10,
                                thickness: 0.5,
                                color: Color(0xFFBBF7D0),
                              ),
                              ...rows.map(
                                (row) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          row['label'] as String,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF047857),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          'SAR ${(row['amount'] as double).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF065F46),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        // ── Refund Amount (always visible below breakdown) ───────
        if (totalPaid > 0)
          Container(
            margin: const EdgeInsets.only(top: 2, bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'REFUND AMOUNT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Total Refund:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'SAR ${widget.item.calculatedRefund.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7F1D1D),
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper: compact action button used in the order-card footer (Row 2).
// Uses an icon + label so it stays readable even on narrow cards.
// ─────────────────────────────────────────────────────────────────────────────
class _OrderActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;

  const _OrderActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(10);

    return Material(
      color: isLoading ? color.withOpacity(0.55) : color,
      borderRadius: radius,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: radius,
        splashColor: Colors.white24,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//-✅--Bill Print Dialog (Customer Receipt)---------------------------------✅-//
/// Dialog for printing customer bills/receipts to cashier printer
class _BillPrintDialog extends StatefulWidget {
  final OrderData order;

  const _BillPrintDialog({required this.order});

  @override
  State<_BillPrintDialog> createState() => _BillPrintDialogState();
}

class _BillPrintDialogState extends State<_BillPrintDialog>
    with SingleTickerProviderStateMixin {
  bool _isPrinting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Generates a ZATCA Phase-1 compliant QR code string (Base64 TLV).
  /// Used on Saudi simplified tax invoices (B2C).
  String _buildZatcaQr({
    required String sellerName,
    required String vatNumber,
    required String invoiceDate,
    required double totalAmount,
    required double vatAmount,
  }) {
    final List<int> tlv = [];
    void addField(int tag, String value) {
      final bytes = utf8.encode(value);
      tlv.add(tag);
      tlv.add(bytes.length);
      tlv.addAll(bytes);
    }

    addField(1, sellerName.isNotEmpty ? sellerName : 'Restaurant');
    addField(2, vatNumber.isNotEmpty ? vatNumber : '000000000000000');
    addField(
      3,
      invoiceDate.isNotEmpty ? invoiceDate : DateTime.now().toIso8601String(),
    );
    addField(4, totalAmount.toStringAsFixed(2));
    addField(5, vatAmount.toStringAsFixed(2));
    return base64Encode(tlv);
  }

  /// Renders ZATCA TLV base64 string as a 120×120 QR code PNG bitmap.
  /// Mirrors web: QRCode.toDataURL(payload) → resizeImageToBase64(120, 120) → addImage.
  /// Returns null silently on failure — receipt prints without QR.
  Future<String?> _generateQrPngBase64(String data) async {
    try {
      final painter = QrPainter(data: data, version: QrVersions.auto);
      final imageData = await painter.toImageData(120.0);
      if (imageData == null) return null;
      return base64Encode(imageData.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  // In-memory logo cache — org logo never changes mid-session so we
  // download once and reuse on every subsequent print.  This mirrors
  // the web where the browser HTTP cache makes the image instant.
  static String? _cachedLogoBase64;
  static String? _cachedLogoUrl;

  /// Downloads logo image from URL and returns base64 string.
  /// Uses a static in-memory cache so the network roundtrip only
  /// happens once per session — subsequent prints are instant.
  Future<String?> _downloadLogoBase64(String logoUrl) async {
    // Return cached value if the URL hasn't changed
    if (_cachedLogoBase64 != null && _cachedLogoUrl == logoUrl) {
      return _cachedLogoBase64;
    }
    // Try up to 2 attempts with a generous timeout for reliability
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http
            .get(Uri.parse(logoUrl))
            .timeout(const Duration(milliseconds: 5000));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          _cachedLogoUrl = logoUrl;
          _cachedLogoBase64 = base64Encode(response.bodyBytes);
          return _cachedLogoBase64;
        }
      } catch (_) {
        // Retry once on timeout/network error
      }
    }
    return null;
  }

  Future<void> _printBill(BuildContext dialogContext) async {
    setState(() => _isPrinting = true);

    try {
      final printerProvider = Provider.of<PrinterIntegrationProvider>(
        dialogContext,
        listen: false,
      );

      // Skip isPrinterConnected gate — the queue / native layer handles
      // connection errors and the catch block below shows a user-visible
      // "Print failed" snackbar with a Retry button.  This matches
      // _printToKDS which has no pre-flight connection check and works
      // reliably for manual KDS prints.
      debugPrint(
        '🖨️ [_printBill] Proceeding with print (queue handles connection)',
      );

      // Extract items (Flattened List Strategy for Printer)
      // Matches Web App: Modifiers are treated as line items with prices, directly under their parent.
      final allDetails = widget.order.details;
      final List<PrintJobItem> items = [];

      // Include ALL products (cancelled ones included with status:'cancelled').
      // Voided items appear on the receipt for transparency; totals already
      // exclude them since they were never charged.
      final productDetails = allDetails
          .where((detail) => detail.itemType == 'product')
          .toList();

      int itemIndex = 1;
      for (var product in productDetails) {
        final isCancelled = product.status.toLowerCase() == 'cancelled';
        
        // Calculate cancelled quantity
        int cancelledQty = product.originalQty - product.quantity;
        if (product.cancelledQty > cancelledQty) {
          cancelledQty = product.cancelledQty;
        }
        if (cancelledQty <= 0 && isCancelled) {
          final fallbackQty = product.originalQty > 0
              ? product.originalQty
              : (product.qty > 0 ? product.qty : product.quantity);
          cancelledQty = fallbackQty > 0 ? fallbackQty : 1;
        }

        // 1. Add active portion if quantity > 0 and status is not fully cancelled
        final int activeQty = product.quantity;
        final bool hasActivePortion = !isCancelled && activeQty > 0;
        if (hasActivePortion) {
          items.add(
            PrintJobItem(
              name: '$itemIndex. ${product.product.mPName}',
              quantity: activeQty,
              price: double.tryParse(product.rate) ?? 0.0,
              notes: (product.note.isEmpty || product.note == 'N/A')
                  ? null
                  : product.note,
              status: null,
            ),
          );

          // Include active portion of modifiers
          final linkedModifiers = allDetails
              .where(
                (mod) =>
                    mod.itemType == 'modifier' &&
                    mod.link == product.orderDetId.toString(),
              )
              .toList();

          for (final mod in linkedModifiers) {
            final bool modCancelled = mod.status.toLowerCase() == 'cancelled';
            final int modActiveQty = mod.quantity;
            if (!modCancelled && modActiveQty > 0) {
              items.add(
                PrintJobItem(
                  name: '+ ${mod.name != 'N/A' ? mod.name : mod.product.mPName}',
                  quantity: modActiveQty,
                  price: double.tryParse(mod.rate) ?? 0.0,
                  notes: (mod.note.isNotEmpty && mod.note != 'N/A' && !mod.note.toLowerCase().startsWith('modifier for')) ? mod.note : null,
                  status: null,
                ),
              );
            }
          }
          itemIndex++;
        }

        // 2. Add cancelled portion if cancelledQty > 0
        if (cancelledQty > 0) {
          items.add(
            PrintJobItem(
              name: product.product.mPName,
              quantity: cancelledQty,
              price: double.tryParse(product.rate) ?? 0.0,
              notes: (product.note.isEmpty || product.note == 'N/A')
                  ? null
                  : product.note,
              status: 'cancelled',
            ),
          );

          // Include cancelled portion of modifiers
          final linkedModifiers = allDetails
              .where(
                (mod) =>
                    mod.itemType == 'modifier' &&
                    mod.link == product.orderDetId.toString(),
              )
              .toList();

          for (final mod in linkedModifiers) {
            final bool modCancelled = isCancelled || mod.status.toLowerCase() == 'cancelled';
            int modCancelledQty = mod.originalQty - mod.quantity;
            if (mod.cancelledQty > modCancelledQty) {
              modCancelledQty = mod.cancelledQty;
            }
            if (modCancelledQty <= 0 && modCancelled) {
              final fallbackQty = mod.originalQty > 0
                  ? mod.originalQty
                  : (mod.qty > 0 ? mod.qty : mod.quantity);
              modCancelledQty = fallbackQty > 0 ? fallbackQty : 1;
            }

            if (modCancelledQty > 0) {
              items.add(
                PrintJobItem(
                  name: '+ ${mod.name != 'N/A' ? mod.name : mod.product.mPName}',
                  quantity: modCancelledQty,
                  price: double.tryParse(mod.rate) ?? 0.0,
                  notes: (mod.note.isNotEmpty && mod.note != 'N/A' && !mod.note.toLowerCase().startsWith('modifier for')) ? mod.note : null,
                  status: 'cancelled',
                ),
              );
            }
          }
        }
      }

      // Removed block that prevented printing when all items were cancelled

      // Get user info for company details
      final userProvider = Provider.of<UserInfoProvider>(
        context,
        listen: false,
      );
      final userData = userProvider.getUserData;

      // Get tax rate from existing AddOrderProvider (already fetched from /tax endpoint)
      final addOrderCtrl = Provider.of<AddOrderProvider>(
        context,
        listen: false,
      );
      final taxRate =
          addOrderCtrl.selectedTaxRate ??
          (addOrderCtrl.OrderTaxListing.isNotEmpty
              ? double.tryParse(addOrderCtrl.OrderTaxListing.first.rate) ?? 15.0
              : 15.0);

      // Calculate totals - Match web format (Tax-inclusive system)
      final totalAmount = normalizeFormattedAmount(
        widget.order.fullPayableTotal,
      ); // Grand total
      final taxAmt = widget.order.displayTotalTax; // Tax amount
      final netAmount = widget.order.displayNetAmount > 0
          ? widget.order.displayNetAmount
          : totalAmount - taxAmt; // fallback if no tax breakdown from backend

      // Format date as DD/MM/YYYY
      final orderDateTime =
          DateTime.tryParse(widget.order.orderDate) ?? DateTime.now();
      final date =
          '${orderDateTime.day.toString().padLeft(2, '0')}/${orderDateTime.month.toString().padLeft(2, '0')}/${orderDateTime.year}';

      // Format time as HH:MM
      final time =
          '${orderDateTime.hour.toString().padLeft(2, '0')}:${orderDateTime.minute.toString().padLeft(2, '0')}';

      // Extract order type formatted
      final orderType = widget.order.type.toUpperCase().replaceAll('_', '-');

      // Customer name
      final customerName =
          widget.order.customer.isNotEmpty && widget.order.customer != 'N/A'
          ? widget.order.customer
          : 'Guest Customer';

      // Payment status
      final paymentStatus = widget.order.paymentStatus.toUpperCase();

      // Invoice number from API invoice_no field (e.g. 842), falls back to order_no
      final invoiceNumber = widget.order.invoiceNo > 0
          ? widget.order.invoiceNo.toString().padLeft(4, '0')
          : widget.order.orderNo.toString().padLeft(4, '0');

      // Generate ZATCA-compliant QR code (Saudi tax authority requirement)
      final qrData = _buildZatcaQr(
        sellerName: userData?.orgName ?? '',
        vatNumber: userData?.vatNo ?? '',
        invoiceDate: widget.order.orderDate,
        totalAmount: totalAmount,
        vatAmount: taxAmt,
      );

      // Render ZATCA TLV as QR PNG bitmap (matches web: QRCode→canvas→addImage)
      final qrImageBase64 = await _generateQrPngBase64(qrData);

      // Download org logo for receipt header (graceful degradation if unavailable)
      String? logoBase64;
      if (userData?.orgPicture.isNotEmpty == true) {
        logoBase64 = await _downloadLogoBase64(
          '${GlobalServiceURL.ImageBaseUrl}${userData!.orgPicture}',
        );
      }

      // Guard: bail if dialog was dismissed during the async logo download
      if (!mounted) return;
      await printerProvider.printReceipt(
        storeName: userData?.orgName ?? 'Restaurant',
        vatNumber: (userData?.vatNo.isNotEmpty == true)
            ? userData!.vatNo
            : null,
        branchName: userData?.branchName ?? 'Main Branch',
        storeAddress: (userData?.branchAddress.isNotEmpty == true)
            ? userData!.branchAddress
            : null,
        orderNumber: widget.order.orderNo.toString().padLeft(4, '0'),
        invoiceNumber: invoiceNumber,
        orderType: orderType,
        tableNumber: widget.order.tableName,
        customerName: customerName,
        date: date,
        time: time,
        items: items,
        netAmount: netAmount,
        tax: taxAmt,
        taxRate: taxRate,
        total: totalAmount,
        discount: double.tryParse(widget.order.discountAmt) ?? 0.0,
        adjustmentAmount: double.tryParse(widget.order.adjustAmt) ?? 0.0,
        totalPaidAmount: widget.order.totalPaidAmount,
        paidAmount: widget.order.paymentStatus.toLowerCase() == 'paid'
            ? (widget.order.totalPaidAmount > 0
                  ? widget.order.totalPaidAmount
                  : totalAmount)
            : widget.order.totalPaidAmount,
        tableCharge: widget.order.tableCharge,
        refundAmount: widget.order.calculatedRefund,
        paymentMethod: widget.order.payments.length > 2
            ? 'MULTI'
            : (widget.order.payments.length == 2
                  ? 'SPLIT'
                  : widget.order.paymentTypeLabel),
        paymentStatus: paymentStatus,
        qrCodeData: qrImageBase64,
        logoBase64: logoBase64,
        taxBreakdown: widget.order.displayTaxesMap?.map(
          (k, v) => MapEntry(
            k,
            v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0),
          ),
        ),
        paymentDistribution: widget.order.payments.isNotEmpty
            ? widget.order.payments
                .map((p) => {
                  'method': p.methodName,
                  'amount': p.amount,
                })
                .toList()
            : null,
        openDrawer: false,
        useQueue: false,
      );

      // Show success message before closing
      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
      Navigator.pop(dialogContext);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Bill #${widget.order.orderNo} printed successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPrinting = false);

      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Print failed',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Check printer connection',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _printBill(dialogContext),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Color(0xFF059669),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Print Customer Bill', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 2),
                  Text(
                    'Cashier Receipt',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Number',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '#${widget.order.orderNo}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Table',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          widget.order.tableName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This will print a customer bill to your cashier printer.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isPrinting ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton.icon(
            onPressed: _isPrinting ? null : () => _printBill(context),
            icon: _isPrinting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.print, size: 20),
            label: Text(
              _isPrinting ? 'Printing...' : 'Print Bill',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//-✅--KDS Print Dialog (Kitchen Ticket)------------------------------------✅-//
/// Dialog for printing kitchen tickets to KDS printer with format options
class _KdsPrintDialog extends StatefulWidget {
  final OrderData order;

  const _KdsPrintDialog({required this.order});

  @override
  State<_KdsPrintDialog> createState() => _KdsPrintDialogState();
}

class _KdsPrintDialogState extends State<_KdsPrintDialog>
    with SingleTickerProviderStateMixin {
  String _selectedFormat = 'normal'; // 'normal' or 'bill'
  bool _isPrinting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _printToKDS(BuildContext dialogContext) async {
    if (!mounted) return;
    setState(() => _isPrinting = true);

    try {
      final printerProvider = Provider.of<PrinterIntegrationProvider>(
        dialogContext,
        listen: false,
      );

      // Build KDS items matching web kdsBridgePayload.js logic:
      // Products are indexed (1. Name), modifiers are sub-items (+ Modifier),
      // notes shown as *** note ***, cancelled items excluded.
      final allDetails = widget.order.details;
      final products = allDetails
          .where(
            (d) =>
                d.itemType == 'product' &&
                d.status.toLowerCase() != 'cancelled',
          )
          .toList();

      final List<PrintJobItem> kdsItems = [];
      for (final product in products) {
        kdsItems.add(
          PrintJobItem(
            name: product.product.mPName,
            quantity: product.quantity,
            price: double.tryParse(product.rate) ?? 0.0,
            notes: (product.note.isEmpty || product.note == 'N/A')
                ? null
                : product.note,
            status: product.status,
          ),
        );
        // Linked modifiers (matches web: mod.type === "modifier" && mod.link === item.order_det_id)
        final modifiers = allDetails
            .where(
              (mod) =>
                  mod.itemType == 'modifier' &&
                  mod.status.toLowerCase() != 'cancelled' &&
                  mod.link == product.orderDetId.toString(),
            )
            .toList();
        for (final mod in modifiers) {
          kdsItems.add(
            PrintJobItem(
              name: '+ ${mod.name != 'N/A' ? mod.name : mod.product.mPName}',
              quantity: mod.quantity,
              price: double.tryParse(mod.rate) ?? 0.0,
              notes: (mod.note.isNotEmpty && mod.note != 'N/A' && !mod.note.toLowerCase().startsWith('modifier for')) ? mod.note : null,
              status: mod.status,
            ),
          );
        }
      }

      // Get store name for KDS ticket header
      final kdsUserProvider = Provider.of<UserInfoProvider>(
        context,
        listen: false,
      );
      final kdsUserData = kdsUserProvider.getUserData;

      if (_selectedFormat == 'normal') {
        // Format date as dd/MM/yyyy — matches web kdsBridgePayload.js dateStr
        final orderDateTime =
            DateTime.tryParse(widget.order.orderDate) ?? DateTime.now();
        final printDate =
            '${orderDateTime.day.toString().padLeft(2, '0')}/${orderDateTime.month.toString().padLeft(2, '0')}/${orderDateTime.year}';
        final printCustomer =
            widget.order.customer.isNotEmpty && widget.order.customer != 'N/A'
            ? widget.order.customer
            : null;

        // Direct print (useQueue: false) gives immediate error feedback to the user.
        // The queue is designed for background/auto-printing; user-triggered prints
        // need to surface errors so the user knows KDS printer is not connected.
        await printerProvider.printKitchenOrder(
          storeName: kdsUserData?.orgName ?? 'CulAI Restaurant',
          orderNumber: widget.order.orderNo.toString(),
          tableName: widget.order.tableName,
          orderType: widget.order.type,
          items: kdsItems,
          priority: 'normal',
          date: printDate,
          customerName: printCustomer,
          orderNotes:
              (widget.order.orderDes.isNotEmpty &&
                  widget.order.orderDes != 'N/A')
              ? widget.order.orderDes
              : null,
          useQueue: false,
        );
      } else {
        // Print as Bill format to KDS printer (uses regular receipt print channel)
        final subtotal = widget.order.calculatedSubtotal;
        final tableCharge = widget.order.tableCharge;
        final adjustAmt = double.tryParse(widget.order.adjustAmt) ?? 0.0;
        final total = normalizeFormattedAmount(
          subtotal + tableCharge + adjustAmt,
        );
        final tax = total - subtotal - adjustAmt;

        // Bill items include all details for pricing; build same as _printBill
        final billItems = allDetails
            .where(
              (d) =>
                  d.itemType == 'product' &&
                  d.status.toLowerCase() != 'cancelled',
            )
            .expand((product) {
              final modifiers = allDetails
                  .where(
                    (mod) =>
                        mod.itemType == 'modifier' &&
                        mod.status.toLowerCase() != 'cancelled' &&
                        mod.link == product.orderDetId.toString(),
                  )
                  .toList();
              return [
                PrintJobItem(
                  name: product.product.mPName,
                  quantity: product.quantity,
                  price: double.tryParse(product.rate) ?? 0.0,
                  notes: (product.note.isEmpty || product.note == 'N/A')
                      ? null
                      : product.note,
                ),
                ...modifiers.map(
                  (mod) => PrintJobItem(
                    name: '+ ${mod.name != 'N/A' ? mod.name : mod.product.mPName}',
                    quantity: mod.quantity,
                    price: double.tryParse(mod.rate) ?? 0.0,
                    notes: (mod.note.isNotEmpty && mod.note != 'N/A' && !mod.note.toLowerCase().startsWith('modifier for')) ? mod.note : null,
                  ),
                ),
              ];
            })
            .toList();

        await printerProvider.printReceipt(
          storeName: 'CulAI Restaurant (KDS)',
          orderNumber: widget.order.orderNo.toString(),
          items: billItems,
          netAmount: subtotal,
          tax: tax,
          total: total,
          tableCharge: tableCharge,
          tableNumber: widget.order.tableName,
          paymentMethod: 'For Kitchen',
          openDrawer: false,
          useQueue:
              false, // Direct print — immediate error feedback for manual KDS bill
        );
      }

      // Show success message before closing
      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
      Navigator.pop(dialogContext);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                _selectedFormat == 'normal'
                    ? 'Kitchen ticket #${widget.order.orderNo} printed'
                    : 'Bill #${widget.order.orderNo} sent to KDS',
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPrinting = false);

      // Extract a short human-readable message from the exception.
      // PlatformException wraps Kotlin errors — message is the Kotlin error string.
      final detail = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : e.toString();

      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  detail,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _printToKDS(dialogContext),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant,
                color: Color(0xFFF59E0B),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Print to KDS', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 2),
                  Text(
                    'Kitchen Display System',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Number',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '#${widget.order.orderNo}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Table',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          widget.order.tableName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Print Format',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              // Format options with enhanced UI
              InkWell(
                onTap: () => setState(() => _selectedFormat = 'normal'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: _selectedFormat == 'normal'
                        ? LinearGradient(
                            colors: [
                              const Color(0xFFF59E0B).withOpacity(0.15),
                              const Color(0xFFF59E0B).withOpacity(0.08),
                            ],
                          )
                        : null,
                    color: _selectedFormat != 'normal'
                        ? Colors.grey[100]
                        : null,
                    border: Border.all(
                      color: _selectedFormat == 'normal'
                          ? const Color(0xFFF59E0B)
                          : Colors.grey[300]!,
                      width: _selectedFormat == 'normal' ? 2.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 24,
                        color: _selectedFormat == 'normal'
                            ? const Color(0xFFF59E0B)
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kitchen Ticket',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: _selectedFormat == 'normal'
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: _selectedFormat == 'normal'
                                    ? const Color(0xFFF59E0B)
                                    : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Normal KDS format for cooking',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedFormat == 'normal')
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => setState(() => _selectedFormat = 'bill'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: _selectedFormat == 'bill'
                        ? LinearGradient(
                            colors: [
                              const Color(0xFFF59E0B).withOpacity(0.15),
                              const Color(0xFFF59E0B).withOpacity(0.08),
                            ],
                          )
                        : null,
                    color: _selectedFormat != 'bill' ? Colors.grey[100] : null,
                    border: Border.all(
                      color: _selectedFormat == 'bill'
                          ? const Color(0xFFF59E0B)
                          : Colors.grey[300]!,
                      width: _selectedFormat == 'bill' ? 2.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt,
                        size: 24,
                        color: _selectedFormat == 'bill'
                            ? const Color(0xFFF59E0B)
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bill Format',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: _selectedFormat == 'bill'
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: _selectedFormat == 'bill'
                                    ? const Color(0xFFF59E0B)
                                    : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Full bill with prices to KDS',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedFormat == 'bill')
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isPrinting ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton.icon(
            onPressed: _isPrinting ? null : () => _printToKDS(context),
            icon: _isPrinting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.print, size: 20),
            label: Text(
              _isPrinting ? 'Printing...' : 'Print to KDS',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//-✅--Multi-Payment Widget-------------------------------------------------✅-//
/// Widget for handling multi-payment entries
class _MultiPaymentWidget extends StatelessWidget {
  final double payableAmount;
  final List<PaymentMethodsPayBillModel> paymentMethods;
  final bool isLoading;

  const _MultiPaymentWidget({
    required this.payableAmount,
    required this.paymentMethods,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MultiPaymentProvider>(
      builder: (context, multiPayCtrl, _) {
        // Initialize if empty
        if (multiPayCtrl.entries.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            multiPayCtrl.initialize();
          });
        }

        final totalAmount = multiPayCtrl.totalAmount;
        final remaining = payableAmount - totalAmount;
        final isValid = remaining.abs() < 0.01;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Symbols.payments,
                    size: 18,
                    color: Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Multi-Payment Entries',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CommonWidget.CommonTitleTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${multiPayCtrl.entries.length} Payment${multiPayCtrl.entries.length == 1 ? '' : 's'}',
                    style: CommonWidget.CommonTitleTextStyle(
                      fontSize: 11,
                      color: const Color(0xFF7C3AED).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Payment Entries List
            ...multiPayCtrl.entries.asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final entry = mapEntry.value;
              // Collect method names used by ALL other entries (not this one)
              final usedByOthers = multiPayCtrl.entries
                  .where((e) => e.id != entry.id && e.paymentMethodName != null)
                  .map((e) => e.paymentMethodName!)
                  .toSet();
              return _MultiPaymentEntryRow(
                entry: entry,
                entryNumber: index + 1,
                paymentMethods: paymentMethods,
                canDelete: multiPayCtrl.entries.length > 1,
                isLoading: isLoading,
                usedMethodNames: usedByOthers,
                onAmountChanged: (amount) {
                  multiPayCtrl.updateAmount(entry.id, amount);
                },
                onMethodChanged: (methodId, methodName, methodType) {
                  multiPayCtrl.updatePaymentMethod(
                    entry.id,
                    methodId,
                    methodName,
                    methodType,
                  );
                },
                onRemarkChanged: (remark) {
                  multiPayCtrl.updateRemark(entry.id, remark);
                },
                onDelete: () {
                  multiPayCtrl.removeEntry(entry.id);
                },
              );
            }).toList(),

            // Add Payment Button
            const SizedBox(height: 10),
            GestureDetector(
              onTap: isLoading ? null : () => multiPayCtrl.addEntry(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFDDD6FE),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Symbols.add_circle,
                      size: 18,
                      color: Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Add Payment',
                      style: CommonWidget.CommonTitleTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Totals Section
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isValid
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isValid
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFECACA),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Multi-payments Total:',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CommonWidget.CommonTitleTextStyle(
                            fontSize: 12,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${totalAmount.toStringAsFixed(2)} SAR',
                        style: CommonWidget.CommonTitleTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Payable Amount Required:',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CommonWidget.CommonTitleTextStyle(
                            fontSize: 12,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${payableAmount.toStringAsFixed(2)} SAR',
                        style: CommonWidget.CommonTitleTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  if (!isValid) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Symbols.error,
                            size: 16,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              remaining > 0
                                  ? 'Remaining: ${remaining.toStringAsFixed(2)} SAR'
                                  : 'Over by: ${(-remaining).toStringAsFixed(2)} SAR',
                              style: CommonWidget.CommonTitleTextStyle(
                                fontSize: 11,
                                color: const Color(0xFFDC2626),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isValid) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Symbols.check_circle,
                            size: 16,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '✓ Ready to complete payment',
                            style: CommonWidget.CommonTitleTextStyle(
                              fontSize: 11,
                              color: const Color(0xFF16A34A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

//-✅--Multi-Payment Entry Row---------------------------------------------✅-//
/// Individual payment entry row
class _MultiPaymentEntryRow extends StatefulWidget {
  final MultiPaymentEntry entry;
  final int entryNumber;
  final List<PaymentMethodsPayBillModel> paymentMethods;
  final bool canDelete;
  final bool isLoading;
  final Set<String>
  usedMethodNames; // Methods used by OTHER entries — excluded from this dropdown
  final Function(double) onAmountChanged;
  final Function(int, String, String) onMethodChanged;
  final Function(String) onRemarkChanged;
  final VoidCallback onDelete;

  const _MultiPaymentEntryRow({
    required this.entry,
    required this.entryNumber,
    required this.paymentMethods,
    required this.canDelete,
    required this.isLoading,
    required this.usedMethodNames,
    required this.onAmountChanged,
    required this.onMethodChanged,
    required this.onRemarkChanged,
    required this.onDelete,
  });

  @override
  State<_MultiPaymentEntryRow> createState() => _MultiPaymentEntryRowState();
}

class _MultiPaymentEntryRowState extends State<_MultiPaymentEntryRow> {
  late TextEditingController _amountController;
  late TextEditingController _remarkController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.entry.amount > 0
          ? widget.entry.amount.toStringAsFixed(2)
          : '',
    );
    _remarkController = TextEditingController(text: widget.entry.remark ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment #${widget.entryNumber}',
                style: CommonWidget.CommonTitleTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              if (widget.canDelete && !widget.isLoading)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(
                    Symbols.delete,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Amount Input
          Text(
            'Amount (SAR)',
            style: CommonWidget.CommonTitleTextStyle(
              fontSize: 11,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _amountController,
            enabled: !widget.isLoading,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0.00',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF7C3AED)),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: CommonWidget.CommonTitleTextStyle(fontSize: 13),
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              widget.onAmountChanged(amount);
            },
          ),
          const SizedBox(height: 10),

          // Payment Method Dropdown
          Text(
            'Payment Method',
            style: CommonWidget.CommonTitleTextStyle(
              fontSize: 11,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: widget.entry.paymentMethodName,
            decoration: InputDecoration(
              hintText: 'Select Method',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF7C3AED)),
              ),
              filled: true,
              fillColor: Colors.white,
              hintStyle: CommonWidget.CommonTitleTextStyle(
                color: const Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
            style: CommonWidget.CommonTitleTextStyle(
              color: GlobalAppColor.DarkTextColorCode,
              fontSize: 12,
            ),
            items: widget.paymentMethods
                .where(
                  (m) =>
                      m.type.toUpperCase() != "SPLIT" &&
                      m.type.toUpperCase() != "MULTI-PAYMENT" &&
                      m.type.toUpperCase() != "MULTI" &&
                      m.name.toUpperCase() != "MULTI" &&
                      // Allow currently-selected method; exclude methods used by other entries
                      (m.name == widget.entry.paymentMethodName ||
                          !widget.usedMethodNames.contains(m.name)),
                )
                .map(
                  (method) => DropdownMenuItem<String>(
                    value: method.name,
                    child: Text(method.name),
                  ),
                )
                .toList(),
            onChanged: widget.isLoading
                ? null
                : (value) {
                    if (value != null) {
                      final selectedMethod = widget.paymentMethods.firstWhere(
                        (m) => m.name == value,
                        orElse: () => PaymentMethodsPayBillModel(),
                      );
                      widget.onMethodChanged(
                        selectedMethod.payMId,
                        selectedMethod.name,
                        selectedMethod.type,
                      );
                    }
                  },
          ),
          const SizedBox(height: 10),

          // Remark Input
          Text(
            'Remark (Optional)',
            style: CommonWidget.CommonTitleTextStyle(
              fontSize: 11,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _remarkController,
            enabled: !widget.isLoading,
            decoration: InputDecoration(
              hintText: 'Add a note...',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF7C3AED)),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: CommonWidget.CommonTitleTextStyle(fontSize: 12),
            onChanged: widget.onRemarkChanged,
          ),
        ],
      ),
    );
  }
}

//-✅--Item Note Sheet-------------------------------------------------✅-//
class _ItemNoteSheet extends StatefulWidget {
  final OrderDetail detail;
  final int orderId;
  final HomeProvider homeCtrl;

  const _ItemNoteSheet({
    required this.detail,
    required this.orderId,
    required this.homeCtrl,
  });

  @override
  State<_ItemNoteSheet> createState() => _ItemNoteSheetState();
}

class _ItemNoteSheetState extends State<_ItemNoteSheet> {
  final TextEditingController _controller = TextEditingController();
  List<NoteModel> _ingredients = [];
  List<String> _selectedIngredients = [];
  bool _loadingIngredients = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefill();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIngredients());
  }

  void _prefill() {
    final note = widget.detail.note.trim();
    if (note.isEmpty ||
        note.toLowerCase() == 'n/a' ||
        note.toLowerCase() == 'null')
      return;

    final cleanLines = note
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final typedText = cleanLines
        .where((l) => !l.startsWith('Remove:'))
        .join('\n');

    _selectedIngredients = cleanLines
        .where((l) => l.startsWith('Remove:'))
        .map((l) => l.replaceFirst('Remove:', '').trim())
        .toSet()
        .toList();

    final removeLines = _selectedIngredients
        .map((e) => 'Remove: $e')
        .join('\n');

    if (typedText.isNotEmpty && removeLines.isNotEmpty) {
      _controller.text = '$typedText\n$removeLines';
    } else if (typedText.isNotEmpty) {
      _controller.text = typedText;
    } else {
      _controller.text = removeLines;
    }
  }

  Future<void> _loadIngredients() async {
    if (!mounted) return;
    final mProdId = widget.detail.mProdId;
    if (mProdId == 0) return;

    setState(() => _loadingIngredients = true);

    final httpCtrl = Provider.of<HttpServiceProvider>(context, listen: false);
    final token =
        Provider.of<UserInfoProvider>(context, listen: false).AccessToken ?? '';
    final authHeaders = APIHelper.buildAuthHeaders(token);

    try {
      if (!httpCtrl.isApiActive) httpCtrl.startHttpClient();

      final responseRaw = await httpCtrl.request(
        method: 'GET',
        url: '${NoteListService}m_prod_id=$mProdId',
        context: context,
        headers: authHeaders,
        requireLogin: true,
      );

      if (!mounted) return;

      if (responseRaw is List) {
        final records = responseRaw.whereType<Map<String, dynamic>>().toList();
        setState(() {
          _ingredients = records.map((e) => NoteModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      GlobalFunction().debugFunction('❌ Error loading ingredients: $e');
    } finally {
      if (mounted) setState(() => _loadingIngredients = false);
    }
  }

  void _toggleIngredient(NoteModel item) {
    final name = item.inventoryProduct.pName.trim();

    // 1. toggle selection
    if (_selectedIngredients.contains(name)) {
      _selectedIngredients.remove(name);
    } else {
      _selectedIngredients.add(name);
    }

    // 2. keep only typed text (strip any existing Remove: lines)
    final typedText = _controller.text
        .split('\n')
        .where((line) => !line.trim().startsWith('Remove:'))
        .join('\n')
        .trim();

    // 3. rebuild Remove: lines from current selection — no duplicates ever
    final removeLines = _selectedIngredients.isNotEmpty
        ? _selectedIngredients.map((e) => 'Remove: $e').join('\n')
        : '';

    // 4. merge back into controller
    if (typedText.isNotEmpty && removeLines.isNotEmpty) {
      _controller.text = '$typedText\n$removeLines';
    } else if (typedText.isNotEmpty) {
      _controller.text = typedText;
    } else {
      _controller.text = removeLines;
    }

    setState(() {});
  }

  Future<void> _save() async {
    GlobalFunction.hideKeyboard(context);

    final String finalNote = _controller.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .join('\n');

    if (finalNote.trim().isEmpty) {
      final existingNote = widget.detail.note.trim();
      final hasExistingNote =
          existingNote.isNotEmpty &&
          existingNote.toLowerCase() != 'n/a' &&
          existingNote.toLowerCase() != 'null';
      if (!hasExistingNote) {
        showCustomToast(
          context: context,
          message: 'Enter some text or select an ingredient',
        );
        return;
      }
      // hasExistingNote → fall through to save empty string (clears the note)
    }

    setState(() => _saving = true);
    final success = await widget.homeCtrl.updateItemNoteService(
      context,
      widget.orderId,
      widget.detail.orderDetId,
      finalNote,
    );
    if (mounted) {
      setState(() => _saving = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 700;

    return SafeArea(
      bottom: true,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            width: isLargeScreen ? 600 : double.infinity,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.only(top: 15, bottom: 20),
                decoration: BoxDecoration(
                  color: GlobalAppColor.WhiteColorCode,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // drag indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: GlobalAppColor.ButtonColor.withValues(
                            alpha: .9,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 15,
                      ),
                      child: Text(
                        'Add Special Instructions',
                        textAlign: TextAlign.center,
                        style: CommonWidget.CommonTitleTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // form
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Special Instructions'),
                          _label('For: ${widget.detail.product.mPName}'),
                          const SizedBox(height: 5),
                          CommonWidget().MultilineTextFormField(
                            controller: _controller,
                            minLines: 5,
                            maxLines: 10,
                            hintText:
                                'Add any special instructions, allergies, or preferences for this item...',
                          ),

                          // ingredient chips
                          if (_loadingIngredients) ...[
                            const SizedBox(height: 15),
                            const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ] else if (_ingredients.isNotEmpty) ...[
                            const SizedBox(height: 15),
                            _label('Ingredients'),
                            SizedBox(
                              height: 45,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemCount: _ingredients.length,
                                itemBuilder: (context, index) {
                                  final item = _ingredients[index];
                                  final name = item.inventoryProduct.pName
                                      .trim();
                                  final isSelected = _selectedIngredients
                                      .contains(name);
                                  return GestureDetector(
                                    onTap: () => _toggleIngredient(item),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? GlobalAppColor.ButtonColor
                                            : GlobalAppColor.WhiteColorCode,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? GlobalAppColor.ButtonColor
                                              : GlobalAppColor
                                                    .LightTextColorCode,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          item.inventoryProduct.pName,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : GlobalAppColor
                                                      .HomeDarkTextColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),
                          _label(
                            'These instructions will be sent to the kitchen',
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),

                    // buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: CommonWidget().CustomElevatedButton(
                                borderColor: GlobalAppColor.LightTextColorCode,
                                borderWidth: 0.5,
                                backgroundColor: GlobalAppColor.WhiteColorCode,
                                title: 'Cancel',
                                fontWeight: FontWeight.w400,
                                textColor: GlobalAppColor.HomeDarkTextColor,
                                onPressed: () {
                                  GlobalFunction.hideKeyboard(context);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _saving
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : CommonWidget().customElevatedButtonWithIcon(
                                      icon: Symbols.article,
                                      backgroundColor:
                                          GlobalAppColor.ButtonColor,
                                      title: ' Save Note',
                                      onPressed: _save,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        title,
        style: CommonWidget.CommonTitleTextStyle(
          fontSize: 15,
          fontWeight: title == 'These instructions will be sent to the kitchen'
              ? FontWeight.w400
              : FontWeight.w500,
          color: GlobalAppColor.LightTextColorCode,
        ),
      ),
    );
  }
}