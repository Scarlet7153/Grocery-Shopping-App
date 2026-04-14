import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_routes.dart';
import 'category_model.dart';

/// Categories API: GET /categories.
class CategoryService {
  CategoryService() : _client = ApiClient();
  final ApiClient _client;

  /// GET /categories — danh sách tất cả categories (public).
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _client.get<dynamic>(ApiRoutes.categories);
      final raw = response.data;
      if (raw == null) return [];

      final dynamic data =
          raw is Map<String, dynamic> ? (raw['data'] ?? raw) : raw;
      if (data is List) {
        return data
            .map((e) => CategoryModel.fromJson(e is Map<String, dynamic>
                ? e
                : Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('getCategories failed: $e');
      return [];
    }
  }
}
