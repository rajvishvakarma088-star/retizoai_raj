// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅---------------------------------------------------------------------✅-//
class AddSpecialInstructions extends StatelessWidget {
  final Map<String, dynamic> item;

  const AddSpecialInstructions({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AddOrderProvider, UserInfoProvider>(
      builder: (context, AddOrderCtrl, UserInfoCtrl, child) {
        final double screenWidth = MediaQuery.of(context).size.width;
        final double screenHeight = MediaQuery.of(context).size.height;
        final bool isLargeScreen = screenWidth > 700;
        // ------------------------------------------------------------
        // PREFILL OLD NOTE (only first time)
        // ------------------------------------------------------------
        // PREFILL OLD NOTE (only first time)
        final note = item['note']?.toString().trim();

        // ⚡ Only prefill if not already done
        if (!AddOrderCtrl.isPrefilled) {
          AddOrderCtrl.isPrefilled = true;

          if (note == null ||
              note.isEmpty ||
              note.toLowerCase() == "n/a" ||
              note.toLowerCase() == "null") {
            AddOrderCtrl.SpecialInstructionsController.clear();
            AddOrderCtrl.selectedIngredients.clear();
          } else {
            // Remove duplicate lines & clean
            List<String> cleanLines = note
                .split("\n")
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toSet() // remove duplicates
                .toList();

            // Typed text (remove "Remove:" lines)
            String typedText = cleanLines
                .where((line) => !line.startsWith("Remove:"))
                .join("\n");

            // Ingredients to remove
            AddOrderCtrl.selectedIngredients = cleanLines
                .where((line) => line.startsWith("Remove:"))
                .map((line) => line.replaceFirst("Remove:", "").trim())
                .toSet()
                .toList();

            // Build final controller text
            String removeLines = AddOrderCtrl.selectedIngredients
                .map((e) => "Remove: $e")
                .join("\n");

            String finalText = typedText.isNotEmpty && removeLines.isNotEmpty
                ? "$typedText\n$removeLines"
                : typedText.isNotEmpty
                ? typedText
                : removeLines;

            AddOrderCtrl.SpecialInstructionsController.text = finalText;
          }
        }

        return SafeArea(
          bottom: true,
          child: WillPopScope(
            onWillPop: () async => false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                // ✅ Ensures keyboard visible area is respected
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  width: isLargeScreen ? 600 : double.infinity,

                  // ✅ Standard width
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        // ✅ Scrolls only when keyboard opens
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight * 0.4,
                            maxHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Container(
                              padding: const EdgeInsets.only(
                                top: 15,
                                bottom: 20,
                              ),
                              decoration: BoxDecoration(
                                color: GlobalAppColor.WhiteColorCode,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15.0),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 🔹 Drag indicator
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: GlobalAppColor
                                            .ButtonColor.withValues(alpha: .9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // 🔹 Title
                                  Animate(
                                    effects: [
                                      FadeEffect(delay: 600.ms),
                                      const SlideEffect(
                                        begin: Offset(0, 0.3),
                                        end: Offset(0, 0),
                                      ),
                                    ],
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5,
                                        horizontal: 15,
                                      ),
                                      child: Text(
                                        "Add Special Instructions",
                                        textAlign: TextAlign.center,
                                        style:
                                            CommonWidget.CommonTitleTextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // 🔹 Form Fields
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildLabel("Special Instructions"),
                                            _buildLabel(
                                              "For: ${item['m_p_name']}",
                                            ),
                                            const SizedBox(height: 5),
                                            CommonWidget().MultilineTextFormField(
                                              controller: AddOrderCtrl
                                                  .SpecialInstructionsController,
                                              focusNode: AddOrderCtrl
                                                  .myFocusNodeSpecialInstructions,
                                              minLines: 5,
                                              maxLines: 10,
                                              hintText:
                                                  "Add any special instructions, allergies, or preferences for this item...",
                                            ),

                                            // 🔹 Ingredient Horizontal List
                                            if (AddOrderCtrl
                                                .NoteListing
                                                .isNotEmpty)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 5.0,
                                                    ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 15),
                                                    _buildLabel("Ingredients"),

                                                    SizedBox(
                                                      height: 45,
                                                      child: ListView.separated(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        separatorBuilder:
                                                            (_, __) =>
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                        itemCount: AddOrderCtrl
                                                            .NoteListing
                                                            .length,
                                                        itemBuilder: (context, index) {
                                                          final note = AddOrderCtrl
                                                              .NoteListing[index];
                                                          final name = note
                                                              .inventoryProduct
                                                              .pName
                                                              .trim();
                                                          final isSelected =
                                                              AddOrderCtrl
                                                                  .selectedIngredients
                                                                  .contains(
                                                                    name,
                                                                  );

                                                          return GestureDetector(
                                                            onTap: () {
                                                              AddOrderCtrl.selectIngredient(
                                                                note,
                                                              );
                                                            },
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical: 5,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    isSelected
                                                                    ? GlobalAppColor
                                                                          .ButtonColor
                                                                    : GlobalAppColor
                                                                          .WhiteColorCode,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                                border: Border.all(
                                                                  color:
                                                                      isSelected
                                                                      ? GlobalAppColor
                                                                            .ButtonColor
                                                                      : GlobalAppColor
                                                                            .LightTextColorCode,
                                                                ),
                                                              ),
                                                              child: Center(
                                                                child: Text(
                                                                  note
                                                                      .inventoryProduct
                                                                      .pName,
                                                                  style: TextStyle(
                                                                    color:
                                                                        isSelected
                                                                        ? Colors
                                                                              .white
                                                                        : GlobalAppColor
                                                                              .HomeDarkTextColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            const SizedBox(height: 10),
                                            _buildLabel(
                                              "These instructions will be sent to the kitchen",
                                            ),
                                            const SizedBox(height: 10),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 🔹 Buttons
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Platform.isIOS ? 15 : 10,
                                    ),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: CommonWidget()
                                                .CustomElevatedButton(
                                                  borderColor: GlobalAppColor
                                                      .LightTextColorCode,
                                                  borderWidth: 0.5,
                                                  backgroundColor:
                                                      GlobalAppColor
                                                          .WhiteColorCode,
                                                  title: "Cancel",
                                                  fontWeight: FontWeight.w400,
                                                  textColor: GlobalAppColor
                                                      .HomeDarkTextColor,
                                                  onPressed: () {
                                                    GlobalFunction.hideKeyboard(
                                                      context,
                                                    );
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: CommonWidget()
                                                .customElevatedButtonWithIcon(
                                                  icon: Symbols.article,
                                                  backgroundColor:
                                                      GlobalAppColor
                                                          .ButtonColor,
                                                  title: " Save Note",
                                                  onPressed: () {
                                                    GlobalFunction.hideKeyboard(
                                                      context,
                                                    );
                                                    ExecuteButtonCondition(
                                                      context,
                                                      item,
                                                    );
                                                  },
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Platform.isIOS
                                      ? SizedBox(height: 15)
                                      : SizedBox(height: 5),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        title,
        style: CommonWidget.CommonTitleTextStyle(
          fontSize: 15,
          fontWeight: title == "These instructions will be sent to the kitchen"
              ? FontWeight.w400
              : FontWeight.w500,
          color: GlobalAppColor.LightTextColorCode,
        ),
      ),
    );
  }

  //-✅-------------------------------------------------------------------✅-//
  void ExecuteButtonCondition(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    GlobalFunction.hideKeyboard(context);

    final AddNewCtrl = Provider.of<AddOrderProvider>(context, listen: false);

    // -------------------------------------------------------
    // 1️⃣ CLEAN typed text (Remove "Remove:" lines from it)
    // -------------------------------------------------------
    // Use controller text directly — respects manual edits by the user
    final String finalNote = AddNewCtrl.SpecialInstructionsController.text
        .split("\n")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .join("\n");

    // -------------------------------------------------------
    // 4️⃣ No content error
    // -------------------------------------------------------
    if (finalNote.trim().isEmpty) {
      final existingNote = item['note']?.toString().trim() ?? '';
      final hasExistingNote =
          existingNote.isNotEmpty &&
          existingNote.toLowerCase() != 'n/a' &&
          existingNote.toLowerCase() != 'null';
      if (!hasExistingNote) {
        PopupAlertHelper.showPopupFailedAlert(
          context,
          "Failed",
          "",
          "Enter some text or select at least 1 ingredient",
        );
        return;
      }
      // hasExistingNote → fall through to save empty string (clears the note)
    }

    // -------------------------------------------------------
    // 5️⃣ API / Provider update
    // -------------------------------------------------------
    final isConnected = await GlobalFunction().checkInternetConnection(context);
    if (isConnected) {
      AddNewCtrl.updateItemNote(
        mProdId: item['m_prod_id'].toString(),
        note: finalNote,
        cartEntryId: item['cart_entry_id'] as String?,
      );

      // Close bottom sheet
      Navigator.pop(context);

      // -------------------------------------------------------
      // 6️⃣ RESET ALL for next opening
      // -------------------------------------------------------
      AddNewCtrl.SpecialInstructionsController.clear();
      AddNewCtrl.selectedIngredients.clear();
      AddNewCtrl.isPrefilled = false; // ⭐ CRITICAL FIX ⭐

      // Toast
      showCustomToast(
        context: context,
        message: "Note saved for ${item['m_p_name']}",
      );
    }
  }
}

//-✅---------------------------------------------------------------------✅-//
