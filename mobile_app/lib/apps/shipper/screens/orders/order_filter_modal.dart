import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/apps/shipper/models/order_filter.dart';
import 'package:grocery_shopping_app/apps/shipper/bloc/order_filter_bloc.dart';

class OrderFilterModal extends StatefulWidget {
  final OrderFilter initialFilter;
  final Function(OrderFilter) onApply;

  const OrderFilterModal({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<OrderFilterModal> createState() => _OrderFilterModalState();
}

class _OrderFilterModalState extends State<OrderFilterModal> {
  late OrderFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Header
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                automaticallyImplyLeading: false,
                centerTitle: true,
                title: Text(
                  'Lọc đơn hàng',
                  style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.black,
                      ) ??
                      const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.black),
                  ),
                ],
              ),
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Max Distance
                      _buildDistanceControl(),
                      const SizedBox(height: 28),

                      // Min Earning
                      _buildEarningControl(),
                      const SizedBox(height: 28),

                      // Avoid Pickup
                      _buildCheckboxOptions(),
                      const SizedBox(height: 28),

                      // Max Items
                      _buildMaxItemsControl(),
                      const SizedBox(height: 40),

                      // Action Buttons
                      _buildActionButtons(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Distance control with +/- buttons
  Widget _buildDistanceControl() {
    final distance = _currentFilter.maxDistance ?? 20;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khoảng cách tối đa',
          style:
              Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.black54) ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Row(
            children: [
              // Minus button (48px)
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: ShipperTheme.primaryColor,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: Colors.transparent),
                  ),
                  onPressed: distance > 0
                      ? () => setState(() {
                          _currentFilter = _currentFilter.copyWith(
                            maxDistance: (distance - 1).toDouble(),
                          );
                        })
                      : null,
                  child: const Icon(Icons.remove, size: 20),
                ),
              ),
              // Display value (expanded)
              Expanded(
                child: Center(
                  child: Text(
                    '${distance.toStringAsFixed(1)} km',
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: ShipperTheme.primaryColor,
                        ) ??
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: ShipperTheme.primaryColor,
                        ),
                  ),
                ),
              ),
              // Plus button (48px)
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: ShipperTheme.primaryColor,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: Colors.transparent),
                  ),
                  onPressed: distance < 20
                      ? () => setState(() {
                          _currentFilter = _currentFilter.copyWith(
                            maxDistance: (distance + 1).toDouble(),
                          );
                        })
                      : null,
                  child: const Icon(Icons.add, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Earning control with +/- buttons
  Widget _buildEarningControl() {
    final earning = (_currentFilter.minEarning ?? 10000).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thu nhập tối thiểu',
          style:
              Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.black54) ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Row(
            children: [
              // Minus button (48px)
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: ShipperTheme.primaryColor,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: Colors.transparent),
                  ),
                  onPressed: earning > 10000
                      ? () => setState(() {
                          _currentFilter = _currentFilter.copyWith(
                            minEarning: (earning - 5000).toDouble(),
                          );
                        })
                      : null,
                  child: const Icon(Icons.remove, size: 20),
                ),
              ),
              // Display value (expanded)
              Expanded(
                child: Center(
                  child: Text(
                    '${earning ~/ 1000}K₫',
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: ShipperTheme.primaryColor,
                        ) ??
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: ShipperTheme.primaryColor,
                        ),
                  ),
                ),
              ),
              // Plus button (48px)
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: ShipperTheme.primaryColor,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: Colors.transparent),
                  ),
                  onPressed: earning < 100000
                      ? () => setState(() {
                          _currentFilter = _currentFilter.copyWith(
                            minEarning: (earning + 5000).toDouble(),
                          );
                        })
                      : null,
                  child: const Icon(Icons.add, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Max Items control with +/- buttons
  Widget _buildMaxItemsControl() {
    final items = _currentFilter.maxItems ?? 50;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tối đa sản phẩm',
          style:
              Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.black54) ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Row(
            children: [
              // Minus button (48px)
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: ShipperTheme.primaryColor,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: Colors.transparent),
                  ),
                  onPressed: items > 10
                      ? () => setState(() {
                          _currentFilter = _currentFilter.copyWith(
                            maxItems: items - 1,
                          );
                        })
                      : null,
                  child: const Icon(Icons.remove, size: 20),
                ),
              ),
              // Display value (expanded)
              Expanded(
                child: Center(
                  child: Text(
                    '$items sản phẩm',
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: ShipperTheme.primaryColor,
                        ) ??
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: ShipperTheme.primaryColor,
                        ),
                  ),
                ),
              ),
              // Plus button (48px)
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: ShipperTheme.primaryColor,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: Colors.transparent),
                  ),
                  onPressed: items < 50
                      ? () => setState(() {
                          _currentFilter = _currentFilter.copyWith(
                            maxItems: items + 1,
                          );
                        })
                      : null,
                  child: const Icon(Icons.add, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Checkbox options
  Widget _buildCheckboxOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tùy chọn',
          style:
              Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.black54) ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: CheckboxListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            title: Text(
              'Tránh lấy hàng (chỉ giao)',
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ) ??
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Chỉ nhận những order cửa hàng chuẩn bị sẵn',
              style:
                  Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: Colors.grey[600]) ??
                  TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            value: _currentFilter.avoidPickup ?? false,
            onChanged: (value) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(avoidPickup: value);
              });
            },
            activeColor: ShipperTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  /// Action buttons
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Reset button (48px)
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentFilter = OrderFilter.defaultFilter();
                });
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[400]!, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Đặt lại',
                style:
                    Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ) ??
                    TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Apply button (56px primary)
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                context.read<OrderFilterBloc>().add(
                  SaveOrderFilter(_currentFilter),
                );
                widget.onApply(_currentFilter);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ShipperTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Áp dụng',
                style:
                    Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ) ??
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
