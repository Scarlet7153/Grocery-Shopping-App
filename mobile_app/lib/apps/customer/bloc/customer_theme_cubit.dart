import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CustomerThemePreference {
  system,
  light,
  dark,
}

class CustomerThemeState {
  final CustomerThemePreference preference;

  const CustomerThemeState({required this.preference});

  ThemeMode get themeMode {
    switch (preference) {
      case CustomerThemePreference.system:
        return ThemeMode.system;
      case CustomerThemePreference.light:
        return ThemeMode.light;
      case CustomerThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  bool get isDarkMode => preference == CustomerThemePreference.dark;

  String get displayLabel {
    switch (preference) {
      case CustomerThemePreference.system:
        return 'Theo hệ thống';
      case CustomerThemePreference.light:
        return 'Sáng';
      case CustomerThemePreference.dark:
        return 'Tối';
    }
  }
}

class CustomerThemeCubit extends Cubit<CustomerThemeState> {
  static const String _prefKey = 'customer_theme_preference';

  CustomerThemeCubit()
    : super(const CustomerThemeState(preference: CustomerThemePreference.system)) {
    _loadSavedPreference();
  }

  Future<void> setThemePreference(CustomerThemePreference preference) async {
    emit(CustomerThemeState(preference: preference));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, preference.name);
  }

  Future<void> _loadSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(_prefKey);

    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    for (final item in CustomerThemePreference.values) {
      if (item.name == rawValue) {
        emit(CustomerThemeState(preference: item));
        return;
      }
    }
  }
}
