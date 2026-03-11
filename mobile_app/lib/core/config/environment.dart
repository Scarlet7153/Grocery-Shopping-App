class Environment {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8080', // Android emulator
    // defaultValue: 'http://localhost:8080', // iOS simulator
    // defaultValue: 'https://api.groceryapp.com', // Production
  );

  static const bool isDevelopment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  ) == 'development';

  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );
}