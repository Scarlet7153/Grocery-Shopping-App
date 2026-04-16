import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CustomerLanguagePreference {
  system,
  vietnamese,
  english,
}

class CustomerLanguageState {
  const CustomerLanguageState({required this.preference});

  final CustomerLanguagePreference preference;

  Locale? get locale {
    switch (preference) {
      case CustomerLanguagePreference.vietnamese:
        return const Locale('vi');
      case CustomerLanguagePreference.english:
        return const Locale('en');
      case CustomerLanguagePreference.system:
        return null;
    }
  }
}

class CustomerLanguageCubit extends Cubit<CustomerLanguageState> {
  CustomerLanguageCubit()
      : super(
          const CustomerLanguageState(
            preference: CustomerLanguagePreference.system,
          ),
        ) {
    _loadSavedPreference();
  }

  static const String _prefKey = 'customer_language_preference';

  Future<void> setLanguagePreference(
    CustomerLanguagePreference preference,
  ) async {
    emit(CustomerLanguageState(preference: preference));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, preference.name);
  }

  Future<void> _loadSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(_prefKey);
    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    for (final value in CustomerLanguagePreference.values) {
      if (value.name == rawValue) {
        emit(CustomerLanguageState(preference: value));
        return;
      }
    }
  }
}
