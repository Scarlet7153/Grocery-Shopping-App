import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'package:grocery_shopping_app/core/config/environment.dart';
import 'package:grocery_shopping_app/core/config/routing_service.dart';

/// GraphHopper Routing Service Implementation
class GraphHopperRoutingService implements RoutingService {
  late final Dio _dio;
  final String _apiKey;

  String get _baseUrl => Environment.graphHopperBaseUrl;
  String get _vrpBaseUrl => Environment.graphHopperVrpUrl;
  String get _trackAsiaGeocodeUrl => Environment.trackAsiaGeocodeUrl;
  String get _trackAsiaApiKey => Environment.trackAsiaApiKey;

  GraphHopperRoutingService({String? apiKey, Dio? dio})
      : _apiKey = apiKey ?? Environment.graphHopperApiKey {
    _dio = dio ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
  }

  @override
  Future<List<LatLng>> getRoute({
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
          'instructions': false,
          'calc_points': true,
          'points_encoded': false,
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final paths = data['paths'] as List<dynamic>;
        if (paths.isEmpty) throw Exception('No route found');

        final path = paths.first as Map<String, dynamic>;
        final points = path['points'] as Map<String, dynamic>;
        final coordinates = points['coordinates'] as List<dynamic>;

        return coordinates.map((coord) {
          final c = coord as List<dynamic>;
          return LatLng(c[1] as double, c[0] as double);
        }).toList();
      }
      throw Exception('Failed to get route: ${response.statusCode}');
    } catch (e) {
      throw Exception('GraphHopper routing error: $e');
    }
  }

  @override
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
        if (paths.isEmpty) throw Exception('No route found');

        final path = paths.first as Map<String, dynamic>;
        return (path['distance'] as num).toDouble() / 1000;
      }
      throw Exception('Failed to get distance: ${response.statusCode}');
    } catch (e) {
      throw Exception('GraphHopper distance error: $e');
    }
  }

  @override
  Future<LatLng?> geocodeAddress(String address) async {
    if (address.isEmpty) throw Exception('Address cannot be empty');

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
        if (paths.isEmpty) throw Exception('No route found');

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
                distance: ((i['distance'] as num?)?.toDouble() ?? 0) / 1000,
                time: (i['time'] as num?)?.toDouble() ?? 0,
                sign: i['sign'] as int? ?? 0,
              );
            }).toList() ??
            [];

        return RouteInfo(
          distance: (path['distance'] as num).toDouble() / 1000,
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

  @override
  Future<MultiStopRouteResult> getMultiStopRoute({
    required List<LatLng> waypoints,
    List<String>? labels,
    String profile = 'car',
  }) async {
    if (waypoints.length < 2) throw Exception('Need at least 2 waypoints');

    try {
      final points = waypoints.map((p) => '${p.latitude},${p.longitude}').toList();
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
        if (paths.isEmpty) throw Exception('No route found');

        final path = paths.first as Map<String, dynamic>;
        final pointsData = path['points'] as Map<String, dynamic>;
        final coordinates = pointsData['coordinates'] as List<dynamic>;
        final allPoints = coordinates.map((coord) {
          final c = coord as List<dynamic>;
          return LatLng(c[1] as double, c[0] as double);
        }).toList();

        final totalDistance = (path['distance'] as num).toDouble() / 1000;
        final totalDuration = (path['time'] as num).toDouble() / 1000;

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
      throw Exception('Failed to get multi-stop route: ${response.statusCode}');
    } catch (e) {
      throw Exception('GraphHopper multi-stop routing error: $e');
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
          'id': stop.orderId.toString(),
          'pickup': {
            'location': [
              stop.pickupLocation.longitude,
              stop.pickupLocation.latitude,
            ],
            'service_time': stop.pickupServiceTime ?? 600,
          },
          'delivery': {
            'location': [
              stop.deliveryLocation.longitude,
              stop.deliveryLocation.latitude,
            ],
            'service_time': stop.deliveryServiceTime ?? 300,
          },
        });
      }

      final requestBody = {
        'vehicles': [
          {
            'vehicle_id': 'shipper_1',
            'start_address': {
              'location': [shipperLocation.longitude, shipperLocation.latitude],
            },
            'type': 'car',
            'profile': 'car',
          },
        ],
        'shipments': shipments,
        'objectives': [
          {'type': 'min', 'value': 'completion_time'},
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
        if (routes == null || routes.isEmpty) throw Exception('No solution found');

        final route = routes.first as Map<String, dynamic>;
        final activities = route['activities'] as List<dynamic>?;
        if (activities == null || activities.isEmpty) {
          throw Exception('No activities in route');
        }

        final orderedStopIds = <int>[];
        for (final activity in activities) {
          final act = activity as Map<String, dynamic>;
          final shipmentId = act['id'] as String?;
          if (shipmentId != null && shipmentId.isNotEmpty) {
            try {
              final orderId = int.parse(shipmentId);
              if (!orderedStopIds.contains(orderId)) orderedStopIds.add(orderId);
            } catch (_) {}
          }
        }

        final distance = (route['distance'] as num?)?.toDouble() ?? 0;
        final time = (route['time'] as num?)?.toDouble() ?? 0;

        return VrpResult(
          optimizedOrderIds: orderedStopIds,
          totalDistance: distance / 1000,
          totalTime: time / 1000,
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
