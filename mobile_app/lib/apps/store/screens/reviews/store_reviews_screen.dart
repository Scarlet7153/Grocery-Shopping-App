import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/store_theme.dart';
import '../../bloc/store_blocs.dart';
import '../../../../features/review/data/review_model.dart';
import '../../utils/store_localizations.dart';

class StoreReviewsScreen extends StatefulWidget {
  const StoreReviewsScreen({super.key});
  @override
  State<StoreReviewsScreen> createState() => _StoreReviewsScreenState();
}

class _StoreReviewsScreenState extends State<StoreReviewsScreen> {
  int? _storeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardState = context.read<StoreDashboardBloc>().state;
      if (dashboardState is StoreDashboardLoaded) {
        _storeId = dashboardState.store.id;
        if (_storeId != null) {
          context.read<StoreReviewsBloc>().add(LoadStoreReviews(_storeId!));
        }
      }
    });
  }

  void _showReplyDialog(int reviewId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.storeTr('reply_review')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.storeTr('enter_reply'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.storeTr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty && _storeId != null) {
                Navigator.pop(ctx);
                context.read<StoreReviewsBloc>().add(
                  ReplyToReview(reviewId, text, _storeId!),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: StoreTheme.primaryColor),
            child: Text(context.storeTr('send')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
          title: Text(context.storeTr('reviews')),
          backgroundColor: StoreTheme.primaryColor,
          foregroundColor: Colors.white),
      body: BlocBuilder<StoreReviewsBloc, StoreReviewsState>(
        builder: (context, state) {
          if (state is StoreReviewsLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is StoreReviewsError)
            return Center(child: Text(state.message));
          if (state is StoreReviewsLoaded || state is StoreReviewsReplying) {
            final reviews = state is StoreReviewsLoaded
                ? state.reviews
                : (state as StoreReviewsReplying).reviews;
            final rating = state is StoreReviewsLoaded
                ? state.rating
                : (state as StoreReviewsReplying).rating;
            final isReplying = state is StoreReviewsReplying;

            if (reviews.isEmpty) {
              return Center(child: Text(context.storeTr('no_reviews')));
            }
            return Column(
              children: [
                if (rating != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 40),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${rating.averageRating?.toStringAsFixed(1) ?? '0'}${context.storeTr('rating_out_of')}',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            Text(
                                '${rating.totalReviews ?? 0} ${context.storeTr('total_reviews_count')}',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (isReplying)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: LinearProgressIndicator(),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: reviews.length,
                    itemBuilder: (ctx, i) =>
                        _ReviewCard(
                          review: reviews[i],
                          onReply: () => _showReplyDialog(reviews[i].id!),
                        ),
                  ),
                ),
              ],
            );
          }
          return Center(child: Text(context.storeTr('no_reviews')));
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onReply;

  const _ReviewCard({required this.review, required this.onReply});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasReply = review.storeReply != null && review.storeReply!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.reviewerName ?? context.storeTr('customer'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(Icons.star,
                        size: 16,
                        color: i < (review.rating ?? 0)
                            ? Colors.amber
                            : Colors.grey[300])),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: TextStyle(color: Colors.grey[700])),
          ],
          if (review.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(_formatDate(review.createdAt!),
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
          // Store reply
          if (hasReply) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: StoreTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(color: StoreTheme.primaryColor, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store, size: 14, color: StoreTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        context.storeTr('store_reply'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: StoreTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review.storeReply!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                  ),
                  if (review.storeReplyAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(review.storeReplyAt!),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
          ],
          // Reply button
          if (!hasReply && review.id != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReply,
                icon: Icon(Icons.reply, size: 18, color: StoreTheme.primaryColor),
                label: Text(
                  context.storeTr('reply'),
                  style: TextStyle(color: StoreTheme.primaryColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
