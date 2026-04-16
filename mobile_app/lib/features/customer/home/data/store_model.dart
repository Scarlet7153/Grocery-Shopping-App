class StoreModel {
  final int id;
  final String storeName;
  final String address;
  final bool isOpen;
  final double? averageRating;
  final int? totalReviews;

  StoreModel({
    required this.id,
    required this.storeName,
    required this.address,
    required this.isOpen,
    this.averageRating,
    this.totalReviews,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: (json['id'] ?? 0) as int,
      storeName: (json['storeName'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      isOpen: (json['isOpen'] ?? false) as bool,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: (json['totalReviews'] as num?)?.toInt(),
    );
  }
}
