import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_error.dart';
import '../repository/store_repository.dart';

/// EVENTS

abstract class StoreDashboardEvent {}

class LoadStoreDashboard extends StoreDashboardEvent {
  final String token;
  /// Khi false: không emit [StoreDashboardLoading] (tránh nhấp nháy khi làm mới sau toggle).
  final bool showLoading;

  LoadStoreDashboard(this.token, {this.showLoading = true});
}

/// Gộp phản hồi PATCH toggle (hoặc từng phần) vào state đã tải — cập nhật UI ngay.
class MergeStoreDashboardState extends StoreDashboardEvent {
  final Map<String, dynamic> partial;

  MergeStoreDashboardState(this.partial);
}

/// STATES

abstract class StoreDashboardState {}

class StoreDashboardInitial extends StoreDashboardState {}

class StoreDashboardLoading extends StoreDashboardState {}

class StoreDashboardLoaded extends StoreDashboardState {
  final Map<String, dynamic> store;

  StoreDashboardLoaded(this.store);
}

class StoreDashboardError extends StoreDashboardState {
  final String message;

  StoreDashboardError(this.message);
}

/// BLOC

class StoreDashboardBloc
    extends Bloc<StoreDashboardEvent, StoreDashboardState> {
  final StoreRepository repository;

  StoreDashboardBloc(this.repository) : super(StoreDashboardInitial()) {
    on<LoadStoreDashboard>(_onLoad);
    on<MergeStoreDashboardState>(_onMerge);
  }

  Future<void> _onLoad(
    LoadStoreDashboard event,
    Emitter<StoreDashboardState> emit,
  ) async {
    if (event.showLoading) emit(StoreDashboardLoading());

    try {
      final data = await repository.getMyStore(event.token);

      emit(StoreDashboardLoaded(data));
    } catch (e) {
      emit(StoreDashboardError(_messageFromError(e)));
    }
  }

  static String _messageFromError(Object e) {
    if (e is ApiException) return e.displayMessage;
    return e.toString().replaceFirst(RegExp(r'^Exception: '), '');
  }

  void _onMerge(
    MergeStoreDashboardState event,
    Emitter<StoreDashboardState> emit,
  ) {
    final s = state;
    if (s is! StoreDashboardLoaded) return;
    final merged = Map<String, dynamic>.from(s.store);
    event.partial.forEach((k, v) {
      merged[k] = v;
    });
    emit(StoreDashboardLoaded(merged));
  }
}
