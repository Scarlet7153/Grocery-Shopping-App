import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ShipperLanguagePreference {
  system,
  vietnamese,
  english,
}

class ShipperLanguageState {
  final ShipperLanguagePreference preference;

  const ShipperLanguageState({required this.preference});

  Locale? get locale {
    switch (preference) {
      case ShipperLanguagePreference.vietnamese:
        return const Locale('vi');
      case ShipperLanguagePreference.english:
        return const Locale('en');
      case ShipperLanguagePreference.system:
        return null;
    }
  }
}

class ShipperLanguageCubit extends Cubit<ShipperLanguageState> {
  static const String _prefKey = 'shipper_language_preference';

  ShipperLanguageCubit()
      : super(
          const ShipperLanguageState(
            preference: ShipperLanguagePreference.system,
          ),
        ) {
    _loadSavedPreference();
  }

  Future<void> setLanguagePreference(
    ShipperLanguagePreference preference,
  ) async {
    emit(ShipperLanguageState(preference: preference));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, preference.name);
  }

  Future<void> _loadSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(_prefKey);

    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    for (final item in ShipperLanguagePreference.values) {
      if (item.name == rawValue) {
        emit(ShipperLanguageState(preference: item));
        return;
      }
    }
  }
}
