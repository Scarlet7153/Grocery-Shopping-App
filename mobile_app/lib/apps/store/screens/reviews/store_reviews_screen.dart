import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/store_theme.dart';
import '../../bloc/store_blocs.dart';
import '../../../../features/review/data/review_model.dart';

class StoreReviewsScreen extends StatefulWidget {
  const StoreReviewsScreen({super.key});
  @override
  State<StoreReviewsScreen> createState() => _StoreReviewsScreenState();
}

class _StoreReviewsScreenState extends State<StoreReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardState = context.read<StoreDashboardBloc>().state;
      if (dashboardState is StoreDashboardLoaded) {
        final storeId = dashboardState.store.id;
        if (storeId != null) {
          context.read<StoreReviewsBloc>().add(LoadStoreReviews(storeId));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
          title: const Text('Đánh giá'),
          backgroundColor: StoreTheme.primaryColor,
          foregroundColor: Colors.white),
      body: BlocBuilder<StoreReviewsBloc, StoreReviewsState>(
        builder: (context, state) {
          if (state is StoreReviewsLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is StoreReviewsError)
            return Center(child: Text(state.message));
          if (state is StoreReviewsLoaded) {
            if (state.reviews.isEmpty) {
              return const Center(child: Text('Chưa có đánh giá nào'));
            }
            return Column(
              children: [
                if (state.rating != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 40),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${state.rating!.averageRating?.toStringAsFixed(1) ?? '0'} / 5.0',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('${state.rating!.totalReviews ?? 0} đánh giá',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.reviews.length,
                    itemBuilder: (ctx, i) =>
                        _ReviewCard(review: state.reviews[i]),
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text('Chưa có đánh giá nào'));
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.reviewerName ?? 'Khách hàng',
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
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
