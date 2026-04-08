import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  final String? id;
  final String? name;
  final String? description;
  final double? price;
  final String? imageUrl;
  final String? category;
  final int? stock;
  final String? unit;
  final String? storeId;
  final bool? isActive;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const ProductModel({
    this.id,
    this.name,
    this.description,
    this.price,
    this.imageUrl,
    this.category,
    this.stock,
    this.unit,
    this.storeId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}

@JsonSerializable()
class CreateProductRequest {
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? category;
  final int? stock;
  final String? unit;
  final bool? isActive;

  const CreateProductRequest({
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.category,
    this.stock,
    this.unit,
    this.isActive,
  });

  factory CreateProductRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateProductRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateProductRequestToJson(this);
}

@JsonSerializable()
class UpdateProductRequest {
  final String? name;
  final String? description;
  final double? price;
  final String? imageUrl;
  final String? category;
  final int? stock;
  final String? unit;
  final bool? isActive;

  const UpdateProductRequest({
    this.name,
    this.description,
    this.price,
    this.imageUrl,
    this.category,
    this.stock,
    this.unit,
    this.isActive,
  });

  factory UpdateProductRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProductRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateProductRequestToJson(this);
}
