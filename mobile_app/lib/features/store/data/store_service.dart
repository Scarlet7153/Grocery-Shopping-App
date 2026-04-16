import '../../../core/api/api_client.dart';
import '../../../core/api/api_routes.dart';
import 'store_model.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

class StoreService {
  StoreService() : _client = ApiClient();
  final ApiClient _client;

  /// GET /stores/my-store — lấy thông tin cửa hàng của user hiện tại.
  Future<StoreModel?> getStoreInfo() async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>(ApiRoutes.storeInfo);
      final raw = response.data;
      if (raw == null) return null;
      final data = raw['data'] ?? raw;
      if (data is! Map) return null;
      return StoreModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      return null;
    }
  }

  /// PUT /stores/{storeId} — cập nhật thông tin cửa hàng.
  Future<StoreModel?> updateStoreProfile(
      int storeId, UpdateStoreProfileRequest request) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '${ApiRoutes.stores}/$storeId',
        data: request.toJson(),
      );
      final raw = response.data;
      if (raw == null) return null;
      final data = raw['data'] ?? raw;
      if (data is! Map) return null;
      return StoreModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      return null;
    }
  }

  /// PATCH /stores/{storeId}/toggle-status — mở/đóng cửa hàng.
  Future<bool> toggleStoreStatus(int storeId) async {
    try {
      await _client.patch('${ApiRoutes.stores}/$storeId/toggle-status');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// GET /stores — danh sách tất cả cửa hàng (public).
  Future<List<StoreModel>> getAllStores() async {
    try {
      final response = await _client.get<dynamic>(ApiRoutes.stores);
      final raw = response.data;
      if (raw == null) return [];
      final dynamic data =
          raw is Map<String, dynamic> ? (raw['data'] ?? raw) : raw;
      if (data is List) {
        return data
            .map((e) => StoreModel.fromJson(e is Map<String, dynamic>
                ? e
                : Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// POST /upload/store/{storeId} — upload ảnh cửa hàng và trả về URL ảnh.
  Future<String?> uploadStoreImage(
    int storeId,
    Uint8List bytes, {
    String filename = 'store.jpg',
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await _client.post<Map<String, dynamic>>(
        ApiRoutes.uploadStoreImage(storeId),
        data: formData,
      );

      final raw = response.data;
      if (raw == null) return null;

      final data = raw['data'];
      if (data is String && data.isNotEmpty) {
        return data;
      }

      if (data is Map<String, dynamic>) {
        final imageUrl = data['imageUrl']?.toString();
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }

      final imageUrl = raw['imageUrl']?.toString();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return imageUrl;
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
