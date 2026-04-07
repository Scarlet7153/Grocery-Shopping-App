import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class GraphHopperRoutingService {
  final Dio _dio;
  final String _apiKey;

  static const String _baseUrl = 'https://graphhopper.com/api/1/route';
  static const String _vrpBaseUrl = 'https://graphhopper.com/api/1/vrp';
  static const String _trackAsiaGeocodeUrl =
      'https://maps.track-asia.com/api/v2/place/textsearch/json';
  static const String _trackAsiaApiKey = '0f3c3158d0682da17755746463e57bbe0c';

  GraphHopperRoutingService({
    required String apiKey,
    Dio? dio,
  })  : _apiKey = apiKey,
        _dio = dio ?? Dio();

  Future<List<LatLng>> getRoute({
    required LatLng origin,
    required LatLng destination,
    String profile = 'foot', // foot, car, bike
  }) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'point': [
            '${origin.latitude},${origin.longitude}',
            '${destination.latitude},${destination.longitude}',
          ],
          'profile': profile,
          'locale': 'vi',
          'instructions': false,
          'calc_points': true,
          'points_encoded': false,
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final paths = data['paths'] as List<dynamic>;

        if (paths.isEmpty) {
          throw Exception('No route found');
        }

        final path = paths.first as Map<String, dynamic>;
        final points = path['points'] as Map<String, dynamic>;
        final coordinates = points['coordinates'] as List<dynamic>;

        return coordinates.map((coord) {
          final c = coord as List<dynamic>;
          return LatLng(
            c[1] as double, // lat
            c[0] as double, // lng
          );
        }).toList();
      }

      throw Exception('Failed to get route: ${response.statusCode}');
    } catch (e) {
      throw Exception('GraphHopper routing error: $e');
    }
  }

  Future<double> getDistance({
    required LatLng origin,
    required LatLng destination,
    String profile = 'foot',
  }) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'point': [
            '${origin.latitude},${origin.longitude}',
            '${destination.latitude},${destination.longitude}',
          ],
          'profile': profile,
          'instructions': false,
          'calc_points': false,
          'points_encoded': false,
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final paths = data['paths'] as List<dynamic>;

        if (paths.isEmpty) {
          throw Exception('No route found');
        }

        final path = paths.first as Map<String, dynamic>;
        return (path['distance'] as num).toDouble();
      }

      throw Exception('Failed to get distance: ${response.statusCode}');
    } catch (e) {
      throw Exception('GraphHopper distance error: $e');
    }
  }

  /// Geocode address string to LatLng using TrackAsia Geocoding API
  /// Returns null if no results found
  Future<LatLng?> geocodeAddress(String address) async {
    if (address.isEmpty) {
      throw Exception('Address cannot be empty');
    }

    final addressVariants = _generateAddressVariants(address);

    for (final variant in addressVariants) {
      try {
        final response = await _dio.get(
          _trackAsiaGeocodeUrl,
          queryParameters: {
            'query': variant,
            'key': _trackAsiaApiKey,
            'language': 'vi',
          },
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          final results = data['results'] as List<dynamic>?;

          if (results != null && results.isNotEmpty) {
            final firstResult = results.first as Map<String, dynamic>;
            final geometry = firstResult['geometry'] as Map<String, dynamic>?;
            final location = geometry?['location'] as Map<String, dynamic>?;

            if (location != null) {
              final lat = (location['lat'] as num?)?.toDouble();
              final lng = (location['lng'] as num?)?.toDouble();
              if (lat != null && lng != null) {
                debugPrint('TrackAsia geocoded "$variant" to ($lat, $lng)');
                return LatLng(lat, lng);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('TrackAsia geocode failed for "$variant": $e');
      }
    }

    throw Exception('TrackAsia geocoding: no results for $address');
  }

  List<String> _generateAddressVariants(String address) {
    final variants = <String>[];

    String normalized = address;
    normalized = normalized.replaceAll('Q1', 'Quận 1');
    normalized = normalized.replaceAll('Q2', 'Quận 2');
    normalized = normalized.replaceAll('Q3', 'Quận 3');
    normalized = normalized.replaceAll('Q4', 'Quận 4');
    normalized = normalized.replaceAll('Q5', 'Quận 5');
    normalized = normalized.replaceAll('Q6', 'Quận 6');
    normalized = normalized.replaceAll('Q7', 'Quận 7');
    normalized = normalized.replaceAll('Q8', 'Quận 8');
    normalized = normalized.replaceAll('Q9', 'Quận 9');
    normalized = normalized.replaceAll('Q10', 'Quận 10');
    normalized = normalized.replaceAll('Q11', 'Quận 11');
    normalized = normalized.replaceAll('Q12', 'Quận 12');
    normalized = normalized.replaceAll('TP.HCM', 'Hồ Chí Minh');
    normalized = normalized.replaceAll('TPHCM', 'Hồ Chí Minh');
    normalized = normalized.replaceAll('HCM', 'Hồ Chí Minh');

    variants.add(normalized);
    variants.add('$normalized, Vietnam');
    variants.add(normalized.replaceAll('Đường', '').replaceAll('đường', ''));
    variants.add(
        normalized.replaceAll('Phường', '').replaceAll('Quận', 'District'));
    variants.add('$normalized, Ho Chi Minh City, Vietnam');

    final parts = normalized.split(',').map((p) => p.trim()).toList();
    if (parts.isNotEmpty) {
      variants.add(parts.first);
      variants.add('${parts.first}, Vietnam');
    }

    variants.add(address);
    variants.add('$address, Vietnam');

    return variants.toSet().toList();
  }

  Future<RouteInfo> getRouteWithInfo({
    required LatLng origin,
    required LatLng destination,
    String profile = 'foot',
  }) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'point': [
            '${origin.latitude},${origin.longitude}',
            '${destination.latitude},${destination.longitude}',
          ],
          'profile': profile,
          'locale': 'vi',
          'instructions': true,
          'calc_points': true,
          'points_encoded': false,
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final paths = data['paths'] as List<dynamic>;

        if (paths.isEmpty) {
          throw Exception('No route found');
        }

        final path = paths.first as Map<String, dynamic>;

        final points = path['points'] as Map<String, dynamic>;
        final coordinates = points['coordinates'] as List<dynamic>;
        final routePoints = coordinates.map((coord) {
          final c = coord as List<dynamic>;
          return LatLng(c[1] as double, c[0] as double);
        }).toList();

        final instructions = path['instructions'] as List<dynamic>?;
        final routeInstructions = instructions?.map((inst) {
              final i = inst as Map<String, dynamic>;
              return RouteInstruction(
                text: i['text'] as String? ?? '',
                distance: (i['distance'] as num?)?.toDouble() ?? 0,
                time: (i['time'] as num?)?.toDouble() ?? 0,
                sign: i['sign'] as int? ?? 0,
              );
            }).toList() ??
            [];

        return RouteInfo(
          distance: (path['distance'] as num).toDouble(),
          duration: (path['time'] as num).toDouble() / 1000,
          points: routePoints,
          instructions: routeInstructions,
        );
      }

      throw Exception('Failed to get route: ${response.statusCode}');
    } catch (e) {
      throw Exception('GraphHopper routing error: $e');
    }
  }

  Future<MultiStopRouteResult> getMultiStopRoute({
    required List<LatLng> waypoints,
    List<String>? labels,
    String profile = 'car',
  }) async {
    if (waypoints.length < 2) {
      throw Exception('Need at least 2 waypoints');
    }

    try {
      final points =
          waypoints.map((p) => '${p.latitude},${p.longitude}').toList();

      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'point': points,
          'profile': profile,
          'locale': 'vi',
          'instructions': true,
          'calc_points': true,
          'points_encoded': false,
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final paths = data['paths'] as List<dynamic>;

        if (paths.isEmpty) {
          throw Exception('No route found');
        }

        final path = paths.first as Map<String, dynamic>;

        final pointsData = path['points'] as Map<String, dynamic>;
        final coordinates = pointsData['coordinates'] as List<dynamic>;
        final allPoints = coordinates.map((coord) {
          final c = coord as List<dynamic>;
          return LatLng(c[1] as double, c[0] as double);
        }).toList();

        final totalDistance = (path['distance'] as num).toDouble();
        final totalDuration = (path['time'] as num).toDouble() / 1000;

        final segments = <RouteSegment>[];

        for (int i = 0; i < waypoints.length - 1; i++) {
          final segRoute = await getRouteWithInfo(
            origin: waypoints[i],
            destination: waypoints[i + 1],
            profile: profile,
          );

          segments.add(RouteSegment(
            start: waypoints[i],
            end: waypoints[i + 1],
            distance: segRoute.distance,
            duration: segRoute.duration,
            points: segRoute.points,
            label: labels != null && (i + 1) < labels.length
                ? labels[i + 1]
                : 'Điểm dừng ${i + 1}',
          ));
        }

        return MultiStopRouteResult(
          totalDistance: totalDistance,
          totalDuration: totalDuration,
          points: allPoints,
          segments: segments,
        );
      }

      throw Exception('Failed to get multi-stop route: ${response.statusCode}');
    } catch (e) {
      throw Exception('GraphHopper multi-stop routing error: $e');
    }
  }

  /// Optimize delivery sequence using GraphHopper VRP API
  /// Returns optimized list of order IDs
  Future<VrpResult> optimizeDeliverySequence({
    required LatLng shipperLocation,
    required List<DeliveryStop> stops, // pickup + delivery stops
  }) async {
    if (stops.isEmpty) {
      throw Exception('Need at least 1 delivery stop');
    }

    try {
      // Build VRP request
      final jobs = <Map<String, dynamic>>[];
      final shipments = <Map<String, dynamic>>[];

      for (int i = 0; i < stops.length; i++) {
        final stop = stops[i];

        // Pickup job
        jobs.add({
          'id': '${stop.orderId}_pickup',
          'location': [
            stop.pickupLocation.longitude,
            stop.pickupLocation.latitude
          ],
          'service_time': stop.pickupServiceTime ?? 600, // 10 min in seconds
        });

        // Delivery job
        jobs.add({
          'id': '${stop.orderId}_delivery',
          'location': [
            stop.deliveryLocation.longitude,
            stop.deliveryLocation.latitude
          ],
          'service_time': stop.deliveryServiceTime ?? 300, // 5 min in seconds
        });

        // Shipment (link pickup to delivery)
        shipments.add({
          'id': stop.orderId.toString(),
          'pickup': {
            'location': [
              stop.pickupLocation.longitude,
              stop.pickupLocation.latitude
            ],
            'service_time': stop.pickupServiceTime ?? 600,
          },
          'delivery': {
            'location': [
              stop.deliveryLocation.longitude,
              stop.deliveryLocation.latitude
            ],
            'service_time': stop.deliveryServiceTime ?? 300,
          },
        });
      }

      // Build request
      final requestBody = {
        'vehicles': [
          {
            'vehicle_id': 'shipper_1',
            'start_address': {
              'location': [shipperLocation.longitude, shipperLocation.latitude],
            },
            'type': 'car',
            'profile': 'car',
          }
        ],
        'shipments': shipments,
        'objectives': [
          {'type': 'min', 'value': 'completion_time'} // Minimize time
        ],
        'configuration': {
          'routing': {'calc_points': true},
        },
      };

      final response = await _dio.post(
        _vrpBaseUrl,
        queryParameters: {'key': _apiKey},
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;

        if (routes == null || routes.isEmpty) {
          throw Exception('No solution found');
        }

        final route = routes.first as Map<String, dynamic>;
        final activities = route['activities'] as List<dynamic>?;

        if (activities == null || activities.isEmpty) {
          throw Exception('No activities in route');
        }

        // Extract optimized order sequence
        final orderedStopIds = <int>[];
        for (final activity in activities) {
          final act = activity as Map<String, dynamic>;
          final shipmentId = act['id'] as String?;

          if (shipmentId != null && shipmentId.isNotEmpty) {
            try {
              final orderId = int.parse(shipmentId);
              if (!orderedStopIds.contains(orderId)) {
                orderedStopIds.add(orderId);
              }
            } catch (e) {
              // Skip if not parseable
            }
          }
        }

        final distance = (route['distance'] as num?)?.toDouble() ?? 0;
        final time = (route['time'] as num?)?.toDouble() ?? 0;

        return VrpResult(
          optimizedOrderIds: orderedStopIds,
          totalDistance: distance / 1000, // Convert to km
          totalTime: time / 1000, // Convert to seconds
          solution: route,
        );
      } else if (response.statusCode == 400) {
        throw Exception('Invalid VRP request: ${response.data}');
      } else {
        throw Exception('Failed to optimize: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('GraphHopper VRP optimization error: $e');
    }
  }
}

class RouteInfo {
  final double distance; // in meters
  final double duration; // in seconds
  final List<LatLng> points;
  final List<RouteInstruction> instructions;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.points,
    this.instructions = const [],
  });

  double get distanceKm => distance / 1000;

  int get durationMinutes => (duration / 60).ceil();
}

class RouteInstruction {
  final String text;
  final double distance;
  final double time;
  final int sign;

  RouteInstruction({
    required this.text,
    required this.distance,
    required this.time,
    required this.sign,
  });
}

class MultiStopRouteResult {
  final double totalDistance;
  final double totalDuration;
  final List<LatLng> points;
  final List<RouteSegment> segments;

  MultiStopRouteResult({
    required this.totalDistance,
    required this.totalDuration,
    required this.points,
    required this.segments,
  });

  double get totalDistanceKm => totalDistance / 1000;
  int get totalDurationMinutes => (totalDuration / 60).ceil();
}

class RouteSegment {
  final LatLng start;
  final LatLng end;
  final double distance;
  final double duration;
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

  double get distanceKm => distance / 1000;
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
  final Map<String, dynamic> solution; // Full GraphHopper solution

  VrpResult({
    required this.optimizedOrderIds,
    required this.totalDistance,
    required this.totalTime,
    required this.solution,
  });
}
