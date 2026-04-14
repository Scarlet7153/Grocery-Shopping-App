import 'package:json_annotation/json_annotation.dart';
import 'unit_model.dart';

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

  /// Backend: AVAILABLE | OUT_OF_STOCK | HIDDEN (ProductResponse.status)
  final String? status;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  /// Danh sách các đơn vị bán của sản phẩm (nếu có)
  final List<ProductUnitMapping>? units;

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
    this.status,
    this.createdAt,
    this.updatedAt,
    this.units,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Lấy giá trị cơ bản trước (fallback)
    double? price = (json['price'] as num?)?.toDouble();
    int? stock = (json['stock'] ?? json['stockQuantity']) as int?;
    String? unit = json['unit'] as String?;

    // Parse units list nếu có
    List<ProductUnitMapping>? unitsList;
    final unitsJson =
        json['units'] ?? json['productUnits'] ?? json['productUnitMappings'];

    if (unitsJson is List && unitsJson.isNotEmpty) {
      try {
        unitsList = unitsJson
            .map((u) => ProductUnitMapping.fromJson(u as Map<String, dynamic>))
            .where((u) => u.isActive)
            .toList();

        // Nếu có units, lấy giá/tồn từ đơn vị mặc định hoặc đơn vị đầu tiên.
        if (unitsList.isNotEmpty) {
          final defaultUnit = unitsList.firstWhere(
            (u) => u.isDefault,
            orElse: () => unitsList!.first,
          );
          price = defaultUnit.price;
          stock = defaultUnit.stockQuantity;
          unit = defaultUnit.displayName;
        }
      } catch (e) {
        // Nếu parse lỗi, dùng giá trị từ JSON gốc.
      }
    }

    final statusStr = json['status'] as String?;
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
      isActive: json['isActive'] ?? (statusStr != 'HIDDEN'),
      status: statusStr,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      units: unitsList,
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
        'status': status,
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
  final int? categoryId;
  final int? stock;
  final String? unit;
  final bool? isActive;
  final List<CreateProductUnitRequest>? units;

  const CreateProductRequest({
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.category,
    this.categoryId,
    this.stock,
    this.unit,
    this.isActive,
    this.units,
  });

  factory CreateProductRequest.fromJson(Map<String, dynamic> json) =>
      CreateProductRequest(
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num).toDouble(),
        imageUrl: json['imageUrl'] as String?,
        category: json['category'] as String?,
        categoryId: (json['categoryId'] as num?)?.toInt(),
        stock: (json['stock'] as num?)?.toInt(),
        unit: json['unit'] as String?,
        isActive: json['isActive'] as bool?,
      );

  Map<String, dynamic> toJson() {
    final mappedUnits =
        (units != null && units!.isNotEmpty)
            ? units!
            : <CreateProductUnitRequest>[
                CreateProductUnitRequest(
                  unitCode: unit ?? 'kg',
                  unitName: unit ?? 'kg',
                  price: price,
                  stockQuantity: stock ?? 0,
                ),
              ];

    return {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'units': mappedUnits.map((u) => u.toJson()).toList(),
    };
  }
}

class CreateProductUnitRequest {
  final String unitCode;
  final String unitName;
  final double? baseQuantity;
  final String? baseUnit;
  final double price;
  final int stockQuantity;

  const CreateProductUnitRequest({
    required this.unitCode,
    required this.unitName,
    this.baseQuantity,
    this.baseUnit,
    required this.price,
    required this.stockQuantity,
  });

  Map<String, dynamic> toJson() => {
        'unitCode': unitCode,
        'unitName': unitName,
        'baseQuantity': baseQuantity,
        'baseUnit': baseUnit,
        'price': price,
        'stockQuantity': stockQuantity,
      };
}

@JsonSerializable()
class UpdateProductRequest {
  final String? name;
  final String? description;
  final double? price;
  final String? imageUrl;
  final String? category;
  final int? categoryId;
  final int? stock;
  final String? unit;
  final bool? isActive;
  final List<UpdateProductUnitRequest>? units;

  const UpdateProductRequest({
    this.name,
    this.description,
    this.price,
    this.imageUrl,
    this.category,
    this.categoryId,
    this.stock,
    this.unit,
    this.isActive,
    this.units,
  });

  factory UpdateProductRequest.fromJson(Map<String, dynamic> json) =>
      UpdateProductRequest(
        name: json['name'] as String?,
        description: json['description'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        imageUrl: json['imageUrl'] as String?,
        category: json['category'] as String?,
        categoryId: (json['categoryId'] as num?)?.toInt(),
        stock: (json['stock'] as num?)?.toInt(),
        unit: json['unit'] as String?,
        isActive: json['isActive'] as bool?,
        units: (json['units'] as List<dynamic>?)
            ?.map((e) =>
                UpdateProductUnitRequest.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
    };

    if (units != null && units!.isNotEmpty) {
      data['units'] = units!.map((u) => u.toJson()).toList();
    }

    return data;
  }
}

class UpdateProductUnitRequest {
  final int? id;
  final String unitCode;
  final String unitName;
  final double? baseQuantity;
  final String? baseUnit;
  final double price;
  final int stockQuantity;
  final bool isDefault;
  final bool isActive;

  const UpdateProductUnitRequest({
    this.id,
    required this.unitCode,
    required this.unitName,
    this.baseQuantity,
    this.baseUnit,
    required this.price,
    required this.stockQuantity,
    this.isDefault = false,
    this.isActive = true,
  });

  factory UpdateProductUnitRequest.fromJson(Map<String, dynamic> json) =>
      UpdateProductUnitRequest(
        id: (json['id'] as num?)?.toInt(),
        unitCode: (json['unitCode'] ?? json['unit_code'] ?? '').toString(),
        unitName: (json['unitName'] ?? json['unit_label'] ?? '') as String,
        baseQuantity:
          (json['baseQuantity'] ?? json['base_quantity'] as num?)?.toDouble(),
        baseUnit: (json['baseUnit'] ?? json['base_unit']) as String?,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        stockQuantity: ((json['stockQuantity'] ?? json['stock_quantity']) as num?)
                ?.toInt() ??
            0,
        isDefault: (json['isDefault'] ?? json['is_default']) as bool? ?? false,
        isActive: (json['isActive'] ?? json['is_active']) as bool? ?? true,
      );

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'unitCode': unitCode,
      'unitName': unitName,
      'baseQuantity': baseQuantity,
      'baseUnit': baseUnit,
      'price': price,
      'stockQuantity': stockQuantity,
      'isDefault': isDefault,
      'isActive': isActive,
    };
    if (id != null && id! > 0) {
      json['id'] = id;
    }
    return json;
  }
}
