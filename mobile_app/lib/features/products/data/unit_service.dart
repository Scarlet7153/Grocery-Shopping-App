import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../data/unit_model.dart';

class UnitService {
  final Dio _dio;

  UnitService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  /// Lấy tất cả phân loại đơn vị (weight, count, bundle, volume)
  Future<List<UnitCategory>> getUnitCategories() async {
    try {
      final response = await _dio.get('/units/categories');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return data.map((json) => UnitCategory.fromJson(json)).toList();
        }
      }
      return [];
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Lấy tất cả đơn vị
  Future<List<Unit>> getAllUnits() async {
    try {
      final response = await _dio.get('/units');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return data.map((json) => Unit.fromJson(json)).toList();
        }
      }
      return [];
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Lấy đơn vị theo phân loại
  Future<List<Unit>> getUnitsByCategory(int categoryId) async {
    try {
      final response = await _dio.get('/units/categories/$categoryId/units');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return data.map((json) => Unit.fromJson(json)).toList();
        }
      }
      return [];
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Lấy đơn vị theo code (kg, bo, qua...)
  Future<Unit?> getUnitByCode(String code) async {
    try {
      final response = await _dio.get('/units/$code');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return Unit.fromJson(data);
      }
      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get units organized by category for UI
  Future<Map<UnitCategory, List<Unit>>> getUnitsOrganizedByCategory() async {
    final categories = await getUnitCategories();
    final units = await getAllUnits();

    final Map<UnitCategory, List<Unit>> organized = {};

    for (final category in categories) {
      organized[category] =
          units.where((u) => u.categoryId == category.id).toList();
    }

    return organized;
  }
}
