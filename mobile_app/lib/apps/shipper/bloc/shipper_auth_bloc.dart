import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/shipper_repository.dart';

part 'shipper_auth_event.dart';
part 'shipper_auth_state.dart';

class ShipperAuthBloc extends Bloc<ShipperAuthEvent, ShipperAuthState> {
  final ShipperRepository _repository;

  ShipperAuthBloc({required ShipperRepository repository})
      : _repository = repository,
        super(ShipperAuthInitial()) {
    on<ShipperLoginRequested>(_onLoginRequested);
    on<ShipperRegisterRequested>(_onRegisterRequested);
    on<ShipperLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(
      ShipperLoginRequested event, Emitter<ShipperAuthState> emit) async {
    emit(ShipperAuthLoading());
    try {
      final success =
          await _repository.login(phone: event.phone, password: event.password);
      if (success) {
        emit(ShipperAuthAuthenticated());
      } else {
        emit(const ShipperAuthError(
            message: 'Thông tin đăng nhập không hợp lệ'));
      }
    } catch (e) {
      emit(ShipperAuthError(message: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
      ShipperRegisterRequested event, Emitter<ShipperAuthState> emit) async {
    emit(ShipperAuthLoading());
    try {
      final success = await _repository.register(
        phoneNumber: event.phoneNumber,
        password: event.password,
        fullName: event.fullName,
        address: event.address,
      );
      if (success) {
        emit(ShipperAuthAuthenticated());
      } else {
        emit(const ShipperAuthError(message: 'Đăng ký thất bại'));
      }
    } catch (e) {
      emit(ShipperAuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
      ShipperLogoutRequested event, Emitter<ShipperAuthState> emit) async {
    await _repository.logout();
    emit(ShipperAuthInitial());
  }
}
