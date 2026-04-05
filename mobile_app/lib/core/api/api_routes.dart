/// Central API route constants for the Store frontend.
/// All API URLs are defined here for easy maintenance and consistency.
class ApiRoutes {
  ApiRoutes._();

  // ─── Auth ─────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // ─── Store ─────────────────────────────────────────────────────────────
  static const String storeInfo = '/store/my-store';
  static const String updateStoreProfile = '/store/my-store';

  // ─── Products ──────────────────────────────────────────────────────────
  static const String products = '/products';
  static String productById(String id) => '/products/$id';

  // ─── Orders ────────────────────────────────────────────────────────────
  static const String storeOrders = '/store/orders';
  static String orderById(String id) => '/store/orders/$id';
  static String updateOrderStatus(String id) => '/store/orders/$id/status';
}
