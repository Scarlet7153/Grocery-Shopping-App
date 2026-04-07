import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';

class PerformanceStats extends StatelessWidget {
  final int delivered;
  final double rating;

  const PerformanceStats(
      {super.key, required this.delivered, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStat(context, 'Đã giao', delivered.toString()),
        _buildStat(context, 'Đánh giá', rating.toString()),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) => Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: ShipperTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ) ??
                const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ShipperTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ) ??
                TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      );
}
