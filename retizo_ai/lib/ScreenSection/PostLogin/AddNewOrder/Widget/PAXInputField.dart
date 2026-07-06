// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, strict_top_level_inference, avoid_web_libraries_in_flutter, unnecessary_import, curly_braces_in_flow_control_structures
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
class PAXInputField extends StatefulWidget {
  final String hintText;

  const PAXInputField({super.key, this.hintText = "PAX (person)"});

  @override
  State<PAXInputField> createState() => _PAXInputFieldState();
}

class _PAXInputFieldState extends State<PAXInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NumberInputPAXProvider, AddOrderProvider>(
      builder: (context, provider, AddOrderCtrl, child) {
        // Update controller value on rebuild
        if (provider.value == 0 && _controller.text.isNotEmpty) {
          _controller.text = '';
        } else if (provider.value != 0 &&
            _controller.text != provider.value.toString()) {
          _controller.text = provider.value.toString();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: GlobalAppColor.DarkTextColorCode.withOpacity(.1),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: GlobalAppColor.DarkTextColorCode,
                  style: CommonWidget.CommonTitleTextStyle(
                    color: GlobalAppColor.DarkTextColorCode,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: CommonWidget.CommonTitleTextStyle(
                      color: GlobalAppColor.DarkTextColorCode.withOpacity(.6),
                      fontSize: 13,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 4,
                    ),
                  ),
                  onChanged: AddOrderCtrl.isBookingLoader
                      ? null
                      : provider.manualInput,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: AddOrderCtrl.isBookingLoader
                        ? null
                        : provider.increment,
                    child: const Icon(Icons.arrow_drop_up, size: 18),
                  ),
                  InkWell(
                    onTap: AddOrderCtrl.isBookingLoader
                        ? null
                        : provider.decrement,
                    child: const Icon(Icons.arrow_drop_down, size: 18),
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
