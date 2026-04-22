import 'package:latlong2/latlong.dart';

/// Abstract Routing Service Interface
/// Cho phép thay thế giữa GraphHopper và OpenRouteService dễ dàng qua .env
///
/// Tất cả distance values được trả về ở đơn vị **kilometers (km)**
/// Tất cả duration values được trả về ở đơn vị **seconds (s)**
abstract class RoutingService {
  /// Tìm đường đi giữa 2 điểm, trả về danh sách tọa độ
  Future<List<LatLng>> getRoute({
    required LatLng origin,
    required LatLng destination,
    String profile,
  });

  /// Tính khoảng cách (km) giữa 2 điểm
  Future<double> getDistance({
    required LatLng origin,
    required LatLng destination,
    String profile,
  });

  /// Geocode địa chỉ sang LatLng
  Future<LatLng?> geocodeAddress(String address);

  /// Tìm đường đi + thông tin chi tiết (khoảng cách km, thờ i gian s, chỉ dẫn)
  Future<RouteInfo> getRouteWithInfo({
    required LatLng origin,
    required LatLng destination,
    String profile,
  });

  /// Tìm đường đi qua nhiều điểm dừng
  Future<MultiStopRouteResult> getMultiStopRoute({
    required List<LatLng> waypoints,
    List<String>? labels,
    String profile,
  });

  /// Tối ưu hóa thứ tự giao hàng (VRP)
  Future<VrpResult> optimizeDeliverySequence({
    required LatLng shipperLocation,
    required List<DeliveryStop> stops,
  });
}

// =============================================================================
// Shared Data Models - All distances in km, durations in seconds
// =============================================================================

class RouteInfo {
  final double distance; // in km
  final double duration; // in seconds
  final List<LatLng> points;
  final List<RouteInstruction> instructions;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.points,
    this.instructions = const [],
  });

  double get distanceKm => distance;

  int get durationMinutes => (duration / 60).ceil();
}

class RouteInstruction {
  final String text;
  final double distance; // in km
  final double time; // in seconds
  final int sign;

  RouteInstruction({
    required this.text,
    required this.distance,
    required this.time,
    required this.sign,
  });
}

class MultiStopRouteResult {
  final double totalDistance; // in km
  final double totalDuration; // in seconds
  final List<LatLng> points;
  final List<RouteSegment> segments;

  MultiStopRouteResult({
    required this.totalDistance,
    required this.totalDuration,
    required this.points,
    required this.segments,
  });

  double get totalDistanceKm => totalDistance;
  int get totalDurationMinutes => (totalDuration / 60).ceil();
}

class RouteSegment {
  final LatLng start;
  final LatLng end;
  final double distance; // in km
  final double duration; // in seconds
  final List<LatLng> points;
  final String label;

  RouteSegment({
    required this.start,
    required this.end,
    required this.distance,
    required this.duration,
    required this.points,
    required this.label,
  });

  double get distanceKm => distance;
  int get durationMinutes => (duration / 60).ceil();
}

/// Model for delivery stop (pickup + delivery location)
class DeliveryStop {
  final int orderId;
  final LatLng pickupLocation;
  final LatLng deliveryLocation;
  final int? pickupServiceTime; // in seconds
  final int? deliveryServiceTime; // in seconds

  DeliveryStop({
    required this.orderId,
    required this.pickupLocation,
    required this.deliveryLocation,
    this.pickupServiceTime,
    this.deliveryServiceTime,
  });
}

/// Result from VRP optimization
class VrpResult {
  final List<int> optimizedOrderIds; // Order sequence
  final double totalDistance; // in km
  final double totalTime; // in seconds
  final Map<String, dynamic> solution; // Full provider solution

  VrpResult({
    required this.optimizedOrderIds,
    required this.totalDistance,
    required this.totalTime,
    required this.solution,
  });
}
