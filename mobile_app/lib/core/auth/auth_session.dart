import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  static const String _tokenKey = 'customer_auth_token';
  static SharedPreferences? _prefs;

  static String? token;
  static String? fullName;
  static String? address;
  static String? phoneNumber;
  static String? avatarUrl;
  static bool useCurrentLocation = true;
  static double? currentLatitude;
  static double? currentLongitude;
  static String? currentLocationAddress;
  static double? manualLatitude;
  static double? manualLongitude;
  static List<Map<String, dynamic>> savedAddresses = [];
  static int selectedAddressIndex = 0;
  static bool defaultHasOtherReceiver = false;
  static String? defaultOtherReceiverName;
  static String? defaultOtherReceiverPhone;
  static String? defaultOtherReceiverTitle;

  static Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> restore() async {
    await _ensurePrefs();
    token = _prefs!.getString(_tokenKey);
  }

  static Future<void> persistToken(String jwt) async {
    await _ensurePrefs();
    token = jwt;
    await _prefs!.setString(_tokenKey, jwt);
  }

  static Future<void> clearPersistedToken() async {
    await _ensurePrefs();
    await _prefs!.remove(_tokenKey);
  }

  static bool get hasCurrentCoordinates =>
      currentLatitude != null && currentLongitude != null;

  static String? get effectiveAddress {
    if (useCurrentLocation) {
      return currentLocationAddress ?? address;
    }
    return address;
  }

  static String get displayLocation {
    if (useCurrentLocation) {
      final current = currentLocationAddress;
      if (current == null || current.trim().isEmpty) {
        return 'Đang dùng vị trí hiện tại';
      }
      return current;
    }

    final manual = address;
    if (manual == null || manual.trim().isEmpty) {
      return 'Chưa có địa chỉ';
    }
    return manual;
  }

  static double? get selectedLatitude =>
      useCurrentLocation ? currentLatitude : manualLatitude;

  static double? get selectedLongitude =>
      useCurrentLocation ? currentLongitude : manualLongitude;

  static void updateCurrentLocation({
    required double latitude,
    required double longitude,
    String? resolvedAddress,
  }) {
    currentLatitude = latitude;
    currentLongitude = longitude;
    if (resolvedAddress != null && resolvedAddress.trim().isNotEmpty) {
      currentLocationAddress = resolvedAddress.trim();
    }
    useCurrentLocation = true;
  }

  static void setManualAddress(String? value) {
    address = value;
    useCurrentLocation = false;
    manualLatitude = null;
    manualLongitude = null;
  }

  static void setManualAddressWithCoordinates({
    required String? value,
    required double latitude,
    required double longitude,
  }) {
    address = value;
    useCurrentLocation = false;
    manualLatitude = latitude;
    manualLongitude = longitude;
  }

  static void switchToCurrentLocation() {
    useCurrentLocation = true;
  }

  static void clear() {
    token = null;
    fullName = null;
    address = null;
    phoneNumber = null;
    avatarUrl = null;
    useCurrentLocation = true;
    currentLatitude = null;
    currentLongitude = null;
    currentLocationAddress = null;
    manualLatitude = null;
    manualLongitude = null;
    savedAddresses = [];
    selectedAddressIndex = 0;
    defaultHasOtherReceiver = false;
    defaultOtherReceiverName = null;
    defaultOtherReceiverPhone = null;
    defaultOtherReceiverTitle = null;
  }
}
