import 'package:flutter/material.dart';

import '../../../core/cart/cart_session.dart';
import '../../../core/format/formatters.dart';
import '../../../features/customer/home/data/product_model.dart';
import 'customer_product_image.dart';

import '../utils/customer_l10n.dart';
import '../screens/cart/customer_cart_screen.dart';

Future<void> showVariantSelectionSheet(
  BuildContext context,
  ProductModel product,
) async {
  if (product.units.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(context.tr(vi: 'Sản phẩm chưa có biến thể bán', en: 'This product has no purchasable variant')),
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      int selectedIndex = 0;
      int quantity = 1;

      return StatefulBuilder(builder: (ctx, setState) {
        final unit = product.units[selectedIndex];
        final stock = unit.stockQuantity;

        void doAddToCart({required bool goToCart}) {
          if (stock <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr(vi: 'Biến thể này đã hết hàng', en: 'This variant is out of stock'))),
            );
            return;
          }

          if (quantity > stock) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr(vi: 'Số lượng vượt quá tồn kho', en: 'Quantity exceeds stock'))),
            );
            return;
          }

          CartSession.addProduct(
            product,
            quantity: quantity,
            unitPrice: unit.price,
            productUnitMappingId: unit.id,
            unitLabel: unit.unitName,
            stockQuantity: stock,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr(vi: 'Đã thêm vào giỏ hàng', en: 'Added to cart'))),
          );

          if (goToCart) {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerCartScreen()),
            );
          } else {
            Navigator.of(context).pop();
          }
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CustomerProductImage(imageUrl: product.imageUrl, width: 64, height: 64, borderRadius: BorderRadius.circular(8)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(context.tr(vi: 'Chọn phân loại', en: 'Choose variant'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(product.units.length, (i) {
                      final u = product.units[i];
                      final selected = i == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${u.unitName}\n${formatVnd(u.price)}', textAlign: TextAlign.center),
                          selected: selected,
                          onSelected: (_) => setState(() {
                            selectedIndex = i;
                            quantity = 1;
                          }),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                Text(context.tr(vi: 'Số lượng', en: 'Quantity'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: quantity > 1 ? () => setState(() => quantity -= 1) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    IconButton(
                      onPressed: stock > 0 && quantity < stock ? () => setState(() => quantity += 1) : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const SizedBox(width: 12),
                    if (stock > 0) Text(context.tr(vi: 'Còn: ', en: 'Stock: ') + '$stock'),
                    if (stock <= 0) Text(context.tr(vi: 'Hết hàng', en: 'Out of stock'), style: const TextStyle(color: Colors.red)),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: stock > 0 ? () => doAddToCart(goToCart: false) : null,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: Text(context.tr(vi: 'Thêm giỏ', en: 'Add to cart')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: stock > 0 ? () => doAddToCart(goToCart: true) : null,
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: Text(context.tr(vi: 'Mua ngay', en: 'Buy now')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      });
    },
  );
}
