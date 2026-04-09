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
  final String? storeName;
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
    this.storeName,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Handle nested units structure from backend if present
    double? price;
    int? stock;
    String? unit;
    
    final units = json['units'];
    if (units is List && units.isNotEmpty) {
      final firstUnit = units.first;
      if (firstUnit is Map<String, dynamic>) {
        price = (firstUnit['price'] as num?)?.toDouble();
        stock = firstUnit['stockQuantity'] as int?;
        unit = firstUnit['unitName'] as String?;
      }
    } else {
      // Fallback to flat structure
      price = (json['price'] as num?)?.toDouble();
      stock = (json['stock'] ?? json['stockQuantity']) as int?;
      unit = json['unit'] as String?;
    }

    return ProductModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      description: json['description'] as String?,
      price: price,
      imageUrl: json['imageUrl'] as String?,
      category: json['categoryName'] ?? json['category'] as String?,
      stock: stock,
      unit: unit,
      storeId: (json['storeId'] ?? json['store_id'])?.toString(),
      storeName: json['storeName'] ?? json['store_name'],
      isActive: json['isActive'] ?? (json['status'] == 'AVAILABLE'),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'category': category,
    'stock': stock,
    'unit': unit,
    'storeId': storeId,
    'storeName': storeName,
    'isActive': isActive,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
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
