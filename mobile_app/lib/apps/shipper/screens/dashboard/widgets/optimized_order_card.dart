import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/apps/shipper/models/shipper_order.dart';
import 'package:grocery_shopping_app/apps/shipper/constants/shipper_strings.dart';

/// ===== OPTIMIZED ORDER CARD (Phase 1 UX/UI) =====
/// Thiết kế cho UX/UI tối ưu:
/// - Typography 16px+ (outdoor readable)
/// - Touch targets 56px (thumb-friendly)
/// - Status color-coded (dễ nhận biết)
/// - Compact info, large CTAs
class OptimizedOrderCard extends StatelessWidget {
  final ShipperOrder order;
  final double? distance;
  final VoidCallback? onStart; // "Start accepting/delivering"
  final VoidCallback? onDetails;
  final VoidCallback? onMap;
  final bool isLoading;

  const OptimizedOrderCard({
    super.key,
    required this.order,
    this.distance,
    this.onStart,
    this.onDetails,
    this.onMap,
    this.isLoading = false,
  });

  Color _getStatusColor() {
    return ShipperTheme.getStatusColor(order.status.name);
  }

  IconData _getStatusIcon() {
    return ShipperTheme.getStatusIcon(order.status.name);
  }

  String _getStatusLabel() {
    switch (order.status) {
      case OrderStatus.PICKING_UP:
        return ShipperStrings.statusPickingUp;
      case OrderStatus.DELIVERING:
        return ShipperStrings.statusDelivering;
      case OrderStatus.DELIVERED:
        return ShipperStrings.statusDelivered;
      case OrderStatus.CONFIRMED:
        return ShipperStrings.statusReady;
      case OrderStatus.PENDING:
        return ShipperStrings.statusPending;
      case OrderStatus.CANCELLED:
        return ShipperStrings.statusCancelled;
      case OrderStatus.UNKNOWN:
        return ShipperStrings.statusUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final statusLabel = _getStatusLabel();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ShipperTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ===== TOP BAR - Status + Order ID =====
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Order ID
                Text(
                  '#${order.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ShipperTheme.textGreyColor,
                  ),
                ),
              ],
            ),
          ),

          // ===== CONTENT AREA =====
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer name (LARGE - 18px)
                Text(
                  order.customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ShipperTheme.textDarkColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Store name (secondary - 14px)
                Row(
                  children: [
                    Icon(
                      Icons.store,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.storeName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ShipperTheme.textGreyColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Delivery address (16px body)
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.deliveryAddress,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: ShipperTheme.textDarkColor,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ===== METRICS ROW =====
                Row(
                  children: [
                    // Distance
                    if (distance != null)
                      Flexible(
                        child: _buildMetricBadge(
                          icon: Icons.near_me,
                          label: '${distance!.toStringAsFixed(1)} km',
                          bgColor: Colors.blue.withValues(alpha: 0.1),
                          textColor: Colors.blue.shade700,
                        ),
                      ),
                    if (distance != null) const SizedBox(width: 8),

                    // Price/Earnings
                    Flexible(
                      child: _buildMetricBadge(
                        icon: Icons.attach_money,
                        label: '${order.shippingFee.toStringAsFixed(0)}₫',
                        bgColor: Colors.green.withValues(alpha: 0.1),
                        textColor: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Items count
                    Flexible(
                      child: _buildMetricBadge(
                        icon: Icons.shopping_bag,
                        label:
                            '${order.items.length} ${ShipperStrings.itemsLabel}',
                        bgColor: Colors.purple.withValues(alpha: 0.1),
                        textColor: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ===== ACTION BUTTON (FULL WIDTH - THUMB ZONE) =====
          if (onStart != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onStart,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.check_circle, size: 20),
                label: isLoading
                    ? const Text(ShipperStrings.buttonProcessing)
                    : const Text(ShipperStrings.buttonStart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 56),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
