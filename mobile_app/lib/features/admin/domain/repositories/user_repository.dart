import '../../../auth/models/user_model.dart';
import '../../../../core/enums/app_type.dart';

abstract class UserRepository {
  Future<List<UserModel>> getUsers({AppType? appType, UserRole? role});
  Future<UserModel> getUserById(String id);
  Future<void> updateUserStatus(String id, UserStatus status);
  Future<void> deleteUser(String id);
  Future<UserModel> createUser(UserModel user, {required String password});
  Future<UserModel> updateUser(UserModel user);
}
