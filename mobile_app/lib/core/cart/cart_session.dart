import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/customer/home/data/product_model.dart';

class CartItem {
  CartItem({
    required this.productId,
    required this.productUnitMappingId,
    required this.unitLabel,
    required this.name,
    required this.unitPrice,
    required this.imageUrl,
    required this.storeName,
    required this.stockQuantity,
    required this.quantity,
  });

  final int productId;

  /// Backend expects `productUnitMappingId` when creating an order.
  /// This id is unique per sellable variant.
  final int productUnitMappingId;
  final String unitLabel;
  final String name;
  final num unitPrice;
  final String imageUrl;
  final String storeName;
  final int stockQuantity;
  final int quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      productUnitMappingId: productUnitMappingId,
      unitLabel: unitLabel,
      name: name,
      unitPrice: unitPrice,
      imageUrl: imageUrl,
      storeName: storeName,
      stockQuantity: stockQuantity,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productUnitMappingId': productUnitMappingId,
        'unitLabel': unitLabel,
        'name': name,
        'unitPrice': unitPrice,
        'imageUrl': imageUrl,
        'storeName': storeName,
        'stockQuantity': stockQuantity,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as int,
        productUnitMappingId: json['productUnitMappingId'] as int,
        unitLabel: json['unitLabel'] as String,
        name: json['name'] as String,
        unitPrice: json['unitPrice'] as num,
        imageUrl: json['imageUrl'] as String,
        storeName: json['storeName'] as String,
        stockQuantity: json['stockQuantity'] as int,
        quantity: json['quantity'] as int,
      );
}

class CartSession {
  CartSession._();

  static const _key = 'cart_items';

  static final ValueNotifier<List<CartItem>> items =
      ValueNotifier<List<CartItem>>(<CartItem>[]);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = (jsonDecode(raw) as List)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
      items.value = list;
    }
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.value.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  static Future<void> addProduct(
    ProductModel product, {
    int quantity = 1,
    num? unitPrice,
    int? productUnitMappingId,
    String? unitLabel,
    int? stockQuantity,
  }) async {
    final fallbackUnit = product.units.isNotEmpty ? product.units.first : null;
    final unitMappingId = productUnitMappingId ?? fallbackUnit?.id ?? 0;
    final resolvedStock = stockQuantity ?? fallbackUnit?.stockQuantity ?? 0;
    final resolvedLabel = unitLabel ?? fallbackUnit?.unitName ?? '';

    final current = List<CartItem>.from(items.value);
    final index = current.indexWhere(
      (item) => item.productUnitMappingId == unitMappingId,
    );

    int nextQuantity = quantity;
    if (index >= 0) {
      final existing = current[index];
      nextQuantity = existing.quantity + quantity;
      if (resolvedStock > 0 && nextQuantity > resolvedStock) {
        nextQuantity = resolvedStock;
      }
      current[index] = existing.copyWith(
        quantity: nextQuantity,
      );
    } else {
      if (resolvedStock > 0 && nextQuantity > resolvedStock) {
        nextQuantity = resolvedStock;
      }
      current.add(
        CartItem(
          productId: product.id,
          productUnitMappingId: unitMappingId,
          unitLabel: resolvedLabel,
          name: product.name,
          unitPrice: unitPrice ?? product.displayPrice,
          imageUrl: product.imageUrl,
          storeName: product.storeName,
          stockQuantity: resolvedStock,
          quantity: nextQuantity,
        ),
      );
    }
    items.value = current;
    await _save();
  }

  static Future<void> updateQuantity(
      int productUnitMappingId, int quantity) async {
    final current = List<CartItem>.from(items.value);
    final index = current.indexWhere(
      (item) => item.productUnitMappingId == productUnitMappingId,
    );
    if (index < 0) {
      return;
    }
    if (quantity <= 0) {
      current.removeAt(index);
    } else {
      final existing = current[index];
      var next = quantity;
      if (existing.stockQuantity > 0 && next > existing.stockQuantity) {
        next = existing.stockQuantity;
      }
      current[index] = existing.copyWith(quantity: next);
    }
    items.value = current;
    await _save();
  }

  static Future<void> removeProduct(int productUnitMappingId) async {
    final current = List<CartItem>.from(items.value);
    current.removeWhere(
      (item) => item.productUnitMappingId == productUnitMappingId,
    );
    items.value = current;
    await _save();
  }

  static Future<void> clear() async {
    items.value = <CartItem>[];
    await _save();
  }
}
