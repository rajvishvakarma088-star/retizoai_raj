// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅-------------------------------------------------------------------✅-//
/// Professional Modifier Selection Bottom Sheet
/// Shows when a user adds a menu item that has modifiers.
/// Returns [List<SelectedModifier>] on confirm, null on cancel.
///
/// Usage:
///   final result = await ModifierSelectionSheet.show(
///     context: context,
///     item: menuItem,
///     groups: modifierGroups,
///   );
//-✅-------------------------------------------------------------------✅-//
class ModifierSelectionSheet extends StatefulWidget {
  final MenuModel item;
  final List<ModifierGroup> groups;

  const ModifierSelectionSheet({
    super.key,
    required this.item,
    required this.groups,
  });

  /// Show the bottom sheet and await user selection.
  static Future<List<SelectedModifier>?> show({
    required BuildContext context,
    required MenuModel item,
    required List<ModifierGroup> groups,
  }) async {
    return showModalBottomSheet<List<SelectedModifier>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ModifierSelectionSheet(item: item, groups: groups),
    );
  }

  @override
  State<ModifierSelectionSheet> createState() => _ModifierSelectionSheetState();
}

//-✅-------------------------------------------------------------------✅-//
class _ModifierSelectionSheetState extends State<ModifierSelectionSheet> {
  /// groupIndex → Set of selected modifier_ids
  late final Map<int, Set<int>> _selectedIds;

  /// groupIndex → single selected modifier_id (for single-select groups)
  late final Map<int, int?> _singleSelected;

  bool get _isValid {
    for (int i = 0; i < widget.groups.length; i++) {
      final g = widget.groups[i];
      if (!g.isRequired) continue;
      final count = g.isSingleSelect
          ? (_singleSelected[i] != null ? 1 : 0)
          : (_selectedIds[i]?.length ?? 0);
      if (count < g.minSelect) return false;
    }
    return true;
  }

  double get _modifierTotal {
    double total = 0;
    for (int i = 0; i < widget.groups.length; i++) {
      final g = widget.groups[i];
      if (g.isSingleSelect) {
        final selId = _singleSelected[i];
        if (selId != null) {
          final mod = g.items.firstWhere(
            (m) => m.modifierId == selId,
            orElse: () => const ModifierMappingItem(),
          );
          total += mod.priceAmount;
        }
      } else {
        final ids = _selectedIds[i] ?? {};
        for (final id in ids) {
          final mod = g.items.firstWhere(
            (m) => m.modifierId == id,
            orElse: () => const ModifierMappingItem(),
          );
          total += mod.priceAmount;
        }
      }
    }
    return total;
  }

  double get _basePrice =>
      double.tryParse(widget.item.price?.toString() ?? '0') ?? 0.0;

  double get _grandTotal => _basePrice + _modifierTotal;

  @override
  void initState() {
    super.initState();
    _selectedIds = {for (int i = 0; i < widget.groups.length; i++) i: <int>{}};
    _singleSelected = {for (int i = 0; i < widget.groups.length; i++) i: null};

    // Auto-select if a group has exactly one required item
    for (int i = 0; i < widget.groups.length; i++) {
      final g = widget.groups[i];
      if (g.isRequired &&
          g.items.length == 1 &&
          g.items.first.modifierId != null) {
        if (g.isSingleSelect) {
          _singleSelected[i] = g.items.first.modifierId;
        } else {
          _selectedIds[i]!.add(g.items.first.modifierId!);
        }
      }
    }
  }

  List<SelectedModifier> _buildResult() {
    final List<SelectedModifier> result = [];
    for (int i = 0; i < widget.groups.length; i++) {
      final g = widget.groups[i];
      if (g.isSingleSelect) {
        final selId = _singleSelected[i];
        if (selId != null) {
          final mod = g.items.firstWhere((m) => m.modifierId == selId);
          result.add(
            SelectedModifier(
              modifierId: mod.modifierId,
              modifierName: mod.modifierName ?? '',
              price: mod.priceAmount,
              groupId: g.groupId,
              groupName: g.groupName,
            ),
          );
        }
      } else {
        for (final id in (_selectedIds[i] ?? {})) {
          final mod = g.items.firstWhere((m) => m.modifierId == id);
          result.add(
            SelectedModifier(
              modifierId: mod.modifierId,
              modifierName: mod.modifierName ?? '',
              price: mod.priceAmount,
              groupId: g.groupId,
              groupName: g.groupName,
            ),
          );
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLarge = screenWidth > 700;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: isLarge ? 620.0 : double.infinity,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: GlobalAppColor.ButtonColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              // ── Product header ───────────────────────────────────────
              _buildHeader(),

              CommonWidget().DividerWidget(height: 1.0),

              // ── Scrollable groups ────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < widget.groups.length; i++) ...[
                        _buildGroupSection(i, widget.groups[i]),
                        if (i < widget.groups.length - 1)
                          CommonWidget().DividerWidget(height: 1.0),
                      ],
                    ],
                  ),
                ),
              ),

              CommonWidget().DividerWidget(height: 1.0),

              // ── Bottom action bar ────────────────────────────────────
              _buildActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  //-✅--buildHeader------------------------------------------------------✅-//
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CommonWidget().RectangleCachedImage(
              context: context,
              imageUrl:
                  widget.item.mProductIcon != null &&
                      widget.item.mProductIcon!.startsWith('https')
                  ? widget.item.mProductIcon!
                  : '${GlobalServiceURL.ImageBaseUrl}${widget.item.mProductIcon}',
              width: 58,
              height: 58,
              decoration: const BoxDecoration(),
            ),
          ),
          const SizedBox(width: 12),
          // Name + price column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.mPName ?? 'Item',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CommonWidget.CommonTitleTextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                if (widget.item.mPArbName != null &&
                    widget.item.mPArbName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.item.mPArbName!,
                    style: CommonWidget.CommonTitleTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: GlobalAppColor.DarkTextColorCode.withOpacity(0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Symbols.credit_card,
                      size: 15,
                      color: GlobalAppColor.DarkTextColorCode.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.item.price ?? '0.00',
                      style: CommonWidget.CommonTitleTextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: GlobalAppColor.DarkTextColorCode.withOpacity(
                          0.8,
                        ),
                      ),
                    ),
                    if (_modifierTotal > 0) ...[
                      Text(
                        '  +  ${_modifierTotal.toStringAsFixed(2)}',
                        style: CommonWidget.CommonTitleTextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: GlobalAppColor.ButtonColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            icon: Icon(
              Icons.close,
              color: GlobalAppColor.DarkTextColorCode.withOpacity(0.5),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  //-✅--buildGroupSection------------------------------------------------✅-//
  Widget _buildGroupSection(int groupIndex, ModifierGroup group) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.groupName,
                      style: CommonWidget.CommonTitleTextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      group.subtitle,
                      style: CommonWidget.CommonTitleTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: GlobalAppColor.DarkTextColorCode.withOpacity(
                          0.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Required badge
              if (group.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFEF4444),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'Required',
                    style: CommonWidget.CommonTitleTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Modifier items
          ...group.items.asMap().entries.map((entry) {
            final mod = entry.value;
            return _buildModifierTile(groupIndex, group, mod);
          }),
        ],
      ),
    );
  }

  //-✅--buildModifierTile------------------------------------------------✅-//
  Widget _buildModifierTile(
    int groupIndex,
    ModifierGroup group,
    ModifierMappingItem mod,
  ) {
    if (mod.modifierId == null) return const SizedBox.shrink();

    // Determine if this modifier is "active" (status active or null)
    final bool isActive =
        mod.status == null ||
        mod.status!.toLowerCase() == 'active' ||
        mod.status!.toLowerCase() == '';

    final bool isSelected = group.isSingleSelect
        ? _singleSelected[groupIndex] == mod.modifierId
        : (_selectedIds[groupIndex]?.contains(mod.modifierId) ?? false);

    final bool isDisabled =
        !isActive ||
        (!isSelected && !group.isSingleSelect && group.hasReachedMax);

    return InkWell(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                if (group.isSingleSelect) {
                  _singleSelected[groupIndex] =
                      _singleSelected[groupIndex] == mod.modifierId
                      ? null
                      : mod.modifierId;
                } else {
                  final ids = _selectedIds[groupIndex]!;
                  if (ids.contains(mod.modifierId)) {
                    ids.remove(mod.modifierId);
                  } else {
                    ids.add(mod.modifierId!);
                  }
                }
              });
            },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? GlobalAppColor.ButtonColor.withOpacity(0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? GlobalAppColor.ButtonColor
                : GlobalAppColor.DarkTextColorCode.withOpacity(0.12),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Selector (radio or checkbox)
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: group.isSingleSelect
                    ? BoxShape.circle
                    : BoxShape.rectangle,
                borderRadius: group.isSingleSelect
                    ? null
                    : BorderRadius.circular(4),
                color: isSelected ? GlobalAppColor.ButtonColor : Colors.white,
                border: Border.all(
                  color: isDisabled
                      ? Colors.grey.shade300
                      : isSelected
                      ? GlobalAppColor.ButtonColor
                      : GlobalAppColor.DarkTextColorCode.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            // Modifier name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mod.modifierName ?? '',
                    style: CommonWidget.CommonTitleTextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isDisabled
                          ? GlobalAppColor.DarkTextColorCode.withOpacity(0.4)
                          : const Color(0xFF1F2937),
                    ),
                  ),
                  if (mod.modifierArbName != null &&
                      mod.modifierArbName!.isNotEmpty)
                    Text(
                      mod.modifierArbName!,
                      style: CommonWidget.CommonTitleTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: GlobalAppColor.DarkTextColorCode.withOpacity(
                          0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Price badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: mod.priceAmount > 0
                    ? GlobalAppColor.ButtonColor.withOpacity(0.1)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Symbols.credit_card,
                    size: 12,
                    color: mod.priceAmount > 0
                        ? GlobalAppColor.ButtonColor
                        : GlobalAppColor.DarkTextColorCode.withOpacity(0.5),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    mod.priceAmount > 0
                        ? '+${mod.priceAmount.toStringAsFixed(2)}'
                        : 'Free',
                    style: CommonWidget.CommonTitleTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: mod.priceAmount > 0
                          ? GlobalAppColor.ButtonColor
                          : GlobalAppColor.DarkTextColorCode.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //-✅--buildActionBar---------------------------------------------------✅-//
  Widget _buildActionBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Row(
          children: [
            // Grand total display
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: CommonWidget.CommonTitleTextStyle(
                      fontSize: 12,
                      color: GlobalAppColor.DarkTextColorCode.withOpacity(0.5),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Symbols.credit_card,
                        size: 16,
                        color: GlobalAppColor.DarkTextColorCode,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _grandTotal.toStringAsFixed(2),
                        style: CommonWidget.CommonTitleTextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Add to Order button
            Expanded(
              flex: 2,
              child: AnimatedOpacity(
                opacity: _isValid ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: GlobalElevatedButton(
                  onPressed: _isValid
                      ? () => Navigator.pop(context, _buildResult())
                      : () {}, // tap blocked — opacity signals disabled state
                  buttonText: 'Add to Order',
                  backgroundColor: GlobalAppColor.ButtonColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//-✅-------------------------------------------------------------------✅-//
