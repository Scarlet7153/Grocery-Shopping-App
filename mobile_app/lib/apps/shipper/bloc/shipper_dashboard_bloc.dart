import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:grocery_shopping_app/apps/shipper/models/shipper_order.dart';
import 'package:grocery_shopping_app/apps/shipper/repository/shipper_repository.dart';

part 'shipper_dashboard_event.dart';
part 'shipper_dashboard_state.dart';

class ShipperDashboardBloc
    extends Bloc<ShipperDashboardEvent, ShipperDashboardState> {
  final ShipperRepository _repository;

  ShipperDashboardBloc({required ShipperRepository repository})
    : _repository = repository,
      super(const ShipperDashboardState.initial()) {
    on<LoadDashboardData>(onLoadData);
    on<RefreshDashboardData>(onLoadData);
    on<AcceptOrder>(onAcceptOrder);
    on<CompleteOrder>(onCompleteOrder);
    on<ToggleOnlineStatus>(onToggleOnline);
    on<UpdateDistances>(onUpdateDistances);
  }

  void onUpdateDistances(
    UpdateDistances event,
    Emitter<ShipperDashboardState> emit,
  ) {
    emit(state.copyWith(distances: event.distances));
  }

  Future<void> onLoadData(
    ShipperDashboardEvent event,
    Emitter<ShipperDashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final data = await _repository.fetchDashboardData();
      emit(
        state.copyWith(
          status: DashboardStatus.loaded,
          isOnline: data['isOnline'] as bool,
          earnings: data['earnings'] as double,
          availableOrders: List<ShipperOrder>.from(
            data['availableOrders'] as List,
          ),
          deliveries: List<ShipperOrder>.from(data['deliveries'] as List),
          completedCount: data['completedCount'] as int,
          acceptanceRate: data['acceptanceRate'] as double,
          distances: state.distances.isNotEmpty ? state.distances : const {},
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: DashboardStatus.error, error: e.toString()));
    }
  }

  Future<ShipperOrder?> onAcceptOrder(
    AcceptOrder event,
    Emitter<ShipperDashboardState> emit,
  ) async {
    try {
      final order = await _repository.assignOrder(event.orderId);
      if (order != null) {
        add(RefreshDashboardData());
      }
      event.completer.complete(order);
      return order;
    } catch (e) {
      event.completer.complete(null);
      return null;
    }
  }

  Future<ShipperOrder?> onCompleteOrder(
    CompleteOrder event,
    Emitter<ShipperDashboardState> emit,
  ) async {
    try {
      final order = await _repository.updateOrderStatus(
        event.orderId,
        'DELIVERED',
      );
      if (order != null) {
        add(RefreshDashboardData());
      }
      event.completer.complete(order);
      return order;
    } catch (e) {
      event.completer.complete(null);
      return null;
    }
  }

  void onToggleOnline(
    ToggleOnlineStatus event,
    Emitter<ShipperDashboardState> emit,
  ) {
    emit(state.copyWith(isOnline: !state.isOnline));
  }

  Future<ShipperOrder?> acceptOrder(int orderId) async {
    final completer = Completer<ShipperOrder?>();
    add(AcceptOrder(orderId, completer));
    return completer.future;
  }

  Future<ShipperOrder?> completeOrder(int orderId) async {
    final completer = Completer<ShipperOrder?>();
    add(CompleteOrder(orderId, completer));
    return completer.future;
  }
}
