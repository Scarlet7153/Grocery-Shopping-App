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
                Text(
                  'Thu nhập hôm nay',
                  style:
                      Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ) ??
                      TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${amount.toStringAsFixed(0)}₫',
                  style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: ShipperTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ) ??
                      const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: ShipperTheme.primaryColor,
                      ),
                ),
              ],
            ),
            Icon(
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
