import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/store_repository.dart';

/// EVENTS

abstract class StoreAuthEvent {}

class LoginStoreEvent extends StoreAuthEvent {

  final String phoneNumber;
  final String password;

  LoginStoreEvent({
    required this.phoneNumber,
    required this.password,
  });
}

/// STATES

abstract class StoreAuthState {}

class StoreAuthInitial extends StoreAuthState {}

class StoreAuthLoading extends StoreAuthState {}

class StoreAuthSuccess extends StoreAuthState {

  final Map<String, dynamic> data;

  StoreAuthSuccess(this.data);
}

class StoreAuthError extends StoreAuthState {

  final String message;

  StoreAuthError(this.message);
}

/// BLOC

class StoreAuthBloc extends Bloc<StoreAuthEvent, StoreAuthState> {

  final StoreRepository repository;

  StoreAuthBloc(this.repository) : super(StoreAuthInitial()) {

    on<LoginStoreEvent>((event, emit) async {

      emit(StoreAuthLoading());

      try {

        final data = await repository.login(
          event.phoneNumber,
          event.password,
        );

        emit(StoreAuthSuccess(data));

      } catch (e) {

        emit(StoreAuthError(e.toString()));

      }

    });

  }

}