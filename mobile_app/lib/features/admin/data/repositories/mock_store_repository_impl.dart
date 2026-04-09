import '../../domain/repositories/store_repository.dart';

class MockStoreRepositoryImpl implements StoreRepository {
  static final List<Map<String, dynamic>> _mockStores = List.generate(
    10,
    (index) => {
      'id': 'store_$index',
      'name': 'Cửa hàng tiện lợi $index',
      'ownerName': 'Chủ $index',
      'address': '${index + 1} Đường Hùng Vương, Quận 5',
      'phone': '091234567$index',
      'status': index < 3 ? 'pending' : (index % 4 == 0 ? 'rejected' : 'active'),
      'rating': 4.0 + (index % 10) / 10,
      'createdAt': DateTime.now().subtract(Duration(days: index * 5)),
    },
  );

  @override
  Future<List<Map<String, dynamic>>> getStores({bool? pendingApproval}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (pendingApproval == true) {
      return _mockStores.where((s) => s['status'] == 'pending').toList();
    }
    return _mockStores.where((s) => s['status'] != 'pending').toList();
  }

  @override
  Future<void> approveStore(String storeId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _mockStores.indexWhere((s) => s['id'] == storeId);
    if (index != -1) {
      _mockStores[index]['status'] = 'active';
    }
  }

  @override
  Future<void> rejectStore(String storeId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _mockStores.indexWhere((s) => s['id'] == storeId);
    if (index != -1) {
      _mockStores[index]['status'] = 'rejected';
    }
  }

  @override
  Future<Map<String, dynamic>> createStore(Map<String, dynamic> storeData) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newStore = Map<String, dynamic>.from(storeData);
    newStore['id'] = 'store_${DateTime.now().millisecondsSinceEpoch}';
    newStore['status'] = 'active';
    newStore['rating'] = 5.0;
    newStore['createdAt'] = DateTime.now();
    _mockStores.add(newStore);
    return newStore;
  }

  @override
  Future<Map<String, dynamic>> updateStore(Map<String, dynamic> storeData) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockStores.indexWhere((s) => s['id'] == storeData['id']);
    if (index != -1) {
      _mockStores[index] = {..._mockStores[index], ...storeData};
      return _mockStores[index];
    }
    throw Exception('Store not found');
  }

  @override
  Future<void> deleteStore(String storeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockStores.removeWhere((s) => s['id'] == storeId);
  }
}
