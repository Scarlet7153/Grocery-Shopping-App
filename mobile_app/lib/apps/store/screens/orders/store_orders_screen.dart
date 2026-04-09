import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_shopping_app/core/ui/ui_constants.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:intl/intl.dart';

import '../../block/store_orders_bloc.dart';
import '../../widgets/scale_on_tap.dart';

/// Design system — Grab Merchant (#00B14F)
const Color _kPrimary = Color(0xFF00B14F);
const Color _kSurface = Color(0xFFF5F6FA);
const Color _kCardShadow = Color(0x0A000000);

/// Một dòng sản phẩm trong đơn (chỉ UI)
class _OrderItem {
  final String name;
  final int qty;
  final String price;
  _OrderItem({required this.name, required this.qty, required this.price});
}

// Demo data removed as per user request

class _OrderData {
  final String id;
  final String amount;
  final String status;
  final OrderStatusType statusType;
  final String customerName;
  final String phone;
  final String address;
  final List<_OrderItem> items;
  final String createdAt;
  final List<String> statusHistory;

  _OrderData({
    required this.id,
    required this.amount,
    required this.status,
    required this.statusType,
    this.customerName = '',
    this.phone = '',
    this.address = '',
    this.items = const [],
    this.createdAt = '',
    this.statusHistory = const [],
  });
}

/// Luồng đơn: Đơn mới → Đang chuẩn bị → Đang giao → Hoàn thành
enum OrderStatusType { newOrder, processing, shipping, done }

OrderStatusType _orderStatusFromApi(String? s) {
  if (s == null || s.isEmpty) return OrderStatusType.newOrder;
  final u = s.toUpperCase();
  if (u == 'PENDING' || u == 'NEW') return OrderStatusType.newOrder;
  if (u == 'PROCESSING') return OrderStatusType.processing;
  if (u == 'SHIPPING') return OrderStatusType.shipping;
  if (u == 'DELIVERED' || u == 'DONE' || u == 'COMPLETED')
    return OrderStatusType.done;
  return OrderStatusType.newOrder;
}

String _orderStatusToApi(OrderStatusType t) {
  switch (t) {
    case OrderStatusType.newOrder:
      return 'PENDING';
    case OrderStatusType.processing:
      return 'PROCESSING';
    case OrderStatusType.shipping:
      return 'SHIPPING';
    case OrderStatusType.done:
      return 'DELIVERED';
  }
}

String _formatAmount(double? v) {
  if (v == null) return '0đ';
  return '${NumberFormat('#,###', 'vi').format(v.round())}đ';
}

_OrderData _orderDataFromModel(OrderModel o) {
  final statusType = _orderStatusFromApi(o.status);
  final statusLabels = {
    OrderStatusType.newOrder: 'Đơn mới',
    OrderStatusType.processing: 'Đang chuẩn bị',
    OrderStatusType.shipping: 'Đang giao',
    OrderStatusType.done: 'Hoàn thành',
  };
  final items = (o.items ?? []).map((i) => _OrderItem(
    name: i.productName ?? '',
    qty: i.quantity ?? 0,
    price: _formatAmount(i.unitPrice),
  )).toList();
  final history = <String>['Đặt đơn'];
  if (statusType.index >= 1) history.add('Đang chuẩn bị');
  if (statusType.index >= 2) history.add('Đang giao');
  if (statusType.index >= 3) history.add('Hoàn thành');
  final String idStr = o.id?.toString() ?? '';
  final displayId = idStr.isNotEmpty ? (idStr.startsWith('#') ? idStr : '#$idStr') : '';
  return _OrderData(
    id: displayId,
    amount: _formatAmount(o.totalAmount),
    status: statusLabels[statusType] ?? o.status ?? 'Đơn mới',
    statusType: statusType,
    customerName: o.customerName ?? '',
    phone: o.customerPhone ?? '',
    address: o.address ?? '',
    items: items,
    createdAt: o.createdAt ?? '',
    statusHistory: history,
  );
}

enum _FilterTab { all, newOrder, processing, shipping, done }

enum _TimeFilter { all, today, last7, last30 }

class StoreOrdersScreen extends StatefulWidget {
  const StoreOrdersScreen({super.key});

  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen> {
  _FilterTab _filter = _FilterTab.all;
  _TimeFilter _timeFilter = _TimeFilter.all;
  final TextEditingController _orderSearchController = TextEditingController();
  String _orderSearchQuery = '';
  String? _cardLoadingOrderId;
  String? _cardLoadingAction;

  @override
  void initState() {
    super.initState();
    context.read<StoreOrdersBloc>().add(LoadStoreOrders());
    _orderSearchController.addListener(() {
      if (mounted)
        setState(
          () => _orderSearchQuery = _orderSearchController.text
              .trim()
              .toLowerCase(),
        );
    });
  }

  @override
  void dispose() {
    _orderSearchController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✔ $message'),
        backgroundColor: _kPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _rawOrderId(String displayId) => displayId.replaceFirst('#', '');

  void _updateOrderStatus(String orderId, OrderStatusType newType) {
    context.read<StoreOrdersBloc>().add(
          UpdateStoreOrderStatus(int.parse(_rawOrderId(orderId)), _orderStatusToApi(newType)),
        );
  }

  void _acceptOrder(String orderId) {
    _updateOrderStatus(orderId, OrderStatusType.processing);
  }

  void _rejectOrder(String orderId) {
    context.read<StoreOrdersBloc>().add(
          UpdateStoreOrderStatus(int.parse(_rawOrderId(orderId)), 'CANCELLED'),
        );
  }

  Future<void> _runCardAccept(_OrderData o) async {
    if (_cardLoadingOrderId != null) return;
    setState(() {
      _cardLoadingOrderId = o.id;
      _cardLoadingAction = 'accept';
    });
    try {
      _acceptOrder(o.id);
      if (mounted) _showToast('Đơn đã được chấp nhận');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể chấp nhận đơn. Vui lòng thử lại.'),
            backgroundColor: Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (mounted)
      setState(() {
        _cardLoadingOrderId = null;
        _cardLoadingAction = null;
      });
  }

  Future<void> _runCardReject(_OrderData o) async {
    if (_cardLoadingOrderId != null) return;
    setState(() {
      _cardLoadingOrderId = o.id;
      _cardLoadingAction = 'reject';
    });
    try {
      _rejectOrder(o.id);
      if (mounted) _showToast('Đơn đã bị từ chối');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể từ chối đơn. Vui lòng thử lại.'),
            backgroundColor: Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (mounted)
      setState(() {
        _cardLoadingOrderId = null;
        _cardLoadingAction = null;
      });
  }

  Future<void> _runCardMarkReady(_OrderData o) async {
    if (_cardLoadingOrderId != null) return;
    setState(() {
      _cardLoadingOrderId = o.id;
      _cardLoadingAction = 'markReady';
    });
    try {
      _updateOrderStatus(o.id, OrderStatusType.shipping);
      if (mounted) _showToast('Đã cập nhật trạng thái');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật trạng thái. Vui lòng thử lại.'),
            backgroundColor: Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (mounted)
      setState(() {
        _cardLoadingOrderId = null;
        _cardLoadingAction = null;
      });
  }

  void _showOrderDetailModal(BuildContext context, _OrderData order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OrderDetailSheet(
        order: order,
        onClose: () => Navigator.pop(ctx),
        onUpdateStatus: () {
          Navigator.pop(ctx);
          _showUpdateStatusSheet(context, order);
        },
        onAccept: order.statusType == OrderStatusType.newOrder
            ? () {
                _acceptOrder(order.id);
                _showToast('Đơn đã được chấp nhận');
                Navigator.pop(ctx);
              }
            : null,
        onReject: order.statusType == OrderStatusType.newOrder
            ? () {
                _rejectOrder(order.id);
                _showToast('Đơn đã bị từ chối');
                Navigator.pop(ctx);
              }
            : null,
        onMarkReady: order.statusType == OrderStatusType.processing
            ? () {
                _updateOrderStatus(order.id, OrderStatusType.shipping);
                _showToast('Đã cập nhật trạng thái');
                Navigator.pop(ctx);
              }
            : null,
        onMarkDelivered: order.statusType == OrderStatusType.shipping
            ? () {
                _updateOrderStatus(order.id, OrderStatusType.done);
                _showToast('Đã cập nhật trạng thái');
                Navigator.pop(ctx);
              }
            : null,
      ),
    );
  }

  void _showUpdateStatusSheet(BuildContext context, _OrderData order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(kRadiusLarge + 4),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              kPaddingLarge,
              kPaddingMedium,
              kPaddingLarge,
              kPaddingLarge + 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: kSectionSpacing),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Cập nhật trạng thái đơn ${order.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: kSectionSpacing),
                _StatusOption(
                  label: 'Đang chuẩn bị',
                  type: OrderStatusType.processing,
                  current: order.statusType,
                  onTap: () {
                    _updateOrderStatus(order.id, OrderStatusType.processing);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: kCardPadding),
                _StatusOption(
                  label: 'Đang giao',
                  type: OrderStatusType.shipping,
                  current: order.statusType,
                  onTap: () {
                    _updateOrderStatus(order.id, OrderStatusType.shipping);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: kCardPadding),
                _StatusOption(
                  label: 'Hoàn thành',
                  type: OrderStatusType.done,
                  current: order.statusType,
                  onTap: () {
                    _updateOrderStatus(order.id, OrderStatusType.done);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_OrderData> _ordersByTab(List<_OrderData> orders) {
    switch (_filter) {
      case _FilterTab.all:
        return orders;
      case _FilterTab.newOrder:
        return orders
            .where((o) => o.statusType == OrderStatusType.newOrder)
            .toList();
      case _FilterTab.processing:
        return orders
            .where((o) => o.statusType == OrderStatusType.processing)
            .toList();
      case _FilterTab.shipping:
        return orders
            .where((o) => o.statusType == OrderStatusType.shipping)
            .toList();
      case _FilterTab.done:
        return orders
            .where((o) => o.statusType == OrderStatusType.done)
            .toList();
    }
  }

  /// Parse createdAt "dd/MM HH:mm" to DateTime (current year). Returns null if invalid.
  static DateTime? _orderDate(_OrderData o) {
    if (o.createdAt.isEmpty) return null;
    try {
      final parts = o.createdAt.trim().split(RegExp(r'\s+'));
      final datePart = parts.first.split('/');
      if (datePart.length < 2) return null;
      final day = int.tryParse(datePart[0]);
      final month = int.tryParse(datePart[1]);
      if (day == null ||
          month == null ||
          month < 1 ||
          month > 12 ||
          day < 1 ||
          day > 31)
        return null;
      final now = DateTime.now();
      return DateTime(now.year, month, day);
    } catch (_) {
      return null;
    }
  }

  List<_OrderData> _ordersByTimeFilter(List<_OrderData> orders) {
    final list = _ordersByTab(orders);
    if (_timeFilter == _TimeFilter.all) return list;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final cutoff7 = todayStart.subtract(const Duration(days: 6));
    final cutoff30 = todayStart.subtract(const Duration(days: 29));
    return list.where((o) {
      final d = _orderDate(o);
      if (d == null) return false;
      switch (_timeFilter) {
        case _TimeFilter.today:
          return d.year == now.year && d.month == now.month && d.day == now.day;
        case _TimeFilter.last7:
          return !d.isBefore(cutoff7) && !d.isAfter(todayStart);
        case _TimeFilter.last30:
          return !d.isBefore(cutoff30) && !d.isAfter(todayStart);
        case _TimeFilter.all:
          return true;
      }
    }).toList();
  }

  List<_OrderData> _filteredOrders(List<_OrderData> orders) {
    var list = _ordersByTimeFilter(orders);
    if (_orderSearchQuery.isEmpty) return list;
    return list
        .where(
          (o) =>
              o.id.toLowerCase().contains(_orderSearchQuery) ||
              o.customerName.toLowerCase().contains(_orderSearchQuery),
        )
        .toList();
  }

  static const _statusOrder = [
    OrderStatusType.newOrder,
    OrderStatusType.processing,
    OrderStatusType.shipping,
    OrderStatusType.done,
  ];
  static const _statusLabels = {
    OrderStatusType.newOrder: 'Đơn mới',
    OrderStatusType.processing: 'Đang chuẩn bị',
    OrderStatusType.shipping: 'Đang giao',
    OrderStatusType.done: 'Hoàn thành',
  };

  int _orderListItemCount(List<_OrderData> orders) {
    final filtered = _filteredOrders(orders);
    if (filtered.isEmpty) return 1;
    final byStatus = <OrderStatusType, List<_OrderData>>{
      OrderStatusType.newOrder: filtered
          .where((o) => o.statusType == OrderStatusType.newOrder)
          .toList(),
      OrderStatusType.processing: filtered
          .where((o) => o.statusType == OrderStatusType.processing)
          .toList(),
      OrderStatusType.shipping: filtered
          .where((o) => o.statusType == OrderStatusType.shipping)
          .toList(),
      OrderStatusType.done: filtered
          .where((o) => o.statusType == OrderStatusType.done)
          .toList(),
    };
    int count = 0;
    for (final status in _statusOrder) {
      final group = byStatus[status]!;
      if (group.isEmpty) continue;
      if (_filter == _FilterTab.all && count > 0) count += 3;
      if (_filter == _FilterTab.all) count += 1;
      count += group.length * 2 - 1;
    }
    return count > 0 ? count : 1;
  }

  Widget _orderListItemAt(
    BuildContext context,
    int index,
    List<_OrderData> orders,
  ) {
    final filtered = _filteredOrders(orders);
    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            'Chưa có đơn hàng nào',
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
        ),
      );
    }
    final byStatus = <OrderStatusType, List<_OrderData>>{
      OrderStatusType.newOrder: filtered
          .where((o) => o.statusType == OrderStatusType.newOrder)
          .toList(),
      OrderStatusType.processing: filtered
          .where((o) => o.statusType == OrderStatusType.processing)
          .toList(),
      OrderStatusType.shipping: filtered
          .where((o) => o.statusType == OrderStatusType.shipping)
          .toList(),
      OrderStatusType.done: filtered
          .where((o) => o.statusType == OrderStatusType.done)
          .toList(),
    };
    int idx = 0;
    for (final status in _statusOrder) {
      final group = byStatus[status]!;
      if (group.isEmpty) continue;
      if (_filter == _FilterTab.all && idx > 0) {
        if (index == idx) return const SizedBox(height: 24);
        idx++;
        if (index == idx)
          return Divider(height: 1, color: Colors.grey.shade300);
        idx++;
        if (index == idx) return const SizedBox(height: 24);
        idx++;
      }
      if (_filter == _FilterTab.all) {
        if (index == idx) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _statusLabels[status]!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          );
        }
        idx++;
      }
      for (var i = 0; i < group.length; i++) {
        final o = group[i];
        if (index == idx) {
          final cardLoadingAccept =
              _cardLoadingOrderId == o.id && _cardLoadingAction == 'accept';
          final cardLoadingReject =
              _cardLoadingOrderId == o.id && _cardLoadingAction == 'reject';
          final cardLoadingMarkReady =
              _cardLoadingOrderId == o.id && _cardLoadingAction == 'markReady';
          return _OrderCard(
            order: o,
            onTap: () => _showOrderDetailModal(context, o),
            onUpdateStatus: () => _showUpdateStatusSheet(context, o),
            onMarkReady: o.statusType == OrderStatusType.processing
                ? () => _runCardMarkReady(o)
                : null,
            onAccept: o.statusType == OrderStatusType.newOrder
                ? () => _runCardAccept(o)
                : null,
            onReject: o.statusType == OrderStatusType.newOrder
                ? () => _runCardReject(o)
                : null,
            loadingAccept: cardLoadingAccept,
            loadingReject: cardLoadingReject,
            loadingMarkReady: cardLoadingMarkReady,
          );
        }
        idx++;
        if (i < group.length - 1 && index == idx)
          return const SizedBox(height: kCardPadding);
        if (i < group.length - 1) idx++;
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width > 600;
    return BlocListener<StoreOrdersBloc, StoreOrdersState>(
      listenWhen: (prev, curr) => curr is StoreOrdersError,
      listener: (context, state) {
        if (state is StoreOrdersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<StoreOrdersBloc, StoreOrdersState>(
        builder: (context, state) {
          final isLoading = state is StoreOrdersLoading;
          final orders = state is StoreOrdersLoaded
              ? state.orders.map(_orderDataFromModel).toList()
              : <_OrderData>[];
          return Scaffold(
            backgroundColor: _kSurface,
            appBar: AppBar(
              title: Text(
                'Quản lý đơn hàng',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 1,
              surfaceTintColor: Colors.transparent,
              foregroundColor: const Color(0xFF1A1A1A),
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        kPaddingLarge,
                        kPaddingMedium,
                        kPaddingLarge,
                        0,
                      ),
                      child: TextField(
                        controller: _orderSearchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm đơn hàng...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: _kPrimary,
                            size: kIconSizeMedium,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kRadiusMedium),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        kPaddingLarge,
                        0,
                        kPaddingLarge,
                        0,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'Tất cả',
                              selected: _filter == _FilterTab.all,
                              onTap: () =>
                                  setState(() => _filter = _FilterTab.all),
                            ),
                            const SizedBox(width: 10),
                            _FilterChip(
                              label: 'Đơn mới',
                              selected: _filter == _FilterTab.newOrder,
                              onTap: () =>
                                  setState(() => _filter = _FilterTab.newOrder),
                            ),
                            const SizedBox(width: 10),
                            _FilterChip(
                              label: 'Đang chuẩn bị',
                              selected: _filter == _FilterTab.processing,
                              onTap: () => setState(
                                () => _filter = _FilterTab.processing,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _FilterChip(
                              label: 'Đang giao',
                              selected: _filter == _FilterTab.shipping,
                              onTap: () =>
                                  setState(() => _filter = _FilterTab.shipping),
                            ),
                            const SizedBox(width: 10),
                            _FilterChip(
                              label: 'Hoàn thành',
                              selected: _filter == _FilterTab.done,
                              onTap: () =>
                                  setState(() => _filter = _FilterTab.done),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        kPaddingLarge,
                        0,
                        kPaddingLarge,
                        0,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Thời gian: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _FilterChip(
                                    label: 'Tất cả',
                                    selected: _timeFilter == _TimeFilter.all,
                                    onTap: () => setState(
                                      () => _timeFilter = _TimeFilter.all,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterChip(
                                    label: 'Hôm nay',
                                    selected: _timeFilter == _TimeFilter.today,
                                    onTap: () => setState(
                                      () => _timeFilter = _TimeFilter.today,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterChip(
                                    label: '7 ngày',
                                    selected: _timeFilter == _TimeFilter.last7,
                                    onTap: () => setState(
                                      () => _timeFilter = _TimeFilter.last7,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterChip(
                                    label: '30 ngày',
                                    selected: _timeFilter == _TimeFilter.last30,
                                    onTap: () => setState(
                                      () => _timeFilter = _TimeFilter.last30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: isLoading
                          ? ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                kPaddingLarge,
                                0,
                                kPaddingLarge,
                                isWide ? 32 : 28,
                              ),
                              itemCount: 8,
                              itemBuilder: (context, index) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: index < 7 ? kCardPadding : 0,
                                ),
                                child: const _OrderCardSkeleton(),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                kPaddingLarge,
                                0,
                                kPaddingLarge,
                                isWide ? 32 : 28,
                              ),
                              itemCount: _orderListItemCount(orders),
                              itemBuilder: (context, index) =>
                                  _orderListItemAt(context, index, orders),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _kPrimary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _kPrimary : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: selected
                ? null
                : [
                    const BoxShadow(
                      color: _kCardShadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final OrderStatusType type;
  final OrderStatusType current;
  final VoidCallback onTap;

  const _StatusOption({
    required this.label,
    required this.type,
    required this.current,
    required this.onTap,
  });

  IconData get _icon {
    switch (type) {
      case OrderStatusType.newOrder:
        return Icons.notifications_active_rounded;
      case OrderStatusType.processing:
        return Icons.hourglass_top_rounded;
      case OrderStatusType.shipping:
        return Icons.local_shipping_rounded;
      case OrderStatusType.done:
        return Icons.check_circle_rounded;
    }
  }

  Color get _color {
    switch (type) {
      case OrderStatusType.newOrder:
        return const Color(0xFF7B1FA2);
      case OrderStatusType.processing:
        return const Color(0xFFF57C00);
      case OrderStatusType.shipping:
        return const Color(0xFF1976D2);
      case OrderStatusType.done:
        return _kPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = type == current;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusMedium),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(
            horizontal: kCardPadding,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? _color.withValues(alpha: 0.1)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(kRadiusMedium),
            border: Border.all(
              color: isSelected ? _color : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(_icon, color: _color, size: kIconSizeMedium),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? _color : Colors.grey.shade800,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: _color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight skeleton for order card (static grey boxes).
const Color _kSkeletonColor = Color(0xFFE8E8E8);

class _OrderCardSkeleton extends StatelessWidget {
  const _OrderCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(
          color: Colors.grey.shade200.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kSkeletonColor,
              borderRadius: BorderRadius.circular(kRadiusMedium),
            ),
          ),
          const SizedBox(width: kCardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 14,
                  width: 72,
                  decoration: BoxDecoration(
                    color: _kSkeletonColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 18,
                  width: 90,
                  decoration: BoxDecoration(
                    color: _kSkeletonColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 28,
            width: 88,
            decoration: BoxDecoration(
              color: _kSkeletonColor,
              borderRadius: BorderRadius.circular(kRadiusMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final _OrderData order;
  final VoidCallback? onTap;
  final VoidCallback? onUpdateStatus;
  final VoidCallback? onMarkReady;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool loadingAccept;
  final bool loadingReject;
  final bool loadingMarkReady;

  const _OrderCard({
    required this.order,
    this.onTap,
    this.onUpdateStatus,
    this.onMarkReady,
    this.onAccept,
    this.onReject,
    this.loadingAccept = false,
    this.loadingReject = false,
    this.loadingMarkReady = false,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _hover = false;

  Color _statusColor(OrderStatusType t) {
    switch (t) {
      case OrderStatusType.newOrder:
        return const Color(0xFF7B1FA2);
      case OrderStatusType.processing:
        return const Color(0xFFF57C00);
      case OrderStatusType.shipping:
        return const Color(0xFF1976D2);
      case OrderStatusType.done:
        return _kPrimary;
    }
  }

  IconData _orderStatusIcon(OrderStatusType t) {
    switch (t) {
      case OrderStatusType.newOrder:
        return Icons.notifications_active_rounded;
      case OrderStatusType.processing:
        return Icons.hourglass_top_rounded;
      case OrderStatusType.shipping:
        return Icons.local_shipping_rounded;
      case OrderStatusType.done:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final isNewOrder = o.statusType == OrderStatusType.newOrder;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(
          color: _hover
              ? _kPrimary.withValues(alpha: 0.25)
              : Colors.grey.shade200.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _kCardShadow,
            blurRadius: _hover ? 10 : 8,
            offset: Offset(0, _hover ? 4 : 3),
          ),
        ],
      ),
      child: isNewOrder
          ? _buildNewOrderContent(o)
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusColor(o.statusType).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(kRadiusMedium),
                  ),
                  child: Icon(
                    _orderStatusIcon(o.statusType),
                    color: _statusColor(o.statusType),
                    size: kIconSizeMedium,
                  ),
                ),
                const SizedBox(width: kCardPadding),
                Expanded(
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(kRadiusMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Đơn ${o.id}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          o.amount,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _StatusChip(label: o.status, color: _statusColor(o.statusType)),
                const SizedBox(width: 8),
                if (o.statusType == OrderStatusType.processing &&
                    widget.onMarkReady != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: TextButton(
                      onPressed: widget.loadingMarkReady
                          ? null
                          : widget.onMarkReady,
                      style: TextButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: widget.loadingMarkReady
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Chuẩn bị xong',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                if (widget.onUpdateStatus != null)
                  IconButton(
                    onPressed: widget.onUpdateStatus,
                    icon: const Icon(
                      Icons.edit_rounded,
                      size: kIconSizeSmall,
                      color: _kPrimary,
                    ),
                    tooltip: 'Cập nhật trạng thái',
                  ),
              ],
            ),
    );
    if (kIsWeb) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: content,
      );
    }
    return ScaleOnTap(onTap: widget.onTap, child: content);
  }

  /// Thẻ đơn mới: Mã đơn, Tên khách hàng, Tổng tiền, [Chấp nhận đơn] [Từ chối]
  Widget _buildNewOrderContent(_OrderData o) {
    final color = _statusColor(OrderStatusType.newOrder);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(kRadiusMedium),
              ),
              child: Icon(
                _orderStatusIcon(OrderStatusType.newOrder),
                color: color,
                size: kIconSizeMedium,
              ),
            ),
            const SizedBox(width: kCardPadding),
            Expanded(
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(kRadiusMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Đơn ${o.id}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (o.customerName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        o.customerName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      o.amount,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (widget.onAccept != null)
              Expanded(
                child: FilledButton.icon(
                  onPressed: (widget.loadingAccept || widget.loadingReject)
                      ? null
                      : widget.onAccept,
                  icon: widget.loadingAccept
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Chấp nhận đơn'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusMedium),
                    ),
                  ),
                ),
              ),
            if (widget.onAccept != null && widget.onReject != null)
              const SizedBox(width: 10),
            if (widget.onReject != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (widget.loadingAccept || widget.loadingReject)
                      ? null
                      : widget.onReject,
                  icon: widget.loadingReject
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_rounded, size: 18),
                  label: const Text('Từ chối'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusMedium),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Modal chi tiết đơn — Mã đơn, Thời gian đặt, Khách hàng, SĐT, Địa chỉ, SP, Tổng tiền, Trạng thái + Cập nhật trạng thái (nút có loading)
class _OrderDetailSheet extends StatefulWidget {
  final _OrderData order;
  final VoidCallback onClose;
  final VoidCallback? onUpdateStatus;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onMarkReady;
  final VoidCallback? onMarkDelivered;

  const _OrderDetailSheet({
    required this.order,
    required this.onClose,
    this.onUpdateStatus,
    this.onAccept,
    this.onReject,
    this.onMarkReady,
    this.onMarkDelivered,
  });

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  bool _loadingAccept = false;
  bool _loadingReject = false;
  bool _loadingMarkReady = false;
  bool _loadingMarkDelivered = false;

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _runAccept() async {
    if (_loadingAccept) return;
    setState(() => _loadingAccept = true);
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      widget.onAccept!();
    } catch (_) {
      if (mounted) {
        setState(() => _loadingAccept = false);
        _showErrorSnackBar('Không thể chấp nhận đơn. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _runReject() async {
    if (_loadingReject) return;
    setState(() => _loadingReject = true);
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      widget.onReject!();
    } catch (_) {
      if (mounted) {
        setState(() => _loadingReject = false);
        _showErrorSnackBar('Không thể từ chối đơn. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _runMarkReady() async {
    if (_loadingMarkReady) return;
    setState(() => _loadingMarkReady = true);
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      widget.onMarkReady!();
    } catch (_) {
      if (mounted) {
        setState(() => _loadingMarkReady = false);
        _showErrorSnackBar('Không thể cập nhật trạng thái. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _runMarkDelivered() async {
    if (_loadingMarkDelivered) return;
    setState(() => _loadingMarkDelivered = true);
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      widget.onMarkDelivered!();
    } catch (_) {
      if (mounted) {
        setState(() => _loadingMarkDelivered = false);
        _showErrorSnackBar('Không thể cập nhật trạng thái. Vui lòng thử lại.');
      }
    }
  }

  Color _statusColor(OrderStatusType t) {
    switch (t) {
      case OrderStatusType.newOrder:
        return const Color(0xFF7B1FA2);
      case OrderStatusType.processing:
        return const Color(0xFFF57C00);
      case OrderStatusType.shipping:
        return const Color(0xFF1976D2);
      case OrderStatusType.done:
        return _kPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final statusColor = _statusColor(order.statusType);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(kRadiusLarge + 4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(
                top: kPaddingMedium,
                bottom: kCardPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                kPaddingLarge,
                0,
                kPaddingLarge,
                kPaddingLarge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Đơn ${order.id}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(kRadiusMedium),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          order.status,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (order.createdAt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _DetailRow(
                      icon: Icons.schedule_rounded,
                      label: 'Thời gian đặt: ${order.createdAt}',
                    ),
                  ],
                  const SizedBox(height: kSectionSpacing),
                  Text(
                    'Thông tin khách hàng',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.person_rounded,
                    label: order.customerName,
                  ),
                  if (order.phone.isNotEmpty)
                    _DetailRow(icon: Icons.phone_rounded, label: order.phone),
                  if (order.address.isNotEmpty)
                    _DetailRow(
                      icon: Icons.location_on_rounded,
                      label: order.address,
                    ),
                  const SizedBox(height: kSectionSpacing),
                  Text(
                    'Danh sách sản phẩm',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(kRadiusMedium),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        for (final item in order.items)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kCardPadding,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ),
                                Text(
                                  'x${item.qty}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.price,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: kCardPadding),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Tổng tiền: ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        order.amount,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kSectionSpacing),
                  Text(
                    'Trạng thái đơn',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < order.statusHistory.length; i++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          i == order.statusHistory.length - 1
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_checked_rounded,
                          size: 18,
                          color: _kPrimary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            order.statusHistory[i],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (i < order.statusHistory.length - 1)
                      const SizedBox(height: 6),
                  ],
                  const SizedBox(height: kSectionSpacing),
                  Text(
                    'Cập nhật trạng thái',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _OrderDetailActions(
                    order: order,
                    loadingAccept: _loadingAccept,
                    loadingReject: _loadingReject,
                    loadingMarkReady: _loadingMarkReady,
                    loadingMarkDelivered: _loadingMarkDelivered,
                    onClose: widget.onClose,
                    onAccept: widget.onAccept != null
                        ? () => _runAccept()
                        : null,
                    onReject: widget.onReject != null
                        ? () => _runReject()
                        : null,
                    onMarkReady: widget.onMarkReady != null
                        ? () => _runMarkReady()
                        : null,
                    onMarkDelivered: widget.onMarkDelivered != null
                        ? () => _runMarkDelivered()
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút hành động theo trạng thái đơn (có loading)
class _OrderDetailActions extends StatelessWidget {
  final _OrderData order;
  final bool loadingAccept;
  final bool loadingReject;
  final bool loadingMarkReady;
  final bool loadingMarkDelivered;
  final VoidCallback onClose;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onMarkReady;
  final VoidCallback? onMarkDelivered;

  const _OrderDetailActions({
    required this.order,
    required this.loadingAccept,
    required this.loadingReject,
    required this.loadingMarkReady,
    required this.loadingMarkDelivered,
    required this.onClose,
    this.onAccept,
    this.onReject,
    this.onMarkReady,
    this.onMarkDelivered,
  });

  @override
  Widget build(BuildContext context) {
    final isNewOrder = order.statusType == OrderStatusType.newOrder;
    final isProcessing = order.statusType == OrderStatusType.processing;
    final isShipping = order.statusType == OrderStatusType.shipping;
    final anyLoading =
        loadingAccept ||
        loadingReject ||
        loadingMarkReady ||
        loadingMarkDelivered;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: anyLoading ? null : onClose,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusMedium),
              ),
            ),
            child: const Text('Đóng'),
          ),
        ),
        const SizedBox(width: 12),
        if (isNewOrder && onAccept != null && onReject != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: anyLoading ? null : onReject,
              icon: loadingReject
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_rounded, size: 18),
              label: const Text('Từ chối'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusMedium),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: anyLoading ? null : onAccept,
              icon: loadingAccept
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('Chấp nhận đơn'),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusMedium),
                ),
              ),
            ),
          ),
        ] else if (isProcessing && onMarkReady != null) ...[
          Expanded(
            child: FilledButton.icon(
              onPressed: anyLoading ? null : onMarkReady,
              icon: loadingMarkReady
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text('Chuẩn bị xong'),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusMedium),
                ),
              ),
            ),
          ),
        ] else if (isShipping && onMarkDelivered != null) ...[
          Expanded(
            child: FilledButton.icon(
              onPressed: anyLoading ? null : onMarkDelivered,
              icon: loadingMarkDelivered
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.local_shipping_rounded, size: 18),
              label: const Text('Đã giao thành công'),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusMedium),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(kRadiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
