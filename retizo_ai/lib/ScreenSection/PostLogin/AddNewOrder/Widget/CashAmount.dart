// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, strict_top_level_inference, avoid_web_libraries_in_flutter, unnecessary_import, curly_braces_in_flow_control_structures
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
class CashAmount extends StatelessWidget {
  final String hintText;

  const CashAmount({super.key, this.hintText = "SAR"});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CashAmountProvider, AddOrderProvider>(
      builder: (context, p1, order, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          p1.setFromTotal(order.overallTotal);
        });

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: GlobalAppColor.LightTextColorCode.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: p1.controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: GlobalAppColor.DarkTextColorCode),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // only numbers
                    LengthLimitingTextInputFormatter(3), // max 3 digits
                  ],
                  onChanged: (v) => p1.manualInput(v),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: TextStyle(color: GlobalAppColor.LightTextColorCode.withOpacity(0.5)),
                  ),
                ),
              ),

              Column(
                children: [
                  InkWell(
                    onTap: () => p1.increment(),
                    child: Icon(Icons.arrow_drop_up, color: GlobalAppColor.LightTextColorCode),
                  ),
                  InkWell(
                    onTap: () => p1.decrement(),
                    child: Icon(Icons.arrow_drop_down, color: GlobalAppColor.LightTextColorCode),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
class CardAmount extends StatelessWidget {
  final String hintText;

  const CardAmount({super.key, this.hintText = "SAR"});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CardAmountProvider, AddOrderProvider>(
      builder: (context, p2, order, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          p2.setFromTotal(order.overallTotal);
        });

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: GlobalAppColor.LightTextColorCode.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: p2.controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: GlobalAppColor.DarkTextColorCode),
                  onChanged: (v) => p2.manualInput(v),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // only numbers
                    LengthLimitingTextInputFormatter(3), // max 3 digits
                  ],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: TextStyle(color: GlobalAppColor.LightTextColorCode.withOpacity(0.5)),
                  ),
                ),
              ),

              Column(
                children: [
                  InkWell(
                    onTap: () => p2.increment(),
                    child: Icon(Icons.arrow_drop_up, color: GlobalAppColor.LightTextColorCode),
                  ),
                  InkWell(
                    onTap: () => p2.decrement(),
                    child: Icon(Icons.arrow_drop_down, color: GlobalAppColor.LightTextColorCode),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

//-✅-Cash Amount Widget---------------------------------------------------✅-//
//-✅-Cash Amount Widget---------------------------------------------------✅-//
class PayBillCashAmount extends StatelessWidget {
  final String hintText;

  const PayBillCashAmount({super.key, this.hintText = "SAR"});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PayBillCashAmountProvider, HomeProvider>(
      builder: (context, p1, homeCtrl, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final isPartial =
              homeCtrl.selectedOrder?.paymentStatus.toLowerCase() == 'partial';
          final netAmt = isPartial
              ? homeCtrl.remainingPayableForOrder(
                  context,
                  homeCtrl.selectedOrder,
                )
              : homeCtrl.payableTotalForOrder(context, homeCtrl.selectedOrder);

          p1.setFromNetAmt(netAmt);
        });

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: GlobalAppColor.LightTextColorCode.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: p1.controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: GlobalAppColor.DarkTextColorCode),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(7),
                  ],
                  onChanged: (v) => p1.manualInput(v),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: TextStyle(color: GlobalAppColor.LightTextColorCode.withOpacity(0.5)),
                  ),
                ),
              ),
              Column(
                children: [
                  InkWell(
                    onTap: () => p1.increment(),
                    child: Icon(Icons.arrow_drop_up, color: GlobalAppColor.LightTextColorCode),
                  ),
                  InkWell(
                    onTap: () => p1.decrement(),
                    child: Icon(Icons.arrow_drop_down, color: GlobalAppColor.LightTextColorCode),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

//-✅-Card Amount Widget---------------------------------------------------✅-//
//-✅-Card Amount Widget---------------------------------------------------✅-//
class PayBillCardAmount extends StatelessWidget {
  final String hintText;

  const PayBillCardAmount({super.key, this.hintText = "SAR"});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PayBillCardAmountProvider, HomeProvider>(
      builder: (context, p2, homeCtrl, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final isPartial =
              homeCtrl.selectedOrder?.paymentStatus.toLowerCase() == 'partial';
          final netAmt = isPartial
              ? homeCtrl.remainingPayableForOrder(
                  context,
                  homeCtrl.selectedOrder,
                )
              : homeCtrl.payableTotalForOrder(context, homeCtrl.selectedOrder);

          p2.setFromNetAmt(netAmt);
        });

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: GlobalAppColor.LightTextColorCode.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: p2.controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: GlobalAppColor.DarkTextColorCode),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(7),
                  ],
                  onChanged: (v) => p2.manualInput(v),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: TextStyle(color: GlobalAppColor.LightTextColorCode.withOpacity(0.5)),
                  ),
                ),
              ),
              Column(
                children: [
                  InkWell(
                    onTap: () => p2.increment(),
                    child: Icon(Icons.arrow_drop_up, color: GlobalAppColor.LightTextColorCode),
                  ),
                  InkWell(
                    onTap: () => p2.decrement(),
                    child: Icon(Icons.arrow_drop_down, color: GlobalAppColor.LightTextColorCode),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
