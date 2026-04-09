import 'package:json_annotation/json_annotation.dart';

part 'order_model.g.dart';

@JsonSerializable()
class OrderModel {
  final int? id;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final int? storeId;
  final String? storeName;
  final String? storeAddress;
  final int? shipperId;
  final String? shipperName;
  final String? shipperPhone;
  final String? status;
  final double? totalAmount;
  final double? shippingFee;
  final double? grandTotal;
  @JsonKey(name: 'deliveryAddress')
  final String? address;
  final String? podImageUrl;
  final String? cancelReason;
  final String? createdAt;
  final String? updatedAt;
  final List<OrderItemModel>? items;

  const OrderModel({
    this.id,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.storeId,
    this.storeName,
    this.storeAddress,
    this.shipperId,
    this.shipperName,
    this.shipperPhone,
    this.status,
    this.totalAmount,
    this.shippingFee,
    this.grandTotal,
    this.address,
    this.podImageUrl,
    this.cancelReason,
    this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Manually handle address variations for robustness
    final String? addr = json['deliveryAddress'] ?? json['address'] ?? json['delivery_address'];
    
    return _$OrderModelFromJson(json).copyWith(address: addr);
  }
  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
  
  OrderModel copyWith({
    int? id,
    int? customerId,
    String? customerName,
    String? customerPhone,
    int? storeId,
    String? storeName,
    String? storeAddress,
    int? shipperId,
    String? shipperName,
    String? shipperPhone,
    String? status,
    double? totalAmount,
    double? shippingFee,
    double? grandTotal,
    String? address,
    String? podImageUrl,
    String? cancelReason,
    String? createdAt,
    String? updatedAt,
    List<OrderItemModel>? items,
  }) => OrderModel(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    storeId: storeId ?? this.storeId,
    storeName: storeName ?? this.storeName,
    storeAddress: storeAddress ?? this.storeAddress,
    shipperId: shipperId ?? this.shipperId,
    shipperName: shipperName ?? this.shipperName,
    shipperPhone: shipperPhone ?? this.shipperPhone,
    status: status ?? this.status,
    totalAmount: totalAmount ?? this.totalAmount,
    shippingFee: shippingFee ?? this.shippingFee,
    grandTotal: grandTotal ?? this.grandTotal,
    address: address ?? this.address,
    podImageUrl: podImageUrl ?? this.podImageUrl,
    cancelReason: cancelReason ?? this.cancelReason,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    items: items ?? this.items,
  );
}

@JsonSerializable()
class OrderItemModel {
  final int? id;
  final int? productId;
  final String? productName;
  final String? productImageUrl;
  final String? unitName;
  final double? unitPrice;
  final int? quantity;
  final double? subtotal;

  const OrderItemModel({
    this.id,
    this.productId,
    this.productName,
    this.productImageUrl,
    this.unitName,
    this.unitPrice,
    this.quantity,
    this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);
}

@JsonSerializable()
class UpdateOrderStatusRequest {
  final String status;

  const UpdateOrderStatusRequest({required this.status});

  factory UpdateOrderStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateOrderStatusRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateOrderStatusRequestToJson(this);
}
