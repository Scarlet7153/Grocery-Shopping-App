import 'package:flutter/material.dart';

import '../../../../core/cart/cart_session.dart';
import '../../../../features/customer/home/data/product_model.dart';

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

  void _addToCart() {
    CartSession.addProduct(
      _product,
      quantity: _quantity,
      unitPrice: _unitPrice,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng')));
  }

  void _buyNow() {
    _addToCart();
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _product.imageUrl.isEmpty
                    ? Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 48),
                      )
                    : (_product.imageUrl.startsWith('assets/'))
                    ? Image.asset(_product.imageUrl, fit: BoxFit.cover)
                    : Image.network(
                        _product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 48),
                          );
                        },
                      ),
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
                'C\u00f2n l\u1ea1i: $_stockLeft',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (_product.storeName.isNotEmpty)
              Text(
                'C\u1eeda h\u00e0ng: ${_product.storeName}',
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 12),
            Text(
              _product.description.isEmpty
                  ? 'Ch\u01b0a c\u00f3 m\u00f4 t\u1ea3 s\u1ea3n ph\u1ea9m.'
                  : _product.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ch\u1ecdn ph\u00e2n lo\u1ea1i',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_product.units.isEmpty)
              const Text('Ch\u01b0a c\u00f3 \u0111\u01a1n v\u1ecb b\u00e1n.')
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
                    onSelected: (_) {
                      setState(() {
                        _selectedUnitIndex = index;
                      });
                    },
                    labelStyle: TextStyle(
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    selectedColor: const Color(
                      0xFF2F80ED,
                    ).withValues(alpha: 0.2),
                  );
                }),
              ),
            const SizedBox(height: 16),
            const Text(
              'S\u1ed1 l\u01b0\u1ee3ng',
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
                  onPressed: () => setState(() => _quantity += 1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'T\u1ed5ng c\u1ed9ng',
                    style: const TextStyle(
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
                    onPressed: _addToCart,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Th\u00eam gi\u1ecf'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _buyNow,
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text('Mua ngay'),
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
    return SizedBox(
      width: 32,
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
