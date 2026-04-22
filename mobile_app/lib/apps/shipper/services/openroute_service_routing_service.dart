import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'package:grocery_shopping_app/core/config/environment.dart';
import 'package:grocery_shopping_app/core/config/routing_service.dart';

/// OpenRouteService (ORS) Routing Service Implementation
/// Docs: https://openrouteservice.org/dev/#/api-docs
class OpenRouteServiceRoutingService implements RoutingService {
  late final Dio _dio;
  final String _apiKey;

  static const String _orsBaseUrl = 'https://api.openrouteservice.org';

  OpenRouteServiceRoutingService({String? apiKey, Dio? dio})
      : _apiKey = apiKey ?? Environment.openRouteServiceApiKey {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: _orsBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Authorization': _apiKey,
              'Content-Type': 'application/json; charset=utf-8',
            },
          ),
        );
  }

  /// Map GraphHopper profile names -> ORS profile names
  String _mapProfile(String profile) {
    switch (profile.toLowerCase()) {
      case 'car':
      case 'driving-car':
        return 'driving-car';
      case 'foot':
      case 'walking':
      case 'foot-walking':
        return 'foot-walking';
      case 'bike':
      case 'cycling':
      case 'cycling-regular':
        return 'cycling-regular';
      default:
        return 'driving-car';
    }
  }

  /// Chuyển LatLng sang ORS coordinate format [lng, lat]
  List<double> _toCoord(LatLng p) => [p.longitude, p.latitude];

  /// Chuyển ORS coordinate [lng, lat] sang LatLng
  LatLng _fromCoord(List<dynamic> c) => LatLng(c[1] as double, c[0] as double);

  @override
  Future<List<LatLng>> getRoute({
    required LatLng origin,
    required LatLng destination,
    String profile = 'foot',
  }) async {
    try {
      final response = await _dio.post(
        '/v2/directions/${_mapProfile(profile)}/geojson',
        data: {
          'coordinates': [_toCoord(origin), _toCoord(destination)],
          'instructions': false,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>;
        if (features.isEmpty) throw Exception('No route found');

        final geometry = features.first['geometry'] as Map<String, dynamic>;
        final coordinates = geometry['coordinates'] as List<dynamic>;

        return coordinates.map((c) => _fromCoord(c as List<dynamic>)).toList();
      }
      throw Exception('ORS route failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('OpenRouteService routing error: $e');
    }
  }

  @override
  Future<double> getDistance({
    required LatLng origin,
    required LatLng destination,
    String profile = 'foot',
  }) async {
    try {
      final response = await _dio.post(
        '/v2/directions/${_mapProfile(profile)}/geojson',
        data: {
          'coordinates': [_toCoord(origin), _toCoord(destination)],
          'instructions': false,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>;
        if (features.isEmpty) throw Exception('No route found');

        final props = features.first['properties'] as Map<String, dynamic>;
        final summary = props['summary'] as Map<String, dynamic>;
        return (summary['distance'] as num).toDouble() / 1000;
      }
      throw Exception('ORS distance failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('OpenRouteService distance error: $e');
    }
  }

  @override
  Future<LatLng?> geocodeAddress(String address) async {
    if (address.isEmpty) throw Exception('Address cannot be empty');

    final variants = _generateAddressVariants(address);
    for (final variant in variants) {
      try {
        final response = await _dio.get(
          '/geocode/search',
          queryParameters: {
            'api_key': _apiKey,
            'text': variant,
            'size': 1,
          },
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          final features = data['features'] as List<dynamic>?;
          if (features != null && features.isNotEmpty) {
            final coords = (features.first['geometry']['coordinates'] as List<dynamic>)
                .map((c) => (c as num).toDouble())
                .toList();
            if (coords.length >= 2) {
              debugPrint('ORS geocoded "$variant" to (${coords[1]}, ${coords[0]})');
              return LatLng(coords[1], coords[0]);
            }
          }
        }
      } catch (e) {
        debugPrint('ORS geocode failed for "$variant": $e');
      }
    }
    throw Exception('ORS geocoding: no results for $address');
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
      normalized.replaceAll('Phường', '').replaceAll('Quận', 'District'),
    );
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

  @override
  Future<RouteInfo> getRouteWithInfo({
    required LatLng origin,
    required LatLng destination,
    String profile = 'foot',
  }) async {
    // Validate coordinates
    if (origin.latitude.isNaN || origin.longitude.isNaN ||
        destination.latitude.isNaN || destination.longitude.isNaN) {
      throw Exception('Invalid coordinates: origin=$origin, destination=$destination');
    }
    if (origin.latitude < -90 || origin.latitude > 90 ||
        origin.longitude < -180 || origin.longitude > 180 ||
        destination.latitude < -90 || destination.latitude > 90 ||
        destination.longitude < -180 || destination.longitude > 180) {
      throw Exception('Coordinates out of range: origin=$origin, destination=$destination');
    }

    final requestBody = {
      'coordinates': [_toCoord(origin), _toCoord(destination)],
      'instructions': true,
      'language': 'vi',
    };
    debugPrint('[ORS] getRouteWithInfo request: $requestBody');

    try {
      final response = await _dio.post(
        '/v2/directions/${_mapProfile(profile)}/geojson',
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>;
        if (features.isEmpty) throw Exception('No route found');

        final feature = features.first as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>;
        final coordinates = geometry['coordinates'] as List<dynamic>;
        final routePoints = coordinates.map((c) => _fromCoord(c as List<dynamic>)).toList();

        final props = feature['properties'] as Map<String, dynamic>;
        final summary = props['summary'] as Map<String, dynamic>;
        final segments = props['segments'] as List<dynamic>?;

        final instructions = <RouteInstruction>[];
        if (segments != null && segments.isNotEmpty) {
          final seg = segments.first as Map<String, dynamic>;
          final steps = seg['steps'] as List<dynamic>?;
          if (steps != null) {
            for (final step in steps) {
              final s = step as Map<String, dynamic>;
              instructions.add(RouteInstruction(
                text: s['instruction'] as String? ?? '',
                distance: ((s['distance'] as num?)?.toDouble() ?? 0) / 1000,
                time: ((s['duration'] as num?)?.toDouble() ?? 0),
                sign: (s['type'] as num?)?.toInt() ?? 0,
              ));
            }
          }
        }

        return RouteInfo(
          distance: (summary['distance'] as num).toDouble() / 1000,
          duration: (summary['duration'] as num).toDouble(),
          points: routePoints,
          instructions: instructions,
        );
      }
      throw Exception('ORS route info failed: ${response.statusCode}');
    } on DioException catch (e) {
      final reqData = e.requestOptions.data;
      final respData = e.response?.data;
      debugPrint('[ORS] getRouteWithInfo ERROR status=${e.response?.statusCode}');
      debugPrint('[ORS] Request body: $reqData');
      debugPrint('[ORS] Response body: $respData');
      throw Exception('OpenRouteService routing error: ${e.response?.statusCode} - $respData');
    } catch (e) {
      throw Exception('OpenRouteService routing error: $e');
    }
  }

  @override
  Future<MultiStopRouteResult> getMultiStopRoute({
    required List<LatLng> waypoints,
    List<String>? labels,
    String profile = 'car',
  }) async {
    if (waypoints.length < 2) throw Exception('Need at least 2 waypoints');

    try {
      final coordinates = waypoints.map((p) => _toCoord(p)).toList();
      final response = await _dio.post(
        '/v2/directions/${_mapProfile(profile)}/geojson',
        data: {
          'coordinates': coordinates,
          'instructions': true,
          'language': 'vi',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>;
        if (features.isEmpty) throw Exception('No route found');

        final feature = features.first as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>;
        final coords = geometry['coordinates'] as List<dynamic>;
        final allPoints = coords.map((c) => _fromCoord(c as List<dynamic>)).toList();

        final props = feature['properties'] as Map<String, dynamic>;
        final summary = props['summary'] as Map<String, dynamic>;
        final totalDistance = (summary['distance'] as num).toDouble() / 1000;
        final totalDuration = (summary['duration'] as num).toDouble();

        // ORS trả về 1 route tổng hợp, không tách segments theo waypoint.
        // Ta tính segments bằng cách gọi getRouteWithInfo từng chặng.
        final segments = <RouteSegment>[];
        for (int i = 0; i < waypoints.length - 1; i++) {
          final segRoute = await getRouteWithInfo(
            origin: waypoints[i],
            destination: waypoints[i + 1],
            profile: profile,
          );
          segments.add(
            RouteSegment(
              start: waypoints[i],
              end: waypoints[i + 1],
              distance: segRoute.distance,
              duration: segRoute.duration,
              points: segRoute.points,
              label: labels != null && (i + 1) < labels.length
                  ? labels[i + 1]
                  : 'Điểm dừng ${i + 1}',
            ),
          );
        }

        return MultiStopRouteResult(
          totalDistance: totalDistance,
          totalDuration: totalDuration,
          points: allPoints,
          segments: segments,
        );
      }
      throw Exception('ORS multi-stop route failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('OpenRouteService multi-stop routing error: $e');
    }
  }

  @override
  Future<VrpResult> optimizeDeliverySequence({
    required LatLng shipperLocation,
    required List<DeliveryStop> stops,
  }) async {
    if (stops.isEmpty) throw Exception('Need at least 1 delivery stop');

    try {
      final shipments = <Map<String, dynamic>>[];
      for (final stop in stops) {
        shipments.add({
          'id': stop.orderId,
          'amount': [1],
          'pickup': {
            'location': _toCoord(stop.pickupLocation),
            'service': stop.pickupServiceTime ?? 600,
          },
          'delivery': {
            'location': _toCoord(stop.deliveryLocation),
            'service': stop.deliveryServiceTime ?? 300,
          },
        });
      }

      final requestBody = {
        'vehicles': [
          {
            'id': 0,
            'profile': 'driving-car',
            'start': _toCoord(shipperLocation),
          },
        ],
        'shipments': shipments,
      };

      final response = await _dio.post(
        '/optimization',
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes == null || routes.isEmpty) throw Exception('No solution found');

        final route = routes.first as Map<String, dynamic>;
        final steps = route['steps'] as List<dynamic>?;
        if (steps == null || steps.isEmpty) {
          throw Exception('No steps in optimized route');
        }

        final orderedStopIds = <int>[];
        for (final step in steps) {
          final s = step as Map<String, dynamic>;
          final type = s['type'] as String?;
          final shipmentId = s['id'] as int?;
          if ((type == 'pickup' || type == 'delivery') &&
              shipmentId != null &&
              !orderedStopIds.contains(shipmentId)) {
            orderedStopIds.add(shipmentId);
          }
        }

        return VrpResult(
          optimizedOrderIds: orderedStopIds,
          totalDistance: ((route['distance'] as num?)?.toDouble() ?? 0) / 1000,
          totalTime: (route['duration'] as num?)?.toDouble() ?? 0,
          solution: route,
        );
      }
      throw Exception('ORS optimization failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('OpenRouteService VRP optimization error: $e');
    }
  }
}
