import 'package:flutter/foundation.dart';

import '../../features/customer/home/data/product_model.dart';

class CartItem {
  CartItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.imageUrl,
    required this.storeName,
    required this.quantity,
  });

  final int productId;
  final String name;
  final num unitPrice;
  final String imageUrl;
  final String storeName;
  final int quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      name: name,
      unitPrice: unitPrice,
      imageUrl: imageUrl,
      storeName: storeName,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartSession {
  CartSession._();

  static final ValueNotifier<List<CartItem>> items =
      ValueNotifier<List<CartItem>>(<CartItem>[]);

  static void addProduct(
    ProductModel product, {
    int quantity = 1,
    num? unitPrice,
  }) {
    final current = List<CartItem>.from(items.value);
    final index = current.indexWhere((item) => item.productId == product.id);
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
          unitPrice: unitPrice ?? product.displayPrice,
          imageUrl: product.imageUrl,
          storeName: product.storeName,
          quantity: quantity,
        ),
      );
    }
    items.value = current;
  }

  static void updateQuantity(int productId, int quantity) {
    final current = List<CartItem>.from(items.value);
    final index = current.indexWhere((item) => item.productId == productId);
    if (index < 0) {
      return;
    }
    if (quantity <= 0) {
      current.removeAt(index);
    } else {
      final existing = current[index];
      current[index] = existing.copyWith(quantity: quantity);
    }
    items.value = current;
  }

  static void removeProduct(int productId) {
    final current = List<CartItem>.from(items.value);
    current.removeWhere((item) => item.productId == productId);
    items.value = current;
  }

  static void clear() {
    items.value = <CartItem>[];
  }
}
