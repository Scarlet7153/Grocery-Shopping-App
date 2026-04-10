import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/features/auth/models/user_model.dart';
import 'package:grocery_shopping_app/features/admin/domain/repositories/user_repository.dart';
import 'package:grocery_shopping_app/features/admin/data/repositories/api_user_repository_impl.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/user_management/user_detail_screen.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';
import 'package:intl/intl.dart';

class ShipperManagementScreen extends StatefulWidget {
  const ShipperManagementScreen({super.key});

  @override
  State<ShipperManagementScreen> createState() => _ShipperManagementScreenState();
}

class _ShipperManagementScreenState extends State<ShipperManagementScreen> {
  final UserRepository _userRepository = ApiUserRepositoryImpl();
  final OrderService _orderService = OrderService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Quản lý Shipper', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.indigo),
            onPressed: () => _exportShippers(context),
            tooltip: 'Xuất Excel',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm shipper theo tên/SĐT...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF0F2F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _userRepository.getUsers(role: UserRole.shipper),
          _orderService.getAllOrdersAdmin(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }

          final shippers = snapshot.data?[0] as List<UserModel>? ?? [];
          final allOrders = snapshot.data?[1] as List<OrderModel>? ?? [];
          
          final filteredShippers = shippers.where((s) => 
            s.fullName.toLowerCase().contains(_searchQuery) || s.phoneNumber.contains(_searchQuery)
          ).toList();

          // Calculate system-wide stats
          final int onlineCount = shippers.where((s) => s.status == UserStatus.active).length;
          
          // Total revenue for shippers (sum of all shipping fees from completed orders)
          double totalSystemRevenue = 0.0;
          for (var order in allOrders) {
            if (['DELIVERED', 'COMPLETED', 'Hoàn thành'].contains(order.status)) {
              totalSystemRevenue += (order.shippingFee ?? 0.0);
            }
          }

          return Column(
            children: [
              _buildStatsHeader(shippers.length, onlineCount, totalSystemRevenue),
              Expanded(
                child: filteredShippers.isEmpty 
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () async => setState(() {}),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredShippers.length,
                        itemBuilder: (context, index) {
                          final shipper = filteredShippers[index];
                          // Aggregate orders for this specific shipper
                          final shipperOrders = allOrders.where((o) => o.shipperId.toString() == shipper.id).toList();
                          final completedCount = shipperOrders.where((o) => ['DELIVERED', 'COMPLETED', 'Hoàn thành'].contains(o.status)).length;
                          final earnings = shipperOrders.where((o) => ['DELIVERED', 'COMPLETED', 'Hoàn thành'].contains(o.status))
                              .fold(0.0, (sum, o) => sum + (o.shippingFee ?? 0.0));

                          return _buildShipperCard(shipper, completedCount, earnings);
                        },
                      ),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(int total, int online, double revenue) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Tổng Shipper', total.toString(), Icons.group),
          _buildStatItem('Đang Online', online.toString(), Icons.online_prediction, color: Colors.green),
          _buildStatItem('Tổng thu nhập', _currencyFormat.format(revenue), Icons.account_balance_wallet, color: Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, {Color color = Colors.grey}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildShipperCard(UserModel shipper, int completedOrders, double earnings) {
    final bool isOnline = shipper.status == UserStatus.active;

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
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.orange[50],
                      child: Text(shipper.fullName.substring(0, 1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shipper.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(shipper.phoneNumber, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                _buildLockIndicator(shipper.status),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat('Tổng đơn', completedOrders.toString(), Icons.local_mall_outlined),
                _buildMiniStat('Thu nhập', _currencyFormat.format(earnings), Icons.account_balance_wallet_outlined),
                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UserDetailScreen(user: shipper)),
                    );
                    setState(() {});
                  },
                  child: const Text('Chi tiết', style: TextStyle(fontSize: 12, color: Colors.indigo)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildLockIndicator(UserStatus status) {
    final bool active = status == UserStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(active ? 'Sẵn sàng' : 'Khóa', style: TextStyle(color: active ? Colors.green[700] : Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _exportShippers(BuildContext context) async {
    try {
      final List<UserModel> shippers = await _userRepository.getUsers(role: UserRole.shipper);
      
      final exportData = shippers.map((s) => {
        'ID': s.id,
        'Họ tên': s.fullName,
        'SĐT': s.phoneNumber,
        'Trạng thái': s.status == UserStatus.active ? 'Sẵn sàng' : 'Đã khóa',
        'Ngày tham gia': DateFormat('dd/MM/yyyy').format(s.createdAt),
      }).toList();

      if (mounted) {
        await ExportService.exportToCsv(
          context: context,
          data: exportData,
          fileName: 'danhsach_shipper_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xuất dữ liệu: $e')));
      }
    }
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('Không tìm thấy shipper phù hợp', style: TextStyle(color: Colors.grey)));
  }
}
