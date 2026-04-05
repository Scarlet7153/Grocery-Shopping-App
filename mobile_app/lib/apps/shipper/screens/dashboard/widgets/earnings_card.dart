import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';

class EarningsCard extends StatelessWidget {
  final double amount;

  const EarningsCard({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thu nhập hôm nay',
                  style: TextStyle(
                      fontSize: 16, color: ShipperTheme.textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  '${amount.toStringAsFixed(0)}₫',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ShipperTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.attach_money,
              size: 48,
              color: ShipperTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
