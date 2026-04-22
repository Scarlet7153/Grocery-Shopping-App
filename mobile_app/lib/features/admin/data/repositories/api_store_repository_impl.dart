import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/repositories/store_repository.dart';

class ApiStoreRepositoryImpl implements StoreRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<Map<String, dynamic>>> getStores({bool? pendingApproval}) async {
    try {
      final endpoint = pendingApproval == true ? '/users/stores/pending' : '/stores';
      final response = await _apiClient.get(endpoint);
      final List data = response.data['data'] as List;
      
      if (pendingApproval == true) {
        // Normalize pending store data to match regular store format
        return data.map<Map<String, dynamic>>((item) {
          return {
            'id': item['storeId'],
            'userId': item['userId'],
            'storeName': item['storeName'] ?? 'Chưa đặt tên',
            'ownerName': item['fullName'] ?? 'N/A',
            'address': item['storeAddress'] ?? 'N/A',
            'phoneNumber': item['phoneNumber'] ?? 'N/A',
            'isOpen': false,
            'status': 'PENDING',
            'imageUrl': item['avatarUrl'],
          };
        }).toList();
      }
      
      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403 || status == 401) {
        return [];
      }
      rethrow;
    } catch (e) {
      throw Exception('Failed to load stores: $e');
    }
  }

  @override
  Future<void> approveStore(String userId) async {
    try {
      await _apiClient.patch('/users/$userId/approve-store');
    } catch (e) {
      throw Exception('Failed to approve store: $e');
    }
  }

  @override
  Future<void> rejectStore(String userId) async {
    try {
      await _apiClient.patch('/users/$userId/reject-store');
    } catch (e) {
      throw Exception('Failed to reject store: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> createStore(Map<String, dynamic> storeData) async {
    try {
      // Backend handles store creation via registration with role STORE
      final response = await _apiClient.post('/auth/register', data: {
        'phoneNumber': storeData['phone'],
        'password': storeData['password'],
        'fullName': storeData['ownerName'],
        'role': 'STORE',
        'storeName': storeData['name'],
        'storeAddress': storeData['address'],
      });
      return response.data['data'] ?? {};
    } catch (e) {
      throw Exception('Failed to create store: $e');
    }
  }


  @override
  Future<Map<String, dynamic>> updateStore(Map<String, dynamic> storeData) async {
    try {
      final id = storeData['id'];
      final response = await _apiClient.put('/stores/$id', data: storeData);
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to update store: $e');
    }
  }

  @override
  Future<void> deleteStore(String storeId) async {
    try {
      await _apiClient.delete('/stores/$storeId');
    } catch (e) {
      throw Exception('Failed to delete store: $e');
    }
  }
}
