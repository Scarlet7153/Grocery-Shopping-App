import 'package:dio/dio.dart';

class LocationItem {
  final int code;
  final String name;

  LocationItem({required this.code, required this.name});

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(
      code: (json['code'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
    );
  }
}

class ProvinceApi {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://provinces.open-api.vn/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<LocationItem>> getProvinces() async {
    final response = await _dio.get('/?depth=1');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(LocationItem.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<LocationItem>> getDistricts(int provinceCode) async {
    final response = await _dio.get('/p/$provinceCode?depth=2');
    final data = response.data;
    if (data is Map && data['districts'] is List) {
      return (data['districts'] as List)
          .whereType<Map<String, dynamic>>()
          .map(LocationItem.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<LocationItem>> getWards(int districtCode) async {
    final response = await _dio.get('/d/$districtCode?depth=2');
    final data = response.data;
    if (data is Map && data['wards'] is List) {
      return (data['wards'] as List)
          .whereType<Map<String, dynamic>>()
          .map(LocationItem.fromJson)
          .toList();
    }
    return [];
  }
}
