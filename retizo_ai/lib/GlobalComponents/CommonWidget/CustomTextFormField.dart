// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final TextAlignVertical textAlignVertical;
  final bool enabled;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextStyle? style;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? disabledBorder;
  final Color? fillColor;
  final double? textFieldHeight;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool isPassword;
  final Widget? suffixIcon;

  final ValueNotifier<bool>? obscureTextNotifier;

  CustomTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textAlign = TextAlign.left,
    this.textAlignVertical = TextAlignVertical.center,
    this.enabled = true,
    this.hintText,
    this.hintStyle,
    this.style,
    this.enabledBorder,
    this.focusedBorder,
    this.disabledBorder,
    this.fillColor,
    this.textFieldHeight,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.isPassword = false,
    this.suffixIcon,
    ValueNotifier<bool>? obscureTextNotifier,
  }) : obscureTextNotifier =
           obscureTextNotifier ?? ValueNotifier<bool>(isPassword);

  @override
  Widget build(BuildContext context) {
    Widget textField = isPassword
        ? ValueListenableBuilder<bool>(
            valueListenable: obscureTextNotifier!,
            builder: (context, obscure, child) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType ?? TextInputType.text,
                textAlign: textAlign,
                textAlignVertical: textAlignVertical,
                enabled: enabled,
                textCapitalization: TextCapitalization.words,
                style: style ?? CommonWidget.CommonTitleTextStyle(),
                maxLines: maxLines,
                minLines: minLines,
                maxLength: maxLength,
                inputFormatters: inputFormatters,
                onChanged: onChanged,
                obscureText: obscure,
                cursorColor: GlobalAppColor.DarkTextColorCode,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle:
                      hintStyle ??
                      CommonWidget.CommonTitleTextStyle(
                        fontWeight: FontWeight.w500,
                        color: GlobalAppColor.LightTextColorCode.withOpacity(
                          0.8,
                        ),
                      ),
                  filled: true,
                  fillColor: fillColor ?? Colors.white,
                  enabledBorder: enabledBorder ?? CommonWidget().buildBorder(),
                  focusedBorder: focusedBorder ?? CommonWidget().buildBorder(),
                  disabledBorder:
                      disabledBorder ?? CommonWidget().buildBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: AppDimensions.md,
                    horizontal: AppDimensions.md,
                  ),
                  isDense: true,
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller!,
                    builder: (context, textValue, child) {
                      return InkWell(
                        overlayColor: MaterialStateProperty.all(
                          Colors.transparent,
                        ),
                        onTap: textValue.text.isEmpty
                            ? null
                            : () => obscureTextNotifier!.value = !obscure,
                        child: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                          size: 22,
                          color: obscure
                              ? GlobalAppColor.LightTextColorCode.withOpacity(
                                  0.6,
                                )
                              : GlobalAppColor.ButtonColor,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          )
        : TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType ?? TextInputType.text,
            textAlign: textAlign,
            textAlignVertical: textAlignVertical,
            enabled: enabled,
            style: style ?? CommonWidget.CommonTitleTextStyle(),
            maxLines: maxLines,
            minLines: minLines,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            cursorColor: GlobalAppColor.DarkTextColorCode,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle:
                  hintStyle ??
                  CommonWidget.CommonTitleTextStyle(
                    fontWeight: FontWeight.w500,
                    color: GlobalAppColor.LightTextColorCode.withOpacity(0.8),
                  ),
              filled: true,
              fillColor: fillColor ?? Colors.white,
              enabledBorder: enabledBorder ?? CommonWidget().buildBorder(),
              focusedBorder: focusedBorder ?? CommonWidget().buildBorder(),
              disabledBorder: disabledBorder ?? CommonWidget().buildBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: AppDimensions.md,
                horizontal: AppDimensions.md,
              ),
              isDense: true,
              suffixIcon: suffixIcon,
            ),
          );

    return textFieldHeight != null
        ? SizedBox(height: textFieldHeight, child: textField)
        : textField;
  }
}

//-✅---------------------------------------------------------------------✅-//
