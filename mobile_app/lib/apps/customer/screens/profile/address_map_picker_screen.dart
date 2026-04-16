import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../utils/customer_l10n.dart';

class AddressMapPickerScreen extends StatefulWidget {
  const AddressMapPickerScreen({super.key});

  @override
  State<AddressMapPickerScreen> createState() => _AddressMapPickerScreenState();
}

class _AddressMapPickerScreenState extends State<AddressMapPickerScreen> {
  static const LatLng _defaultCenter = LatLng(10.762622, 106.660172);

  final MapController _mapController = MapController();

  LatLng _center = _defaultCenter;
  String _resolvedAddress = '';
  bool _loadingAddress = true;
  bool _requestingLocation = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _initCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      final current = LatLng(position.latitude, position.longitude);
      setState(() {
        _center = current;
        _requestingLocation = false;
      });
      _mapController.move(current, 17);
      await _resolveAddress(current);
    } catch (_) {
      if (!mounted) return;
      setState(() => _requestingLocation = false);
      await _resolveAddress(_center);
    }
  }

  void _onMapMoved(MapPosition position, bool hasGesture) {
    final center = position.center;
    if (center == null) return;
    _center = center;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _resolveAddress(_center);
    });
  }

  Future<void> _resolveAddress(LatLng point) async {
    if (!mounted) return;
    setState(() => _loadingAddress = true);

    final native = await _reverseByNative(point);
    final nominatim = await _reverseByNominatim(point);
    final best = _pickBetter(native, nominatim);

    if (!mounted) return;
    setState(() {
      _resolvedAddress = best ?? _formatCoordinates(point);
      _loadingAddress = false;
    });
  }

  Future<_AddressCandidate?> _reverseByNative(LatLng point) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
        localeIdentifier: 'vi_VN',
      );
      if (placemarks.isEmpty) return null;

      Placemark? best;
      var bestScore = -1;
      for (final place in placemarks) {
        final score = _nativeScore(place);
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

      final compact = <String>[];
      for (final part in parts) {
        if (!compact.contains(part)) compact.add(part);
      }
      if (compact.isEmpty) return null;

      final text = compact.join(', ');
      return _AddressCandidate(
        value: text,
        score: bestScore,
        hasHouseNumber:
            (best.subThoroughfare ?? '').trim().isNotEmpty ||
            _looksLikeHouseNumber((best.name ?? '').trim()),
      );
    } catch (_) {
      return null;
    }
  }

  int _nativeScore(Placemark place) {
    var score = 0;
    if ((place.name ?? '').trim().isNotEmpty) score += 2;
    if ((place.subThoroughfare ?? '').trim().isNotEmpty) score += 4;
    if ((place.thoroughfare ?? '').trim().isNotEmpty) score += 3;
    if ((place.street ?? '').trim().isNotEmpty) score += 2;
    if ((place.subLocality ?? '').trim().isNotEmpty) score += 2;
    if ((place.locality ?? '').trim().isNotEmpty) score += 2;
    if ((place.subAdministrativeArea ?? '').trim().isNotEmpty) score += 1;
    if ((place.administrativeArea ?? '').trim().isNotEmpty) score += 1;
    if ((place.country ?? '').trim().isNotEmpty) score += 1;
    return score;
  }

  Future<_AddressCandidate?> _reverseByNominatim(LatLng point) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${point.latitude}'
        '&lon=${point.longitude}'
        '&format=jsonv2'
        '&addressdetails=1'
        '&accept-language=vi'
        '&zoom=18',
      );

      final response = await http
          .get(uri, headers: {'User-Agent': 'GroceryShoppingApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

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

        final compact = <String>[];
        for (final part in parts) {
          if (!compact.contains(part)) compact.add(part);
        }

        if (compact.isNotEmpty) {
          var score = 0;
          if (houseNumber.isNotEmpty) score += 6;
          if (road.isNotEmpty) score += 4;
          if (suburb.isNotEmpty) score += 2;
          if (cityDistrict.isNotEmpty) score += 2;
          if (city.isNotEmpty) score += 2;
          if (state.isNotEmpty) score += 1;
          if (country.isNotEmpty) score += 1;

          return _AddressCandidate(
            value: compact.join(', '),
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

  String? _pickBetter(_AddressCandidate? native, _AddressCandidate? nominatim) {
    if (native == null && nominatim == null) return null;
    if (native == null) return nominatim!.value;
    if (nominatim == null) return native.value;

    if (native.hasHouseNumber != nominatim.hasHouseNumber) {
      return native.hasHouseNumber ? native.value : nominatim.value;
    }
    return nominatim.score > native.score ? nominatim.value : native.value;
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

  String _formatCoordinates(LatLng point) {
    return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(vi: 'Chọn địa chỉ', en: 'Pick address'))),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 16,
                    minZoom: 5,
                    maxZoom: 19,
                    onPositionChanged: _onMapMoved,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.grocery.shopping_app',
                    ),
                  ],
                ),
                IgnorePointer(
                  child: Center(
                    child: Icon(
                      Icons.location_pin,
                      size: 54,
                      color: scheme.primary,
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'address_map_my_location',
                    onPressed: _requestingLocation ? null : _initCurrentLocation,
                    child: _requestingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(vi: 'Địa chỉ gợi ý', en: 'Suggested address'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.place_outlined, color: scheme.primary),
                  title: _loadingAddress
                      ? Text(context.tr(vi: 'Đang tải địa chỉ...', en: 'Loading address...'))
                      : Text(
                          _resolvedAddress,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                  subtitle: Text(
                    _formatCoordinates(_center),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadingAddress
                        ? null
                        : () => Navigator.of(context).pop(
                            AddressMapPickerResult(
                              address: _resolvedAddress,
                              latitude: _center.latitude,
                              longitude: _center.longitude,
                            ),
                          ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(context.tr(vi: 'Dùng địa chỉ này', en: 'Use this address')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddressMapPickerResult {
  const AddressMapPickerResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;
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
