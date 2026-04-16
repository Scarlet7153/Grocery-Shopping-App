class ReviewModel {
  final int id;
  final int orderId;
  final int reviewerId;
  final String reviewerName;
  final int storeId;
  final String? storeName;
  final int rating;
  final String? comment;
  final String? storeReply;
  final DateTime? storeReplyAt;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.orderId,
    required this.reviewerId,
    required this.reviewerName,
    required this.storeId,
    this.storeName,
    required this.rating,
    this.comment,
    this.storeReply,
    this.storeReplyAt,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: (json['id'] ?? 0) as int,
      orderId: (json['orderId'] ?? 0) as int,
      reviewerId: (json['reviewerId'] ?? 0) as int,
      reviewerName: (json['reviewerName'] ?? '') as String,
      storeId: (json['storeId'] ?? 0) as int,
      storeName: json['storeName'] as String?,
      rating: (json['rating'] ?? 0) as int,
      comment: json['comment'] as String?,
      storeReply: json['storeReply'] as String?,
      storeReplyAt: json['storeReplyAt'] != null
          ? DateTime.tryParse(json['storeReplyAt'] as String)
          : null,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class StoreRatingModel {
  final int storeId;
  final String storeName;
  final double averageRating;
  final int totalReviews;

  StoreRatingModel({
    required this.storeId,
    required this.storeName,
    required this.averageRating,
    required this.totalReviews,
  });

  factory StoreRatingModel.fromJson(Map<String, dynamic> json) {
    return StoreRatingModel(
      storeId: (json['storeId'] ?? 0) as int,
      storeName: (json['storeName'] ?? '') as String,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalReviews: (json['totalReviews'] ?? 0) as int,
    );
  }
}

class PaginatedReviews {
  final List<ReviewModel> content;
  final int totalElements;
  final int totalPages;

  PaginatedReviews({
    required this.content,
    required this.totalElements,
    required this.totalPages,
  });

  factory PaginatedReviews.fromJson(Map<String, dynamic> json) {
    final contentList = (json['content'] as List? ?? [])
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedReviews(
      content: contentList,
      totalElements: (json['totalElements'] ?? 0) as int,
      totalPages: (json['totalPages'] ?? 0) as int,
    );
  }
}
