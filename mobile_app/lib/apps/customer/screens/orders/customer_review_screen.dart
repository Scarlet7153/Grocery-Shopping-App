import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/snackbar_utils.dart';
import '../../utils/customer_l10n.dart';

class CustomerReviewScreen extends StatefulWidget {
  final int orderId;
  final String storeName;

  const CustomerReviewScreen({
    super.key,
    required this.orderId,
    required this.storeName,
  });

  @override
  State<CustomerReviewScreen> createState() => _CustomerReviewScreenState();
}

class _CustomerReviewScreenState extends State<CustomerReviewScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      await ApiClient.dio.post(
        '/reviews',
        data: {
          'orderId': widget.orderId,
          'rating': _rating,
          'comment': _commentController.text.trim(),
        },
      );

      if (mounted) {
        SnackBarUtils.showSuccess(
          context: context,
          message: context.tr(
            vi: 'Cảm ơn bạn đã đánh giá!',
            en: 'Thank you for your review!',
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Không thể gửi đánh giá';
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }
      if (mounted) {
        SnackBarUtils.showError(context: context, message: message);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(vi: 'Đánh giá', en: 'Review')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    context.tr(
                      vi: 'Đánh giá cửa hàng',
                      en: 'Rate the store',
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.storeName,
                    style: TextStyle(
                      fontSize: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        star <= _rating ? Icons.star : Icons.star_border,
                        size: 48,
                        color: star <= _rating
                            ? Colors.amber
                            : scheme.outlineVariant,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _ratingLabel(context),
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              context.tr(vi: 'Nhận xét của bạn', en: 'Your comment'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: context.tr(
                  vi: 'Chia sẻ trải nghiệm của bạn với cửa hàng...',
                  en: 'Share your experience with the store...',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        context.tr(vi: 'Gửi đánh giá', en: 'Submit review'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(BuildContext context) {
    switch (_rating) {
      case 1:
        return context.tr(vi: 'Rất tệ', en: 'Very bad');
      case 2:
        return context.tr(vi: 'Tệ', en: 'Bad');
      case 3:
        return context.tr(vi: 'Bình thường', en: 'Average');
      case 4:
        return context.tr(vi: 'Tốt', en: 'Good');
      case 5:
        return context.tr(vi: 'Rất tốt', en: 'Excellent');
      default:
        return '';
    }
  }
}
