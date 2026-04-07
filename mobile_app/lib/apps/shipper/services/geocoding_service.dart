import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';

/// Service để geocode địa chỉ text → lat/lng
/// Ưu tiên dùng native geocoding, fallback sang OpenStreetMap Nominatim
class GeocodingService {
  /// Chuyển địa chỉ text thành coordinates
  /// Dùng native APIs trước, fallback sang Nominatim nếu thất bại
  static Future<LatLng?> geocodeAddress(String address) async {
    if (address.isEmpty) {
      throw Exception('Address cannot be empty');
    }

    try {
      final placemarks = await geo.locationFromAddress(address);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return LatLng(place.latitude, place.longitude);
      }
    } catch (e) {
      debugPrint('Native geocoding failed: $e, trying Nominatim...');
    }

    return await _geocodeWithNominatim(address);
  }

  /// Fallback geocoding dùng OpenStreetMap Nominatim (không cần API key)
  static Future<LatLng?> _geocodeWithNominatim(String address) async {
    final addressVariants = _generateAddressVariants(address);

    for (final variant in addressVariants) {
      try {
        final encodedAddress = Uri.encodeComponent(variant);
        final url = 'https://nominatim.openstreetmap.org/search'
            '?q=$encodedAddress'
            '&format=json'
            '&limit=1'
            '&countrycodes=vn';

        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'GroceryShoppingApp/1.0'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          if (data.isNotEmpty) {
            final lat = double.tryParse(data[0]['lat'].toString());
            final lon = double.tryParse(data[0]['lon'].toString());
            if (lat != null && lon != null) {
              debugPrint('Geocoded "$variant" to ($lat, $lon)');
              return LatLng(lat, lon);
            }
          }
        }
      } catch (e) {
        debugPrint('Nominatim variant "$variant" failed: $e');
      }
    }

    throw Exception('Nominatim: no results for any address variant');
  }

  /// Generate multiple address variants to try with Nominatim
  static List<String> _generateAddressVariants(String address) {
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

    return variants.toSet().toList();
  }

  /// Chuyển coordinate thành địa chỉ text (reverse geocoding)
  static Future<String?> reverseGeocode(LatLng location) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) {
        return await _reverseGeocodeWithNominatim(location);
      }

      final place = placemarks.first;
      final parts = <String>[
        if (place.street?.isNotEmpty == true) place.street!,
        if (place.postalCode?.isNotEmpty == true) place.postalCode!,
        if (place.locality?.isNotEmpty == true) place.locality!,
        if (place.administrativeArea?.isNotEmpty == true)
          place.administrativeArea!,
      ];

      return parts.join(', ');
    } catch (e) {
      try {
        return await _reverseGeocodeWithNominatim(location);
      } catch (_) {
        return null;
      }
    }
  }

  static Future<String?> _reverseGeocodeWithNominatim(LatLng location) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse'
          '?lat=${location.latitude}'
          '&lon=${location.longitude}'
          '&format=json';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'GroceryShoppingApp/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Geocode multiple addresses
  static Future<Map<String, LatLng?>> geocodeMultiple(
    List<String> addresses,
  ) async {
    final results = <String, LatLng?>{};

    for (final address in addresses) {
      try {
        results[address] = await geocodeAddress(address);
      } catch (e) {
        results[address] = null;
      }
    }

    return results;
  }
}
