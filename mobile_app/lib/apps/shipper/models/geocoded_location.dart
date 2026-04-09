import 'package:equatable/equatable.dart';

/// Model lưu địa chỉ đã geocode (text → lat/lng)
class GeocodedLocation extends Equatable {
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId; // Google Maps place ID (cho caching)

  const GeocodedLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });

  @override
  List<Object?> get props => [address, latitude, longitude, placeId];

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'placeId': placeId,
  };

  /// Convert from JSON
  factory GeocodedLocation.fromJson(Map<String, dynamic> json) {
    return GeocodedLocation(
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      placeId: json['placeId'] as String?,
    );
  }

  /// Copy with
  GeocodedLocation copyWith({
    String? address,
    double? latitude,
    double? longitude,
    String? placeId,
  }) {
    return GeocodedLocation(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
    );
  }
}
