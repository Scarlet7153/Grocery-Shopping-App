import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/customer_state_view.dart';
import '../../services/customer_realtime_service.dart';
import '../../utils/customer_l10n.dart';
import '../../../../core/format/formatters.dart';
import '../../../../core/network/api_client.dart';
import 'customer_order_detail_screen.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = const [];
  final CustomerRealtimeService _realtimeService = CustomerRealtimeService();
  StreamSubscription<CustomerRealtimeEvent>? _realtimeSubscription;
  bool _isRealtimeSyncing = false;

  num _asNum(dynamic v) {
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initRealtimeStreaming();
      }
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  Future<void> _initRealtimeStreaming() async {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _realtimeService.events.listen((event) {
      switch (event.type) {
        case CustomerRealtimeEventType.orderCreated:
        case CustomerRealtimeEventType.orderStatusChanged:
          _refreshOrdersFromRealtime();
          break;
        case CustomerRealtimeEventType.error:
        case CustomerRealtimeEventType.connected:
        case CustomerRealtimeEventType.disconnected:
          break;
      }
    });

    await _realtimeService.connect();
  }

  Future<void> _refreshOrdersFromRealtime() async {
    if (!mounted || _isRealtimeSyncing || _loading) return;

    _isRealtimeSyncing = true;
    try {
      await _loadOrders();
    } finally {
      _isRealtimeSyncing = false;
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.dio.get('/orders/my-orders');
      final data = response.data;
      if (data is Map && data['data'] is List) {
        _orders = List<Map<String, dynamic>>.from(data['data']);
      } else {
        _orders = const [];
      }
    } catch (e) {
      _error = context.tr(
        vi: 'Không thể tải đơn hàng',
        en: 'Unable to load orders',
      );
      _orders = const [];
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return CustomerStateView.loading(
        title: context.tr(vi: 'Đang tải dữ liệu', en: 'Loading data'),
        message: context.tr(
            vi: 'Vui lòng chờ trong giây lát...',
            en: 'Please wait a moment...'),
      );
    }

    if (_error != null) {
      return CustomerStateView.error(
        message: _error!,
        onAction: _loadOrders,
      );
    }

    if (_orders.isEmpty) {
      return CustomerStateView.empty(
        title: context.tr(vi: 'Chưa có đơn hàng', en: 'No orders yet'),
        message: context.tr(
          vi: 'Khi đặt đơn đầu tiên, lịch sử mua hàng sẽ hiển thị tại đây.',
          en: 'Your order history will appear here after your first purchase.',
        ),
        icon: Icon(Icons.receipt_long, size: 56),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.surfaceContainerLowest,
      child: RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.tr(vi: 'Đơn hàng', en: 'Orders'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._orders.map((order) {
              final total = order['grandTotal'] ?? order['totalAmount'] ?? 0;
              final status = order['status']?.toString() ?? 'UNKNOWN';
              final id = order['id']?.toString() ?? '';
              final storeName = order['storeName']?.toString() ?? '';
              final createdAt = order['createdAt']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    if (id.isEmpty) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerOrderDetailScreen(orderId: id),
                      ),
                    );
                    await _loadOrders();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(vi: 'Đơn #$id', en: 'Order #$id'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (storeName.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    storeName,
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (createdAt.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    createdAt,
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatVnd(_asNum(total)),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: scheme.error,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _StatusChip(status: status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  String _label(BuildContext context) {
    switch (status) {
      case 'PENDING':
        return context.tr(vi: 'Chờ xác nhận', en: 'Pending');
      case 'CONFIRMED':
        return context.tr(vi: 'Đã xác nhận', en: 'Confirmed');
      case 'PICKING_UP':
        return context.tr(vi: 'Đang lấy hàng', en: 'Picking up');
      case 'DELIVERING':
        return context.tr(vi: 'Đang giao', en: 'Delivering');
      case 'DELIVERED':
        return context.tr(vi: 'Đã giao', en: 'Delivered');
      case 'CANCELLED':
        return context.tr(vi: 'Đã hủy', en: 'Cancelled');
      default:
        return status;
    }
  }

  Color _color() {
    switch (status) {
      case 'DELIVERED':
        return Colors.green;
      case 'DELIVERING':
        return Colors.orange;
      case 'PICKING_UP':
        return Colors.deepOrange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label(context),
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
