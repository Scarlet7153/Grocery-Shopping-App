abstract class StoreRepository {
  Future<List<Map<String, dynamic>>> getStores({bool? pendingApproval});
  Future<void> approveStore(String storeId);
  Future<void> rejectStore(String storeId);
  Future<Map<String, dynamic>> createStore(Map<String, dynamic> storeData);
  Future<Map<String, dynamic>> updateStore(Map<String, dynamic> storeData);
  Future<void> deleteStore(String storeId);
}
