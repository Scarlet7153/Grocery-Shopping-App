import 'package:latlong2/latlong.dart';
import 'package:collection/collection.dart';
import '../models/shipper_order.dart';
import '../../../core/config/routing_service.dart';
import 'geocoding_service.dart';

/// Service để optimize delivery route cho multiple orders
class OrderOptimizationService {
  final RoutingService _routingService;

  OrderOptimizationService({required RoutingService routingService})
    : _routingService = routingService;

  /// Optimize sequence của multiple orders
  /// Input: list orders + current shipper location
  /// Output: optimized order sequence + route info
  Future<OptimizationResult> optimizeOrders({
    required List<ShipperOrder> orders,
    required LatLng shipperLocation,
    String? storeAddress, // Store/warehouse address for pickup
  }) async {
    if (orders.isEmpty) {
      throw Exception('No orders to optimize');
    }

    try {
      // 1. Geocode all delivery addresses
      final geocodedLocations = <int, LatLng>{};
      for (final order in orders) {
        try {
          final lat = await GeocodingService.geocodeAddress(
            order.deliveryAddress,
          );
          if (lat != null) {
            geocodedLocations[order.id] = lat;
          }
        } catch (e) {
          throw Exception(
            'Failed to geocode order ${order.id} (${order.deliveryAddress}): $e',
          );
        }
      }

      // 2. Get store location (if provided)
      LatLng? storeLocation;
      if (storeAddress != null && storeAddress.isNotEmpty) {
        try {
          storeLocation = await GeocodingService.geocodeAddress(storeAddress);
        } catch (e) {
          // Warn but continue - store location optional
          // Note: Could not geocode store address: $e
        }
      }

      // 3. Build delivery stops for VRP
      final stops = <DeliveryStop>[];

      for (final order in orders) {
        final deliveryLat = geocodedLocations[order.id];
        if (deliveryLat == null) continue;

        // Pickup at store (or shipper location if no store)
        final pickupLoc = storeLocation ?? shipperLocation;

        stops.add(
          DeliveryStop(
            orderId: order.id,
            pickupLocation: pickupLoc,
            deliveryLocation: deliveryLat,
            pickupServiceTime: 600, // 10 minutes
            deliveryServiceTime: 300, // 5 minutes
          ),
        );
      }

      if (stops.isEmpty) {
        throw Exception('No valid delivery stops after geocoding');
      }

      // 4. Call GraphHopper VRP API
      final vrpResult = await _routingService.optimizeDeliverySequence(
        shipperLocation: shipperLocation,
        stops: stops,
      );

      // 5. Map optimized order IDs back to order objects
      final optimizedOrders = <ShipperOrder>[];
      for (final orderId in vrpResult.optimizedOrderIds) {
        final order = orders.firstWhereOrNull((o) => o.id == orderId);
        if (order != null) {
          optimizedOrders.add(order);
        }
      }

      return OptimizationResult(
        optimizedOrders: optimizedOrders,
        totalDistance: vrpResult.totalDistance,
        totalTime: vrpResult.totalTime,
        geocodedLocations: geocodedLocations,
      );
    } catch (e) {
      throw Exception('Order optimization failed: $e');
    }
  }
}

/// Result từ order optimization
class OptimizationResult {
  final List<ShipperOrder> optimizedOrders; // Ordered by sequence
  final double totalDistance; // km
  final double totalTime; // seconds
  final Map<int, LatLng> geocodedLocations; // order_id → LatLng cache

  OptimizationResult({
    required this.optimizedOrders,
    required this.totalDistance,
    required this.totalTime,
    required this.geocodedLocations,
  });

  int get estimatedTimeMinutes => (totalTime / 60).ceil();
}
