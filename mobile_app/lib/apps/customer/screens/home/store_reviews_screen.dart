import 'package:flutter/material.dart';

import '../../../../features/customer/home/data/review_api.dart';
import '../../../../features/customer/home/data/review_model.dart';
import '../../shared/customer_state_view.dart';
import '../../utils/customer_l10n.dart';

class StoreReviewsScreen extends StatefulWidget {
  const StoreReviewsScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  final int storeId;
  final String storeName;

  @override
  State<StoreReviewsScreen> createState() => _StoreReviewsScreenState();
}

class _StoreReviewsScreenState extends State<StoreReviewsScreen> {
  final ReviewApi _reviewApi = ReviewApi();

  StoreRatingModel? _rating;
  List<ReviewModel> _reviews = [];
  bool _loadingRating = true;
  bool _loadingReviews = true;
  bool _loadingMore = false;
  String? _errorRating;
  String? _errorReviews;
  int _currentPage = 0;
  int _totalPages = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRating();
    _loadReviews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadRating() async {
    try {
      final rating = await _reviewApi.getStoreRating(widget.storeId);
      if (mounted) {
        setState(() {
          _rating = rating;
          _loadingRating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorRating = context.tr(
            vi: 'Không thể tải đánh giá',
            en: 'Unable to load ratings',
          );
          _loadingRating = false;
        });
      }
    }
  }

  Future<void> _loadReviews() async {
    try {
      final result = await _reviewApi.getStoreReviews(widget.storeId, page: 0);
      if (mounted) {
        setState(() {
          _reviews = result.content;
          _totalPages = result.totalPages;
          _currentPage = 0;
          _loadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorReviews = context.tr(
            vi: 'Không thể tải danh sách đánh giá',
            en: 'Unable to load reviews',
          );
          _loadingReviews = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _currentPage >= _totalPages - 1) return;

    setState(() => _loadingMore = true);

    try {
      final result = await _reviewApi.getStoreReviews(
        widget.storeId,
        page: _currentPage + 1,
      );
      if (mounted) {
        setState(() {
          _reviews.addAll(result.content);
          _currentPage++;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.storeName)),
      body: Container(
        color: scheme.surfaceContainerLowest,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            _buildRatingHeader(),
            const SizedBox(height: 20),
            _buildReviewsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingHeader() {
    final scheme = Theme.of(context).colorScheme;

    if (_loadingRating) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: CustomerStateView.loading(
              compact: true,
              title: context.tr(vi: 'Đang tải...', en: 'Loading...'),
            ),
          ),
        ),
      );
    }

    if (_errorRating != null || _rating == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              _errorRating ??
                  context.tr(
                    vi: 'Chưa có đánh giá',
                    en: 'No reviews yet',
                  ),
              style: TextStyle(color: scheme.error),
            ),
          ),
        ),
      );
    }

    final rating = _rating!;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rating.averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '/5',
                    style: TextStyle(
                      fontSize: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildStars(rating.averageRating),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                vi: '${rating.totalReviews} đánh giá',
                en: '${rating.totalReviews} reviews',
              ),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStars(double rating) {
    final stars = <Widget>[];
    for (int i = 1; i <= 5; i++) {
      if (rating >= i) {
        stars.add(const Icon(Icons.star, color: Colors.amber, size: 24));
      } else if (rating >= i - 0.5) {
        stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 24));
      } else {
        stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 24));
      }
    }
    return stars;
  }

  Widget _buildReviewsList() {
    if (_loadingReviews) {
      return CustomerStateView.loading(
        compact: true,
        title: context.tr(vi: 'Đang tải đánh giá...', en: 'Loading reviews...'),
      );
    }

    if (_errorReviews != null) {
      return CustomerStateView.error(
        compact: true,
        message: _errorReviews!,
        onAction: _loadReviews,
      );
    }

    if (_reviews.isEmpty) {
      return CustomerStateView.empty(
        compact: true,
        title: context.tr(vi: 'Chưa có đánh giá', en: 'No reviews yet'),
        message: context.tr(
          vi: 'Hãy là người đầu tiên đánh giá cửa hàng này!',
          en: 'Be the first to review this store!',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(vi: 'Đánh giá', en: 'Reviews'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._reviews.map((review) => _buildReviewCard(review)),
        if (_loadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    review.reviewerName.isNotEmpty
                        ? review.reviewerName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: _buildStars(review.rating.toDouble()),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(review.createdAt),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(review.comment!),
            ],
            if (review.storeReply != null && review.storeReply!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.tr(
                              vi: 'Phản hồi từ cửa hàng', en: 'Store reply'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.storeReply!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
