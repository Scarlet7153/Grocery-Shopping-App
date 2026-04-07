import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';

/// Small card presenting three quick stats: orders today, earnings, rating.
class StatsCard extends StatelessWidget {
  final int orders;
  final double earnings;
  final double rating;

  const StatsCard({
    super.key,
    required this.orders,
    required this.earnings,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildItem(
              context: context,
              icon: Icons.list_alt,
              label: 'Đơn hôm nay',
              value: orders.toString(),
            ),
            _buildItem(
              context: context,
              icon: Icons.attach_money,
              label: 'Thu nhập',
              value: '${earnings.toStringAsFixed(0)}₫',
            ),
            _buildItem(
              context: context,
              icon: Icons.star,
              label: 'Đánh giá',
              value: rating.toStringAsFixed(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: ShipperTheme.primaryColor, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ShipperTheme.primaryColor,
                  ) ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ShipperTheme.primaryColor,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ) ??
              TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
