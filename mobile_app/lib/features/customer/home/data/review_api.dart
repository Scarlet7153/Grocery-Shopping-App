import 'package:grocery_shopping_app/core/network/api_client.dart';

import 'review_model.dart';

class ReviewApi {
  Future<StoreRatingModel> getStoreRating(int storeId) async {
    final response = await ApiClient.dio.get('/reviews/store/$storeId/rating');
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return StoreRatingModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Invalid rating response');
  }

  Future<PaginatedReviews> getStoreReviews(int storeId,
      {int page = 0, int size = 10}) async {
    final response = await ApiClient.dio.get(
      '/reviews/store/$storeId',
      queryParameters: {'page': page, 'size': size},
    );
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return PaginatedReviews.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Invalid reviews response');
  }
}
