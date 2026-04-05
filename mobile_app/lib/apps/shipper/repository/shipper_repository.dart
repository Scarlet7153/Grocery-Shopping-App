import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grocery_shopping_app/core/constants/app_constants.dart';
import 'package:grocery_shopping_app/core/network/network_config.dart';
import 'package:grocery_shopping_app/apps/shipper/models/shipper_order.dart';

/// Real repository which calls the API defined in the provided Postman collection.
///
/// It uses [dio] for HTTP requests and stores tokens in [SharedPreferences].
class ShipperRepository {
  final Dio _dio;

  ShipperRepository({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = NetworkConfig.createDio();

    // add auth interceptor to attach token from storage
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.accessTokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    }));

    return dio;
  }

  /// Send login request. Returns true if success and token was saved.
  Future<bool> login({required String phone, required String password}) async {
    final response = await _dio.post(AppConstants.loginEndpoint, data: {
      'phoneNumber': phone,
      'password': password,
    });

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
    }
    return false;
  }

  /// Register a new shipper/user with given [info] map. Returns true if server
  /// responded with success flag.
  Future<bool> register(Map<String, dynamic> info) async {
    final response = await _dio.post(AppConstants.registerEndpoint, data: info);
    if (response.statusCode == 201) {
      final data = response.data as Map<String, dynamic>;
      return data['success'] == true;
    }
    return false;
  }

  /// Fetch dashboard data for the shipper role.
  ///
  /// Returns a map containing both available orders and my deliveries.
  Future<Map<String, dynamic>> fetchDashboardData() async {
    final result = <String, dynamic>{};

    final availableOrders = await getAvailableOrders();
    final deliveries = await getMyDeliveries();

    // Basic stats
    final deliveredCount = deliveries.where((o) => o.status == OrderStatus.DELIVERED).length;
    final totalOrders = deliveries.length;
    final acceptanceRate = totalOrders == 0 ? 0.0 : (deliveredCount / totalOrders) * 100;
    final earnings = deliveries
        .where((o) => o.status == OrderStatus.DELIVERED)
        .fold<double>(0.0, (prev, e) => prev + e.grandTotal);

    result['availableOrders'] = availableOrders;
    result['deliveries'] = deliveries;
    result['isOnline'] = true;
    result['earnings'] = earnings;
    result['completedCount'] = deliveredCount;
    result['acceptanceRate'] = acceptanceRate;

    return result;
  }

  /// Fetch orders that are available for the shipper to accept.
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

  /// Fetch the list of deliveries assigned to the current shipper.
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

  String _formatEndpoint(String template, int id) {
    return template.replaceAll(':id', id.toString());
  }

  /// Assigns the current shipper to the order.
  Future<ShipperOrder?> assignOrder(int orderId) async {
    final uri = _formatEndpoint(AppConstants.assignShipperEndpoint, orderId);
    final response = await _dio.post(uri);
    if (response.statusCode == 200) {
      final data = response.data;
      final payload = (data is Map && data['data'] != null) ? data['data'] : data;
      return ShipperOrder.fromJson(payload as Map<String, dynamic>);
    }
    return null;
  }

  /// Updates order status (DELIVERED, DELIVERING, etc.).
  Future<ShipperOrder?> updateOrderStatus(int orderId, String newStatus,
      {String? podImageUrl}) async {
    final body = {'newStatus': newStatus};
    if (podImageUrl != null) {
      body['podImageUrl'] = podImageUrl;
    }
    final uri = _formatEndpoint(AppConstants.orderStatusEndpoint, orderId);
    final response = await _dio.patch(uri, data: body);
    if (response.statusCode == 200) {
      final data = response.data;
      final payload = (data is Map && data['data'] != null) ? data['data'] : data;
      return ShipperOrder.fromJson(payload as Map<String, dynamic>);
    }
    return null;
  }

  /// Clear saved token (logout)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    // optionally notify server
    try {
      await _dio.post(AppConstants.logoutEndpoint);
    } catch (_) {}
  }
}
