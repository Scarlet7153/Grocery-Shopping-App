import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_routes.dart';
import 'store_model.dart';

/// Store API: get store info, update store profile.
class StoreService {
  StoreService() : _client = ApiClient();

  final ApiClient _client;

  /// Get current store information (requires auth).
  Future<StoreModel?> getStoreInfo() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiRoutes.storeInfo,
      );
      final raw = response.data;
      if (raw == null) return null;
      final data = (raw['data'] ?? raw);
      return StoreModel.fromJson(
        data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map),
      );
    } on DioException catch (e) {
      debugPrint('getStoreInfo failed: $e');
      return null;
    } catch (e) {
      debugPrint('getStoreInfo unexpected error: $e');
      return null;
    }
  }

  /// Update store profile (requires auth).
  Future<StoreModel?> updateStoreProfile(
    UpdateStoreProfileRequest request,
  ) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        ApiRoutes.updateStoreProfile,
        data: request.toJson(),
      );
      final raw = response.data;
      if (raw == null) return null;
      final data = (raw['data'] ?? raw);
      return StoreModel.fromJson(
        data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map),
      );
    } on DioException catch (e) {
      debugPrint('updateStoreProfile failed: $e');
      return null;
    } catch (e) {
      debugPrint('updateStoreProfile unexpected error: $e');
      return null;
    }
  }

  /// Get all stores (Admin/Public).
  Future<List<StoreModel>> getAllStores() async {
    try {
      final response = await _client.get<dynamic>('/stores');
      final raw = response.data;
      if (raw == null) return [];
      final dynamic data = raw is Map<String, dynamic> ? (raw['data'] ?? raw) : raw;
      if (data is List) {
        return data.map((e) => StoreModel.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map))).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('getAllStores failed: $e');
      return [];
    }
  }
}
