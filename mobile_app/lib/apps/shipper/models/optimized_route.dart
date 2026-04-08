import 'package:equatable/equatable.dart';
import 'package:grocery_shopping_app/apps/shipper/models/shipper_order.dart';

/// Model cho optimized route từ GraphHopper
class OptimizedRoute extends Equatable {
  /// Ordered list của orders (theo GraphHopper optimization)
  final List<ShipperOrder> optimizedOrders;

  /// Tổng khoảng cách (km)
  final double totalDistance;

  /// Tổng thời gian ước tính (phút)
  final int estimatedTime;

  /// Polyline (encoded) từ start → all stops → end
  final String? polyline;

  /// List của tất cả stops trong thứ tự (pickup, delivery, etc)
  final List<RouteStop> stops;

  const OptimizedRoute({
    required this.optimizedOrders,
    required this.totalDistance,
    required this.estimatedTime,
    this.polyline,
    required this.stops,
  });

  @override
  List<Object?> get props => [
    optimizedOrders,
    totalDistance,
    estimatedTime,
    polyline,
    stops,
  ];

  Map<String, dynamic> toJson() => {
    'optimizedOrders': optimizedOrders.map((o) => o.id).toList(),
    'totalDistance': totalDistance,
    'estimatedTime': estimatedTime,
    'polyline': polyline,
    'stops': stops.map((s) => s.toJson()).toList(),
  };
}

/// Một stop trong route (pickup hoặc delivery)
class RouteStop extends Equatable {
  final int orderId;
  final String title; // "Pick up from [Store]" hoặc "Deliver to [Address]"
  final bool isPickup;
  final double latitude;
  final double longitude;
  final String? address;

  const RouteStop({
    required this.orderId,
    required this.title,
    required this.isPickup,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  List<Object?> get props => [
    orderId,
    title,
    isPickup,
    latitude,
    longitude,
    address,
  ];

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'title': title,
    'isPickup': isPickup,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
  };

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      orderId: json['orderId'] as int,
      title: json['title'] as String,
      isPickup: json['isPickup'] as bool,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
    );
  }
}
