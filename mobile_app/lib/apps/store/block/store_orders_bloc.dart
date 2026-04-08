import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/orders/data/order_model.dart';
import '../../../features/orders/data/order_service.dart';

/// EVENTS

abstract class StoreOrdersEvent {}

class LoadStoreOrders extends StoreOrdersEvent {
  final int? page;
  final int? limit;
  final String? status;

  LoadStoreOrders({this.page, this.limit, this.status});
}

class UpdateStoreOrderStatus extends StoreOrdersEvent {
  final String orderId;
  final String status;

  UpdateStoreOrderStatus(this.orderId, this.status);
}

/// STATES

abstract class StoreOrdersState {}

class StoreOrdersInitial extends StoreOrdersState {}

class StoreOrdersLoading extends StoreOrdersState {}

class StoreOrdersLoaded extends StoreOrdersState {
  final List<OrderModel> orders;

  StoreOrdersLoaded(this.orders);
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
  }

  final OrderService _orderService;

  Future<void> _onLoad(
    LoadStoreOrders event,
    Emitter<StoreOrdersState> emit,
  ) async {
    emit(StoreOrdersLoading());
    try {
      final list = await _orderService.getStoreOrders(
        page: event.page,
        limit: event.limit,
        status: event.status,
      );
      emit(StoreOrdersLoaded(list));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      emit(StoreOrdersError(message));
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
        event.status,
      );
      final list = current.orders
          .map((o) => o.id == event.orderId ? updated : o)
          .toList();
      if (!list.any((o) => o.id == event.orderId)) list.add(updated);
      emit(StoreOrdersLoaded(list));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      emit(StoreOrdersError(message));
      emit(StoreOrdersLoaded(current.orders));
    }
  }
}
