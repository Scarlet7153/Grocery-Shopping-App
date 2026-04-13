import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import 'api_error.dart';

/// Centralized service for uploading images to the backend/Cloudinary.
class UploadService {
  UploadService() : _client = ApiClient();

  final ApiClient _client;

  /// Generic upload method for Multipart images.
  /// [endpoint] is the target API path.
  /// [file] is the XFile picked from image_picker.
  Future<String> uploadImage(String endpoint, XFile file) async {
    try {
      // Read file bytes for cross-platform compatibility (Web, Mobile, Desktop)
      final bytes = await file.readAsBytes();
      
      // Create Multipart data
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name,
        ),
      });

      // Execute POST request
      final response = await _client.post<Map<String, dynamic>>(
        endpoint,
        data: formData,
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Phản hồi từ server trống');
      }

      // Backend returns ApiResponse<String> where 'data' is the imageUrl
      final imageUrl = data['data'];
      if (imageUrl == null || imageUrl is! String) {
        throw const ApiException(message: 'Không lấy được URL ảnh từ phản hồi');
      }

      return imageUrl;
    } on DioException catch (e) {
      final message = e.response?.data is Map 
          ? (e.response?.data['message'] ?? e.message) 
          : e.message;
      throw ApiException(message: message ?? 'Lỗi upload ảnh');
    } catch (e) {
      throw ApiException(message: 'Lỗi không xác định khi upload: $e');
    }
  }
}
