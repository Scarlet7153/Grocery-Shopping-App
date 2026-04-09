// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoreModel _$StoreModelFromJson(Map<String, dynamic> json) => StoreModel(
  id: json['id'] as String?,
  name: json['name'] as String?,
  address: json['address'] as String?,
  status: json['status'] as String?,
  revenueToday: (json['revenueToday'] as num?)?.toDouble(),
  ordersToday: (json['ordersToday'] as num?)?.toInt(),
  phoneNumber: json['phoneNumber'] as String?,
  imageUrl: json['imageUrl'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$StoreModelToJson(StoreModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'status': instance.status,
      'revenueToday': instance.revenueToday,
      'ordersToday': instance.ordersToday,
      'phoneNumber': instance.phoneNumber,
      'imageUrl': instance.imageUrl,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

UpdateStoreProfileRequest _$UpdateStoreProfileRequestFromJson(
  Map<String, dynamic> json,
) => UpdateStoreProfileRequest(
  name: json['name'] as String?,
  address: json['address'] as String?,
  status: json['status'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  imageUrl: json['imageUrl'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$UpdateStoreProfileRequestToJson(
  UpdateStoreProfileRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'address': instance.address,
  'status': instance.status,
  'phoneNumber': instance.phoneNumber,
  'imageUrl': instance.imageUrl,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
