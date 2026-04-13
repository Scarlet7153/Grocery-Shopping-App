import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grocery_shopping_app/core/constants/app_constants.dart';
import 'package:grocery_shopping_app/core/network/network_config.dart';
import 'package:grocery_shopping_app/core/network/api_endpoints.dart';
import 'package:grocery_shopping_app/apps/shipper/models/shipper_order.dart';
import 'package:grocery_shopping_app/apps/shipper/models/order_filter.dart';

class ShipperRepository {
  final Dio _dio;

  ShipperRepository({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = NetworkConfig.createDio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(AppConstants.accessTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    return dio;
  }

  Future<bool> login({required String phone, required String password}) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: {'phoneNumber': phone, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true && data['data'] != null) {
          final token = data['data']['token'] as String?;
          if (token != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(AppConstants.accessTokenKey, token);
            return true;
          }
        }

        // Lỗi từ backend - xử lý message
        String message = data['message']?.toString() ?? '';

        // Nếu message rỗng hoặc null
        if (message.isEmpty) {
          message = 'Thông tin đăng nhập không chính xác';
        }

        throw Exception(message);
      }
      throw Exception('Lỗi máy chủ, vui lòng thử lại sau');
    } on DioException catch (e) {
      debugPrint('DioException statusCode: ${e.response?.statusCode}');
      debugPrint('DioException responseData: ${e.response?.data}');
      debugPrint('DioException type: ${e.type}');
      debugPrint('DioException message: ${e.message}');
      debugPrint('DioException error: ${e.error}');

      if (e.response?.data != null &&
          e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        final backendMessage = data['message']?.toString();
        final statusCode = e.response!.statusCode;

        debugPrint(
          'Backend message: $backendMessage, statusCode: $statusCode',
        );

        if (statusCode == 401 ||
            (backendMessage != null &&
                (backendMessage.toLowerCase().contains('thông tin đăng nhập') ||
                    backendMessage.toLowerCase().contains('bad credentials') ||
                    backendMessage.toLowerCase().contains('sai')))) {
          throw Exception('Sai số điện thoại hoặc mật khẩu');
        }
        if (statusCode == 404 ||
            (backendMessage != null &&
                backendMessage.toLowerCase().contains('chưa được đăng ký'))) {
          throw Exception('Số điện thoại chưa được đăng ký');
        }
        if (statusCode == 403 ||
            (backendMessage != null &&
                (backendMessage.toLowerCase().contains('khóa') ||
                    backendMessage.toLowerCase().contains('banned')))) {
          throw Exception('Tài khoản đã bị khóa');
        }
        if (backendMessage != null && backendMessage.isNotEmpty) {
          throw Exception(backendMessage);
        }
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Kết nối quá chậm. Vui lòng thử lại.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối Internet.',
        );
      }
      if (e.type == DioExceptionType.unknown) {
        if (e.error != null) {
          final errorMsg = e.error.toString().toLowerCase();
          if (errorMsg.contains('socket') ||
              errorMsg.contains('connection') ||
              errorMsg.contains('network')) {
            throw Exception(
              'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối Internet.',
            );
          }
        }
        throw Exception('Không thể kết nối đến máy chủ. Vui lòng thử lại sau.');
      }

      throw Exception('Đăng nhập thất bại. Vui lòng thử lại.');
    } on ShipperApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      debugPrint('Unexpected error: ${e.toString()}');
      throw Exception('Lỗi không xác định, vui lòng thử lại');
    }
  }

  Future<bool> register({
    required String phoneNumber,
    required String password,
    required String fullName,
    String? address,
  }) async {
    final response = await _dio.post(
      AppConstants.registerEndpoint,
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
        'fullName': fullName,
        'role': 'SHIPPER',
        if (address != null && address.isNotEmpty) 'address': address,
      },
    );
    if (response.statusCode == 201) {
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final token = data['data']['token'] as String?;
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.accessTokenKey, token);
        }
        return true;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>> fetchDashboardData() async {
    final availableOrders = await getAvailableOrders();
    final deliveries = await getMyDeliveries();

    final deliveredCount =
        deliveries.where((o) => o.status == OrderStatus.DELIVERED).length;
    final totalOrders = deliveries.length;
    final acceptanceRate =
        totalOrders == 0 ? 0.0 : (deliveredCount / totalOrders) * 100;
    final earnings = deliveries
        .where((o) => o.status == OrderStatus.DELIVERED)
        .fold<double>(0.0, (prev, e) => prev + e.grandTotal);

    return {
      'availableOrders': availableOrders,
      'deliveries': deliveries,
      'isOnline': true,
      'earnings': earnings,
      'completedCount': deliveredCount,
      'acceptanceRate': acceptanceRate,
    };
  }

  Future<List<ShipperOrder>> getAvailableOrders() async {
    final response = await _dio.get(AppConstants.availableOrdersEndpoint);
    if (response.statusCode == 200) {
      final data = response.data;
      final list = (data is Map && data['data'] != null)
          ? data['data'] as List<dynamic>
          : data as List<dynamic>;
      return list
          .map((e) => ShipperOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<ShipperOrder>> getMyDeliveries() async {
    final response = await _dio.get(AppConstants.myDeliveriesEndpoint);
    if (response.statusCode == 200) {
      final data = response.data;
      final list = (data is Map && data['data'] != null)
          ? data['data'] as List<dynamic>
          : data as List<dynamic>;
      return list
          .map((e) => ShipperOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Lọc đơn hàng theo filter
  ///
  /// Các thông số filter:
  /// - maxDistance: khoảng cách tối đa (km)
  /// - minEarning: thu nhập tối thiểu (VNĐ)
  /// - avoidPickup: chỉ lấy những đơn đã sẵn (không cần pickup)
  /// - maxItems: tối đa sản phẩm trong đơn
  ///
  /// Trả về danh sách đơn hàng đã lọc
  List<ShipperOrder> filterOrders(
    List<ShipperOrder> orders,
    OrderFilter filter,
  ) {
    return orders.where((order) {
      // Lọc theo khoảng cách
      if (filter.maxDistance != null &&
          (order.distanceKm ?? 0) > filter.maxDistance!) {
        return false;
      }

      // Lọc theo thu nhập tối thiểu
      if (filter.minEarning != null && order.grandTotal < filter.minEarning!) {
        return false;
      }

      // Lọc theo tránh pickup (nếu bật)
      if (filter.avoidPickup == true && order.status == OrderStatus.PENDING) {
        // Nếu đơn còn PENDING (chưa confirm), nghĩa là chưa pickup
        return false;
      }

      // Lọc theo số lượng sản phẩm
      if (filter.maxItems != null &&
          order.items.isNotEmpty &&
          order.items.length > filter.maxItems!) {
        return false;
      }

      // Order pass all filters
      return true;
    }).toList();
  }

  Future<ShipperOrder?> getOrderById(int orderId) async {
    final uri = AppConstants.orderByIdEndpoint.replaceAll(
      '{id}',
      orderId.toString(),
    );
    final response = await _dio.get(uri);
    if (response.statusCode == 200) {
      final data = response.data;
      final payload =
          (data is Map && data['data'] != null) ? data['data'] : data;
      return ShipperOrder.fromJson(payload as Map<String, dynamic>);
    }
    return null;
  }

  Future<ShipperOrder?> assignOrder(int orderId) async {
    final uri = AppConstants.assignShipperEndpoint.replaceAll(
      '{id}',
      orderId.toString(),
    );
    final response = await _dio.post(uri);
    if (response.statusCode == 200) {
      final data = response.data;
      final payload =
          (data is Map && data['data'] != null) ? data['data'] : data;
      return ShipperOrder.fromJson(payload as Map<String, dynamic>);
    }
    return null;
  }

  Future<ShipperOrder?> updateOrderStatus(
    int orderId,
    String newStatus, {
    String? podImageUrl,
    String? cancelReason,
  }) async {
    final uri = AppConstants.orderStatusEndpoint.replaceAll(
      '{id}',
      orderId.toString(),
    );
    final body = <String, dynamic>{'newStatus': newStatus};
    if (podImageUrl != null) {
      body['podImageUrl'] = podImageUrl;
    }
    if (cancelReason != null) {
      body['cancelReason'] = cancelReason;
    }
    final response = await _dio.patch(uri, data: body);
    if (response.statusCode == 200) {
      final data = response.data;
      final payload =
          (data is Map && data['data'] != null) ? data['data'] : data;
      return ShipperOrder.fromJson(payload as Map<String, dynamic>);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final response = await _dio.get(AppConstants.getCurrentUserEndpoint);
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      }
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    try {
      await _dio.post(AppConstants.logoutEndpoint);
    } catch (_) {}
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (oldPassword == newPassword) {
      throw ShipperApiException('Mật khẩu mới không được trùng mật khẩu cũ');
    }

    try {
      final response = await _dio.post(
        '/users/change-password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );

      if (response.statusCode == 200) {
        final payload = response.data;
        if (payload is Map<String, dynamic> && payload['success'] == false) {
          throw ShipperApiException(
            payload['message']?.toString() ?? 'Đổi mật khẩu thất bại',
          );
        }
        return true;
      }

      throw ShipperApiException('Đổi mật khẩu thất bại');
    } on DioException catch (e) {
      String? message;
      final responseData = e.response?.data;

      if (responseData is Map<String, dynamic>) {
        final rawMessage = responseData['message']?.toString().trim();
        if (rawMessage != null &&
            rawMessage.isNotEmpty &&
            rawMessage.toLowerCase() != 'dữ liệu không hợp lệ') {
          message = rawMessage;
        }

        final fieldErrors = responseData['data'];
        if ((message == null || message.isEmpty) && fieldErrors is Map) {
          for (final key in ['oldPassword', 'newPassword', 'confirmPassword']) {
            final fieldMessage = fieldErrors[key]?.toString().trim();
            if (fieldMessage != null && fieldMessage.isNotEmpty) {
              message = fieldMessage;
              break;
            }
          }

          if ((message == null || message.isEmpty) && fieldErrors.isNotEmpty) {
            message = fieldErrors.values.first?.toString().trim();
          }
        }
      }

      if (message == null || message.isEmpty) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          message = 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại';
        } else if (statusCode == 400) {
          message = 'Thông tin đổi mật khẩu không hợp lệ';
        } else {
          message = 'Đổi mật khẩu thất bại';
        }
      }

      throw ShipperApiException(message);
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    String? address,
  }) async {
    final response = await _dio.put(
      '/users/profile',
      data: {'fullName': fullName, if (address != null) 'address': address},
    );
    return response.statusCode == 200;
  }

  /// Upload avatar user
  ///
  /// Uploads image file (direct Cloudinary ưu tiên, fallback backend)
  /// Returns imageUrl if successful
  Future<String?> uploadAvatar(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return await uploadAvatarBytes(bytes, imageFile.name);
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _requestAvatarUploadSignature() async {
    final response = await _dio.post(ApiEndpoints.uploadAvatarSignature);
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final payload = response.data as Map<String, dynamic>;
      if (payload['success'] == true && payload['data'] is Map<String, dynamic>) {
        return payload['data'] as Map<String, dynamic>;
      }
    }
    return null;
  }

  Future<bool> _saveAvatarUrlToProfile(String imageUrl) async {
    final response = await _dio.put(
      ApiEndpoints.saveAvatarUrl,
      data: {'imageUrl': imageUrl},
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final payload = response.data as Map<String, dynamic>;
      return payload['success'] == true;
    }

    return false;
  }

  Future<String?> _uploadAvatarToCloudinaryDirect(
    Uint8List bytes,
    String filename,
  ) async {
    final signature = await _requestAvatarUploadSignature();
    if (signature == null) return null;

    final uploadUrl = signature['uploadUrl']?.toString();
    final apiKey = signature['apiKey']?.toString();
    final timestamp = signature['timestamp']?.toString();
    final folder = signature['folder']?.toString();
    final publicId = signature['publicId']?.toString();
    final cloudinarySignature = signature['signature']?.toString();

    if (uploadUrl == null ||
        apiKey == null ||
        timestamp == null ||
        folder == null ||
        publicId == null ||
        cloudinarySignature == null) {
      return null;
    }

    final cloudinaryDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 40),
        receiveTimeout: const Duration(seconds: 40),
      ),
    );

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'api_key': apiKey,
      'timestamp': timestamp,
      'folder': folder,
      'public_id': publicId,
      'signature': cloudinarySignature,
    });

    final response = await cloudinaryDio.post(uploadUrl, data: formData);
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final payload = response.data as Map<String, dynamic>;
      final secureUrl = payload['secure_url']?.toString();
      if (secureUrl != null && secureUrl.isNotEmpty) {
        final saved = await _saveAvatarUrlToProfile(secureUrl);
        if (saved) {
          return secureUrl;
        }
      }
    }

    return null;
  }

  Future<String?> _uploadAvatarViaBackend(
    Uint8List bytes,
    String filename,
  ) async {
    final multipartFile = MultipartFile.fromBytes(
      bytes,
      filename: filename,
    );

    final formData = FormData.fromMap({
      'file': multipartFile,
    });

    final response = await _dio.post(
      ApiEndpoints.uploadAvatar,
      data: formData,
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return data['data'] as String;
      }
    }

    return null;
  }

  /// Upload avatar bytes (đã crop)
  ///
  /// Uploads image bytes: direct Cloudinary trước, fallback backend
  /// Returns imageUrl if successful
  Future<String?> uploadAvatarBytes(Uint8List bytes, String filename) async {
    try {
      try {
        final directUrl = await _uploadAvatarToCloudinaryDirect(bytes, filename);
        if (directUrl != null) {
          return directUrl;
        }
      } catch (e) {
        debugPrint('Direct Cloudinary upload failed, fallback to backend: $e');
      }

      return await _uploadAvatarViaBackend(bytes, filename);
    } catch (e) {
      debugPrint('Error uploading avatar bytes: $e');
      rethrow;
    }
  }

  /// Upload POD (Proof of Delivery) image
  ///
  /// Uploads image file for delivery confirmation (POST /api/upload/pod/{orderId})
  /// Returns imageUrl if successful
  Future<String?> uploadPOD(XFile imageFile, int orderId) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: imageFile.name,
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      final uri =
          ApiEndpoints.uploadPOD.replaceAll('{orderId}', orderId.toString());

      final response = await _dio.post(
        uri,
        data: formData,
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as String;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error uploading POD: $e');
      rethrow;
    }
  }
}

class ShipperApiException implements Exception {
  final String message;
  ShipperApiException(this.message);

  @override
  String toString() => message;
}
