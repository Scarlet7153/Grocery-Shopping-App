import 'package:dio/dio.dart';

import '../../../core/location/province_api.dart';

class ProvinceApiV2 {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://provinces.open-api.vn/api/v2',
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

  Future<List<LocationItem>> getWardsByProvince(int provinceCode) async {
    final response = await _dio.get('/p/$provinceCode?depth=2');
    final data = response.data;

    if (data is! Map || data['wards'] is! List) {
      return [];
    }

    final wards = <LocationItem>[];
    final seenCodes = <int>{};

    for (final ward in data['wards'] as List<dynamic>) {
      if (ward is! Map<String, dynamic>) continue;
      final item = LocationItem.fromJson(ward);
      if (seenCodes.add(item.code)) {
        wards.add(item);
      }
    }

    wards.sort((a, b) => a.name.compareTo(b.name));
    return wards;
  }
}

