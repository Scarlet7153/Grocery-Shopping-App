import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:intl/intl.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';
import 'add_edit_order_screen.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _dateRange;

  final List<String> _statusKeys = [
    'all',
    'pending',
    'delivering',
    'delivered',
    'cancelled',
  ];

  bool _isSyncing = false;
  Future<List<OrderModel>>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusKeys.length, vsync: this);
    _syncOrders();
  }

  Future<void> _syncOrders({bool force = false}) async {
    if (_isSyncing) return;
    
    setState(() => _isSyncing = true);
    try {
      _ordersFuture = _orderService.getAllOrdersAdmin();
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddEdit({OrderModel? order}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditOrderScreen(order: order)),
    );
    if (result == true) {
      setState(() {});
    }
  }

  String _statusLabel(String key, AppLocalizations l) {
    switch (key) {
      case 'pending':
        return l.byLocale(vi: 'Chờ xử lý', en: 'Pending');
      case 'delivering':
        return l.byLocale(vi: 'Đang giao', en: 'Delivering');
      case 'delivered':
        return l.byLocale(vi: 'Hoàn thành', en: 'Delivered');
      case 'cancelled':
        return l.byLocale(vi: 'Đã hủy', en: 'Cancelled');
      default:
        return l.byLocale(vi: 'Tất cả', en: 'All');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.byLocale(vi: 'Quản lý Đơn hàng', en: 'Order management'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (_isSyncing)
              Text(AppLocalizations.of(context)!.byLocale(vi: 'Đang tải...', en: 'Loading...'), 
                  style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: 0,
        actions: [
          if (_isSyncing)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)))),
          IconButton(
            icon: Icon(Icons.calendar_today_outlined, color: _dateRange != null ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
            onPressed: () => _syncOrders(force: true),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.byLocale(vi: 'Tìm theo ID, khách hàng, cửa hàng...', en: 'Search by ID, customer, store...'),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF0F2F5),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).disabledColor,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: _statusKeys.map((key) => Tab(text: _statusLabel(key, AppLocalizations.of(context)!))).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statusKeys.map((key) => _buildOrderList(key)).toList(),
      ),

    );
  }

  Widget _buildOrderList(String statusFilter) {
    return FutureBuilder<List<OrderModel>>(
      future: _ordersFuture ?? _orderService.getAllOrdersAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.byLocale(vi: 'Đang tải danh sách...', en: 'Loading order list...'), style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
            ),
          );
        }

        final allOrders = snapshot.data ?? [];
        List<OrderModel> filteredOrders;
        if (statusFilter == 'all') {
          filteredOrders = allOrders;
        } else if (statusFilter == 'delivering') {
          filteredOrders = allOrders.where((o) => o.status == 'DELIVERING' || o.status == 'PICKING_UP').toList();
        } else {
          filteredOrders = allOrders.where((o) => o.status == statusFilter.toUpperCase()).toList();
        }

        // Apply Search Filter
        if (_searchQuery.isNotEmpty) {
          filteredOrders = filteredOrders.where((o) {
            final id = (o.id?.toString() ?? '').toLowerCase();
            final customer = (o.customerName ?? '').toLowerCase();
            final store = (o.storeName ?? '').toLowerCase();
            final shipper = (o.shipperName ?? '').toLowerCase();
            return id.contains(_searchQuery) || customer.contains(_searchQuery) || store.contains(_searchQuery) || shipper.contains(_searchQuery);
          }).toList();
        }

        // Apply Date Filter
        if (_dateRange != null) {
          filteredOrders = filteredOrders.where((o) {
            final dt = DateTime.tryParse(o.createdAt ?? '');
            if (dt == null) return false;
            return dt.isAfter(_dateRange!.start) && dt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
          }).toList();
        }

        if (filteredOrders.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredOrders.length + (_dateRange != null ? 1 : 0),
            itemBuilder: (context, index) {
              if (_dateRange != null && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _dateRange = null),
                              child: Icon(Icons.close, size: 14, color: Theme.of(context).colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _buildOrderCard(filteredOrders[_dateRange != null ? index - 1 : index]);
            },
          ),
        );
      },
    );
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    final l = AppLocalizations.of(context)!;
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + MediaQuery.of(context).size.width - 220,
        offset.dy + 50,
        offset.dx + MediaQuery.of(context).size.width,
        offset.dy + 100,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        _buildDateMenuItem(l.byLocale(vi: 'Hôm nay', en: 'Today'), now, now),
        _buildDateMenuItem(l.byLocale(vi: 'Hôm qua', en: 'Yesterday'), now.subtract(const Duration(days: 1)), now.subtract(const Duration(days: 1))),
        _buildDateMenuItem(l.byLocale(vi: '7 ngày qua', en: 'Last 7 days'), now.subtract(const Duration(days: 6)), now),
        _buildDateMenuItem(l.byLocale(vi: '30 ngày qua', en: 'Last 30 days'), now.subtract(const Duration(days: 29)), now),
        _buildDateMenuItem(l.byLocale(vi: 'Tháng này', en: 'This month'), DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0)),
        _buildDateMenuItem(l.byLocale(vi: 'Tháng trước', en: 'Last month'), DateTime(now.year, now.month - 1, 1), DateTime(now.year, now.month, 0)),
        PopupMenuItem<String>(
          value: 'custom',
          child: Row(children: [const Icon(Icons.date_range, size: 18), const SizedBox(width: 10), Text(l.byLocale(vi: 'Tùy chỉnh...', en: 'Custom...'))]),
        ),
        if (_dateRange != null)
          PopupMenuItem<String>(
            value: 'clear',
            child: Row(children: [const Icon(Icons.clear, size: 18, color: Colors.red), const SizedBox(width: 10), Text(l.byLocale(vi: 'Xóa bộ lọc', en: 'Clear filter'), style: const TextStyle(color: Colors.red))]),
          ),
      ],
    );

    if (picked == null) return;

    if (picked == 'clear') {
      setState(() => _dateRange = null);
      return;
    }

    if (picked == 'custom') {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: now,
        initialDateRange: _dateRange,
        builder: (context, child) {
          return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500), child: child));
        },
      );
      if (range != null) setState(() => _dateRange = range);
      return;
    }

    final parts = picked.split('|');
    if (parts.length == 2) {
      setState(() => _dateRange = DateTimeRange(
        start: DateTime.parse(parts[0]),
        end: DateTime.parse(parts[1]),
      ));
    }
  }

  PopupMenuItem<String> _buildDateMenuItem(String label, DateTime start, DateTime end) {
    return PopupMenuItem<String>(
      value: '${start.toIso8601String().split("T").first}|${end.toIso8601String().split("T").first}',
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return InkWell(
      onTap: () => _navigateToAddEdit(order: order),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.byLocale(vi: 'Đơn hàng #', en: 'Order #')}${order.id?.toString().toUpperCase().characters.takeLast(6) ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse(order.createdAt ?? '') ?? DateTime.now()),
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                      ),
                    ],
                  ),
                  _buildStatusBadge(order.status ?? 'PENDING'),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.person_outline, '${AppLocalizations.of(context)!.byLocale(vi: 'Khách:', en: 'Customer:')} ${order.customerName ?? AppLocalizations.of(context)!.byLocale(vi: 'Khách lẻ', en: 'Walk-in customer')}'),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.storefront_outlined, '${AppLocalizations.of(context)!.byLocale(vi: 'Cửa hàng:', en: 'Store:')} ${order.storeName ?? AppLocalizations.of(context)!.byLocale(vi: 'Chưa rõ', en: 'Unknown')}'),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.local_shipping_outlined, '${AppLocalizations.of(context)!.byLocale(vi: 'Tài xế:', en: 'Driver:')} ${order.shipperName ?? AppLocalizations.of(context)!.byLocale(vi: 'Chưa nhận', en: 'Not assigned')}'),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.byLocale(vi: 'Tổng thanh toán:', en: 'Total payment:'), style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
                  Text(_currencyFormat.format(order.totalAmount ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isGrey = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(context).disabledColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(fontSize: 12, color: isGrey ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color, fontWeight: isGrey ? FontWeight.normal : FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final l = AppLocalizations.of(context)!;
    Color color = Colors.grey;
    String text = status;
    if (status == 'PENDING') { color = Colors.orange; text = l.byLocale(vi: 'Chờ xử lý', en: 'Pending'); }
    if (status == 'CONFIRMED') { color = Colors.blue; text = l.byLocale(vi: 'Đã xác nhận', en: 'Confirmed'); }
    if (status == 'PICKING_UP') { color = Colors.indigo; text = l.byLocale(vi: 'Chờ lấy', en: 'Picking up'); }
    if (status == 'DELIVERING') { color = Colors.purple; text = l.byLocale(vi: 'Đang giao', en: 'Delivering'); }
    if (status == 'DELIVERED') { color = Colors.green; text = l.byLocale(vi: 'Hoàn thành', en: 'Delivered'); }
    if (status == 'CANCELLED') { color = Colors.red; text = l.byLocale(vi: 'Đã hủy', en: 'Cancelled'); }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // ignore: unused_element
  void _exportOrders() async {
    try {
      final List<OrderModel> orders = await _orderService.getAllOrdersAdmin();
      
      final l = AppLocalizations.of(context)!;
      final exportData = orders.map((o) => {
        l.byLocale(vi: 'Mã đơn', en: 'Order ID'): o.id?.toString().toUpperCase() ?? 'N/A',
        l.byLocale(vi: 'Ngày đặt', en: 'Order date'): DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse(o.createdAt ?? '') ?? DateTime.now()),
        l.byLocale(vi: 'Khách hàng', en: 'Customer'): o.customerName ?? 'N/A',
        l.byLocale(vi: 'Cửa hàng', en: 'Store'): o.storeName ?? 'N/A',
        l.byLocale(vi: 'Shipper', en: 'Shipper'): o.shipperName ?? l.byLocale(vi: 'Chưa nhận', en: 'Not assigned'),
        l.byLocale(vi: 'Trạng thái', en: 'Status'): _getStatusText(o.status ?? 'PENDING', l),
        l.byLocale(vi: 'Tổng tiền', en: 'Total'): _currencyFormat.format(o.totalAmount ?? 0),
      }).toList();

      if (mounted) {
        await ExportService.exportToCsv(
          context: context,
          data: exportData,
          fileName: 'danhsach_donhang_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.byLocale(vi: 'Lỗi xuất dữ liệu: $e', en: 'Export error: $e'))));
      }
    }
  }

  String _getStatusText(String status, AppLocalizations l) {
    if (status == 'PENDING') return l.byLocale(vi: 'Chờ xử lý', en: 'Pending');
    if (status == 'CONFIRMED') return l.byLocale(vi: 'Đã xác nhận', en: 'Confirmed');
    if (status == 'PICKING_UP') return l.byLocale(vi: 'Chờ lấy', en: 'Picking up');
    if (status == 'DELIVERING') return l.byLocale(vi: 'Đang giao', en: 'Delivering');
    if (status == 'DELIVERED') return l.byLocale(vi: 'Hoàn thành', en: 'Delivered');
    if (status == 'CANCELLED') return l.byLocale(vi: 'Đã hủy', en: 'Cancelled');
    return status;
  }

  Widget _buildEmptyState() {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Text(l.byLocale(vi: 'Không có đơn hàng nào', en: 'No orders found'), style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 14)),
        ],
      ),
    );
  }
}
