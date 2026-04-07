import 'package:json_annotation/json_annotation.dart';

part 'store_model.g.dart';

@JsonSerializable()
class StoreModel {
  final String? id;
  final String? name;
  final String? address;
  final String? status;
  final double? revenueToday;
  final int? ordersToday;
  final String? phoneNumber;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  const StoreModel({
    this.id,
    this.name,
    this.address,
    this.status,
    this.revenueToday,
    this.ordersToday,
    this.phoneNumber,
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) =>
      _$StoreModelFromJson(json);
  Map<String, dynamic> toJson() => _$StoreModelToJson(this);
}

@JsonSerializable()
class UpdateStoreProfileRequest {
  final String? name;
  final String? address;
  final String? status;
  final String? phoneNumber;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  const UpdateStoreProfileRequest({
    this.name,
    this.address,
    this.status,
    this.phoneNumber,
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  factory UpdateStoreProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateStoreProfileRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateStoreProfileRequestToJson(this);
}
