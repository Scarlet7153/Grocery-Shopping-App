import 'package:json_annotation/json_annotation.dart';

part 'order_model.g.dart';

@JsonSerializable()
class OrderModel {
  final String? id;
  final String? status;
  final double? totalAmount;
  final String? customerName;
  final String? customerPhone;
  final String? address;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final List<OrderItemModel>? items;

  const OrderModel({
    this.id,
    this.status,
    this.totalAmount,
    this.customerName,
    this.customerPhone,
    this.address,
    this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}

@JsonSerializable()
class OrderItemModel {
  final String? productId;
  final String? productName;
  final int? quantity;
  final double? price;

  const OrderItemModel({
    this.productId,
    this.productName,
    this.quantity,
    this.price,
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
