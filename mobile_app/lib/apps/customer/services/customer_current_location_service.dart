import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../core/auth/auth_session.dart';

enum CustomerLocationStatus {
  granted,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  failed,
}

class CustomerCurrentLocationService {
  CustomerCurrentLocationService._();

  static final CustomerCurrentLocationService instance =
      CustomerCurrentLocationService._();

  Future<CustomerLocationStatus> initializeCurrentLocation() async {
    try {
      final permissionStatus = await _ensurePermission();
      if (permissionStatus != CustomerLocationStatus.granted) {
        return permissionStatus;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return CustomerLocationStatus.serviceDisabled;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final address = await _resolveAddress(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      AuthSession.updateCurrentLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        resolvedAddress: address,
      );
      return CustomerLocationStatus.granted;
    } catch (_) {
      AuthSession.switchToCurrentLocation();
      return CustomerLocationStatus.failed;
    }
  }

  Future<CustomerLocationStatus> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return CustomerLocationStatus.permissionDenied;
    }
    if (permission == LocationPermission.deniedForever) {
      return CustomerLocationStatus.permissionDeniedForever;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return CustomerLocationStatus.granted;
    }

    return CustomerLocationStatus.permissionDenied;
  }

  Future<String?> _resolveAddress({
    required double latitude,
    required double longitude,
  }) async {
    _AddressCandidate? nativeCandidate;
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        localeIdentifier: 'vi_VN',
      );
      nativeCandidate = _buildBestNativeCandidate(placemarks);
    } catch (_) {
      // Fallback below.
    }

    final nominatimCandidate = await _reverseGeocodeWithNominatim(
      latitude: latitude,
      longitude: longitude,
    );

    final bestCandidate = _pickBetterAddress(nativeCandidate, nominatimCandidate);
    if (bestCandidate != null && bestCandidate.value.isNotEmpty) {
      return bestCandidate.value;
    }

    return _formatCoordinates(latitude, longitude);
  }

  String _formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  _AddressCandidate? _buildBestNativeCandidate(List<Placemark> placemarks) {
    if (placemarks.isEmpty) return null;

    Placemark? best;
    var bestScore = -1;

    for (final place in placemarks) {
      final score = _placemarkScore(place);
      if (score > bestScore) {
        best = place;
        bestScore = score;
      }
    }

    if (best == null || bestScore <= 0) return null;

    final parts = <String>[
      if ((best.subThoroughfare ?? '').trim().isNotEmpty)
        best.subThoroughfare!.trim(),
      if ((best.thoroughfare ?? '').trim().isNotEmpty) best.thoroughfare!.trim(),
      if ((best.subLocality ?? '').trim().isNotEmpty) best.subLocality!.trim(),
      if ((best.locality ?? '').trim().isNotEmpty) best.locality!.trim(),
      if ((best.subAdministrativeArea ?? '').trim().isNotEmpty)
        best.subAdministrativeArea!.trim(),
      if ((best.administrativeArea ?? '').trim().isNotEmpty)
        best.administrativeArea!.trim(),
      if ((best.country ?? '').trim().isNotEmpty) best.country!.trim(),
    ];

    if ((best.name ?? '').trim().isNotEmpty) {
      parts.insert(0, best.name!.trim());
    }

    final uniqueParts = <String>[];
    for (final part in parts) {
      if (!uniqueParts.contains(part)) {
        uniqueParts.add(part);
      }
    }

    if (uniqueParts.isEmpty) return null;
    return _AddressCandidate(
      value: uniqueParts.join(', '),
      score: bestScore,
      hasHouseNumber:
          (best.subThoroughfare ?? '').trim().isNotEmpty ||
          _looksLikeHouseNumber((best.name ?? '').trim()),
    );
  }

  _AddressCandidate? _pickBetterAddress(
    _AddressCandidate? nativeCandidate,
    _AddressCandidate? nominatimCandidate,
  ) {
    if (nativeCandidate == null) return nominatimCandidate;
    if (nominatimCandidate == null) return nativeCandidate;

    if (nativeCandidate.hasHouseNumber != nominatimCandidate.hasHouseNumber) {
      return nativeCandidate.hasHouseNumber
          ? nativeCandidate
          : nominatimCandidate;
    }

    if (nominatimCandidate.score > nativeCandidate.score) {
      return nominatimCandidate;
    }
    return nativeCandidate;
  }

  int _placemarkScore(Placemark place) {
    var score = 0;
    if ((place.name ?? '').trim().isNotEmpty) score += 2;
    if ((place.subThoroughfare ?? '').trim().isNotEmpty) score += 3;
    if ((place.thoroughfare ?? '').trim().isNotEmpty) score += 3;
    if ((place.street ?? '').trim().isNotEmpty) score += 2;
    if ((place.subLocality ?? '').trim().isNotEmpty) score += 2;
    if ((place.locality ?? '').trim().isNotEmpty) score += 2;
    if ((place.subAdministrativeArea ?? '').trim().isNotEmpty) score += 1;
    if ((place.administrativeArea ?? '').trim().isNotEmpty) score += 1;
    if ((place.country ?? '').trim().isNotEmpty) score += 1;
    return score;
  }

  Future<_AddressCandidate?> _reverseGeocodeWithNominatim({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$latitude'
        '&lon=$longitude'
        '&format=jsonv2'
        '&addressdetails=1'
        '&accept-language=vi'
        '&zoom=18',
      );

      final response = await http
          .get(uri, headers: {'User-Agent': 'GroceryShoppingApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;

      if (address != null) {
        final houseNumber = (address['house_number'] ?? '').toString().trim();
        final road = (address['road'] ?? '').toString().trim();
        final suburb = (address['suburb'] ?? '').toString().trim();
        final cityDistrict =
            (address['city_district'] ?? '').toString().trim();
        final city = (address['city'] ?? '').toString().trim();
        final state = (address['state'] ?? '').toString().trim();
        final country = (address['country'] ?? '').toString().trim();

        final parts = <String>[
          if (houseNumber.isNotEmpty) houseNumber,
          if (road.isNotEmpty) road,
          if (suburb.isNotEmpty) suburb,
          if (cityDistrict.isNotEmpty) cityDistrict,
          if (city.isNotEmpty) city,
          if (state.isNotEmpty) state,
          if (country.isNotEmpty) country,
        ];

        final uniqueParts = <String>[];
        for (final part in parts) {
          if (!uniqueParts.contains(part)) {
            uniqueParts.add(part);
          }
        }

        if (uniqueParts.isNotEmpty) {
          var score = 0;
          if (houseNumber.isNotEmpty) score += 6;
          if (road.isNotEmpty) score += 4;
          if (suburb.isNotEmpty) score += 2;
          if (cityDistrict.isNotEmpty) score += 2;
          if (city.isNotEmpty) score += 2;
          if (state.isNotEmpty) score += 1;
          if (country.isNotEmpty) score += 1;

          return _AddressCandidate(
            value: uniqueParts.join(', '),
            score: score,
            hasHouseNumber: houseNumber.isNotEmpty,
          );
        }
      }

      final displayName = (data['display_name'] ?? '').toString().trim();
      if (displayName.isNotEmpty) {
        return _AddressCandidate(
          value: displayName,
          score: 3,
          hasHouseNumber: _looksLikeHouseNumber(displayName),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _looksLikeHouseNumber(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final hasDigit = RegExp(r'\d').hasMatch(normalized);
    if (!hasDigit) return false;
    return normalized.contains('/') ||
        normalized.contains('-') ||
        normalized.startsWith('so') ||
        normalized.startsWith('số') ||
        RegExp(r'^\d+[a-z]?$').hasMatch(normalized);
  }
}

class _AddressCandidate {
  const _AddressCandidate({
    required this.value,
    required this.score,
    required this.hasHouseNumber,
  });

  final String value;
  final int score;
  final bool hasHouseNumber;
}
