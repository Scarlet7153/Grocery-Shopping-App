import '../../../core/api/api_client.dart';
import '../../../core/api/api_routes.dart';
import 'notification_model.dart';
import '../../../core/api/api_response.dart';

class NotificationService {
  final ApiClient _client = ApiClient();

  /// GET /notifications
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(ApiRoutes.notifications);
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data!,
        (json) => json as List<dynamic>,
      );

      return (apiResponse.data ?? [])
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// GET /notifications/unread-count
  Future<int> getUnreadCount() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(ApiRoutes.notificationUnreadCount);
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data!,
        (json) => json as Map<String, dynamic>,
      );
      
      return (apiResponse.data?['count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// PUT /notifications/{id}/read
  Future<NotificationModel?> markAsRead(String notificationId) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        ApiRoutes.markNotificationRead(notificationId),
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data!,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.data != null) {
        return NotificationModel.fromJson(apiResponse.data!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// PUT /notifications/read-all
  Future<void> markAllAsRead() async {
    try {
      await _client.put<void>(ApiRoutes.markAllNotificationsRead);
    } catch (_) {}
  }

  /// DELETE /notifications/{id}
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.delete<void>(ApiRoutes.deleteNotification(notificationId));
    } catch (_) {}
  }
}
