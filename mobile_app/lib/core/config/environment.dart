import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String get baseUrl {
    final envUrl = dotenv.env['BASE_URL'];
    final portValue = dotenv.env['PORT'];
    final apiPath = dotenv.env['API_PATH']?.trim() ?? '/api';

    if (envUrl == null || envUrl.isEmpty) {
      throw StateError('BASE_URL is not set in .env. Please add BASE_URL=http://<host> and PORT=8080');
    }

    final uri = Uri.parse(envUrl.trim());
    if (uri.scheme.isEmpty || uri.host.isEmpty) {
      throw StateError('BASE_URL must include scheme and host, for example: http://192.168.36.65');
    }

    final resolvedPort = portValue != null && portValue.isNotEmpty
        ? int.tryParse(portValue.trim())
        : (uri.hasPort ? uri.port : null);

    if (portValue != null && portValue.isNotEmpty && resolvedPort == null) {
      throw StateError('PORT must be a valid integer. Example: PORT=8080');
    }

    final path = uri.path.isEmpty || uri.path == '/' ? apiPath : uri.path;

    return uri.replace(port: resolvedPort, path: path).toString();
  }

  static bool get isDevelopment =>
      dotenv.env['ENVIRONMENT']?.toLowerCase() == 'development';

  static bool get enableLogging =>
      (dotenv.env['ENABLE_LOGGING'] ?? 'true').toLowerCase() == 'true';
}
