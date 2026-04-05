import 'package:flutter/material.dart';

import '../../../../core/cart/cart_session.dart';
import '../../../../core/format/formatters.dart';

class CustomerCartScreen extends StatelessWidget {
  const CustomerCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: CartSession.items,
      builder: (context, items, _) {
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text('Giỏ hàng đang trống'),
              ],
            ),
          );
        }

        final total = items.fold<num>(
          0,
          (sum, item) => sum + item.unitPrice * item.quantity,
        );

        return Container(
          color: const Color(0xFFF6F8FB),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Gi\u1ecf h\u00e0ng',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...items.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: item.imageUrl.isEmpty
                          ? Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            )
                          : (item.imageUrl.startsWith('assets/'))
                              ? Image.asset(
                                  item.imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  item.imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) {
                                    return Container(
                                      width: 56,
                                      height: 56,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image),
                                    );
                                  },
                                ),
                    ),
                    title: Text(item.name),
                    subtitle: Text('S\u1ed1 l\u01b0\u1ee3ng: ${item.quantity}'),
                    trailing: Text(
                      formatVnd(item.unitPrice * item.quantity),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 6),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  title: const Text('T\u1ed5ng c\u1ed9ng'),
                  trailing: Text(
                    formatVnd(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.payment),
                  label: const Text('Thanh to\u00e1n'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
