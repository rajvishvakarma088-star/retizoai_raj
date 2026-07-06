// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_calls, deprecated_member_use, unnecessary_cast
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
class CommonDropdown extends StatefulWidget {
  final String? selectedValue;
  final List<String>? items;
  final ValueChanged<String?>? onChanged;
  final BoxDecoration? decoration;
  final double? dropDownHeight;
  final double? dropDownWidth;
  final String? hintText;
  final bool removeDropdownBorder;
  final TextStyle? hintStyle;
  final TextStyle? itemStyle;
  final EdgeInsetsGeometry? textIconSpacing;
  final EdgeInsetsGeometry? textPadding;
  final MainAxisAlignment? textIconAlignment;
  final double? IconSize;
  final bool enabled;
  final double? iconPadding;

  // ✅ Optional flags
  final bool showTextLeft; // Text left aligned
  final bool showIconRight; // Icon right side

  const CommonDropdown({
    super.key,
    this.selectedValue,
    this.items,
    this.onChanged,
    this.decoration,
    this.dropDownHeight = 45,
    this.dropDownWidth = double.infinity,
    this.hintText,
    this.removeDropdownBorder = false,
    this.hintStyle,
    this.itemStyle,
    this.textIconSpacing,
    this.textPadding,
    this.textIconAlignment,
    this.IconSize = 25,
    this.enabled = true,
    this.showTextLeft = false, // default false
    this.showIconRight = true, // default true
    this.iconPadding = 4.0, // default padding
  });

  @override
  State<CommonDropdown> createState() => _CommonDropdownState();
}

class _CommonDropdownState extends State<CommonDropdown> {
  bool isDropdownOpened = false;

  void _showNoInternetPopup(BuildContext context) {
    PopupAlertHelper.showPopupFailedAlert(
      context,
      "InternetNotConnected",
      "",
      GlobalFlag.InternetNotConnected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckInternetProvider>(
      builder: (context, internetProvider, child) {
        final bool isOnline = internetProvider.isConnected;
        final uniqueItems = widget.items?.toSet().toList() ?? [];

        final currentValue =
            (widget.selectedValue != null &&
                uniqueItems.contains(widget.selectedValue))
            ? widget.selectedValue
            : null;

        // 🔹 Updated Hint Logic
        final displayText = (currentValue == null || currentValue.isEmpty)
            ? (widget.hintText ?? "Select Value")
            : currentValue;
        final isHint = (currentValue == null || currentValue.isEmpty);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!isOnline) {
              _showNoInternetPopup(context);
            }
          },
          child: AbsorbPointer(
            absorbing: !isOnline || !widget.enabled,
            child: Container(
              width: widget.dropDownWidth ?? double.infinity,
              height: widget.dropDownHeight ?? 45,
              decoration:
                  widget.decoration ??
                  BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
              child: DropdownButtonHideUnderline(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double buttonWidth = constraints.maxWidth;
                    const double menuWidth = 150;
                    double dx = buttonWidth > menuWidth
                        ? buttonWidth - menuWidth
                        : 0;

                    return DropdownButton2(
                      isDense: true,
                      isExpanded: true,
                      customButton: Padding(
                        padding:
                            widget.textPadding ??
                            const EdgeInsets.symmetric(horizontal: 5.0),
                        child: SizedBox(
                          width: buttonWidth,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment:
                                widget.textIconAlignment ??
                                MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 2.0),
                                  child: Text(
                                    displayText,
                                    textAlign: widget.showTextLeft
                                        ? TextAlign.left
                                        : TextAlign.center,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: isHint
                                        ? (widget.hintStyle ??
                                              CommonWidget.CommonTitleTextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13,
                                                color:
                                                    GlobalAppColor
                                                        .DarkTextColorCode.withOpacity(
                                                      0.5,
                                                    ),
                                              ))
                                        : (widget.itemStyle ??
                                              CommonWidget.CommonTitleTextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13,
                                                color:
                                                    GlobalAppColor.ButtonColor,
                                              )),
                                  ),
                                ),
                              ),
                              if (widget.showIconRight)
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: widget.iconPadding ?? 4.0,
                                  ),
                                  child: Icon(
                                    isDropdownOpened
                                        ? Icons.keyboard_arrow_up_sharp
                                        : Icons.keyboard_arrow_down_sharp,
                                    color: isDropdownOpened
                                        ? GlobalAppColor.ButtonColor
                                        : GlobalAppColor
                                              .DarkTextColorCode.withOpacity(
                                            0.6,
                                          ),
                                    size: widget.IconSize,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      dropdownStyleData: DropdownStyleData(
                        padding: EdgeInsets.zero,
                        useSafeArea: true,
                        width: menuWidth,
                        offset: Offset(dx, -5),
                        maxHeight: 200,
                        decoration: BoxDecoration(
                          color: GlobalAppColor.WhiteColorCode,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                          border: Border.all(
                            color: GlobalAppColor.DarkTextColorCode.withOpacity(0.2),
                            width: 0.6,
                          ),
                        ),
                      ),
                      items: uniqueItems
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    widget.itemStyle ??
                                    CommonWidget.CommonTitleTextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: GlobalAppColor.ButtonColor,
                                    ),
                              ),
                            ),
                          )
                          .toList(),
                      value: currentValue,
                      onChanged: (value) {
                        if (isOnline && widget.enabled) {
                          GlobalFunction.hideKeyboard(context);
                          widget.onChanged?.call(value as String?);
                        }
                      },
                      onMenuStateChange: (isOpen) {
                        if (!isOnline && isOpen) {
                          setState(() => isDropdownOpened = false);
                          _showNoInternetPopup(context);
                        } else {
                          setState(() => isDropdownOpened = isOpen);
                        }
                      },
                      buttonStyleData: ButtonStyleData(
                        overlayColor: MaterialStateProperty.all(
                          Colors.transparent,
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        overlayColor: MaterialStatePropertyAll(
                          Colors.transparent,
                        ),
                        height: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
//-✅---------------------------------------------------------------------✅-//

//-✅---------------------------------------------------------------------✅-//
