class CategoryModel {
  final int id;
  final String name;
  final String iconUrl;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      iconUrl: (json['iconUrl'] ?? '') as String,
    );
  }
}
