import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/apps/shipper/models/order_filter.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/orders/order_filter_modal.dart';

/// Widget nút filter - hiển thị badge nếu filter active
class OrderFilterButton extends StatelessWidget {
  final OrderFilter currentFilter;
  final Function(OrderFilter) onFilterApplied;

  const OrderFilterButton({
    super.key,
    required this.currentFilter,
    required this.onFilterApplied,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main button
        FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => OrderFilterModal(
                initialFilter: currentFilter,
                onApply: onFilterApplied,
              ),
            );
          },
          backgroundColor: ShipperTheme.primaryColor,
          icon: const Icon(Icons.tune, color: Colors.white),
          label: const Text(
            'Lọc',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        // Badge nếu filter active
        if (currentFilter.isActive)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Text(
                  '✓',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Chip hiển thị filter active
class ActiveFilterChip extends StatelessWidget {
  final OrderFilter filter;
  final VoidCallback onClear;

  const ActiveFilterChip({
    super.key,
    required this.filter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (!filter.isActive) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ShipperTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ShipperTheme.primaryColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.filter_list,
            color: ShipperTheme.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Lọc: ${_buildFilterLabel(filter)}',
            style: const TextStyle(
              color: ShipperTheme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close,
              color: ShipperTheme.primaryColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _buildFilterLabel(OrderFilter filter) {
    List<String> labels = [];

    if (filter.maxDistance != null && filter.maxDistance! < 20) {
      labels.add('${filter.maxDistance!.toStringAsFixed(1)}km');
    }

    if (filter.minEarning != null && filter.minEarning! > 10000) {
      labels.add('≥${(filter.minEarning! / 1000).toStringAsFixed(0)}K');
    }

    if (filter.avoidPickup == true) {
      labels.add('Giao');
    }

    return labels.join(' • ');
  }
}
