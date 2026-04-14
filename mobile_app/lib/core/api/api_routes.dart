/// Unified API route constants for the entire app.
/// All API URLs are defined here for easy maintenance and consistency.
///
/// NOTE: These paths are relative — the base URL (e.g. http://localhost:8080/api)
/// is configured in [ApiClient].
class ApiRoutes {
  ApiRoutes._();

  // ─── Auth ─────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // ─── Users ────────────────────────────────────────────────────────────
  static const String users = '/users';
  static const String userProfile = '/users/profile';
  static const String changePassword = '/users/change-password';
  static String userById(dynamic id) => '/users/$id';
  static String usersByRole(String role) => '/users/role/$role';
  static String toggleUserStatus(dynamic id) => '/users/$id/toggle-status';

  // ─── Store ────────────────────────────────────────────────────────────
  static const String stores = '/stores';
  static const String storeInfo = '/stores/my-store';
  static const String openStores = '/stores/open';
  static const String searchStores = '/stores/search';
  static String storeById(dynamic id) => '/stores/$id';
  static String toggleStoreStatus(dynamic id) => '/stores/$id/toggle-status';

  // ─── Categories ───────────────────────────────────────────────────────
  static const String categories = '/categories';
  static String categoryById(dynamic id) => '/categories/$id';

  // ─── Products ─────────────────────────────────────────────────────────
  static const String products = '/products';
  static String productById(dynamic id) => '/products/$id';
  static String productsByStore(dynamic storeId) => '/products/store/$storeId';
  static String availableProductsByStore(dynamic storeId) =>
      '/products/store/$storeId/available';
  static String productsByCategory(dynamic catId) =>
      '/products/category/$catId';
  static const String searchProducts = '/products/search';
  static String toggleProductStatus(dynamic id) =>
      '/products/$id/toggle-status';

  // ─── Orders ───────────────────────────────────────────────────────────
  static const String orders = '/orders';
  static const String myOrders = '/orders/my-orders';
  static const String myStoreOrders = '/orders/my-store-orders';
// ─── Orders ───────────────────────────────────────────────────────────
  static const String myDeliveries = '/orders/my-deliveries';
  static const String availableOrders = '/orders/available';
  static const String adminOrders = '/orders/admin/all';
  // Dùng String id theo chuẩn của nhánh main
  static String orderById(String id) => '/orders/$id';
  static String updateOrderStatus(String id) => '/orders/$id/status';
  static String assignShipper(String id) => '/orders/$id/assign-shipper';

  // ─── Reviews (Từ nhánh store-fe-api-update) ─────────────────────────
  static const String reviews = '/reviews';
  static const String myReviews = '/reviews/my-reviews';
  static String reviewById(String id) => '/reviews/$id';
  static String storeReviews(String storeId) => '/reviews/store/$storeId';
  static String storeRating(String storeId) => '/reviews/store/$storeId/rating';

  // ─── Monitoring (Từ nhánh main) ───────────────────────────────────────
  static const String stats = '/admin/stats';
  static const String activities = '/admin/activities';

  // ─── Uploads (Gộp từ cả 2 nhánh) ──────────────────────────────────────
  static const String uploadAvatar = '/upload/avatar';
  static const String uploadProduct = '/upload/product'; // Từ main
  
  // Gộp cách gọi hàm (Có thể sửa lại tên hàm tuỳ theo cách bạn đang dùng ở code gọi API)
  static String uploadProductImage(String productId) => '/upload/product/$productId'; 
  static String uploadStoreImage(String storeId) => '/upload/store/$storeId'; 
  static String uploadPOD(String orderId) => '/upload/pod/$orderId'; // Từ store-fe-api-update
}
