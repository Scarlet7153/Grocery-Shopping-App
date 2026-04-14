/// UnitCategory: Phân loại đơn vị (Khối lượng, Số lượng, Bó/Mớ, Thể tích)
class UnitCategory {
  final int id;
  final String code; // 'weight', 'count', 'bundle', 'volume'
  final String name; // 'Khối lượng', 'Số lượng'
  final String? icon; // Material icon name
  final int displayOrder;
  final bool isActive;

  const UnitCategory({
    required this.id,
    required this.code,
    required this.name,
    this.icon,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory UnitCategory.fromJson(Map<String, dynamic> json) {
    // Helper để lấy giá trị từ cả camelCase và snake_case
    T? getValue<T>(String camelCase, String snakeCase) {
      if (json.containsKey(camelCase)) return json[camelCase] as T?;
      if (json.containsKey(snakeCase)) return json[snakeCase] as T?;
      return null;
    }

    return UnitCategory(
      id: json['id'] as int? ?? 0,
      code: getValue<String>('code', 'code') ?? '',
      name: getValue<String>('name', 'name') ?? '',
      icon: getValue<String>('icon', 'icon'),
      displayOrder: getValue<int>('displayOrder', 'display_order') ?? 0,
      isActive: getValue<bool>('isActive', 'is_active') ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'icon': icon,
        'displayOrder': displayOrder,
        'isActive': isActive,
      };

  /// Helper: Lấy icon data cho Flutter
  String get flutterIcon => icon ?? _getDefaultIcon();

  String _getDefaultIcon() {
    switch (code) {
      case 'weight':
        return 'scale';
      case 'count':
        return 'format_list_numbered';
      case 'bundle':
        return 'grass';
      case 'volume':
        return 'local_drink';
      default:
        return 'inventory';
    }
  }
}

/// Unit: Đơn vị cụ thể (kg, gram, bó, quả, vỉ, chai)
class Unit {
  final int id;
  final int categoryId;
  final String code; // 'kg', 'gram', 'bo', 'qua'
  final String name; // 'Kilogram', 'Bó'
  final String symbol; // 'kg', 'bó'
  final String? baseUnit; // 'gram', 'count', 'ml'
  final double conversionRate; // 1 kg = 1000 gram
  final double stepValue; // 0.5 for lạng, 1 for quả
  final bool requiresQuantityInput;
  final double minValue;
  final double maxValue;
  final int displayOrder;
  final bool isActive;

  const Unit({
    required this.id,
    required this.categoryId,
    required this.code,
    required this.name,
    required this.symbol,
    this.baseUnit,
    this.conversionRate = 1.0,
    this.stepValue = 1.0,
    this.requiresQuantityInput = false,
    this.minValue = 0.0,
    this.maxValue = 999999.0,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    // Helper để lấy giá trị từ cả camelCase và snake_case
    T? getValue<T>(String camelCase, String snakeCase) {
      if (json.containsKey(camelCase)) return json[camelCase] as T?;
      if (json.containsKey(snakeCase)) return json[snakeCase] as T?;
      return null;
    }

    return Unit(
      id: json['id'] as int? ?? 0,
      categoryId: getValue<int>('categoryId', 'category_id') ?? 0,
      code: getValue<String>('code', 'code') ?? '',
      name: getValue<String>('name', 'name') ?? '',
      symbol: getValue<String>('symbol', 'symbol') ?? '',
      baseUnit: getValue<String>('baseUnit', 'base_unit'),
      conversionRate:
          (getValue<num>('conversionRate', 'conversion_rate'))?.toDouble() ??
              1.0,
      stepValue: (getValue<num>('stepValue', 'step_value'))?.toDouble() ?? 1.0,
        requiresQuantityInput:
          getValue<bool>('requiresQuantityInput', 'requires_quantity_input') ??
            false,
      minValue: (getValue<num>('minValue', 'min_value'))?.toDouble() ?? 0.0,
      maxValue:
          (getValue<num>('maxValue', 'max_value'))?.toDouble() ?? 999999.0,
      displayOrder: getValue<int>('displayOrder', 'display_order') ?? 0,
      isActive: getValue<bool>('isActive', 'is_active') ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'code': code,
        'name': name,
        'symbol': symbol,
        'baseUnit': baseUnit,
        'conversionRate': conversionRate,
        'stepValue': stepValue,
        'requiresQuantityInput': requiresQuantityInput,
        'minValue': minValue,
        'maxValue': maxValue,
        'displayOrder': displayOrder,
        'isActive': isActive,
      };

  /// Helper: Format số lượng với đơn vị
  String formatQuantity(double quantity) {
    // Làm tròn theo step
    final rounded = (quantity / stepValue).round() * stepValue;

    // Hiển thị không thập phân nếu là số nguyên
    if (rounded == rounded.roundToDouble()) {
      return '${rounded.toInt()} $symbol';
    }
    return '${rounded.toStringAsFixed(1)} $symbol';
  }

  /// Helper: Kiểm tra giá trị hợp lệ
  bool isValidQuantity(double quantity) {
    return quantity >= minValue &&
        quantity <= maxValue &&
        (quantity % stepValue).abs() < 0.0001;
  }
}

/// ProductUnitMapping: Liên kết sản phẩm với đơn vị
class ProductUnitMapping {
  final int id;
  final int productId;
  final Unit unit;
  final String? unitLabel; // "Gói 300g", "Bó lớn"
  final double price;
  final int stockQuantity;
  final double? baseQuantity; // 1 bó = 300 gram
  final String? baseUnit;
  final bool isDefault;
  final bool isActive;

  const ProductUnitMapping({
    required this.id,
    required this.productId,
    required this.unit,
    this.unitLabel,
    required this.price,
    this.stockQuantity = 0,
    this.baseQuantity,
    this.baseUnit,
    this.isDefault = false,
    this.isActive = true,
  });

  factory ProductUnitMapping.fromJson(Map<String, dynamic> json) {
    // Helper để lấy giá trị từ cả camelCase và snake_case
    T? getValue<T>(String camelCase, String snakeCase) {
      if (json.containsKey(camelCase)) return json[camelCase] as T?;
      if (json.containsKey(snakeCase)) return json[snakeCase] as T?;
      return null;
    }

    final rawId = json['id'];
    final rawProductId = getValue<num>('productId', 'product_id');
    final unitJson = getValue<Map<String, dynamic>>('unit', 'unit');
    final unitCode = getValue<String>('unitCode', 'unit_code');
    final unitName = getValue<String>('unitName', 'unit_name') ??
      getValue<String>('unitLabel', 'unit_label') ??
      '';

    final parsedUnit = unitJson != null
      ? Unit.fromJson(unitJson)
      : Unit(
        id: 0,
        categoryId: 0,
        code: (unitCode != null && unitCode.isNotEmpty)
          ? unitCode
          : (unitName.isEmpty
            ? 'unit'
            : unitName.toLowerCase().replaceAll(' ', '_')),
        name: unitName.isEmpty ? 'Đơn vị' : unitName,
        symbol: unitName.isEmpty ? 'đv' : unitName,
        );

    return ProductUnitMapping(
      id: rawId is num ? rawId.toInt() : 0,
      productId: rawProductId?.toInt() ?? 0,
      unit: parsedUnit,
      unitLabel: getValue<String>('unitLabel', 'unit_label') ??
        (unitName.isEmpty ? null : unitName),
      price: (getValue<num>('price', 'price') ?? 0).toDouble(),
      stockQuantity:
        (getValue<num>('stockQuantity', 'stock_quantity') ?? 0).toInt(),
      baseQuantity:
          (getValue<num>('baseQuantity', 'base_quantity'))?.toDouble(),
      baseUnit: getValue<String>('baseUnit', 'base_unit'),
      isDefault: getValue<bool>('isDefault', 'is_default') ?? false,
      isActive: getValue<bool>('isActive', 'is_active') ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'unit': unit.toJson(),
        'unitLabel': unitLabel,
        'price': price,
        'stockQuantity': stockQuantity,
        'baseQuantity': baseQuantity,
        'baseUnit': baseUnit,
        'isDefault': isDefault,
        'isActive': isActive,
      };

  /// Helper: Lấy tên hiển thị
  String get displayName => unitLabel ?? unit.name;

  /// Helper: Lấy giá hiển thị
  String get displayPrice => '${price.toStringAsFixed(0)}đ/${unit.symbol}';

  /// Helper: Format số lượng
  String formatQuantity(double quantity) => unit.formatQuantity(quantity);
}

/// UnitConfig: Cấu hình UI cho đơn vị
class UnitUIConfig {
  final String code;
  final String icon;
  final String color;
  final String description;

  const UnitUIConfig({
    required this.code,
    required this.icon,
    required this.color,
    required this.description,
  });

  /// Danh sách cấu hình mặc định
  static const List<UnitUIConfig> defaults = [
    UnitUIConfig(
      code: 'weight',
      icon: 'scale',
      color: '#4CAF50',
      description: 'Đo theo khối lượng: kg, lạng, gram',
    ),
    UnitUIConfig(
      code: 'count',
      icon: 'format_list_numbered',
      color: '#2196F3',
      description: 'Đếm số lượng: quả, con, vỉ',
    ),
    UnitUIConfig(
      code: 'bundle',
      icon: 'grass',
      color: '#FF9800',
      description: 'Bó, mớ, gói: rau củ quả',
    ),
    UnitUIConfig(
      code: 'volume',
      icon: 'local_drink',
      color: '#9C27B0',
      description: 'Thể tích: lít, chai, lon',
    ),
  ];
}
