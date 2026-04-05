class ProductUnitModel {
  final int id;
  final String unitName;
  final double price;
  final int stockQuantity;

  ProductUnitModel({
    required this.id,
    required this.unitName,
    required this.price,
    required this.stockQuantity,
  });

  factory ProductUnitModel.fromJson(Map<String, dynamic> json) {
    return ProductUnitModel(
      id: (json['id'] ?? 0) as int,
      unitName: (json['unitName'] ?? '') as String,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stockQuantity: (json['stockQuantity'] ?? 0) as int,
    );
  }
}

class ProductModel {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final String storeName;
  final String categoryName;
  final String status;
  final List<ProductUnitModel> units;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.storeName,
    required this.categoryName,
    required this.status,
    required this.units,
  });

  double get displayPrice {
    if (units.isEmpty) return 0;
    return units.first.price;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final unitsJson = (json['units'] as List?) ?? const [];

    return ProductModel(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      imageUrl: (json['imageUrl'] ?? '') as String,
      storeName: (json['storeName'] ?? '') as String,
      categoryName: (json['categoryName'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      units: unitsJson
          .whereType<Map<String, dynamic>>()
          .map(ProductUnitModel.fromJson)
          .toList(),
    );
  }
}
