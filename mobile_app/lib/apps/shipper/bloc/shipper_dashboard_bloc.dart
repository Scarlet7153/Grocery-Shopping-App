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
    on<LoadDashboardData>(_onLoadData);
    on<RefreshDashboardData>(_onLoadData);
    on<AcceptOrder>(_onAcceptOrder);
    on<CompleteOrder>(_onCompleteOrder);
    on<ToggleOnlineStatus>(_onToggleOnline);
  }

  Future<void> _onLoadData(
      ShipperDashboardEvent event, Emitter<ShipperDashboardState> emit) async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final data = await _repository.fetchDashboardData();
      emit(state.copyWith(
        status: DashboardStatus.loaded,
        isOnline: data['isOnline'] as bool,
        earnings: data['earnings'] as double,
        availableOrders: data['availableOrders'] as List<ShipperOrder>,
        deliveries: data['deliveries'] as List<ShipperOrder>,
        completedCount: data['completedCount'] as int,
        acceptanceRate: data['acceptanceRate'] as double,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: DashboardStatus.error, error: e.toString()));
    }
  }

  Future<void> _onAcceptOrder(
      AcceptOrder event, Emitter<ShipperDashboardState> emit) async {
    try {
      await _repository.assignOrder(event.orderId);
      add(RefreshDashboardData());
    } catch (_) {
      // keep current state
    }
  }

  Future<void> _onCompleteOrder(
      CompleteOrder event, Emitter<ShipperDashboardState> emit) async {
    try {
      await _repository.updateOrderStatus(event.orderId, 'DELIVERED');
      add(RefreshDashboardData());
    } catch (_) {
      // keep current state
    }
  }

  void _onToggleOnline(
      ToggleOnlineStatus event, Emitter<ShipperDashboardState> emit) {
    emit(state.copyWith(isOnline: !state.isOnline));
  }
}

