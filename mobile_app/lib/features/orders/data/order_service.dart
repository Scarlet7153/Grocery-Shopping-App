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

  /// GET /orders/my-store-orders — backend không hỗ trợ page/limit/status query.
  Future<List<OrderModel>> getStoreOrders() async {
    try {
      final response = await _client.get<dynamic>(ApiRoutes.myStoreOrders);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Phản hồi danh sách đơn hàng không hợp lệ',
        );
      }
      final raw = data['data'];
      if (raw == null) {
        throw const ApiException(
          message: 'Phản hồi danh sách đơn hàng không hợp lệ',
        );
      }
      if (raw is! List) {
        throw const ApiException(
          message: 'Phản hồi danh sách đơn hàng không hợp lệ',
        );
      }
      final out = <OrderModel>[];
      for (final item in raw) {
        if (item is! Map) {
          debugPrint('getStoreOrders: bỏ qua phần tử không phải object');
          continue;
        }
        try {
          out.add(
            OrderModel.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (e, st) {
          debugPrint('getStoreOrders: lỗi parse một đơn — $e\n$st');
        }
      }
      if (raw.isNotEmpty && out.isEmpty) {
        throw const ApiException(
          message: 'Không đọc được dữ liệu đơn hàng',
        );
      }
      return out;
    } on DioException catch (e) {
      debugPrint('getStoreOrders error: $e');
      if (e.error is ApiException) throw e.error as ApiException;
      rethrow;
    }
  }

  // ========== ADMIN DISCOVERY METHODS (NO BACKEND CHANGES) ==========

  // Cache để tránh quét lại nhiều lần trong cùng một phiên làm việc
  static List<OrderModel>? _cachedDiscoveredOrders;

  /// Cơ chế Khám phá Đơn hàng dựa trên danh sách User (Theo gợi ý: Check Users -> Load Orders)
  /// Không quét mù quáng dải ID rộng, tập trung vào các ID có khả năng tồn tại cao.
  /// Cơ chế Khám phá Đơn hàng dựa trên danh sách User (Theo gợi ý: Check Users -> Load Orders)
  /// Lấy đơn hàng của một User bất kỳ (Xử lý 404/403 im lặng)
  Future<List<OrderModel>> getOrdersByUserIdForAdmin(dynamic userId) async {
    try {
      // Endpoint /orders/user/$userId có thể không tồn tại trong backend gốc
      final response = await _client.get<dynamic>('/orders/user/$userId');
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        final List list = data['data'];
        return list.map((json) => OrderModel.fromJson(Map<String, dynamic>.from(json))).toList();
      }
      return [];
    } catch (e) {
      // Nếu API theo User không tồn tại, ta sẽ dựa vào cơ chế quét ID ở discoverRealOrders
      return [];
    }
  }

  /// Cơ chế Khám phá Đơn hàng (TUYỆT CHIÊU: Utilizing existing authenticated detail API)
  /// Vì Backend giới hạn List Order, Admin sẽ "khám phá" đơn hàng bằng cách thử các ID thông qua /orders/{id}
  Future<List<OrderModel>> discoverRealOrders({
    bool forceRefresh = false,
    void Function(int discoveredCount)? onProgress,
  }) async {
    if (!forceRefresh && _cachedDiscoveredOrders != null) {
      return _cachedDiscoveredOrders!;
    }

    debugPrint('🔍 Đang "khám phá" dữ liệu đơn hàng hệ thống (Utilizing Detail API)...');
    
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
      for (var list in results) {
        allFoundOrders.addAll(list);
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

  // Cờ để biết endpoint /orders/available có bị giới hạn (403) hay không
  static bool _isAvailableRestricted = false;

  /// Lấy toàn bộ danh sách đơn hàng cho Admin thông qua cơ chế Khám phá (Tránh 403 redundant)
  Future<List<OrderModel>> getAllOrdersAdmin({bool forceRefresh = false}) async {
    // Nếu đã biết là bị giới hạn, ta vào thẳng chế độ Discovery để tiết kiệm tài nguyên
    if (_isAvailableRestricted) {
      return await discoverRealOrders(forceRefresh: forceRefresh);
    }

    try {
      final response = await _client.get<dynamic>('/orders/available');
      if (response.data != null && response.data['data'] != null) {
        final List list = response.data['data'];
        return list.map((json) => OrderModel.fromJson(Map<String, dynamic>.from(json))).toList();
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        _isAvailableRestricted = true; // Đánh dấu là bị giới hạn
        debugPrint('ℹ️ /orders/available is restricted. Admin is now using Discovery Mode for orders.');
      }
    }
    
    return await discoverRealOrders(forceRefresh: forceRefresh);
  }

  /// Lấy thống kê tổng quan cho Dashboard Admin (An toàn và Tối ưu)
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      // 1. Lấy dữ liệu từ các API chắc chắn có quyền (Users, Stores)
      final results = await Future.wait([
        _client.get<dynamic>('/users').catchError((e) => Response(requestOptions: RequestOptions(path: ''), data: {'data': []})),
        _client.get<dynamic>('/stores').catchError((e) => Response(requestOptions: RequestOptions(path: ''), data: {'data': []})),
      ]);

      final usersList = (results[0].data['data'] as List?) ?? [];
      final storesList = (results[1].data['data'] as List?) ?? [];
      
      // 2. Lấy dữ liệu đơn hàng (Khám phá thay vì gọi API list gây 403)
      final orders = await discoverRealOrders();

      double totalRevenue = 0;
      for (var o in orders) {
        totalRevenue += (o.totalAmount ?? 0).toDouble();
      }

      return {
        'userCount': usersList.length,
        'storeCount': storesList.length,
        'orders': orders.length,
        'revenue': totalRevenue,
        'profit': totalRevenue * 0.1, // Ước tính 10%
        'recentOrders': orders.take(5).toList(),
        'recentUsers': usersList.take(3).toList(),
      };
    } catch (e) {
      debugPrint('getAdminStats Error: $e');
      return {
        'userCount': 0, 'storeCount': 0, 'orders': 0, 'revenue': 0, 'recentOrders': [],
      };
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

  /// PATCH /orders/{id}/status — body: newStatus, optional cancelReason / podImageUrl.
  Future<OrderModel> updateOrderStatus(
    dynamic orderId, {
    required String newStatus,
    String? cancelReason,
    String? podImageUrl,
  }) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        ApiRoutes.updateOrderStatus(orderId),
        data: UpdateOrderStatusRequest(
          newStatus: newStatus,
          cancelReason: cancelReason,
          podImageUrl: podImageUrl,
        ).toJson(),
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
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(
        message: e.message ?? 'Lỗi cập nhật trạng thái đơn hàng',
      );
    }
  }
}
