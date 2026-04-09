import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_error.dart';
import '../../../core/api/api_routes.dart';
import 'product_model.dart';

/// Products API: get store products, create, update, delete.
class ProductService {
  ProductService() : _client = ApiClient();

  final ApiClient _client;

  /// Get store products. Optional query params: page, limit, category, search.
  Future<List<ProductModel>> getProducts({
    int? page,
    int? limit,
    String? category,
    String? search,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (page != null) query['page'] = page;
      if (limit != null) query['limit'] = limit;
      if (category != null && category.isNotEmpty) query['category'] = category;
      if (search != null && search.isNotEmpty) query['search'] = search;

      final response = await _client.get<dynamic>(
        ApiRoutes.products,
        queryParameters: query.isNotEmpty ? query : null,
      );
      final data = response.data;
      if (data == null) return [];

      if (data is List) {
        return data
            .map(
              (e) => ProductModel.fromJson(
                e is Map<String, dynamic>
                    ? e
                    : Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }
      if (data is Map<String, dynamic>) {
        final list = data['data'] ?? data['products'];
        if (list is List) {
          return list
              .map(
                (e) => ProductModel.fromJson(
                  e is Map<String, dynamic>
                      ? e
                      : Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('getProducts failed: $e');
      return [];
    } catch (e) {
      debugPrint('getProducts unexpected error: $e');
      return [];
    }
  }

  /// Get products by store ID.
  Future<List<ProductModel>> getProductsByStore(String storeId) async {
    try {
      final response = await _client.get<dynamic>('/products/store/$storeId');
      final data = response.data;
      if (data == null) return [];

      final list = data is List ? data : (data is Map<String, dynamic> ? (data['data'] ?? []) : []);
      if (list is List) {
        return list
            .map((e) => ProductModel.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('getProductsByStore failed: $e');
      return [];
    } catch (e) {
      debugPrint('getProductsByStore unexpected error: $e');
      return [];
    }
  }

  /// Create a new product (requires auth).
  Future<ProductModel> createProduct(CreateProductRequest request) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiRoutes.products,
        data: request.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Phản hồi trống');
      }
      final product = data['data'] ?? data;
      return ProductModel.fromJson(
        product is Map<String, dynamic>
            ? product
            : Map<String, dynamic>.from(product as Map),
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException(message: e.message ?? 'Lỗi tạo sản phẩm');
    }
  }

  /// Update product by id (requires auth).
  Future<ProductModel> updateProduct(
    String id,
    UpdateProductRequest request,
  ) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        ApiRoutes.productById(id),
        data: request.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Phản hồi trống');
      }
      final product = data['data'] ?? data;
      return ProductModel.fromJson(
        product is Map<String, dynamic>
            ? product
            : Map<String, dynamic>.from(product as Map),
      );
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException(message: e.message ?? 'Lỗi cập nhật sản phẩm');
    }
  }

  /// Delete product by id (requires auth).
  Future<void> deleteProduct(String id) async {
    try {
      await _client.delete(ApiRoutes.productById(id));
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException(message: e.message ?? 'Lỗi xóa sản phẩm');
    }
  }
}
