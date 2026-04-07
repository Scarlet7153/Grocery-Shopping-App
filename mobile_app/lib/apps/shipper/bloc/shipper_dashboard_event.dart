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
  final Completer<ShipperOrder?> completer;

  const AcceptOrder(this.orderId, this.completer);

  @override
  List<Object?> get props => [orderId];
}

class CompleteOrder extends ShipperDashboardEvent {
  final int orderId;
  final Completer<ShipperOrder?> completer;

  const CompleteOrder(this.orderId, this.completer);

  @override
  List<Object?> get props => [orderId];
}

class ToggleOnlineStatus extends ShipperDashboardEvent {}

class UpdateDistances extends ShipperDashboardEvent {
  final Map<int, double> distances;

  const UpdateDistances(this.distances);

  @override
  List<Object?> get props => [distances];
}

class CalculateDistances extends ShipperDashboardEvent {
  const CalculateDistances();
}
