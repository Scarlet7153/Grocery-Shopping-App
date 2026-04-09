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
  static const String availableOrders = '/orders/available';
  static const String myDeliveries = '/orders/my-deliveries';
  static const String myStoreOrders = '/orders/my-store-orders';
  static const String adminOrders = '/orders/admin/all';
  static String assignShipper(String id) => '/orders/$id/assign-shipper';
  static String updateOrderStatus(String id) => '/orders/$id/status';
  static String orderById(String id) => '/orders/$id';
}
