import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:intl/intl.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';

class DeliveryManagementScreen extends StatefulWidget {
  const DeliveryManagementScreen({super.key});

  @override
  State<DeliveryManagementScreen> createState() => _DeliveryManagementScreenState();
}

class _DeliveryManagementScreenState extends State<DeliveryManagementScreen> {
  final OrderService _orderService = OrderService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'Tất cả';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Giao hàng & Vận chuyển', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: 0,
        actions: [
          if (_searchQuery.isNotEmpty || _statusFilter != 'Tất cả')
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined, color: Colors.red),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _statusFilter = 'Tất cả';
                  _searchController.clear();
                });
              },
            ),
          IconButton(
            icon: Icon(Icons.file_download_outlined, color: Theme.of(context).colorScheme.primary),
            onPressed: _exportDeliveries,
            tooltip: 'Xuất Excel',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo Shipper, Mã đơn...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF0F2F5),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _orderService.getAllOrdersAdmin(), // Switch to Admin API for full visibility
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          }

          final allOrders = snapshot.data ?? [];
          var activeDeliveries = allOrders.where((o) {
            final st = (o.status ?? '').toUpperCase();
            return ['PICKING_UP', 'DELIVERING', 'DELIVERED', 'COMPLETED', 'DONE', 'SHIPPED'].contains(st);
          }).toList();

          // Apply Status Filter
          if (_statusFilter != 'Tất cả') {
            String apiStatus = '';
            if (_statusFilter == 'Chờ lấy') apiStatus = 'PICKING_UP';
            if (_statusFilter == 'Đang giao') apiStatus = 'DELIVERING';
            if (_statusFilter == 'Hoàn tất') apiStatus = 'DELIVERED';
            activeDeliveries = activeDeliveries.where((o) => o.status == apiStatus).toList();
          }

          // Apply Search Filter
          if (_searchQuery.isNotEmpty) {
            activeDeliveries = activeDeliveries.where((o) {
              final idStr = (o.id?.toString() ?? '').toLowerCase();
              final shipper = (o.shipperName ?? 'Chưa chỉ định').toLowerCase();
              return idStr.contains(_searchQuery) || shipper.contains(_searchQuery);
            }).toList();
          }

          if (activeDeliveries.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildDeliveryStats(allOrders.where((o) {
                final st = (o.status ?? '').toUpperCase();
                return ['PICKING_UP', 'DELIVERING', 'DELIVERED', 'COMPLETED', 'DONE', 'SHIPPED'].contains(st);
              }).toList()),
              _buildFilterChips(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activeDeliveries.length,
                  itemBuilder: (context, index) => _buildDeliveryCard(activeDeliveries[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeliveryStats(List<OrderModel> deliveries) {
    final delivering = deliveries.where((o) => (o.status ?? '').toUpperCase() == 'DELIVERING').length;
    final picking = deliveries.where((o) => (o.status ?? '').toUpperCase() == 'PICKING_UP').length;
    final completed = deliveries.where((o) {
      final st = (o.status ?? '').toUpperCase();
      return ['DELIVERED', 'COMPLETED', 'DONE'].contains(st);
    }).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Chờ lấy', picking.toString(), Icons.move_to_inbox, Colors.orange),
          _buildStatItem('Đang giao', delivering.toString(), Icons.delivery_dining, Colors.blue),
          _buildStatItem('Hoàn tất', completed.toString(), Icons.check_circle_outline, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    bool isSelected = _statusFilter == title;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = isSelected ? 'Tất cả' : title),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? color : color.withValues(alpha: 0.4), size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).disabledColor)),
          Text(title, style: TextStyle(fontSize: 11, color: isSelected ? color : Theme.of(context).disabledColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          'Tất cả', 'Chờ lấy', 'Đang giao', 'Hoàn tất'
        ].map((filter) {
          bool isSelected = _statusFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color)),
              selected: isSelected,
              onSelected: (val) => setState(() => _statusFilter = filter),
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Colors.white,
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeliveryCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
              children: [
                _buildDeliveryStatusIcon(order.status ?? 'PENDING'),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final String idStr = order.id?.toString() ?? '';
                          final String displayId = idStr.length > 6 ? idStr.substring(idStr.length - 6) : idStr.padLeft(6, '0');
                          return Text('Đơn #${displayId.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15));
                        },
                      ),
                      Text('Khách hàng: ${order.customerName ?? "Khách lẻ"}', style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
                    ],
                  ),
                ),
                _buildSmallStatusBadge(order.status ?? 'PENDING'),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(order.address ?? "Không có địa chỉ", style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_pin_outlined, size: 16, color: Theme.of(context).disabledColor),
                const SizedBox(width: 12),
                Text('Shipper: ${order.shipperName ?? "Chưa chỉ định"}', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                const Spacer(),
                const Text('Dự kiến: 15p', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                double progress = 0.0;
                if (order.status == 'PICKING_UP') progress = 0.3;
                if (order.status == 'DELIVERING') progress = 0.7;
                if (order.status == 'DELIVERED') progress = 1.0;
                return LinearProgressIndicator(
                  value: progress, 
                  backgroundColor: Theme.of(context).dividerColor, 
                  valueColor: AlwaysStoppedAnimation<Color>(progress == 1.0 ? Colors.green : Theme.of(context).colorScheme.primary),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (order.status != 'DELIVERED')
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone_outlined, size: 16),
                    label: const Text('Liên hệ', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.teal),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {},
                  child: Text('Xem lộ trình', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStatusIcon(String status) {
     IconData icon = Icons.local_shipping;
     Color color = Colors.indigo;
     final st = status.toUpperCase();
     if (st == 'PICKING_UP') { icon = Icons.warehouse_outlined; color = Colors.orange; }
     if (['DELIVERED', 'COMPLETED', 'DONE'].contains(st)) { icon = Icons.verified_user_outlined; color = Colors.green; }
     
     return Container(
       padding: const EdgeInsets.all(10),
       decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
       child: Icon(icon, color: color, size: 22),
     );
  }

  Widget _buildSmallStatusBadge(String status) {
    Color color = Colors.grey;
    String text = status;
    final st = status.toUpperCase();
    if (st == 'PICKING_UP') { color = Colors.orange; text = 'Chờ lấy'; }
    if (st == 'DELIVERING') { color = Colors.blue; text = 'Đang giao'; }
    if (['DELIVERED', 'COMPLETED', 'DONE'].contains(st)) { color = Colors.green; text = 'Hoàn tất'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _exportDeliveries() async {
    try {
      final List<OrderModel> allOrders = await _orderService.getStoreOrders();
      final activeDeliveries = allOrders.where((o) => 
        ['PICKING_UP', 'DELIVERING', 'DELIVERED'].contains(o.status)
      ).toList();
      
      final exportData = activeDeliveries.map((o) => {
        'Mã đơn': (o.id?.toString() ?? '').toUpperCase(),
        'Shipper': o.shipperName ?? 'Chưa chỉ định',
        'Khách hàng': o.customerName ?? 'N/A',
        'Địa chỉ': o.address ?? 'N/A',
        'Trạng thái': _getStatusText(o.status ?? ''),
        'Cập nhật': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()), // Mocking last update
      }).toList();

      if (mounted) {
        await ExportService.exportToCsv(
          context: context,
          data: exportData,
          fileName: 'danhsach_vanchuyen_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xuất dữ liệu: $e')));
      }
    }
  }

  String _getStatusText(String status) {
    if (status == 'PICKING_UP') return 'Chờ lấy';
    if (status == 'DELIVERING') return 'Đang giao';
    if (status == 'DELIVERED') return 'Hoàn tất';
    return status;
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 64, color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Text('Không có hoạt động vận chuyển nào', style: TextStyle(color: Theme.of(context).disabledColor)),
        ],
      ),
    );
  }
}
