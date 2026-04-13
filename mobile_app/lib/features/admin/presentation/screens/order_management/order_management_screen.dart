import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:intl/intl.dart';
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

  final List<String> _statuses = [
    'Tất cả',
    'Chờ xử lý',
    'Đang giao',
    'Hoàn thành',
    'Đã hủy',
  ];

  int _discoveredCount = 0;
  bool _isSyncing = false;
  Future<List<OrderModel>>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _syncOrders();
  }

  Future<void> _syncOrders({bool force = false}) async {
    if (_isSyncing) return;
    
    setState(() => _isSyncing = true);
    try {
      await _orderService.discoverRealOrders(
        forceRefresh: force,
      );
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _ordersFuture = _orderService.getAllOrdersAdmin();
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quản lý Đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (_isSyncing)
              Text('Đang dò tìm: $_discoveredCount đơn...', 
                  style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_isSyncing)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)))),
          IconButton(
            icon: Icon(Icons.calendar_today_outlined, color: _dateRange != null ? Colors.indigo : Colors.grey),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.indigo),
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
                    hintText: 'Tìm theo ID, khách hàng, cửa hàng...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.indigo,
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: _statuses.map((s) => Tab(text: s)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((s) => _buildOrderList(s)).toList(),
      ),

    );
  }

  Widget _buildOrderList(String statusFilter) {
    String? apiStatus;
    if (statusFilter == 'Chờ xử lý') apiStatus = 'PENDING';
    if (statusFilter == 'Đang giao') apiStatus = 'DELIVERING';
    if (statusFilter == 'Hoàn thành') apiStatus = 'DELIVERED';
    if (statusFilter == 'Đã hủy') apiStatus = 'CANCELLED';

    return FutureBuilder<List<OrderModel>>(
      future: _ordersFuture ?? _orderService.getAllOrdersAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && (_ordersFuture == null || _isSyncing)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.indigo),
                const SizedBox(height: 16),
                Text(_isSyncing ? 'Đang dò tìm dữ liệu thực tế...' : 'Đang tải danh sách...', style: TextStyle(color: Colors.grey[600])),
                if (_isSyncing) Text('Đã tìm thấy: $_discoveredCount đơn hàng', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        }

        final allOrders = snapshot.data ?? [];
        List<OrderModel> filteredOrders;
        if (statusFilter == 'Tất cả') {
          filteredOrders = allOrders;
        } else if (statusFilter == 'Đang giao') {
          filteredOrders = allOrders.where((o) => o.status == 'DELIVERING' || o.status == 'PICKING_UP').toList();
        } else {
          filteredOrders = allOrders.where((o) => o.status == apiStatus).toList();
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
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) => _buildOrderCard(filteredOrders[index]),
          ),
        );
      },
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
                      'Đơn hàng #${order.id?.toString().toUpperCase().characters.takeLast(6) ?? "N/A"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse(order.createdAt ?? '') ?? DateTime.now()),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status ?? 'PENDING'),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person_outline, 'Khách: ${order.customerName ?? "Khách lẻ"}'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.storefront_outlined, 'Cửa hàng: ${order.storeName ?? "Chưa rõ"}'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.local_shipping_outlined, 'Tài xế: ${order.shipperName ?? "Chưa nhận"}'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng thanh toán:', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                Text(_currencyFormat.format(order.totalAmount ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _navigateToAddEdit(order: order),
                  icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.indigo),
                  tooltip: 'Xem chi tiết',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isGrey = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(fontSize: 12, color: isGrey ? Colors.grey : Colors.black87, fontWeight: isGrey ? FontWeight.normal : FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String text = status;
    if (status == 'PENDING') { color = Colors.orange; text = 'Chờ xử lý'; }
    if (status == 'CONFIRMED') { color = Colors.blue; text = 'Đã xác nhận'; }
    if (status == 'PICKING_UP') { color = Colors.indigo; text = 'Chờ lấy'; }
    if (status == 'DELIVERING') { color = Colors.purple; text = 'Đang giao'; }
    if (status == 'DELIVERED') { color = Colors.green; text = 'Hoàn thành'; }
    if (status == 'CANCELLED') { color = Colors.red; text = 'Đã hủy'; }

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
      
      final exportData = orders.map((o) => {
        'Mã đơn': o.id?.toString().toUpperCase() ?? 'N/A',
        'Ngày đặt': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse(o.createdAt ?? '') ?? DateTime.now()),
        'Khách hàng': o.customerName ?? 'N/A',
        'Cửa hàng': o.storeName ?? 'N/A',
        'Shipper': o.shipperName ?? 'Chưa nhận',
        'Trạng thái': _getStatusText(o.status ?? 'PENDING'),
        'Tổng tiền': _currencyFormat.format(o.totalAmount ?? 0),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xuất dữ liệu: $e')));
      }
    }
  }

  String _getStatusText(String status) {
    if (status == 'PENDING') return 'Chờ xử lý';
    if (status == 'CONFIRMED') return 'Đã xác nhận';
    if (status == 'PICKING_UP') return 'Chờ lấy';
    if (status == 'DELIVERING') return 'Đang giao';
    if (status == 'DELIVERED') return 'Hoàn thành';
    if (status == 'CANCELLED') return 'Đã hủy';
    return status;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text('Không có đơn hàng nào', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}
