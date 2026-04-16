import 'package:grocery_shopping_app/apps/shipper/constants/dashboard_constants.dart';
import 'package:grocery_shopping_app/apps/shipper/services/routing_service.dart';
import 'package:latlong2/latlong.dart';

class CustomerDeliveryEstimate {
  final double distanceKm;
  final int durationMinutes;

  const CustomerDeliveryEstimate({
    required this.distanceKm,
    required this.durationMinutes,
  });

  String get distanceLabel {
    if (distanceKm <= 0) return '-- km';
    if (distanceKm < 1) return '${distanceKm.toStringAsFixed(1)}km';
    return '${distanceKm.toStringAsFixed(1)}km';
  }

  String get durationLabel {
    if (durationMinutes <= 0) return '-- phút';
    return '$durationMinutes phút';
  }
}

class CustomerDeliveryEstimateService {
  CustomerDeliveryEstimateService._();

  static final CustomerDeliveryEstimateService instance =
      CustomerDeliveryEstimateService._();

  final GraphHopperRoutingService _routingService = GraphHopperRoutingService(
    apiKey: DashboardConstants.graphHopperApiKey,
  );

  final Map<String, CustomerDeliveryEstimate> _estimateCache = {};

  Future<CustomerDeliveryEstimate?> estimateByAddress({
    required String customerAddress,
    required String storeAddress,
  }) async {
    final customer = customerAddress.trim();
    final store = storeAddress.trim();

    if (customer.isEmpty || store.isEmpty) {
      return null;
    }

    final key = '${customer.toLowerCase()}|${store.toLowerCase()}';
    final cached = _estimateCache[key];
    if (cached != null) {
      return cached;
    }

    try {
      final customerLoc = await _routingService.geocodeAddress(customer);
      final storeLoc = await _routingService.geocodeAddress(store);
      if (customerLoc == null || storeLoc == null) {
        return null;
      }

      final route = await _routingService.getRouteWithInfo(
        origin: storeLoc,
        destination: customerLoc,
        profile: 'car',
      );

      final estimate = CustomerDeliveryEstimate(
        distanceKm: route.distance / 1000,
        durationMinutes: (route.duration / 60).round(),
      );

      _estimateCache[key] = estimate;
      return estimate;
    } catch (_) {
      return null;
    }
  }

  Future<CustomerDeliveryEstimate?> estimateByCurrentLocation({
    required double customerLatitude,
    required double customerLongitude,
    required String storeAddress,
  }) async {
    final store = storeAddress.trim();
    if (store.isEmpty) {
      return null;
    }

    final key =
        'lat:$customerLatitude,lng:$customerLongitude|${store.toLowerCase()}';
    final cached = _estimateCache[key];
    if (cached != null) {
      return cached;
    }

    try {
      final storeLoc = await _routingService.geocodeAddress(store);
      if (storeLoc == null) {
        return null;
      }

      final route = await _routingService.getRouteWithInfo(
        origin: storeLoc,
        destination: LatLng(customerLatitude, customerLongitude),
        profile: 'car',
      );

      final estimate = CustomerDeliveryEstimate(
        distanceKm: route.distance / 1000,
        durationMinutes: (route.duration / 60).round(),
      );

      _estimateCache[key] = estimate;
      return estimate;
    } catch (_) {
      return null;
    }
  }
}
