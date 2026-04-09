import 'package:grocery_shopping_app/core/network/api_client.dart';

import 'category_model.dart';
import 'product_model.dart';
import 'store_model.dart';

class HomeApi {
  Future<List<ProductModel>> getProducts() async {
    final response = await ApiClient.dio.get('/products');
    final List data = _extractList(response.data);
    if (data.isEmpty) {
      return _mockProducts();
    }
    return data.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await ApiClient.dio.get('/categories');
    final List data = _extractList(response.data);
    if (data.isEmpty) {
      return _mockCategories();
    }
    return data.map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<List<StoreModel>> getFeaturedStores() async {
    final response = await ApiClient.dio.get('/stores/open');
    final List data = _extractList(response.data);
    if (data.isEmpty) {
      return _mockStores();
    }
    return data.map((e) => StoreModel.fromJson(e)).toList();
  }

  Future<List<ProductModel>> searchProducts(String keyword) async {
    final response = await ApiClient.dio.get(
      '/products/search',
      queryParameters: {'keyword': keyword},
    );
    final List data = _extractList(response.data);
    if (data.isEmpty) {
      return _mockProducts()
          .where((p) => p.name.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }
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

  List<CategoryModel> _mockCategories() {
    return [
      CategoryModel(id: 1, name: 'Rau', iconUrl: ''),
      CategoryModel(id: 2, name: 'Cu', iconUrl: ''),
      CategoryModel(id: 3, name: 'Trai cay', iconUrl: ''),
      CategoryModel(id: 4, name: 'Thit', iconUrl: ''),
      CategoryModel(id: 5, name: 'Ca', iconUrl: ''),
      CategoryModel(id: 6, name: 'Do uong', iconUrl: ''),
    ];
  }

  List<StoreModel> _mockStores() {
    return [
      StoreModel(
        id: 1,
        storeName: 'Tap hoa Co Ba',
        address: '123 Le Loi, Q1',
        isOpen: true,
      ),
      StoreModel(
        id: 2,
        storeName: 'Sieu thi Mini B',
        address: '456 Nguyen Hue, Q1',
        isOpen: true,
      ),
      StoreModel(
        id: 3,
        storeName: 'Cua hang Thuc pham Xanh',
        address: '789 Hai Ba Trung, Q3',
        isOpen: false,
      ),
    ];
  }

  List<ProductModel> _mockProducts() {
    return [
      ProductModel(
        id: 1,
        name: 'Thịt ba rọi',
        description: 'Thịt ba rọi tươi ngon',
        imageUrl: 'assets/images/thit_ba_roi.png',
        storeName: 'Sieu thi Mini B',
        categoryName: 'Thit',
        status: 'AVAILABLE',
        units: [
          ProductUnitModel(
            id: 1,
            unitName: 'Goi 300g',
            price: 35000,
            stockQuantity: 50,
          ),
        ],
      ),
      ProductModel(
        id: 2,
        name: 'Cá hồi',
        description: 'Cá hồi nấu ăn',
        imageUrl: 'assets/images/ca_hoi.png',
        storeName: 'Sieu thi Mini B',
        categoryName: 'Ca',
        status: 'AVAILABLE',
        units: [
          ProductUnitModel(
            id: 2,
            unitName: 'Khay 500g',
            price: 120000,
            stockQuantity: 20,
          ),
        ],
      ),
      ProductModel(
        id: 3,
        name: 'Cam tươi',
        description: 'Cam ngọt nhập khẩu',
        imageUrl: 'assets/images/cam_tuoi.png',
        storeName: 'Tap hoa Co Ba',
        categoryName: 'Trai cay',
        status: 'AVAILABLE',
        units: [
          ProductUnitModel(
            id: 3,
            unitName: 'Tui 1kg',
            price: 45000,
            stockQuantity: 30,
          ),
        ],
      ),
    ];
  }
}
