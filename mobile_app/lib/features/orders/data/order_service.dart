import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_error.dart';
import '../../../core/api/api_routes.dart';
import 'order_model.dart';

/// Orders API: get store orders, update order status.
class OrderService {
  OrderService() : _client = ApiClient();

  final ApiClient _client;

  /// Get store orders. Optional: page, limit, status.
  Future<List<OrderModel>> getStoreOrders({
    int? page,
    int? limit,
    String? status,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (page != null) query['page'] = page;
      if (limit != null) query['limit'] = limit;
      if (status != null && status.isNotEmpty) query['status'] = status;

      final response = await _client.get<dynamic>(
        ApiRoutes.storeOrders,
        queryParameters: query.isNotEmpty ? query : null,
      );
      final data = response.data;
      if (data == null) return [];

      if (data is List) {
        return data
            .map((e) => OrderModel.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      if (data is Map<String, dynamic>) {
        final list = data['data'] ?? data['orders'];
        if (list is List) {
          return list
              .map((e) => OrderModel.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('getStoreOrders failed: $e');
      return [];
    } catch (e) {
      debugPrint('getStoreOrders unexpected error: $e');
      return [];
    }
  }

  /// Update order status by id (requires auth).
  Future<OrderModel> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        ApiRoutes.updateOrderStatus(orderId),
        data: UpdateOrderStatusRequest(status: status).toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Phản hồi trống');
      }
      final order = data['data'] ?? data;
      return OrderModel.fromJson(
        order is Map<String, dynamic> ? order : Map<String, dynamic>.from(order as Map),
      );
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(message: e.message ?? 'Lỗi cập nhật trạng thái đơn hàng');
    }
  }
}
