class ApiEndpoints {
  // Base URL (should be loaded from environment config)
  static const String baseUrl = 'http://localhost:8080'; // Remove /api
  
  // Authentication endpoints - Cập nhật theo Postman
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token'; // Khác với thiết kế ban đầu
  static const String getProfile = '/auth/me'; // Endpoint lấy profile
  
  // User endpoints - Cập nhật theo Postman
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String changePassword = '/users/change-password';
  static const String users = '/users'; // Get all users (admin only)
  static const String usersByRole = '/users/role'; // Get users by role
  static const String userById = '/users'; // Get user by ID
  static const String toggleUserStatus = '/users/{id}/toggle-status';
  static const String deleteUser = '/users/{id}';
  static const String usersByStatus = '/users/status/{status}';
  
  // Category endpoints
  static const String categories = '/categories';
  static const String categoryById = '/categories/{id}';
  
  // Product endpoints
  static const String products = '/products';
  static const String productById = '/products/{id}';
  static const String productsByCategory = '/products/category/{categoryId}';
  static const String productsByStore = '/products/store/{storeId}';
  static const String availableProductsByStore = '/products/store/{storeId}/available';
  static const String searchProducts = '/products/search';
  static const String toggleProductStatus = '/products/{id}/toggle-status';
  
  // Store endpoints
  static const String stores = '/stores';
  static const String storeById = '/stores/{id}';
  static const String myStore = '/stores/my-store';
  static const String openStores = '/stores/open';
  static const String searchStores = '/stores/search';
  static const String toggleStoreStatus = '/stores/{id}/toggle-status';
  
  // Order endpoints
  static const String orders = '/orders';
  static const String orderById = '/orders/{id}';
  static const String myOrders = '/orders/my-orders'; // Customer orders
  static const String myStoreOrders = '/orders/my-store-orders'; // Store orders
  static const String myDeliveries = '/orders/my-deliveries'; // Shipper deliveries
  static const String availableOrders = '/orders/available'; // Available for shipper
  static const String orderStatus = '/orders/{id}/status';
  static const String assignShipper = '/orders/{id}/assign-shipper';
  
  // Review endpoints
  static const String reviews = '/reviews';
  static const String reviewById = '/reviews/{id}';
  static const String myReviews = '/reviews/my-reviews';
  static const String storeReviews = '/reviews/store/{storeId}';
  static const String storeRating = '/reviews/store/{storeId}/rating';
}