import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/customer_state_view.dart';
import '../../services/customer_realtime_service.dart';
import '../../utils/customer_l10n.dart';
import '../../../../core/format/formatters.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/notification/bloc/notification_bloc.dart';
import '../../../../features/notification/data/notification_model.dart';
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

  // Filter & Search
  String _searchQuery = '';
  String _selectedStatus = 'ALL';
  bool _sortNewestFirst = true;

  final TextEditingController _searchController = TextEditingController();

  static const _statusOptions = [
    {'value': 'ALL', 'vi': 'Tất cả', 'en': 'All'},
    {'value': 'PENDING', 'vi': 'Chờ xác nhận', 'en': 'Pending'},
    {'value': 'CONFIRMED', 'vi': 'Đã xác nhận', 'en': 'Confirmed'},
    {'value': 'PICKING_UP', 'vi': 'Đang lấy hàng', 'en': 'Picking up'},
    {'value': 'DELIVERING', 'vi': 'Đang giao', 'en': 'Delivering'},
    {'value': 'DELIVERED', 'vi': 'Đã giao', 'en': 'Delivered'},
    {'value': 'CANCELLED', 'vi': 'Đã hủy', 'en': 'Cancelled'},
  ];

  num _asNum(dynamic v) {
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? 0;
  }

  String _norm(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    s = s.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    s = s.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    s = s.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    s = s.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    s = s.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    s = s.replaceAll(RegExp(r'[đ]'), 'd');
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  List<Map<String, dynamic>> get _filteredOrders {
    var list = List<Map<String, dynamic>>.from(_orders);

    // Filter by status
    if (_selectedStatus != 'ALL') {
      list = list.where((o) => (o['status']?.toString() ?? '') == _selectedStatus).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _norm(_searchQuery);
      list = list.where((o) {
        final id = _norm(o['id']?.toString() ?? '');
        final store = _norm(o['storeName']?.toString() ?? '');
        final items = o['items'] as List?;
        final itemNames = items != null
            ? items.map((i) => _norm(i['productName']?.toString() ?? '')).join(' ')
            : '';
        return id.contains(query) || store.contains(query) || itemNames.contains(query);
      }).toList();
    }

    // Sort by createdAt
    list.sort((a, b) {
      final aDate = a['createdAt']?.toString() ?? '';
      final bDate = b['createdAt']?.toString() ?? '';
      final cmp = aDate.compareTo(bDate);
      return _sortNewestFirst ? -cmp : cmp;
    });

    return list;
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
    _searchController.dispose();
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
        case CustomerRealtimeEventType.notificationReceived:
          if (event.payload != null) {
            final notification = NotificationModel.fromJson(event.payload!);
            if (mounted) {
              context
                  .read<NotificationBloc>()
                  .add(ReceiveRealtimeNotification(notification));
            }
          }
          break;
        case CustomerRealtimeEventType.notificationUnreadCountUpdated:
          if (event.payload != null && event.payload!['count'] != null) {
            final count = event.payload!['count'] as int;
            if (mounted) {
              context.read<NotificationBloc>().add(UpdateUnreadCount(count));
            }
          }
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
      debugPrint('❌ Error loading orders: $e');
      _error = '$e';
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
    final filtered = _filteredOrders;

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

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.tr(vi: 'Tìm theo mã, cửa hàng, sản phẩm...', en: 'Search by ID, store, product...'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: scheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 12),

            // Status filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusOptions.map((opt) {
                  final value = opt['value']!;
                  final label = context.tr(vi: opt['vi']!, en: opt['en']!);
                  final selected = value == _selectedStatus;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedStatus = value),
                      selectedColor: scheme.primary.withValues(alpha: 0.15),
                      checkmarkColor: scheme.primary,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Sort toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr(
                    vi: '${filtered.length} đơn hàng',
                    en: '${filtered.length} orders',
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _sortNewestFirst = !_sortNewestFirst),
                  icon: Icon(
                    _sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 16,
                    color: scheme.primary,
                  ),
                  label: Text(
                    context.tr(
                      vi: _sortNewestFirst ? 'Mới nhất' : 'Cũ nhất',
                      en: _sortNewestFirst ? 'Newest' : 'Oldest',
                    ),
                    style: TextStyle(fontSize: 13, color: scheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Order list
            if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        context.tr(vi: 'Không tìm thấy đơn hàng', en: 'No orders found'),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filtered.map((order) {
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

  Color _color(ColorScheme scheme) {
    switch (status) {
      case 'DELIVERED':
        return Colors.green;
      case 'DELIVERING':
        return Colors.orange;
      case 'PICKING_UP':
        return Colors.deepOrange;
      case 'CONFIRMED':
        return scheme.primary;
      case 'CANCELLED':
        return scheme.error;
      default:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _color(scheme);

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
