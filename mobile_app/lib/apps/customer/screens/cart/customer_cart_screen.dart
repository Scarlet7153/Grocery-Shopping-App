import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/cart/cart_session.dart';
import '../../../../core/format/formatters.dart';
import '../../../../shared/widgets/snackbar_utils.dart';
import '../../utils/customer_l10n.dart';
import 'customer_checkout_screen.dart';
import '../profile/recipient_info_screen.dart';

class CustomerCartScreen extends StatefulWidget {
  const CustomerCartScreen({super.key});

  @override
  State<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends State<CustomerCartScreen> {
  final Map<int, bool> _selected = {};

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: CartSession.items,
      builder: (context, items, _) {
        final scheme = Theme.of(context).colorScheme;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 56,
                  color: scheme.outline,
                ),
                const SizedBox(height: 12),
                Text(context.tr(
                    vi: 'Giỏ hàng đang trống', en: 'Your cart is empty')),
              ],
            ),
          );
        }

        for (final item in items) {
          _selected.putIfAbsent(item.productUnitMappingId, () => false);
        }
        _selected.removeWhere(
            (key, _) => !items.any((i) => i.productUnitMappingId == key));

        final selectedItems = items
            .where((i) => _selected[i.productUnitMappingId] == true)
            .toList();
        final selectedTotal = selectedItems.fold<num>(
            0, (sum, item) => sum + item.unitPrice * item.quantity);
        final selectedCount = selectedItems.length;

        final Map<String, List<CartItem>> grouped = {};
        for (final item in items) {
          final key = item.storeName.isEmpty
              ? context.tr(vi: 'Cửa hàng', en: 'Store')
              : item.storeName;
          grouped.putIfAbsent(key, () => <CartItem>[]).add(item);
        }

        return Container(
          color: scheme.surfaceContainerLowest,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr(vi: 'Giỏ hàng', en: 'Cart'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (items.isNotEmpty)
                          TextButton(
                            onPressed: () => _toggleSelectAll(items),
                            child: Text(
                              _selected.values.every((s) => s)
                                  ? context.tr(
                                      vi: 'Bỏ chọn tất cả', en: 'Deselect all')
                                  : context.tr(
                                      vi: 'Chọn tất cả', en: 'Select all'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...grouped.entries.expand((entry) {
                      final storeName = entry.key;
                      final storeItems = entry.value;
                      return [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.store,
                                  size: 18, color: scheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                storeName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              if (storeItems.any((i) =>
                                  _selected[i.productUnitMappingId] == true))
                                TextButton(
                                  onPressed: () => _deselectStore(storeItems),
                                  child: Text(
                                    context.tr(vi: 'Bỏ chọn', en: 'Deselect'),
                                    style: TextStyle(
                                        fontSize: 12, color: scheme.primary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ...storeItems.map((item) => _CartItemTile(
                              key: ValueKey(item.productUnitMappingId),
                              item: item,
                              isSelected:
                                  _selected[item.productUnitMappingId] == true,
                              onSelectedChanged: (v) {
                                setState(() {
                                  _selected[item.productUnitMappingId] =
                                      v ?? false;
                                });
                              },
                              onDelete: () => _removeItem(item),
                              onQuantityChanged: (qty) {
                                if (qty < 1) return;
                                CartSession.updateQuantity(
                                    item.productUnitMappingId, qty);
                              },
                            )),
                      ];
                    }),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              _CheckoutBar(
                selectedCount: selectedCount,
                total: selectedTotal,
                onBuy: selectedItems.isEmpty
                    ? null
                    : () => _onBuySelected(selectedItems),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleSelectAll(List<CartItem> items) {
    final allSelected = _selected.values.every((s) => s);
    setState(() {
      for (final item in items) {
        _selected[item.productUnitMappingId] = !allSelected;
      }
    });
  }

  void _deselectStore(List<CartItem> storeItems) {
    setState(() {
      for (final item in storeItems) {
        _selected[item.productUnitMappingId] = false;
      }
    });
  }

  void _removeItem(CartItem item) {
    CartSession.removeProduct(item.productUnitMappingId);
    _selected.remove(item.productUnitMappingId);
  }

  void _onBuySelected(List<CartItem> selectedItems) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => CustomerCheckoutScreen(selectedItems: selectedItems)),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final bool isSelected;
  final ValueChanged<bool?> onSelectedChanged;
  final VoidCallback onDelete;
  final ValueChanged<int> onQuantityChanged;

  const _CartItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onSelectedChanged,
    required this.onDelete,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey('dismiss_${item.productUnitMappingId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmRemove(context),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onSelectedChanged(!isSelected),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: onSelectedChanged,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: item.imageUrl.isEmpty
                      ? Container(
                          width: 72,
                          height: 72,
                          color: scheme.surfaceContainerHighest,
                          child:
                              Icon(Icons.image, color: scheme.onSurfaceVariant),
                        )
                      : item.imageUrl.startsWith('assets/')
                          ? Image.asset(item.imageUrl,
                              width: 72, height: 72, fit: BoxFit.cover)
                          : Image.network(
                              item.imageUrl,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 72,
                                height: 72,
                                color: scheme.surfaceContainerHighest,
                                child: Icon(Icons.image,
                                    color: scheme.onSurfaceVariant),
                              ),
                            ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final ok = await _confirmRemove(context);
                              if (ok == true) onDelete();
                            },
                            child: Icon(Icons.close,
                                size: 20, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      if (item.unitLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.unitLabel,
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatVnd(item.unitPrice),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: scheme.error,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: scheme.outlineVariant),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _QtyBtn(
                                  icon: Icons.remove,
                                  onTap: item.quantity > 1
                                      ? () =>
                                          onQuantityChanged(item.quantity - 1)
                                      : null,
                                ),
                                Container(
                                  width: 36,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                _QtyBtn(
                                  icon: Icons.add,
                                  onTap: item.quantity < item.stockQuantity
                                      ? () =>
                                          onQuantityChanged(item.quantity + 1)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmRemove(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr(vi: 'Xác nhận', en: 'Confirm')),
        content: Text(context.tr(
          vi: 'Bạn có chắc muốn xóa sản phẩm này?',
          en: 'Are you sure you want to remove this item?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr(vi: 'Không', en: 'No')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.tr(vi: 'Xóa', en: 'Remove')),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? scheme.primary : scheme.outline,
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final int selectedCount;
  final num total;
  final VoidCallback? onBuy;

  const _CheckoutBar({
    required this.selectedCount,
    required this.total,
    this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedCount > 0)
                    Text(
                      context.tr(
                          vi: 'Đã chọn $selectedCount sản phẩm',
                          en: '$selectedCount item(s) selected'),
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  Text(
                    formatVnd(total),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: scheme.error,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    onBuy != null ? scheme.primary : scheme.outline,
                foregroundColor: Colors.white,
                disabledBackgroundColor: scheme.surfaceContainerHighest,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                context.tr(vi: 'Mua hàng', en: 'Buy now'),
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
