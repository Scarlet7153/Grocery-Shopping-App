import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/apps/shipper/models/shipper_order.dart';

class AvailableOrdersList extends StatelessWidget {
  final List<ShipperOrder> orders;
  final void Function(int orderId)? onAccept;
  final void Function(int orderId)? onSkip;
  final void Function(int orderId)? onComplete;

  const AvailableOrdersList({
    super.key,
    required this.orders,
    this.onAccept,
    this.onSkip,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('Không có đơn hàng sẵn có'));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ShipperTheme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delivery_dining,
                          color: ShipperTheme.primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đơn #${order.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.deliveryAddress,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Khách: ${order.customerName}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${order.grandTotal.toStringAsFixed(0)}₫',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: ShipperTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.status.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: order.status == OrderStatus.AVAILABLE
                                ? ShipperTheme.primaryColor
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (order.status == OrderStatus.AVAILABLE)
                  Row(
                    children: [
                      if (onAccept != null)
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF57C00),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => onAccept?.call(order.id),
                            child: const Text('Nhận đơn'),
                          ),
                        ),
                      const SizedBox(width: 10),
                      if (onSkip != null)
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: ShipperTheme.textColor,
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => onSkip?.call(order.id),
                            child: const Text('Bỏ qua'),
                          ),
                        ),
                    ],
                  ),
                if (order.status == OrderStatus.PICKING_UP ||
                    order.status == OrderStatus.DELIVERING)
                  ElevatedButton(
                    onPressed: onComplete != null ? () => onComplete?.call(order.id) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShipperTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Hoàn thành'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
