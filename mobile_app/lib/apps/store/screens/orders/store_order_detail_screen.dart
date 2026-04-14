import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/store_theme.dart';
import '../../bloc/store_blocs.dart';
import '../../../../features/orders/data/order_model.dart';
import '../../utils/store_localizations.dart';

class StoreOrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  const StoreOrderDetailScreen({super.key, required this.order});

  @override
  State<StoreOrderDetailScreen> createState() => _StoreOrderDetailScreenState();
}

class _StoreOrderDetailScreenState extends State<StoreOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StoreOrdersBloc>().add(LoadStoreOrders());
  }

  OrderModel _resolveLatestOrder(StoreOrdersState state) {
    if (state is StoreOrdersLoaded) {
      for (final item in state.orders) {
        if (item.id == widget.order.id) return item;
      }
    }
    return widget.order;
  }

  Color _statusColor(OrderModel order) {
    switch (order.status?.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
      case 'PICKING_UP':
        return Colors.blue;
      case 'DELIVERING':
        return Colors.purple;
      case 'DELIVERED':
        return StoreTheme.primaryColor;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(BuildContext context, OrderModel order) {
    switch (order.status?.toUpperCase()) {
      case 'PENDING':
        return context.storeTr('pending_status');
      case 'CONFIRMED':
        return context.storeTr('confirmed_status');
      case 'PICKING_UP':
        return context.storeTr('preparing_status');
      case 'DELIVERING':
        return context.storeTr('delivering_status');
      case 'DELIVERED':
        return context.storeTr('completed_status');
      case 'CANCELLED':
        return context.storeTr('cancelled_status');
      default:
        return order.status ?? '—';
    }
  }

  String _statusTime(BuildContext context, OrderModel order) {
    if (order.createdAt != null) {
      try {
        final dt = DateTime.parse(order.createdAt!);
        return '${context.storeTr('ordered_at')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }
    return '';
  }

  IconData _statusIcon(OrderModel order) {
    switch (order.status?.toUpperCase()) {
      case 'PENDING':
        return Icons.hourglass_empty;
      case 'CONFIRMED':
        return Icons.check_circle;
      case 'PICKING_UP':
        return Icons.inventory;
      case 'DELIVERING':
        return Icons.local_shipping;
      case 'DELIVERED':
        return Icons.done_all;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreOrdersBloc, StoreOrdersState>(
      builder: (context, state) {
        final order = _resolveLatestOrder(state);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            title: Text('${context.storeTr('order_number')} #${order.id}'),
            backgroundColor: StoreTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusSection(
                    status: order.status,
                    statusColor: _statusColor(order),
                    statusLabel: _statusLabel(context, order),
                    statusTime: _statusTime(context, order),
                    statusIcon: _statusIcon(order)),
                const SizedBox(height: 16),
                _CustomerSection(order: order),
                const SizedBox(height: 16),
                if (order.items != null && order.items!.isNotEmpty) ...[
                  _ItemsSection(items: order.items!),
                  const SizedBox(height: 16),
                ],
                _PaymentSection(order: order),
                const SizedBox(height: 24),
                _ActionButtons(order: order),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusSection extends StatelessWidget {
  final String? status;
  final Color statusColor;
  final String statusLabel;
  final String statusTime;
  final IconData statusIcon;
  const _StatusSection(
      {required this.status,
      required this.statusColor,
      required this.statusLabel,
      required this.statusTime,
      required this.statusIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(statusIcon, color: statusColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusLabel,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor)),
                Text(statusTime,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerSection extends StatelessWidget {
  final OrderModel order;
  const _CustomerSection({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: StoreTheme.primaryColor),
              const SizedBox(width: 8),
              Text(context.storeTr('customer_info'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(),
          _InfoRow(
              label: context.storeTr('customer_name'),
              value: order.customerName ?? '—'),
          _InfoRow(
              label: context.storeTr('phone_number'),
              value: order.customerPhone ?? '—'),
          _InfoRow(
              label: context.storeTr('delivery_address'),
              value: order.address ?? '—'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  final List<OrderItemModel> items;
  const _ItemsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag, color: StoreTheme.primaryColor),
              const SizedBox(width: 8),
              Text(context.storeTr('items'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(),
          ...items.map((item) => _ItemTile(item: item)),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final OrderItemModel item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.productImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(item.productImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.shopping_bag,
                            color: StoreTheme.primaryColor)),
                  )
                : const Icon(Icons.shopping_bag,
                    color: StoreTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName ?? context.storeTr('product'),
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                if (item.unitName != null && item.unitName!.trim().isNotEmpty)
                  Text(
                    item.unitName!,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                Text(
                    '${item.quantity} x ${item.unitPrice?.toStringAsFixed(0) ?? 0}đ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(
              '${(item.subtotal ?? (item.quantity ?? 0) * (item.unitPrice ?? 0)).toStringAsFixed(0)}đ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  final OrderModel order;
  const _PaymentSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final shippingFee = order.shippingFee ?? 0;
    final total = order.totalAmount ?? 0;
    final grandTotal = order.grandTotal ?? (total + shippingFee);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, color: StoreTheme.primaryColor),
              const SizedBox(width: 8),
              Text(context.storeTr('payment'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(),
          _PaymentRow(
              label: context.storeTr('subtotal'),
              value: '${total.toStringAsFixed(0)}đ'),
          _PaymentRow(
              label: context.storeTr('shipping_fee'),
              value: '${shippingFee.toStringAsFixed(0)}đ'),
          const Divider(),
          _PaymentRow(
              label: context.storeTr('total_amount'),
              value: '${grandTotal.toStringAsFixed(0)}đ',
              isBold: true),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.payment, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(context.storeTr('cod_payment'),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  const _PaymentRow(
      {required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: isBold
                  ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  : null),
          Text(value,
              style: isBold
                  ? const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: StoreTheme.primaryColor)
                  : null),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final OrderModel order;
  const _ActionButtons({required this.order});

  void _updateStatus(BuildContext context, String newStatus) {
    context
        .read<StoreOrdersBloc>()
        .add(UpdateOrderStatus(order.id as int, newStatus));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(_getStatusMessage(newStatus)),
          backgroundColor: StoreTheme.primaryColor),
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'CONFIRMED':
        return 'Đã xác nhận đơn hàng';
      default:
        return 'Cập nhật trạng thái thành công';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (order.status == 'PENDING') ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(context),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.all(16)),
                  child: Text(context.storeTr('cancel'),
                      style: const TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus(context, 'CONFIRMED'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: StoreTheme.primaryColor,
                      padding: const EdgeInsets.all(16)),
                  child: Text(context.storeTr('confirm')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.storeTr('cancel_order')),
        content: Text(context.storeTr('cancel_order_confirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.storeTr('close'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(context, 'CANCELLED');
            },
            child: Text(context.storeTr('cancel_order')),
          ),
        ],
      ),
    );
  }
}
