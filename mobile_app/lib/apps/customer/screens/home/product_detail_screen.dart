import 'package:flutter/material.dart';

import '../../../../core/cart/cart_session.dart';
import '../../../../features/customer/home/data/product_model.dart';
import '../../shared/customer_product_image.dart';
import '../../utils/customer_l10n.dart';
import '../cart/customer_cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedUnitIndex = 0;
  int _quantity = 1;

  ProductModel get _product => widget.product;

  ProductUnitModel? get _selectedUnit {
    if (_product.units.isEmpty) return null;
    if (_selectedUnitIndex < 0 || _selectedUnitIndex >= _product.units.length) {
      return _product.units.first;
    }
    return _product.units[_selectedUnitIndex];
  }

  double get _unitPrice => _selectedUnit?.price ?? _product.displayPrice;

  int get _stockLeft => _selectedUnit?.stockQuantity ?? 0;

  bool get _canAddToCart => _stockLeft > 0 && _quantity <= _stockLeft;

  bool get _canIncreaseQuantity => _stockLeft > 0 && _quantity < _stockLeft;

  void _changeUnit(int index) {
    setState(() {
      _selectedUnitIndex = index;
      if (_stockLeft <= 0) {
        _quantity = 1;
      } else if (_quantity > _stockLeft) {
        _quantity = _stockLeft;
      }
    });
  }

  bool _addToCart() {
    if (_stockLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
                vi: 'Biến thể này đã hết hàng',
                en: 'This variant is out of stock'),
          ),
        ),
      );
      return false;
    }

    if (_quantity > _stockLeft) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              vi: 'Chỉ còn $_stockLeft sản phẩm trong kho',
              en: 'Only $_stockLeft items left in stock',
            ),
          ),
        ),
      );
      return false;
    }

    CartSession.addProduct(
      _product,
      quantity: _quantity,
      unitPrice: _unitPrice,
      productUnitMappingId: _selectedUnit?.id,
      unitLabel: _selectedUnit?.unitName,
      stockQuantity: _stockLeft,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
          content: Text(
              context.tr(vi: 'Đã thêm vào giỏ hàng', en: 'Added to cart'))),
    );
    return true;
  }

  void _buyNow() {
    final added = _addToCart();
    if (!added) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerCartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _unitPrice * _quantity;

    return Scaffold(
      appBar: AppBar(title: Text(_product.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CustomerProductImage(
                imageUrl: _product.imageUrl,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_product.categoryName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _product.categoryName,
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_unitPrice.toStringAsFixed(0)}\u0111',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_stockLeft > 0)
              Text(
                context.tr(
                    vi: 'Còn lại: $_stockLeft', en: 'Remaining: $_stockLeft'),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (_product.storeName.isNotEmpty)
              Text(
                context.tr(
                  vi: 'Cửa hàng: ${_product.storeName}',
                  en: 'Store: ${_product.storeName}',
                ),
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 12),
            Text(
              _product.description.isEmpty
                  ? context.tr(
                      vi: 'Chưa có mô tả sản phẩm.',
                      en: 'No product description available.',
                    )
                  : _product.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(vi: 'Chọn phân loại', en: 'Choose variant'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_product.units.isEmpty)
              Text(context.tr(
                  vi: 'Chưa có đơn vị bán.', en: 'No sale unit available.'))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_product.units.length, (index) {
                  final unit = _product.units[index];
                  final selected = index == _selectedUnitIndex;
                  return ChoiceChip(
                    label: Text(
                      '${unit.unitName}\n${unit.price.toStringAsFixed(0)}\u0111',
                      textAlign: TextAlign.center,
                    ),
                    selected: selected,
                    onSelected: (_) => _changeUnit(index),
                    labelStyle: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    selectedColor: const Color(
                      0xFF2F80ED,
                    ).withValues(alpha: 0.2),
                  );
                }),
              ),
            const SizedBox(height: 16),
            Text(
              context.tr(vi: 'Số lượng', en: 'Quantity'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity -= 1)
                      : null,
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                _QtyButton(
                  icon: Icons.add,
                  onPressed: _canIncreaseQuantity
                      ? () => setState(() => _quantity += 1)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr(vi: 'Tổng cộng', en: 'Total'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${totalPrice.toStringAsFixed(0)}\u0111',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _canAddToCart ? () => _addToCart() : null,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(context.tr(vi: 'Thêm giỏ', en: 'Add to cart')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canAddToCart ? _buyNow : null,
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: Text(context.tr(vi: 'Mua ngay', en: 'Buy now')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 40,
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Icon(icon, size: 20, color: scheme.primary),
      ),
    );
  }
}
