import 'package:flutter/material.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../features/products/data/unit_model.dart';

/// Widget chọn số lượng với đơn vị đa dạng
/// Hỗ trợ: +/- step, validation, conversion
class QuantitySelector extends StatefulWidget {
  final ProductUnitMapping productUnit;
  final double initialQuantity;
  final Function(double) onChanged;
  final bool showConversion;

  const QuantitySelector({
    super.key,
    required this.productUnit,
    this.initialQuantity = 1.0,
    required this.onChanged,
    this.showConversion = true,
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late double _quantity;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _controller = TextEditingController(text: _formatValue(_quantity));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(double value) {
    // Làm tròn theo step
    final step = widget.productUnit.unit.stepValue;
    final rounded = (value / step).round() * step;

    // Hiển thị số nguyên nếu không có phần thập phân
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    // Hiển thị 1 số thập phân cho lạng (0.5)
    return rounded.toStringAsFixed(1);
  }

  void _updateQuantity(double newQuantity) {
    final unit = widget.productUnit.unit;

    // Clamp to min/max
    newQuantity = newQuantity.clamp(unit.minValue, unit.maxValue);

    // Round to step
    final step = unit.stepValue;
    newQuantity = (newQuantity / step).round() * step;

    setState(() {
      _quantity = newQuantity;
      _controller.text = _formatValue(newQuantity);
    });

    widget.onChanged(newQuantity);
  }

  void _increment() =>
      _updateQuantity(_quantity + widget.productUnit.unit.stepValue);
  void _decrement() =>
      _updateQuantity(_quantity - widget.productUnit.unit.stepValue);

  @override
  Widget build(BuildContext context) {
    final unit = widget.productUnit.unit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hiển thị số lượng với đơn vị
        Row(
          children: [
            // Nút giảm
            _buildButton(
              icon: Icons.remove,
              onPressed: _quantity > unit.minValue ? _decrement : null,
            ),

            // Input số lượng
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (value) {
                          final parsed = double.tryParse(value);
                          if (parsed != null) {
                            _updateQuantity(parsed);
                          }
                        },
                      ),
                    ),
                    Text(
                      unit.symbol,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Nút tăng
            _buildButton(
              icon: Icons.add,
              onPressed: _quantity < unit.maxValue ? _increment : null,
            ),
          ],
        ),

        // Hiển thị thông tin conversion
        if (widget.showConversion && widget.productUnit.baseQuantity != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildConversionInfo(),
          ),

        // Hiển thị tổng tiền
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildTotalPrice(),
        ),
      ],
    );
  }

  Widget _buildButton(
      {required IconData icon, required VoidCallback? onPressed}) {
    return Material(
      color: onPressed != null
          ? StoreTheme.primaryColor
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildConversionInfo() {
    final baseQty = widget.productUnit.baseQuantity!;
    final totalBase = baseQty * _quantity;
    final baseUnit = widget.productUnit.baseUnit ?? 'gram';

    String baseText;
    if (baseUnit == 'gram') {
      if (totalBase >= 1000) {
        baseText = '${(totalBase / 1000).toStringAsFixed(2)} kg';
      } else {
        baseText = '${totalBase.toStringAsFixed(0)} g';
      }
    } else {
      baseText = '$totalBase $baseUnit';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: StoreTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.scale, size: 16, color: StoreTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            '≈ $baseText',
            style: TextStyle(
              color: StoreTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPrice() {
    final total = widget.productUnit.price * _quantity;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Thành tiền:',
          style: TextStyle(color: Colors.grey[600]),
        ),
        Text(
          '${total.toStringAsFixed(0)}đ',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: StoreTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}

/// Widget hiển thị selector đơn vị cho sản phẩm có nhiều đơn vị
class UnitSelector extends StatelessWidget {
  final List<ProductUnitMapping> units;
  final ProductUnitMapping selectedUnit;
  final Function(ProductUnitMapping) onUnitChanged;

  const UnitSelector({
    super.key,
    required this.units,
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn đơn vị:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: units.where((u) => u.isActive).map((unit) {
            final isSelected = unit.id == selectedUnit.id;

            return GestureDetector(
              onTap: () => onUnitChanged(unit),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? StoreTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? StoreTheme.primaryColor
                        : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      unit.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${unit.price.toStringAsFixed(0)}đ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Example usage widget
class ProductQuantityCard extends StatelessWidget {
  final List<ProductUnitMapping> units;
  final Function(ProductUnitMapping, double) onQuantityChanged;

  const ProductQuantityCard({
    super.key,
    required this.units,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy đơn vị mặc định
    final defaultUnit = units.firstWhere(
      (u) => u.isDefault,
      orElse: () => units.first,
    );

    return StatefulBuilder(
      builder: (context, setState) {
        ProductUnitMapping selectedUnit = defaultUnit;
        double quantity = 1.0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chọn đơn vị (nếu có nhiều đơn vị)
                if (units.length > 1)
                  UnitSelector(
                    units: units,
                    selectedUnit: selectedUnit,
                    onUnitChanged: (unit) {
                      setState(() => selectedUnit = unit);
                      onQuantityChanged(unit, quantity);
                    },
                  ),

                const SizedBox(height: 16),

                // Chọn số lượng
                QuantitySelector(
                  productUnit: selectedUnit,
                  onChanged: (qty) {
                    quantity = qty;
                    onQuantityChanged(selectedUnit, qty);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
