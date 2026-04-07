part of 'shipper_dashboard_bloc.dart';

enum DashboardStatus { initial, loading, loaded, error }

class ShipperDashboardState extends Equatable {
  final DashboardStatus status;
  final bool isOnline;
  final double earnings;
  final List<ShipperOrder> availableOrders;
  final List<ShipperOrder> deliveries;
  final int completedCount;
  final double acceptanceRate;
  final String? error;
  final Map<int, double> distances;

  const ShipperDashboardState({
    required this.status,
    required this.isOnline,
    required this.earnings,
    required this.availableOrders,
    required this.deliveries,
    required this.completedCount,
    required this.acceptanceRate,
    this.error,
    this.distances = const {},
  });

  const ShipperDashboardState.initial()
      : status = DashboardStatus.initial,
        isOnline = false,
        earnings = 0,
        availableOrders = const [],
        deliveries = const [],
        completedCount = 0,
        acceptanceRate = 0.0,
        error = null,
        distances = const {};

  ShipperDashboardState copyWith({
    DashboardStatus? status,
    bool? isOnline,
    double? earnings,
    List<ShipperOrder>? availableOrders,
    List<ShipperOrder>? deliveries,
    int? completedCount,
    double? acceptanceRate,
    String? error,
    Map<int, double>? distances,
  }) {
    return ShipperDashboardState(
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      earnings: earnings ?? this.earnings,
      availableOrders: availableOrders ?? this.availableOrders,
      deliveries: deliveries ?? this.deliveries,
      completedCount: completedCount ?? this.completedCount,
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
      error: error,
      distances: distances ?? this.distances,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isOnline,
        earnings,
        availableOrders,
        deliveries,
        completedCount,
        acceptanceRate,
        error,
        distances
      ];
}
