// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
      id: (json['id'] as num?)?.toInt(),
      customerId: (json['customerId'] as num?)?.toInt(),
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      storeId: (json['storeId'] as num?)?.toInt(),
      storeName: json['storeName'] as String?,
      storeAddress: json['storeAddress'] as String?,
      shipperId: (json['shipperId'] as num?)?.toInt(),
      shipperName: json['shipperName'] as String?,
      shipperPhone: json['shipperPhone'] as String?,
      status: json['status'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      shippingFee: (json['shippingFee'] as num?)?.toDouble(),
      grandTotal: (json['grandTotal'] as num?)?.toDouble(),
      address: json['deliveryAddress'] as String?,
      podImageUrl: json['podImageUrl'] as String?,
      cancelReason: json['cancelReason'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customerId': instance.customerId,
      'customerName': instance.customerName,
      'customerPhone': instance.customerPhone,
      'storeId': instance.storeId,
      'storeName': instance.storeName,
      'storeAddress': instance.storeAddress,
      'shipperId': instance.shipperId,
      'shipperName': instance.shipperName,
      'shipperPhone': instance.shipperPhone,
      'status': instance.status,
      'totalAmount': instance.totalAmount,
      'shippingFee': instance.shippingFee,
      'grandTotal': instance.grandTotal,
      'deliveryAddress': instance.address,
      'podImageUrl': instance.podImageUrl,
      'cancelReason': instance.cancelReason,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'items': instance.items,
    };

OrderItemModel _$OrderItemModelFromJson(Map<String, dynamic> json) =>
    OrderItemModel(
      id: (json['id'] as num?)?.toInt(),
      productId: (json['productId'] as num?)?.toInt(),
      productName: json['productName'] as String?,
      productImageUrl: json['productImageUrl'] as String?,
      unitName: json['unitName'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toInt(),
      subtotal: (json['subtotal'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$OrderItemModelToJson(OrderItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'productName': instance.productName,
      'productImageUrl': instance.productImageUrl,
      'unitName': instance.unitName,
      'unitPrice': instance.unitPrice,
      'quantity': instance.quantity,
      'subtotal': instance.subtotal,
    };

UpdateOrderStatusRequest _$UpdateOrderStatusRequestFromJson(
  Map<String, dynamic> json,
) => UpdateOrderStatusRequest(
      newStatus: json['newStatus'] as String,
      cancelReason: json['cancelReason'] as String?,
      podImageUrl: json['podImageUrl'] as String?,
    );

Map<String, dynamic> _$UpdateOrderStatusRequestToJson(
  UpdateOrderStatusRequest instance,
) {
  final val = <String, dynamic>{
    'newStatus': instance.newStatus,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('cancelReason', instance.cancelReason);
  writeNotNull('podImageUrl', instance.podImageUrl);
  return val;
}
