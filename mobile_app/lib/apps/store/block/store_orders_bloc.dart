import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_error.dart';
import '../../../features/orders/data/order_model.dart';
import '../../../features/orders/data/order_service.dart';

/// EVENTS

abstract class StoreOrdersEvent {}

class LoadStoreOrders extends StoreOrdersEvent {
  LoadStoreOrders();
}

class UpdateStoreOrderStatus extends StoreOrdersEvent {
  final int orderId;
  final String newStatus;
  final String? cancelReason;
  final String? successMessageVi;

  UpdateStoreOrderStatus(
    this.orderId,
    this.newStatus, {
    this.cancelReason,
    this.successMessageVi,
  });
}

class ClearStoreOrdersSuccessMessage extends StoreOrdersEvent {}

/// STATES

abstract class StoreOrdersState {}

class StoreOrdersInitial extends StoreOrdersState {}

class StoreOrdersLoading extends StoreOrdersState {}

class StoreOrdersLoaded extends StoreOrdersState {
  final List<OrderModel> orders;
  /// Thông báo thành công sau PATCH; xóa bằng [ClearStoreOrdersSuccessMessage].
  final String? successMessageVi;

  StoreOrdersLoaded(this.orders, {this.successMessageVi});
}

class StoreOrdersError extends StoreOrdersState {
  final String message;

  StoreOrdersError(this.message);
}

/// Bloc that fetches orders and updates status via [OrderService].
class StoreOrdersBloc extends Bloc<StoreOrdersEvent, StoreOrdersState> {
  StoreOrdersBloc(this._orderService) : super(StoreOrdersInitial()) {
    on<LoadStoreOrders>(_onLoad);
    on<UpdateStoreOrderStatus>(_onUpdateStatus);
    on<ClearStoreOrdersSuccessMessage>(_onClearSuccess);
  }

  final OrderService _orderService;

  String _messageFromError(Object e) {
    if (e is ApiException) return e.displayMessage;
    return e.toString().replaceFirst(RegExp(r'^Exception: '), '');
  }

  Future<void> _onLoad(
    LoadStoreOrders event,
    Emitter<StoreOrdersState> emit,
  ) async {
    emit(StoreOrdersLoading());
    try {
      final list = await _orderService.getStoreOrders();
      list.sort((a, b) {
        final da = DateTime.tryParse(a.createdAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(b.createdAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
      emit(StoreOrdersLoaded(list));
    } catch (e) {
      emit(StoreOrdersError(_messageFromError(e)));
    }
  }

  Future<void> _onUpdateStatus(
    UpdateStoreOrderStatus event,
    Emitter<StoreOrdersState> emit,
  ) async {
    final current = state;
    if (current is! StoreOrdersLoaded) return;
    try {
      final updated = await _orderService.updateOrderStatus(
        event.orderId,
        newStatus: event.newStatus,
        cancelReason: event.cancelReason,
      );
      final list = current.orders
          .map((o) => o.id == event.orderId ? updated : o)
          .toList();
      if (!list.any((o) => o.id == event.orderId)) list.add(updated);
      emit(StoreOrdersLoaded(
        list,
        successMessageVi: event.successMessageVi,
      ));
    } catch (e) {
      emit(StoreOrdersError(_messageFromError(e)));
      emit(StoreOrdersLoaded(current.orders));
    }
  }

  void _onClearSuccess(
    ClearStoreOrdersSuccessMessage event,
    Emitter<StoreOrdersState> emit,
  ) {
    final s = state;
    if (s is StoreOrdersLoaded && s.successMessageVi != null) {
      emit(StoreOrdersLoaded(s.orders));
    }
  }
}
