import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/store_theme.dart';
import '../../bloc/store_blocs.dart';
import '../../../../features/orders/data/order_model.dart';

class StoreOrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const StoreOrderDetailScreen({super.key, required this.order});

  Color _statusColor() {
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

  String _statusLabel() {
    switch (order.status?.toUpperCase()) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'PICKING_UP':
        return 'Đang chuẩn bị';
      case 'DELIVERING':
        return 'Đang giao';
      case 'DELIVERED':
        return 'Hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return order.status ?? '—';
    }
  }

  String _statusTime() {
    if (order.createdAt != null) {
      try {
        final dt = DateTime.parse(order.createdAt!);
        return 'Đặt lúc ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }
    return '';
  }

  IconData _statusIcon() {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Đơn hàng #${order.id}'),
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
                statusColor: _statusColor(),
                statusLabel: _statusLabel(),
                statusTime: _statusTime(),
                statusIcon: _statusIcon()),
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
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
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
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: StoreTheme.primaryColor),
              SizedBox(width: 8),
              Text('Thông tin khách hàng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(),
          _InfoRow(label: 'Tên khách hàng', value: order.customerName ?? '—'),
          _InfoRow(label: 'Số điện thoại', value: order.customerPhone ?? '—'),
          _InfoRow(label: 'Địa chỉ giao hàng', value: order.address ?? '—'),
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
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shopping_bag, color: StoreTheme.primaryColor),
              SizedBox(width: 8),
              Text('Sản phẩm',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                Text(item.productName ?? 'Sản phẩm',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
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
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: StoreTheme.primaryColor),
              SizedBox(width: 8),
              Text('Thanh toán',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(),
          _PaymentRow(label: 'Tạm tính', value: '${total.toStringAsFixed(0)}đ'),
          _PaymentRow(
              label: 'Phí vận chuyển',
              value: '${shippingFee.toStringAsFixed(0)}đ'),
          const Divider(),
          _PaymentRow(
              label: 'Tổng cộng',
              value: '${grandTotal.toStringAsFixed(0)}đ',
              isBold: true),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.payment, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text('Thanh toán khi nhận hàng',
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
      case 'PICKING_UP':
        return 'Đơn hàng đang được chuẩn bị';
      case 'DELIVERING':
        return 'Đơn hàng đang giao';
      case 'DELIVERED':
        return 'Đơn hàng đã hoàn thành';
      case 'CANCELLED':
        return 'Đơn hàng đã bị hủy';
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
                  child: const Text('Từ chối',
                      style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus(context, 'CONFIRMED'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: StoreTheme.primaryColor,
                      padding: const EdgeInsets.all(16)),
                  child: const Text('Xác nhận'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (order.status == 'CONFIRMED')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _updateStatus(context, 'PICKING_UP'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.all(16)),
              child: const Text('Bắt đầu chuẩn bị'),
            ),
          ),
        if (order.status == 'PICKING_UP')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _updateStatus(context, 'DELIVERING'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.all(16)),
              child: const Text('Giao cho tài xế'),
            ),
          ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối đơn'),
        content: const Text('Bạn có chắc muốn từ chối đơn hàng này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(context, 'CANCELLED');
            },
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}
