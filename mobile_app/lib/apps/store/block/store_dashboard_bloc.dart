import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/store_repository.dart';

/// EVENTS

abstract class StoreDashboardEvent {}

class LoadStoreDashboard extends StoreDashboardEvent {
  final String token;

  LoadStoreDashboard(this.token);
}

/// STATES

abstract class StoreDashboardState {}

class StoreDashboardInitial extends StoreDashboardState {}

class StoreDashboardLoading extends StoreDashboardState {}

class StoreDashboardLoaded extends StoreDashboardState {
  final Map<String, dynamic> store;

  StoreDashboardLoaded(this.store);
}

class StoreDashboardError extends StoreDashboardState {}

/// BLOC

class StoreDashboardBloc
    extends Bloc<StoreDashboardEvent, StoreDashboardState> {
  final StoreRepository repository;

  StoreDashboardBloc(this.repository) : super(StoreDashboardInitial()) {
    on<LoadStoreDashboard>((event, emit) async {
      emit(StoreDashboardLoading());

      try {
        final data = await repository.getMyStore(event.token);

        emit(StoreDashboardLoaded(data));
      } catch (e) {
        emit(StoreDashboardError());
      }
    });
  }
}
