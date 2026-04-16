import '../../../core/api/api_client.dart';
import '../../../core/api/api_routes.dart';
import 'review_model.dart';

class ReviewService {
  ReviewService() : _client = ApiClient();
  final ApiClient _client;

  /// GET /reviews/store/{storeId} — lấy tất cả đánh giá của cửa hàng.
  Future<List<ReviewModel>> getStoreReviews(int storeId) async {
    try {
      final response =
          await _client.get<dynamic>(ApiRoutes.storeReviews(storeId));
      final raw = response.data;
      if (raw == null) return [];
      final dynamic data =
          raw is Map<String, dynamic> ? (raw['data'] ?? raw) : raw;
      if (data is List) {
        return data
            .map((e) => ReviewModel.fromJson(e is Map<String, dynamic>
                ? e
                : Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// GET /reviews/store/{storeId}/rating — lấy điểm đánh giá trung bình.
  Future<StoreRatingModel?> getStoreRating(int storeId) async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>(ApiRoutes.storeRating(storeId));
      final raw = response.data;
      if (raw == null) return null;
      final data = (raw['data'] ?? raw);
      return StoreRatingModel.fromJson(data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map));
    } catch (e) {
      return null;
    }
  }
}
