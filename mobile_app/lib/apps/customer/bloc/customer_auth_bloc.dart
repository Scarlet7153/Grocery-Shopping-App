import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/customer_auth_repository.dart';

/// EVENT

abstract class CustomerAuthEvent {}

class CustomerLoginEvent extends CustomerAuthEvent {
  final String phone;
  final String password;

  CustomerLoginEvent(this.phone, this.password);
}

class CustomerRegisterEvent extends CustomerAuthEvent {
  final String phoneNumber;
  final String password;
  final String fullName;
  final String address;

  CustomerRegisterEvent({
    required this.phoneNumber,
    required this.password,
    required this.fullName,
    required this.address,
  });
}

/// STATE

abstract class CustomerAuthState {}

class CustomerAuthInitial extends CustomerAuthState {}

class CustomerAuthLoading extends CustomerAuthState {}

class CustomerAuthSuccess extends CustomerAuthState {}

class CustomerAuthFailure extends CustomerAuthState {
  final String message;

  CustomerAuthFailure(this.message);
}

/// BLOC

class CustomerAuthBloc extends Bloc<CustomerAuthEvent, CustomerAuthState> {
  final CustomerAuthRepository repository;

  CustomerAuthBloc(this.repository) : super(CustomerAuthInitial()) {
    on<CustomerLoginEvent>(_onLogin);
    on<CustomerRegisterEvent>(_onRegister);
  }

  Future<void> _onLogin(
    CustomerLoginEvent event,
    Emitter<CustomerAuthState> emit,
  ) async {
    emit(CustomerAuthLoading());

    try {
      final result = await repository.login(event.phone, event.password);

      if (result) {
        emit(CustomerAuthSuccess());
      } else {
        emit(CustomerAuthFailure('Invalid phone number or password'));
      }
    } catch (e) {
      emit(CustomerAuthFailure(e.toString()));
    }
  }

  Future<void> _onRegister(
    CustomerRegisterEvent event,
    Emitter<CustomerAuthState> emit,
  ) async {
    emit(CustomerAuthLoading());

    try {
      final result = await repository.register(
        phoneNumber: event.phoneNumber,
        password: event.password,
        fullName: event.fullName,
        address: event.address,
      );

      if (result) {
        emit(CustomerAuthSuccess());
      } else {
        emit(CustomerAuthFailure('Sign up failed'));
      }
    } catch (e) {
      emit(CustomerAuthFailure(e.toString()));
    }
  }
}
