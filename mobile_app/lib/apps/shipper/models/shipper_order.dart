enum OrderStatus {
  AVAILABLE,
  PENDING,
  PICKING_UP,
  DELIVERING,
  DELIVERED,
  CANCELLED,
  UNKNOWN,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.AVAILABLE:
        return 'Có thể nhận';
      case OrderStatus.PENDING:
        return 'Chờ nhận';
      case OrderStatus.PICKING_UP:
        return 'Đang lấy hàng';
      case OrderStatus.DELIVERING:
        return 'Đang giao';
      case OrderStatus.DELIVERED:
        return 'Đã giao';
      case OrderStatus.CANCELLED:
        return 'Đã hủy';
      case OrderStatus.UNKNOWN:
        return 'Không rõ';
    }
  }
}

OrderStatus orderStatusFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'AVAILABLE':
      return OrderStatus.AVAILABLE;
    case 'PENDING':
      return OrderStatus.PENDING;
    case 'PICKING_UP':
      return OrderStatus.PICKING_UP;
    case 'DELIVERING':
      return OrderStatus.DELIVERING;
    case 'DELIVERED':
      return OrderStatus.DELIVERED;
    case 'CANCELLED':
      return OrderStatus.CANCELLED;
    default:
      return OrderStatus.UNKNOWN;
  }
}

class ShipperOrder {
  final int id;
  final String customerName;
  final String customerPhone;
  final String storeName;
  final String deliveryAddress;
  final OrderStatus status;
  final double grandTotal;
  final DateTime createdAt;

  ShipperOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.storeName,
    required this.deliveryAddress,
    required this.status,
    required this.grandTotal,
    required this.createdAt,
  });

  factory ShipperOrder.fromJson(Map<String, dynamic> json) {
    return ShipperOrder(
      id: (json['id'] as num).toInt(),
      customerName: (json['customerName'] as String?) ?? 'Khách lạ',
      customerPhone: (json['customerPhone'] as String?) ?? '',
      storeName: (json['storeName'] as String?) ?? '',
      deliveryAddress: (json['deliveryAddress'] as String?) ?? '',
      status: orderStatusFromString(json['status'] as String?),
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}
