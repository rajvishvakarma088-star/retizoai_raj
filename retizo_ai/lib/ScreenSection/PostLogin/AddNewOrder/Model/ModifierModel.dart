// ignore_for_file: file_names, non_constant_identifier_names

//-✅-------------------------------------------------------------------✅-//
/// Represents a single modifier option returned by
/// GET /menu/modifier-mapping/product/{productId}
//-✅-------------------------------------------------------------------✅-//
class ModifierMappingItem {
  final int? mappingId;
  final int? productId;
  final int? modifierId;
  final String? modifierName;
  final String? modifierArbName;
  final String? price;
  final int? groupId;
  final String? groupName;
  final String? groupArbName;
  final int? minSelect;
  final int? maxSelect;
  final bool? isRequired;
  final String? status;

  const ModifierMappingItem({
    this.mappingId,
    this.productId,
    this.modifierId,
    this.modifierName,
    this.modifierArbName,
    this.price,
    this.groupId,
    this.groupName,
    this.groupArbName,
    this.minSelect,
    this.maxSelect,
    this.isRequired,
    this.status,
  });

  /// The effective price as a double (defaults 0 on parse failure).
  double get priceAmount => double.tryParse(price?.toString() ?? '0') ?? 0.0;

  /// Null-safe JSON parsing.
  /// Supports the actual API response shape:
  /// { "id": 133, "name": "cheese", "name_arabic": "...", "price": "100.00", "status": "Active", ... }
  /// Also tolerates legacy nested/flat shapes as fallback.
  factory ModifierMappingItem.fromJson(Map<String, dynamic> json) {
    // Support both nested and flat response shapes
    final Map<String, dynamic>? modifierNode =
        json['modifier'] as Map<String, dynamic>?;
    final Map<String, dynamic>? groupNode =
        json['modifier_group'] as Map<String, dynamic>?;

    return ModifierMappingItem(
      mappingId: _intVal(json['mapping_id']),
      productId: _intVal(json['product_id'] ?? json['m_prod_id']),
      // API returns 'id' at top level — fall back to nested/flat variants
      modifierId: _intVal(
        json['id'] ?? modifierNode?['modifier_id'] ?? json['modifier_id'],
      ),
      // API returns 'name' at top level
      modifierName: _strVal(
        json['name'] ??
            modifierNode?['modifier_name'] ??
            modifierNode?['name'] ??
            json['modifier_name'],
      ),
      // API returns 'name_arabic' at top level
      modifierArbName: _strVal(
        json['name_arabic'] ??
            modifierNode?['modifier_arb_name'] ??
            modifierNode?['arb_name'] ??
            json['modifier_arb_name'] ??
            json['arb_name'],
      ),
      price: _strVal(
        json['price'] ?? modifierNode?['price'] ?? json['modifier_price'],
      ),
      // Group fields — not present in current API; kept for extensibility
      groupId: _intVal(
        groupNode?['group_id'] ??
            groupNode?['modifier_group_id'] ??
            json['modifier_group_id'] ??
            json['group_id'],
      ),
      groupName: _strVal(
        groupNode?['group_name'] ?? groupNode?['name'] ?? json['group_name'],
      ),
      groupArbName: _strVal(
        groupNode?['group_arb_name'] ?? json['group_arb_name'],
      ),
      minSelect: _intVal(groupNode?['min_select'] ?? json['min_select']),
      maxSelect: _intVal(groupNode?['max_select'] ?? json['max_select']),
      isRequired: _boolVal(groupNode?['is_required'] ?? json['is_required']),
      status: _strVal(json['status'] ?? modifierNode?['status']),
    );
  }

  Map<String, dynamic> toJson() => {
    'mapping_id': mappingId,
    'product_id': productId,
    'modifier_id': modifierId,
    'modifier_name': modifierName,
    'modifier_arb_name': modifierArbName,
    'price': price,
    'group_id': groupId,
    'group_name': groupName,
    'group_arb_name': groupArbName,
    'min_select': minSelect,
    'max_select': maxSelect,
    'is_required': isRequired,
    'status': status,
  };

  //----- private helpers ----//
  static int? _intVal(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static String? _strVal(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static bool? _boolVal(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }
}

//-✅-------------------------------------------------------------------✅-//
/// Groups a list of [ModifierMappingItem] by their group, ready for UI display.
//-✅-------------------------------------------------------------------✅-//
class ModifierGroup {
  final int? groupId;
  final String groupName;
  final String? groupArbName;
  final int minSelect;
  final int maxSelect;
  final bool isRequired;
  final List<ModifierMappingItem> items;

  /// Tracks how many of this group have been selected.
  int selectedCount = 0;

  ModifierGroup({
    this.groupId,
    required this.groupName,
    this.groupArbName,
    required this.minSelect,
    required this.maxSelect,
    required this.isRequired,
    required this.items,
  });

  bool get isSingleSelect => maxSelect == 1;

  bool get hasReachedMax => selectedCount >= maxSelect;

  bool get isValid {
    if (isRequired) return selectedCount >= minSelect;
    return true; // optional groups are always valid
  }

  /// Produces a display subtitle like "Choose 1" or "Choose up to 3".
  String get subtitle {
    if (minSelect > 0 && maxSelect == minSelect) {
      return 'Required · Choose $minSelect';
    } else if (minSelect > 0) {
      return 'Required · Choose $minSelect–$maxSelect';
    } else if (maxSelect == 1) {
      return 'Optional · Choose 1';
    } else {
      return 'Optional · Choose up to $maxSelect';
    }
  }

  //----- static factory ------------//
  /// Converts a flat list of [ModifierMappingItem] into grouped display objects.
  static List<ModifierGroup> fromFlatList(List<ModifierMappingItem> items) {
    final Map<int?, List<ModifierMappingItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.groupId, () => []).add(item);
    }

    return grouped.entries.map((entry) {
      final List<ModifierMappingItem> groupItems = entry.value;
      final first = groupItems.first;
      return ModifierGroup(
        groupId: entry.key,
        groupName: first.groupName ?? 'Extras',
        groupArbName: first.groupArbName,
        minSelect: first.minSelect ?? 0,
        maxSelect: first.maxSelect ?? groupItems.length,
        isRequired: first.isRequired ?? false,
        items: groupItems,
      );
    }).toList();
  }
}

//-✅-------------------------------------------------------------------✅-//
/// Represents a single user-selected modifier choice for an order item.
/// Stored inside selectedItems['modifiers'] list.
//-✅-------------------------------------------------------------------✅-//
class SelectedModifier {
  final int? modifierId;
  final String modifierName;
  final double price;
  final int? groupId;
  final String? groupName;
  final int quantity;

  const SelectedModifier({
    this.modifierId,
    required this.modifierName,
    required this.price,
    this.groupId,
    this.groupName,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'modifier_id': modifierId,
    'modifier_name': modifierName,
    'price': price,
    'group_id': groupId,
    'group_name': groupName,
    'quantity': quantity,
  };

  factory SelectedModifier.fromJson(Map<String, dynamic> json) =>
      SelectedModifier(
        modifierId: json['modifier_id'] as int?,
        modifierName: json['modifier_name'] as String? ?? '',
        price: (double.tryParse(json['price']?.toString() ?? '0')) ?? 0.0,
        groupId: json['group_id'] as int?,
        groupName: json['group_name'] as String?,
        quantity: (json['quantity'] as int?) ?? 1,
      );
}

//-✅-------------------------------------------------------------------✅-//
