import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../bloc/store_blocs.dart';
import '../../../../features/orders/data/order_model.dart';
import 'store_order_detail_screen.dart';

String _storeTr(BuildContext context, {required String vi, required String en}) {
  final localizations = AppLocalizations.of(context);
  return localizations?.byLocale(vi: vi, en: en) ?? vi;
}

class StoreOrdersScreen extends StatefulWidget {
  const StoreOrdersScreen({super.key});
  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen> {
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    context.read<StoreOrdersBloc>().add(LoadStoreOrders());
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    if (_filterStatus == null) return orders;
    return orders.where((o) => o.status == _filterStatus).toList();
  }

  void _updateStatus(int orderId, String newStatus) {
    context.read<StoreOrdersBloc>().add(UpdateOrderStatus(orderId, newStatus));
    String message;
    switch (newStatus) {
      case 'CONFIRMED':
        message = _storeTr(context,
            vi: 'Đã xác nhận đơn hàng', en: 'Order confirmed');
        break;
      case 'PICKING_UP':
        message = _storeTr(context,
            vi: 'Đơn hàng đang được chuẩn bị', en: 'Order is being prepared');
        break;
      case 'DELIVERING':
        message =
            _storeTr(context, vi: 'Đơn hàng đang giao', en: 'Order is delivering');
        break;
      case 'DELIVERED':
        message =
            _storeTr(context, vi: 'Đơn hàng đã hoàn thành', en: 'Order completed');
        break;
      case 'CANCELLED':
        message = _storeTr(context,
            vi: 'Đơn hàng đã bị hủy', en: 'Order has been cancelled');
        break;
      default:
        message = _storeTr(context,
            vi: 'Cập nhật trạng thái thành công',
            en: 'Status updated successfully');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message), backgroundColor: StoreTheme.primaryColor),
    );
  }

  void _setFilter(String? status) {
    setState(() => _filterStatus = status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
          title: Text(_storeTr(context, vi: 'Đơn hàng', en: 'Orders')),
          backgroundColor: StoreTheme.primaryColor,
          foregroundColor: Colors.white,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(_storeTr(context, vi: 'Tất cả', en: 'All'), null),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        _storeTr(context, vi: 'Chờ xác nhận', en: 'Pending'),
                        'PENDING'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        _storeTr(context, vi: 'Đã xác nhận', en: 'Confirmed'),
                        'CONFIRMED'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        _storeTr(context, vi: 'Đang giao', en: 'Delivering'),
                        'DELIVERING'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        _storeTr(context, vi: 'Hoàn thành', en: 'Completed'),
                        'DELIVERED'),
                  ],
                ),
              ),
            ),
          )),
      body: BlocBuilder<StoreOrdersBloc, StoreOrdersState>(
        builder: (context, state) {
          if (state is StoreOrdersLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is StoreOrdersError)
            return Center(child: Text(state.message));
          if (state is StoreOrdersLoaded) {
            final orders = _filterOrders(state.orders);
            if (orders.isEmpty) {
              return Center(
                child: Text(
                  _storeTr(context,
                      vi: 'Chưa có đơn hàng nào', en: 'No orders yet'),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<StoreOrdersBloc>().add(LoadStoreOrders());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (ctx, i) => _OrderCard(
                  order: orders[i],
                  onUpdateStatus: _updateStatus,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () => _setFilter(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? StoreTheme.primaryColor
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? StoreTheme.primaryColor
                : Colors.grey.withValues(alpha: 0.28),
          ),
        ),
        child: Text(label,
            style: TextStyle(
            color: isSelected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
                fontSize: 12)),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final Function(int, String) onUpdateStatus;
  const _OrderCard({required this.order, required this.onUpdateStatus});

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

  String _statusLabel(BuildContext context) {
    switch (order.status?.toUpperCase()) {
      case 'PENDING':
        return _storeTr(context, vi: 'Chờ xác nhận', en: 'Pending');
      case 'CONFIRMED':
        return _storeTr(context, vi: 'Đã xác nhận', en: 'Confirmed');
      case 'PICKING_UP':
        return _storeTr(context, vi: 'Đang chuẩn bị', en: 'Preparing');
      case 'DELIVERING':
        return _storeTr(context, vi: 'Đang giao', en: 'Delivering');
      case 'DELIVERED':
        return _storeTr(context, vi: 'Hoàn thành', en: 'Completed');
      case 'CANCELLED':
        return _storeTr(context, vi: 'Đã hủy', en: 'Cancelled');
      default:
        return order.status ?? '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = order.id;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StoreOrderDetailScreen(order: order)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${orderId ?? ''}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(_statusLabel(context),
                      style: TextStyle(
                          color: _statusColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
                Text(order.customerName ?? _storeTr(context, vi: 'Khách hàng', en: 'Customer'),
                style: const TextStyle(fontSize: 14)),
            if (order.customerPhone != null)
              Text(order.customerPhone!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('${(order.totalAmount ?? 0).toStringAsFixed(0)}đ',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: StoreTheme.primaryColor)),
            if (order.items != null && order.items!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${order.items!.length} ${_storeTr(context, vi: 'sản phẩm', en: 'items')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
            if (order.status == 'PENDING' && orderId != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCancelDialog(context, orderId),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red)),
                      child: Text(_storeTr(context, vi: 'Hủy', en: 'Cancel'),
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onUpdateStatus(orderId, 'CONFIRMED'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: StoreTheme.primaryColor),
                      child: Text(_storeTr(context, vi: 'Xác nhận', en: 'Confirm')),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, int orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_storeTr(context, vi: 'Hủy đơn', en: 'Cancel order')),
        content: Text(_storeTr(context,
            vi: 'Bạn có chắc muốn hủy đơn hàng này?',
            en: 'Are you sure you want to cancel this order?')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_storeTr(context, vi: 'Đóng', en: 'Close'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              onUpdateStatus(orderId, 'CANCELLED');
              Navigator.pop(ctx);
            },
            child: Text(_storeTr(context, vi: 'Hủy đơn', en: 'Cancel order')),
          ),
        ],
      ),
    );
  }
}
