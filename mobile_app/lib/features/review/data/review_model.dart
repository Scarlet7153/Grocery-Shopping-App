class ReviewModel {
  final int? id;
  final int? orderId;
  final int? reviewerId;
  final String? reviewerName;
  final int? storeId;
  final String? storeName;
  final int? rating;
  final String? comment;
  final String? storeReply;
  final DateTime? storeReplyAt;
  final DateTime? createdAt;
  const ReviewModel(
      {this.id,
      this.orderId,
      this.reviewerId,
      this.reviewerName,
      this.storeId,
      this.storeName,
      this.rating,
      this.comment,
      this.storeReply,
      this.storeReplyAt,
      this.createdAt});
  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: (json['id'] as num?)?.toInt(),
        orderId: (json['orderId'] as num?)?.toInt(),
        reviewerId: (json['reviewerId'] as num?)?.toInt(),
        reviewerName: json['reviewerName'] as String?,
        storeId: (json['storeId'] as num?)?.toInt(),
        storeName: json['storeName'] as String?,
        rating: (json['rating'] as num?)?.toInt(),
        comment: json['comment'] as String?,
        storeReply: json['storeReply'] as String?,
        storeReplyAt: json['storeReplyAt'] != null
            ? DateTime.tryParse(json['storeReplyAt'])
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
      );
}

class StoreRatingModel {
  final int? storeId;
  final String? storeName;
  final double? averageRating;
  final int? totalReviews;
  const StoreRatingModel(
      {this.storeId, this.storeName, this.averageRating, this.totalReviews});
  factory StoreRatingModel.fromJson(Map<String, dynamic> json) =>
      StoreRatingModel(
        storeId: (json['storeId'] as num?)?.toInt(),
        storeName: json['storeName'] as String?,
        averageRating: (json['averageRating'] as num?)?.toDouble(),
        totalReviews: (json['totalReviews'] as num?)?.toInt(),
      );
}
