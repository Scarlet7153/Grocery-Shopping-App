import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:grocery_shopping_app/core/config/routing_service.dart';
import 'package:grocery_shopping_app/core/config/routing_service_factory.dart';
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

  final RoutingService _routingService = RoutingServiceFactory.instance;

  final Map<String, CustomerDeliveryEstimate> _estimateCache = {};

  /// Tính khoảng cách chim bay (Haversine) giữa 2 điểm
  double _haversineDistance(LatLng p1, LatLng p2) {
    const double earthRadius = 6371; // km
    final dLat = _toRad(p2.latitude - p1.latitude);
    final dLng = _toRad(p2.longitude - p1.longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(p1.latitude)) *
            math.cos(_toRad(p2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRad(double deg) => deg * (math.pi / 180);

  Future<CustomerDeliveryEstimate?> estimateByAddress({
    required String customerAddress,
    required String storeAddress,
  }) async {
    final customer = customerAddress.trim();
    final store = storeAddress.trim();

    if (customer.isEmpty || store.isEmpty) {
      debugPrint('[Estimate] Empty address: customer="$customer" store="$store"');
      return null;
    }

    final key = '${customer.toLowerCase()}|${store.toLowerCase()}';
    final cached = _estimateCache[key];
    if (cached != null) {
      return cached;
    }

    try {
      final customerLoc = await _routingService.geocodeAddress(customer);
      debugPrint('[Estimate] geocode customer="$customer" → $customerLoc');
      final storeLoc = await _routingService.geocodeAddress(store);
      debugPrint('[Estimate] geocode store="$store" → $storeLoc');
      
      if (customerLoc == null || storeLoc == null) {
        debugPrint('[Estimate] geocode returned null');
        return null;
      }

      // Validate coordinates
      if (customerLoc.latitude.isNaN || customerLoc.longitude.isNaN ||
          storeLoc.latitude.isNaN || storeLoc.longitude.isNaN) {
        debugPrint('[Estimate] Invalid coordinates (NaN)');
        return null;
      }

      try {
        final route = await _routingService.getRouteWithInfo(
          origin: storeLoc,
          destination: customerLoc,
          profile: 'car',
        );
        debugPrint('[Estimate] ORS route distance=${route.distance}km');

        final estimate = CustomerDeliveryEstimate(
          distanceKm: route.distance,
          durationMinutes: (route.duration / 60).round(),
        );

        _estimateCache[key] = estimate;
        return estimate;
      } catch (routingError) {
        // ORS routing failed → fallback to Haversine distance
        debugPrint('[Estimate] ORS routing failed: $routingError → using Haversine fallback');
        final haversineKm = _haversineDistance(storeLoc, customerLoc);
        // Haversine is straight-line, multiply by 1.3 to approximate road distance
        final roadDistance = haversineKm * 1.3;
        debugPrint('[Estimate] Haversine=$haversineKm km → road≈$roadDistance km');

        final estimate = CustomerDeliveryEstimate(
          distanceKm: roadDistance,
          durationMinutes: (roadDistance * 3).round(), // ~20km/h average
        );

        _estimateCache[key] = estimate;
        return estimate;
      }
    } catch (e, st) {
      debugPrint('[Estimate] ERROR: $e');
      debugPrint('[Estimate] Stack: $st');
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

      final customerLoc = LatLng(customerLatitude, customerLongitude);
      
      try {
        final route = await _routingService.getRouteWithInfo(
          origin: storeLoc,
          destination: customerLoc,
          profile: 'car',
        );

        final estimate = CustomerDeliveryEstimate(
          distanceKm: route.distance,
          durationMinutes: (route.duration / 60).round(),
        );

        _estimateCache[key] = estimate;
        return estimate;
      } catch (_) {
        // Fallback to Haversine
        final haversineKm = _haversineDistance(storeLoc, customerLoc);
        final roadDistance = haversineKm * 1.3;

        final estimate = CustomerDeliveryEstimate(
          distanceKm: roadDistance,
          durationMinutes: (roadDistance * 3).round(),
        );

        _estimateCache[key] = estimate;
        return estimate;
      }
    } catch (_) {
      return null;
    }
  }
}
