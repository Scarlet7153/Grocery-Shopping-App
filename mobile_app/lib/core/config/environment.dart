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

  // --- Map & Routing APIs ---
  static String get graphHopperApiKey {
    final key = dotenv.env['GRAPH_HOPPER_API_KEY'];
    if (key == null || key.isEmpty) {
      throw StateError('GRAPH_HOPPER_API_KEY is not set in .env');
    }
    return key;
  }

  static String get graphHopperBaseUrl =>
      dotenv.env['GRAPH_HOPPER_BASE_URL'] ?? 'https://graphhopper.com/api/1/route';

  static String get graphHopperVrpUrl =>
      dotenv.env['GRAPH_HOPPER_VRP_URL'] ?? 'https://graphhopper.com/api/1/vrp';

  static String get trackAsiaApiKey {
    final key = dotenv.env['TRACK_ASIA_API_KEY'];
    if (key == null || key.isEmpty) {
      throw StateError('TRACK_ASIA_API_KEY is not set in .env');
    }
    return key;
  }

  static String get trackAsiaGeocodeUrl =>
      dotenv.env['TRACK_ASIA_GEOCODE_URL'] ??
      'https://maps.track-asia.com/api/v2/place/textsearch/json';

  static String get tileUrl =>
      dotenv.env['TILE_URL'] ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // --- OpenRouteService (ORS) ---
  static String get routingProvider =>
      dotenv.env['ROUTING_PROVIDER'] ?? 'graphhopper';

  static String get openRouteServiceApiKey {
    final key = dotenv.env['ORS_API_KEY'];
    if (key == null || key.isEmpty) {
      throw StateError('ORS_API_KEY is not set in .env. Required when using openrouteservice.');
    }
    return key;
  }

  static String get openRouteServiceBaseUrl =>
      dotenv.env['ORS_BASE_URL'] ?? 'https://api.openrouteservice.org';
}
