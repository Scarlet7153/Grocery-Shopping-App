part of 'shipper_dashboard_bloc.dart';

abstract class ShipperDashboardEvent extends Equatable {
  const ShipperDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends ShipperDashboardEvent {}

class RefreshDashboardData extends ShipperDashboardEvent {}

class AcceptOrder extends ShipperDashboardEvent {
  final int orderId;

  const AcceptOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class CompleteOrder extends ShipperDashboardEvent {
  final int orderId;

  const CompleteOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class ToggleOnlineStatus extends ShipperDashboardEvent {}
