/// Category data model — maps to backend `CategoryResponse`.
class CategoryModel {
  final int? id;
  final String? name;
  final String? iconUrl;

  const CategoryModel({this.id, this.name, this.iconUrl});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: (json['id'] as num?)?.toInt(),
        name: json['name'] as String?,
        iconUrl: json['iconUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconUrl': iconUrl,
      };
}
