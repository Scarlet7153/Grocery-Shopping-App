import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';

class PerformanceStats extends StatelessWidget {
  final int delivered;
  final double rating;

  const PerformanceStats({super.key, required this.delivered, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStat('Đã giao', delivered.toString()),
        _buildStat('Đánh giá', rating.toString()),
      ],
    );
  }

  Widget _buildStat(String label, String value) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ShipperTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: ShipperTheme.textColor),
          ),
        ],
      );
}
