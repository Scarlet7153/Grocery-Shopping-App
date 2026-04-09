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

  // Local persistence simulation for Admin Dashboard (Clearing as per user request)
  static final List<OrderModel> _mockOrders = [];

  /// Get store orders. Optional: page, limit, status.
  Future<List<OrderModel>> getStoreOrders({
    int? page,
    int? limit,
    String? status,
  }) async {
    try {
      final response = await _client.get<dynamic>(
        ApiRoutes.myStoreOrders,
        queryParameters: {
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
          if (status != null) 'status': status,
        },
      );
      final data = response.data;
      if (data != null && data['data'] != null) {
        return (data['data'] as List)
            .map((item) => OrderModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('getStoreOrders error: $e');
      // Fallback for development if needed, or rethrow
      return _mockOrders; 
    }
  }

  // ========== ADMIN DISCOVERY METHODS (NO BACKEND CHANGES) ==========

  // Cache để tránh quét lại nhiều lần trong cùng một phiên làm việc
  static List<OrderModel>? _cachedDiscoveredOrders;

  /// Lấy thông tin một đơn hàng (không gây lỗi UI nếu không tìm thấy)
  Future<OrderModel?> _fetchSingleOrderSilently(int id) async {
    try {
      final response = await _client.get<dynamic>('/orders/$id');
      final data = response.data;
      if (data != null && data['data'] != null) {
        return OrderModel.fromJson(Map<String, dynamic>.from(data['data']));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cơ chế Khám phá Đơn hàng dựa trên danh sách User (Theo gợi ý: Check Users -> Load Orders)
  /// Không quét mù quáng dải ID rộng, tập trung vào các ID có khả năng tồn tại cao.
  /// Lấy đơn hàng của một User bất kỳ (API mới dành riêng cho Admin)
  Future<List<OrderModel>> getOrdersByUserIdForAdmin(dynamic userId) async {
    try {
      final response = await _client.get<dynamic>('/orders/user/$userId');
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        final List list = data['data'];
        return list.map((json) => OrderModel.fromJson(Map<String, dynamic>.from(json))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting orders for user $userId: $e');
      return [];
    }
  }

  /// Cơ chế Khám phá Đơn hàng dựa trên danh sách User (Theo yêu cầu: Get Users -> Load Orders)
  Future<List<OrderModel>> discoverRealOrders({bool forceRefresh = false, Function(int)? onProgress}) async {
    if (!forceRefresh && _cachedDiscoveredOrders != null) {
      return _cachedDiscoveredOrders!;
    }

    debugPrint('🔍 Bắt đầu khám phá đơn hàng thông qua danh sách Users (API chính thức)...');
    
    try {
      // 1. Lấy danh sách toàn bộ User thực tế
      final usersRes = await _client.get<dynamic>('/users');
      final List rawList = (usersRes.data != null && usersRes.data['data'] != null) 
          ? usersRes.data['data'] 
          : [];
      
      final List<String> userIds = rawList
          .map((u) => u['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      
      // 2. Gọi API lấy đơn hàng cho từng User (Dùng API mới tạo ở Backend)
      final Set<OrderModel> allFoundOrders = {};
      final List<Future<List<OrderModel>>> futures = [];
      
      for (var uid in userIds) {
        futures.add(getOrdersByUserIdForAdmin(uid));
      }

      final results = await Future.wait(futures);
      int count = 0;
      for (var list in results) {
        allFoundOrders.addAll(list);
        count += list.length;
        if (onProgress != null) onProgress(allFoundOrders.length);
      }

      final List<OrderModel> finalOrders = allFoundOrders.toList();
      
      // Sắp xếp theo thời gian mới nhất
      finalOrders.sort((a, b) {
        final dateA = DateTime.tryParse(a.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      _cachedDiscoveredOrders = finalOrders;
      return finalOrders.isNotEmpty ? finalOrders : _mockOrders;
    } catch (e) {
      debugPrint('❌ Lỗi trong quá trình khám phá Đơn hàng theo User: $e');
      return _cachedDiscoveredOrders ?? _mockOrders;
    }
  }

  /// Lấy toàn bộ danh sách đơn hàng cho Admin thông qua API chuẩn (đã sửa ở Backend)
  Future<List<OrderModel>> getAllOrdersAdmin({bool forceRefresh = false}) async {
    try {
      final response = await _client.get<dynamic>('/orders/admin/all');
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        final List list = data['data'];
        final orders = list.map((json) => OrderModel.fromJson(Map<String, dynamic>.from(json))).toList();
        _cachedDiscoveredOrders = orders;
        return orders;
      }
      return discoverRealOrders(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('getAllOrdersAdmin API Error: $e. Falling back to discovery...');
      return discoverRealOrders(forceRefresh: forceRefresh);
    }
  }

  /// Kiểm tra số lượng User trong hệ thống (để chứng minh DB đang hoạt động)
  Future<int> getTotalUsersCount() async {
    try {
      final response = await _client.get<dynamic>('/users');
      final data = response.data;
      if (data != null && data['data'] != null) {
        return (data['data'] as List).length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Utilize existing API to suggest Customers
  Future<List<Map<String, dynamic>>> fetchCustomersSuggestion() async {
    try {
      final response = await _client.get<dynamic>('/users/role/CUSTOMER');
      final data = response.data;
      if (data != null && data['data'] != null) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchCustomersSuggestion error: $e');
      return [];
    }
  }

  /// Utilize existing API to suggest Shippers
  Future<List<Map<String, dynamic>>> fetchShippersSuggestion() async {
    try {
      final response = await _client.get<dynamic>('/users/role/SHIPPER');
      final data = response.data;
      if (data != null && data['data'] != null) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchShippersSuggestion error: $e');
      return [];
    }
  }

  /// Utilize existing API to suggest Stores
  Future<List<Map<String, dynamic>>> fetchStoresSuggestion() async {
    try {
      final response = await _client.get<dynamic>('/stores');
      final data = response.data;
      if (data != null && data['data'] != null) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchStoresSuggestion error: $e');
      return [];
    }
  }

  /// Utilize existing API to suggest Products per Store
  Future<List<Map<String, dynamic>>> fetchProductsByStore(String storeId) async {
    try {
      final response = await _client.get<dynamic>('/products/store/$storeId');
      final data = response.data;
      if (data != null && data['data'] != null) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchProductsByStore error: $e');
      return [];
    }
  }

  Future<bool> createOrderSimulated(OrderModel order) async {
    // Create a copy with generated ID and timestamp
    final newOrder = OrderModel(
      id: 1000 + _mockOrders.length + 1,
      status: order.status ?? 'PENDING',
      totalAmount: order.totalAmount,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      storeName: order.storeName,
      shipperName: order.shipperName,
      createdAt: DateTime.now().toIso8601String(),
      items: order.items,
    );
    _mockOrders.insert(0, newOrder);
    return true;
  }

  Future<bool> deleteOrderSimulated(int id) async {
    _mockOrders.removeWhere((o) => o.id == id);
    return true;
  }

  /// Update order status by id (requires auth).
  Future<OrderModel> updateOrderStatus(dynamic orderId, String status) async {
    try {
      // For Admin simulation, also update the local mock list if it exists there
      final mockIdx = _mockOrders.indexWhere((o) => o.id == orderId);
      if (mockIdx != -1) {
        final current = _mockOrders[mockIdx];
        _mockOrders[mockIdx] = OrderModel(
          id: current.id,
          status: status,
          totalAmount: current.totalAmount,
          customerName: current.customerName,
          customerPhone: current.customerPhone,
          storeName: current.storeName,
          shipperName: current.shipperName,
          createdAt: current.createdAt,
          items: current.items,
        );
      }

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
        order is Map<String, dynamic>
            ? order
            : Map<String, dynamic>.from(order as Map),
      );
    } on DioException catch (e) {
      // If we are in simulated mode (e.g. 404/500 from backend), we just return the mock one if available
      final mockIdx = _mockOrders.indexWhere((o) => o.id == orderId);
      if (mockIdx != -1) return _mockOrders[mockIdx];
      
      throw e.error is ApiException ? e.error as ApiException : ApiException(message: e.message ?? 'Lỗi cập nhật trạng thái đơn hàng');
    }
  }
}
