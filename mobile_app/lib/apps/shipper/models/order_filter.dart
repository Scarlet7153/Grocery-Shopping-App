import 'package:equatable/equatable.dart';

/// Model cho cấu hình lọc đơn hàng
class OrderFilter extends Equatable {
  final double? maxDistance; // km (0-20)
  final double? minEarning; // VNĐ (10000-100000)
  final List<int>? storeIds; // Cửa hàng ưu tiên
  final bool? avoidPickup; // Tránh order cần pickup (chỉ giao)
  final int? maxItems; // Tối đa N sản phẩm

  // Giá trị mặc định
  static const double DEFAULT_MAX_DISTANCE = 20.0;
  static const double DEFAULT_MIN_EARNING = 10000.0;
  static const bool DEFAULT_AVOID_PICKUP = false;
  static const int DEFAULT_MAX_ITEMS = 50;

  const OrderFilter({
    this.maxDistance,
    this.minEarning,
    this.storeIds,
    this.avoidPickup,
    this.maxItems,
  });

  /// Tạo filter mặc định
  factory OrderFilter.defaultFilter() {
    return const OrderFilter(
      maxDistance: DEFAULT_MAX_DISTANCE,
      minEarning: DEFAULT_MIN_EARNING,
      avoidPickup: DEFAULT_AVOID_PICKUP,
      maxItems: DEFAULT_MAX_ITEMS,
    );
  }

  /// Copy with - để update một vài field
  OrderFilter copyWith({
    double? maxDistance,
    double? minEarning,
    List<int>? storeIds,
    bool? avoidPickup,
    int? maxItems,
  }) {
    return OrderFilter(
      maxDistance: maxDistance ?? this.maxDistance,
      minEarning: minEarning ?? this.minEarning,
      storeIds: storeIds ?? this.storeIds,
      avoidPickup: avoidPickup ?? this.avoidPickup,
      maxItems: maxItems ?? this.maxItems,
    );
  }

  /// Convert to JSON để lưu vào SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'maxDistance': maxDistance,
      'minEarning': minEarning,
      'storeIds': storeIds,
      'avoidPickup': avoidPickup,
      'maxItems': maxItems,
    };
  }

  /// Load từ JSON
  factory OrderFilter.fromJson(Map<String, dynamic> json) {
    return OrderFilter(
      maxDistance: json['maxDistance'] as double?,
      minEarning: json['minEarning'] as double?,
      storeIds: ((json['storeIds'] ?? []) as List).cast<int>(),
      avoidPickup: json['avoidPickup'] as bool?,
      maxItems: json['maxItems'] as int?,
    );
  }

  /// Kiểm tra filter có active không
  bool get isActive {
    return (maxDistance != null && maxDistance! < DEFAULT_MAX_DISTANCE) ||
        (minEarning != null && minEarning! > DEFAULT_MIN_EARNING) ||
        (storeIds != null && storeIds!.isNotEmpty) ||
        (avoidPickup == true) ||
        (maxItems != null && maxItems! < DEFAULT_MAX_ITEMS);
  }

  @override
  List<Object?> get props =>
      [maxDistance, minEarning, storeIds, avoidPickup, maxItems];
}
