import '../../../../core/enums/app_type.dart';
import '../../../auth/models/user_model.dart';
import '../../domain/repositories/user_repository.dart';

class MockUserRepositoryImpl implements UserRepository {
  static final List<UserModel> _mockUsers = List.generate(
    20,
    (index) {
      final isCustomer = index < 8;
      final isStore = index >= 8 && index < 14;
      final isShipper = index >= 14 && index < 19;
      
      UserRole role;
      if (isCustomer) {
        role = UserRole.customer;
      } else if (isStore) role = UserRole.store;
      else if (isShipper) role = UserRole.shipper;
      else role = UserRole.admin;

      return UserModel(
        id: 'user_$index',
        phoneNumber: '09${12345678 + index}',
        fullName: 'Người dùng $index',
        role: role,
        status: index % 5 == 0 ? UserStatus.inactive : UserStatus.active,
        createdAt: DateTime.now().subtract(Duration(days: index * 2)),
        updatedAt: DateTime.now(),
        storeName: isStore ? 'Cửa hàng $index' : null,
      );
    },
  );

  @override
  Future<List<UserModel>> getUsers({AppType? appType, UserRole? role}) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
    
    if (role != null) {
      return _mockUsers.where((u) => u.role == role).toList();
    }
    
    if (appType != null) {
      UserRole targetRole;
      switch (appType) {
        case AppType.customer: targetRole = UserRole.customer; break;
        case AppType.store: targetRole = UserRole.store; break;
        case AppType.shipper: targetRole = UserRole.shipper; break;
        case AppType.admin: targetRole = UserRole.admin; break;
      }
      return _mockUsers.where((u) => u.role == targetRole).toList();
    }
    
    return _mockUsers;
  }

  @override
  Future<UserModel> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockUsers.firstWhere((u) => u.id == id, orElse: () => throw Exception('User not found'));
  }

  @override
  Future<void> updateUserStatus(String id, UserStatus status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockUsers.indexWhere((u) => u.id == id);
    if (index != -1) {
      _mockUsers[index] = _mockUsers[index].copyWith(status: status, updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockUsers.removeWhere((u) => u.id == id);
  }

  @override
  Future<UserModel> createUser(UserModel user, {required String password}) async {
    // Password not used in mock implementation, but kept for API parity
    await Future.delayed(const Duration(milliseconds: 500));
    _mockUsers.add(user);
    return user;
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockUsers.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _mockUsers[index] = user;
      return user;
    }
    throw Exception('User not found');
  }
}
