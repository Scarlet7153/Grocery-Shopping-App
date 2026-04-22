import 'package:grocery_shopping_app/core/config/environment.dart';
import 'package:grocery_shopping_app/core/config/routing_service.dart';
import 'package:grocery_shopping_app/apps/shipper/services/graphhopper_routing_service.dart';
import 'package:grocery_shopping_app/apps/shipper/services/openroute_service_routing_service.dart';

/// Factory tạo RoutingService dựa trên config trong .env
///
/// Trong .env, thêm dòng:
///   ROUTING_PROVIDER=graphhopper   # hoặc openrouteservice
///
/// Mặc định sẽ dùng GraphHopper nếu không config.
class RoutingServiceFactory {
  static RoutingService? _instance;

  /// Lấy singleton instance của RoutingService
  static RoutingService get instance {
    _instance ??= _create();
    return _instance!;
  }

  /// Tạo mới instance (dùng khi muốn reset singleton)
  static RoutingService create() => _create();

  static RoutingService _create() {
    final provider = (Environment.routingProvider).toLowerCase().trim();

    switch (provider) {
      case 'openrouteservice':
      case 'ors':
        return OpenRouteServiceRoutingService();
      case 'graphhopper':
      default:
        return GraphHopperRoutingService();
    }
  }

  /// Reset singleton (dùng khi đổi config runtime, ví dụ testing)
  static void reset() {
    _instance = null;
  }
}
