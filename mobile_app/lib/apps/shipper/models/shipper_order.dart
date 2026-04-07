/// Matches backend OrderResponse DTO + OrderItemResponse DTO.
class ShipperOrder {
  final int id;
  final int customerId;
  final String customerName;
  final String customerPhone;
  final int storeId;
  final String storeName;
  final String storeAddress;
  final int? shipperId;
  final String? shipperName;
  final String? shipperPhone;
  final OrderStatus status;
  final double totalAmount;
  final double shippingFee;
  final double grandTotal;
  final String deliveryAddress;
  final String? podImageUrl;
  final String? cancelReason;
  final DateTime createdAt;
  final List<OrderItem> items;
  final List<StoreInfo> stores;
  final double? distanceKm;

  ShipperOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.storeId,
    required this.storeName,
    required this.storeAddress,
    this.shipperId,
    this.shipperName,
    this.shipperPhone,
    required this.status,
    required this.totalAmount,
    required this.shippingFee,
    required this.grandTotal,
    required this.deliveryAddress,
    this.podImageUrl,
    this.cancelReason,
    required this.createdAt,
    this.items = const [],
    this.stores = const [],
    this.distanceKm,
  });

  factory ShipperOrder.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    return ShipperOrder(
      id: _toInt(data['id']),
      customerId: _toInt(data['customerId']),
      customerName: _str(data['customerName']),
      customerPhone: _str(data['customerPhone']),
      storeId: _toInt(data['storeId']),
      storeName: _str(data['storeName']),
      storeAddress: _str(data['storeAddress']),
      shipperId: data['shipperId'] != null ? _toInt(data['shipperId']) : null,
      shipperName: data['shipperName'],
      shipperPhone: data['shipperPhone'],
      status: _parseStatus(data['status']),
      totalAmount: _toDouble(data['totalAmount']),
      shippingFee: _toDouble(data['shippingFee']),
      grandTotal: _toDouble(data['grandTotal']),
      deliveryAddress: _str(data['deliveryAddress']),
      podImageUrl: data['podImageUrl'],
      cancelReason: data['cancelReason'],
      createdAt: _parseDate(data['createdAt']),
      items: _parseItems(data['items']),
      stores: _parseStores(data['stores']),
      distanceKm:
          data['distanceKm'] != null ? _toDouble(data['distanceKm']) : null,
    );
  }

  static int _toInt(dynamic v) =>
      v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
  static double _toDouble(dynamic v) => v == null
      ? 0.0
      : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
  static String _str(dynamic v) => v?.toString() ?? '';
  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }

  static OrderStatus _parseStatus(dynamic v) {
    if (v == null) return OrderStatus.UNKNOWN;
    final s = v.toString().toUpperCase();
    switch (s) {
      case 'PENDING':
        return OrderStatus.PENDING;
      case 'CONFIRMED':
        return OrderStatus.CONFIRMED;
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

  static List<OrderItem> _parseItems(dynamic v) {
    if (v == null || v is! List) return [];
    return v.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static List<StoreInfo> _parseStores(dynamic v) {
    if (v == null || v is! List) return [];
    return v.map((e) => StoreInfo.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class StoreInfo {
  final int id;
  final String name;
  final String address;

  StoreInfo({
    required this.id,
    required this.name,
    required this.address,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImageUrl;
  final String unitName;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.unitName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: _toInt(json['id']),
      productId: _toInt(json['productId']),
      productName: _str(json['productName']),
      productImageUrl: json['productImageUrl'],
      unitName: _str(json['unitName']),
      unitPrice: _toDouble(json['unitPrice']),
      quantity: _toInt(json['quantity']),
      subtotal: _toDouble(json['subtotal']),
    );
  }

  static int _toInt(dynamic v) =>
      v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
  static double _toDouble(dynamic v) => v == null
      ? 0.0
      : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
  static String _str(dynamic v) => v?.toString() ?? '';
}

enum OrderStatus {
  PENDING,
  CONFIRMED,
  PICKING_UP,
  DELIVERING,
  DELIVERED,
  CANCELLED,
  UNKNOWN,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.PENDING:
        return 'Chờ xác nhận';
      case OrderStatus.CONFIRMED:
        return 'Đã xác nhận';
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
