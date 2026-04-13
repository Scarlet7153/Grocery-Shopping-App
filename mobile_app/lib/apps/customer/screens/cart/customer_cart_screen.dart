import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/cart/cart_session.dart';
import '../../../../core/format/formatters.dart';
import '../profile/recipient_info_screen.dart';

class CustomerCartScreen extends StatelessWidget {
  const CustomerCartScreen({super.key});

  Future<bool> _confirmRemove(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text('Bạn có chắc chắn muốn bỏ sản phẩm này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Không'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Đồng ý'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

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
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 56,
                  color: Colors.grey,
                ),
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
        final itemCount = items.length;
        const shippingFee = 0;
        final grandTotal = total + shippingFee;

        final Map<String, List<CartItem>> grouped = {};
        for (final item in items) {
          final key = item.storeName.isEmpty ? 'Cửa hàng' : item.storeName;
          grouped.putIfAbsent(key, () => <CartItem>[]).add(item);
        }
        final address =
            (AuthSession.address == null || AuthSession.address!.isEmpty)
            ? 'Chua co dia chi'
            : AuthSession.address!;
        final receiverName =
            (AuthSession.defaultHasOtherReceiver &&
                (AuthSession.defaultOtherReceiverName ?? '').isNotEmpty &&
                (AuthSession.defaultOtherReceiverPhone ?? '').isNotEmpty)
            ? '${(AuthSession.defaultOtherReceiverTitle ?? '').isEmpty ? '' : '${AuthSession.defaultOtherReceiverTitle} '}${AuthSession.defaultOtherReceiverName} - ${AuthSession.defaultOtherReceiverPhone}'
            : '${(AuthSession.fullName ?? '').isEmpty ? 'Khách hàng' : AuthSession.fullName!} - ${(AuthSession.phoneNumber ?? '').isEmpty ? 'Chưa có số điện thoại' : AuthSession.phoneNumber!}';

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
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              receiverName,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RecipientInfoScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...grouped.entries.expand((entry) {
                final storeName = entry.key;
                final storeItems = entry.value;
                return [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.store,
                              size: 18,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              storeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const SizedBox.shrink(),
                      ],
                    ),
                  ),
                  ...storeItems.map((item) {
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
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _QuantityButton(
                                icon: Icons.remove,
                                onPressed: () async {
                                  if (item.quantity <= 1) {
                                    final ok = await _confirmRemove(context);
                                    if (ok) {
                                      CartSession.removeProduct(item.productId);
                                    }
                                    return;
                                  }
                                  CartSession.updateQuantity(
                                    item.productId,
                                    item.quantity - 1,
                                  );
                                },
                              ),
                              Container(
                                width: 36,
                                alignment: Alignment.center,
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _QuantityButton(
                                icon: Icons.add,
                                onPressed: () {
                                  CartSession.updateQuantity(
                                    item.productId,
                                    item.quantity + 1,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
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
                ];
              }),
              const SizedBox(height: 6),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.payments, color: Colors.green),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Hình thức thanh toán',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.radio_button_checked,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 6),
                          const Text('Tiền mặt khi nhận hàng'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chi tiết thanh toán',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: 'Tạm tính ($itemCount món)',
                        value: formatVnd(total),
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Phí vận chuyển',
                        value: formatVnd(shippingFee),
                      ),
                      const Divider(height: 18),
                      _SummaryRow(
                        label: 'Tổng tiền',
                        value: formatVnd(grandTotal),
                        isTotal: true,
                      ),
                    ],
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
                  onPressed: () async {
                    final storeName = items.isNotEmpty
                        ? (items.first.storeName)
                        : '';
                    final order = <String, dynamic>{
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'storeName': storeName,
                      'status': 'CONFIRMED',
                      'totalAmount': grandTotal,
                      'grandTotal': grandTotal,
                      'createdAt': DateTime.now().toIso8601String(),
                    };
                    AuthSession.localOrders = [
                      order,
                      ...AuthSession.localOrders,
                    ];
                    await showDialog<void>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Đặt hàng thành công'),
                          content: const Text(
                            'Đơn hàng của bạn đã được ghi nhận.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Đóng'),
                            ),
                          ],
                        );
                      },
                    );
                    CartSession.clear();
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Đặt hàng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: isTotal ? Colors.black : Colors.black87,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(
          value,
          style: style.copyWith(color: isTotal ? Colors.red : Colors.black87),
        ),
      ],
    );
  }
}
