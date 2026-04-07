import 'package:bloc/bloc.dart';
import 'package:grocery_shopping_app/apps/shipper/models/user_profile.dart';
import 'package:grocery_shopping_app/apps/shipper/repository/shipper_repository.dart';

part 'shipper_profile_event.dart';
part 'shipper_profile_state.dart';

class ShipperProfileBloc
    extends Bloc<ShipperProfileEvent, ShipperProfileState> {
  final ShipperRepository _repository;

  ShipperProfileBloc({required ShipperRepository repository})
      : _repository = repository,
        super(const ShipperProfileState()) {
    on<LoadUserProfile>(_handleLoadProfile);
    on<UpdateUserProfile>(_handleUpdateProfile);
    on<ChangePassword>(_handleChangePassword);
    on<ClearProfile>(_handleClearProfile);
  }

  Future<void> _handleLoadProfile(
    LoadUserProfile event,
    Emitter<ShipperProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final userJson = await _repository.getCurrentUser();
      if (userJson != null) {
        final userProfile = UserProfile.fromJson(userJson);
        emit(state.copyWith(
          status: ProfileStatus.loaded,
          userProfile: userProfile,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Không thể lấy thông tin hồ sơ',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _handleUpdateProfile(
    UpdateUserProfile event,
    Emitter<ShipperProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final success = await _repository.updateProfile(
        fullName: event.fullName,
        address: event.address,
      );
      if (success) {
        // Re-fetch profile after successful update
        final userJson = await _repository.getCurrentUser();
        if (userJson != null) {
          final userProfile = UserProfile.fromJson(userJson);
          emit(state.copyWith(
            status: ProfileStatus.success,
            userProfile: userProfile,
            errorMessage: null,
          ));
        } else {
          emit(state.copyWith(
            status: ProfileStatus.error,
            errorMessage: 'Không thể lấy thông tin hồ sơ sau khi cập nhật',
          ));
        }
      } else {
        emit(state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Cập nhật hồ sơ thất bại',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _handleChangePassword(
    ChangePassword event,
    Emitter<ShipperProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final success = await _repository.changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      );
      if (success) {
        emit(state.copyWith(
          status: ProfileStatus.success,
          isPasswordChanged: true,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Đổi mật khẩu thất bại',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _handleClearProfile(
    ClearProfile event,
    Emitter<ShipperProfileState> emit,
  ) async {
    emit(const ShipperProfileState());
  }
}
