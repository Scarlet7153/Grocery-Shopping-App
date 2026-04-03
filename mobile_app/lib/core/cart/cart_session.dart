import 'package:flutter/foundation.dart';

import '../../features/customer/home/data/product_model.dart';

class CartItem {
  CartItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.imageUrl,
    required this.quantity,
  });

  final int productId;
  final String name;
  final num unitPrice;
  final String imageUrl;
  final int quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      name: name,
      unitPrice: unitPrice,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartSession {
  CartSession._();

  static final ValueNotifier<List<CartItem>> items =
      ValueNotifier<List<CartItem>>(<CartItem>[]);

  static void addProduct(ProductModel product, {int quantity = 1}) {
    final current = List<CartItem>.from(items.value);
    final index =
        current.indexWhere((item) => item.productId == product.id);
    if (index >= 0) {
      final existing = current[index];
      current[index] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      current.add(
        CartItem(
          productId: product.id,
          name: product.name,
          unitPrice: product.displayPrice,
          imageUrl: product.imageUrl,
          quantity: quantity,
        ),
      );
    }
    items.value = current;
  }

  static void clear() {
    items.value = <CartItem>[];
  }
}
