import 'package:grocery_shopping_app/core/network/api_client.dart';

import 'category_model.dart';
import 'product_model.dart';
import 'store_model.dart';

/// Home API (Customer)
class HomeApi {
  Future<List<ProductModel>> getProducts() async {
    final response = await ApiClient.dio.get('/products');
    final List data = _extractList(response.data);
    return data.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await ApiClient.dio.get('/categories');
    final List data = _extractList(response.data);
    return data.map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<List<StoreModel>> getFeaturedStores() async {
    final response = await ApiClient.dio.get('/stores/open');
    final List data = _extractList(response.data);
    return data.map((e) => StoreModel.fromJson(e)).toList();
  }

  Future<List<ProductModel>> searchProducts(String keyword) async {
    final response = await ApiClient.dio.get(
      '/products/search',
      queryParameters: {'keyword': keyword},
    );
    final List data = _extractList(response.data);
    return data.map((e) => ProductModel.fromJson(e)).toList();
  }

  List _extractList(dynamic responseData) {
    if (responseData is Map && responseData['data'] is List) {
      return responseData['data'] as List;
    }
    if (responseData is List) {
      return responseData;
    }
    return <dynamic>[];
  }
}
