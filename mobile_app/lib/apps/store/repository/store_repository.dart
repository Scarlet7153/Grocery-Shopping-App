import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_routes.dart';
import '../../../features/products/data/product_model.dart';
import '../data/store_demo_product_seed.dart';

/// Kết quả GET /products/store/{id} kèm tổng tồn (cộng các unit).
class StoreProductsFetchResult {
  final List<ProductModel> products;
  final List<int> stockTotals;

  const StoreProductsFetchResult({
    required this.products,
    required this.stockTotals,
  });
}

class StoreRepository {
  StoreRepository() : _client = ApiClient();
  final ApiClient _client;

  /// LOGIN
  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiRoutes.login,
        data: {
          "phoneNumber": phoneNumber.trim(),
          "password": password,
        },
      );

      final body = response.data;
      if (body == null) {
        throw Exception("Phản hồi đăng nhập trống");
      }

      final token = _extractToken(body);
      if (token == null || token.isEmpty) {
        throw Exception(body["message"]?.toString() ?? "Đăng nhập thất bại");
      }

      await _client.setAccessToken(token);
      return {"token": token};
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 401) {
        throw Exception("Sai số điện thoại hoặc mật khẩu");
      }
      if (data is Map && data["message"] != null) {
        throw Exception(data["message"].toString());
      }
      throw Exception("Không thể kết nối máy chủ");
    }
  }

  /// GET /stores/my-store — dùng cho dashboard/profile; lỗi mạng/API ném exception (không trả map rỗng im lặng).
  Future<Map<String, dynamic>> getMyStore(String token) async {
    if (token.isNotEmpty) {
      await _client.setAccessToken(token);
    }
    try {
      final response = await _client.get<dynamic>('/stores/my-store');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final inner = data['data'];
        if (inner is Map<String, dynamic>) return inner;
        return data;
      }
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
    throw Exception('Phản hồi cửa hàng không hợp lệ');
  }

  /// GET /stores/my-store — full payload for profile (throws on failure).
  Future<Map<String, dynamic>> fetchMyStoreDetails(String token) async {
    if (token.isNotEmpty) {
      await _client.setAccessToken(token);
    }
    try {
      final response = await _client.get<dynamic>('/stores/my-store');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final inner = data['data'];
        if (inner is Map<String, dynamic>) return inner;
        return data;
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      throw Exception('Không thể tải thông tin cửa hàng');
    }
    throw Exception('Phản hồi cửa hàng không hợp lệ');
  }

  /// PATCH /stores/{storeId}/toggle-status — no body; returns updated store in `data`.
  Future<Map<String, dynamic>> toggleStoreStatus(String token, int storeId) async {
    if (token.isNotEmpty) {
      await _client.setAccessToken(token);
    }
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/stores/$storeId/toggle-status',
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final inner = data['data'];
        if (inner is Map<String, dynamic>) return inner;
        return data;
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      throw Exception('Không thể cập nhật trạng thái cửa hàng');
    }
    throw Exception('Phản hồi không hợp lệ');
  }

  /// PUT /stores/{storeId} — body: storeName, address (theo [UpdateStoreRequest] backend).
  Future<Map<String, dynamic>> updateStore({
    required String token,
    required int storeId,
    String? storeName,
    String? address,
  }) async {
    if (token.isNotEmpty) {
      await _client.setAccessToken(token);
    }
    final body = <String, dynamic>{};
    if (storeName != null) body['storeName'] = storeName;
    if (address != null) body['address'] = address;
    if (body.isEmpty) {
      throw Exception('Không có dữ liệu để cập nhật');
    }
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/stores/$storeId',
        data: body,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final inner = data['data'];
        if (inner is Map<String, dynamic>) return inner;
      }
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
    throw Exception('Phản hồi không hợp lệ');
  }

  /// POST /auth/register — role STORE; backend bắt buộc storeName, storeAddress.
  Future<String> registerStoreOwner({
    required String phoneNumber,
    required String password,
    required String fullName,
    required String storeName,
    required String storeAddress,
    String? userAddress,
    String? storeDescription,
    String? storePhoneNumber,
  }) async {
    final payload = <String, dynamic>{
      'phoneNumber': phoneNumber.trim(),
      'password': password,
      'fullName': fullName.trim(),
      'role': 'STORE',
      'storeName': storeName.trim(),
      'storeAddress': storeAddress.trim(),
    };
    if (userAddress != null && userAddress.trim().isNotEmpty) {
      payload['address'] = userAddress.trim();
    }
    if (storeDescription != null && storeDescription.trim().isNotEmpty) {
      payload['storeDescription'] = storeDescription.trim();
    }
    if (storePhoneNumber != null && storePhoneNumber.trim().isNotEmpty) {
      payload['storePhoneNumber'] = storePhoneNumber.trim();
    }
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiRoutes.register,
        data: payload,
      );
      final resBody = response.data;
      if (resBody == null) {
        throw Exception('Phản hồi đăng ký trống');
      }
      final token = _extractToken(resBody);
      if (token == null || token.isEmpty) {
        throw Exception(resBody['message']?.toString() ?? 'Đăng ký thất bại');
      }
      return token;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      throw Exception(_messageFromDio(e));
    }
  }

  String? _extractToken(Map<String, dynamic> body) {
    final data = body["data"];
    if (data is Map) {
      final token = data["token"];
      if (token is String && token.isNotEmpty) return token;
    }
    final token = body["token"];
    if (token is String && token.isNotEmpty) return token;
    return null;
  }

  /// Parses store id from [getMyStore] / [fetchMyStoreDetails] payload.
  int? parseStoreId(Map<String, dynamic>? store) {
    if (store == null) return null;
    final id = store['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return int.tryParse(id?.toString() ?? '');
  }

  /// MIME image/* cho part multipart — backend kiểm tra Content-Type.
  MediaType _contentTypeForProductImagePart(String filename) {
    final lower = filename.toLowerCase().trim();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    return MediaType('image', 'jpeg');
  }

  String _messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? 'Lỗi mạng';
  }

  static int sumStockUnits(Map<String, dynamic> json) {
    final units = json['units'];
    if (units is! List) return 0;
    var sum = 0;
    for (final u in units) {
      if (u is Map<String, dynamic>) {
        final q = u['stockQuantity'];
        if (q is num) sum += q.round();
      } else if (u is Map) {
        final q = u['stockQuantity'];
        if (q is num) sum += q.round();
      }
    }
    return sum;
  }

  /// GET /products/store/{storeId} — products + tổng tồn theo từng dòng.
  Future<StoreProductsFetchResult> fetchProductsForStoreWithStocks({
    required String token,
    required int storeId,
  }) async {
    if (token.isNotEmpty) {
      await _client.setAccessToken(token);
    }
    try {
      final response = await _client.get<dynamic>('/products/store/$storeId');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Phản hồi sản phẩm không hợp lệ');
      }
      final raw = data['data'];
      if (raw is! List) {
        throw Exception('Phản hồi sản phẩm không hợp lệ');
      }
      final products = <ProductModel>[];
      final stockTotals = <int>[];
      for (final e in raw) {
        final map = e is Map<String, dynamic>
            ? e
            : Map<String, dynamic>.from(e as Map);
        products.add(ProductModel.fromJson(map));
        stockTotals.add(sumStockUnits(map));
      }
      return StoreProductsFetchResult(
        products: products,
        stockTotals: stockTotals,
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// Xóa bản trùng tên demo (giữ một bản / tên; ưu tiên có imageUrl, sau đó id nhỏ hơn).
  Future<void> removeDuplicateDemoProducts({
    required String token,
    required List<ProductModel> products,
  }) async {
    if (token.isNotEmpty) {
      await _client.setAccessToken(token);
    }
    final byName = <String, List<ProductModel>>{};
    for (final p in products) {
      final n = p.name?.trim();
      if (n == null || n.isEmpty) continue;
      if (!kDemoProductNames.contains(n)) continue;
      byName.putIfAbsent(n, () => []).add(p);
    }
    for (final entry in byName.entries) {
      final group = entry.value;
      if (group.length < 2) continue;
      group.sort((a, b) {
        final ai = int.tryParse(a.id ?? '') ?? 0;
        final bi = int.tryParse(b.id ?? '') ?? 0;
        final aImg = (a.imageUrl != null && a.imageUrl!.isNotEmpty) ? 0 : 1;
        final bImg = (b.imageUrl != null && b.imageUrl!.isNotEmpty) ? 0 : 1;
        if (aImg != bImg) return aImg.compareTo(bImg);
        return ai.compareTo(bi);
      });
      for (var i = 1; i < group.length; i++) {
        final id = group[i].id;
        if (id == null || id.isEmpty) continue;
        try {
          await _client.delete<dynamic>(ApiRoutes.productById(id));
        } on DioException catch (e) {
          throw Exception(_messageFromDio(e));
        }
      }
    }
  }

  /// PUT /products/{id} — chỉ metadata (đúng backend).
  Future<void> updateProductMetadata({
    required String token,
    required String productId,
    String? name,
    String? description,
    String? imageUrl,
    int? categoryId,
  }) async {
    if (token.isNotEmpty) {
      await _client.setAccessToken(token);
    }
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (imageUrl != null) body['imageUrl'] = imageUrl;
    if (categoryId != null) body['categoryId'] = categoryId;
    try {
      await _client.put<Map<String, dynamic>>(
        ApiRoutes.productById(productId),
        data: body,
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /api/upload/product/{productId} — multipart, field "file".
  Future<String> uploadProductImage({
    required String token,
    required String productId,
    required List<int> bytes,
    required String filename,
  }) async {
    if (token.isNotEmpty) {
      await _client.setAccessToken(token);
    }
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: _contentTypeForProductImagePart(filename),
      ),
    });
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/upload/product/$productId',
        data: formData,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final inner = data['data'];
        if (inner is String && inner.isNotEmpty) return inner;
        if (inner != null) return inner.toString();
      }
      throw Exception('Phản hồi upload không hợp lệ');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /products — backend expects [units] (see CreateProductRequest on server).
  /// Returns new product id when present in `data`.
  Future<int?> createProductForStore({
    required String token,
    required String name,
    String? description,
    required double price,
    required int stock,
    String? imageUrl,
  }) async {
    if (token.isNotEmpty) {
      await _client.setAccessToken(token);
    }
    final body = <String, dynamic>{
      'name': name,
      'units': [
        {
          'unitName': 'Đơn vị',
          'price': price,
          'stockQuantity': stock,
        },
      ],
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      body['imageUrl'] = imageUrl;
    }
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiRoutes.products,
        data: body,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final inner = data['data'];
        if (inner is Map) {
          final id = inner['id'];
          if (id is num) return id.toInt();
          return int.tryParse(id.toString());
        }
      }
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
    return null;
  }

  /// PATCH /products/{id}/toggle-status — after create, to mark product hidden if needed.
  Future<void> toggleProductStatus({
    required String token,
    required int productId,
  }) async {
    if (token.isNotEmpty) {
      await _client.setAccessToken(token);
    }
    try {
      await _client.patch<dynamic>('/products/$productId/toggle-status');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// DELETE /products/{id}
  Future<void> deleteProduct({
    required String token,
    required String productId,
  }) async {
    if (token.isNotEmpty) {
      await _client.setAccessToken(token);
    }
    try {
      await _client.delete<dynamic>(ApiRoutes.productById(productId));
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }
}
