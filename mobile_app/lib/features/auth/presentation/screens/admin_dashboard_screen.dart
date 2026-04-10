import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_shopping_app/features/auth/bloc/auth_bloc.dart';
import 'package:grocery_shopping_app/features/auth/bloc/auth_state.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/user_management/user_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/store_management/store_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/shipper_management/shipper_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/order_management/order_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/delivery_management/delivery_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/settings/settings_screen.dart';
import 'package:grocery_shopping_app/features/admin/domain/repositories/user_repository.dart';
import 'package:grocery_shopping_app/features/admin/data/repositories/api_user_repository_impl.dart';
import 'package:grocery_shopping_app/features/admin/domain/repositories/store_repository.dart';
import 'package:grocery_shopping_app/features/admin/data/repositories/api_store_repository_impl.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/core/utils/logger.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:grocery_shopping_app/features/auth/models/user_model.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';

import '../../../../core/utils/app_localizations.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  
  final UserRepository _userRepository = ApiUserRepositoryImpl();
  final StoreRepository _storeRepository = ApiStoreRepositoryImpl();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  final List<Map<String, dynamic>> _navItems = [
    {'title': 'nav_overview', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard},
    {'title': 'nav_users', 'icon': Icons.people_outline, 'activeIcon': Icons.people},
    {'title': 'nav_stores', 'icon': Icons.storefront_outlined, 'activeIcon': Icons.storefront},
    {'title': 'nav_shippers', 'icon': Icons.local_shipping_outlined, 'activeIcon': Icons.local_shipping},
    {'title': 'nav_orders', 'icon': Icons.assignment_outlined, 'activeIcon': Icons.assignment},
    {'title': 'nav_delivery', 'icon': Icons.delivery_dining_outlined, 'activeIcon': Icons.delivery_dining},
    {'title': 'nav_settings', 'icon': Icons.settings_outlined, 'activeIcon': Icons.settings},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final user = state.user;
          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isLargeScreen = constraints.maxWidth > 900;
              
              return Scaffold(
                backgroundColor: const Color(0xFFF0F2F5),
                appBar: _currentIndex == 0 ? _buildAppBar(user) : null,
                body: Row(
                  children: [
                    if (isLargeScreen) _buildSidebar(),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => _currentIndex = index),
                        children: [
                          _buildOverviewTab(),
                          const UserManagementScreen(),
                          const StoreManagementScreen(),
                          const ShipperManagementScreen(),
                          const OrderManagementScreen(),
                          const DeliveryManagementScreen(),
                          const SettingsScreen(),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: isLargeScreen ? null : _buildBottomNav(),
              );
            },
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildSidebar() {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.shield, color: Colors.indigo, size: 24),
                ),
                const SizedBox(width: 12),
                Text(l.translate('app_title').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _currentIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 12, right: 12),
                  child: ListTile(
                    onTap: () => _onTabTapped(index),
                    selected: isSelected,
                    leading: Icon(isSelected ? item['activeIcon'] : item['icon'], color: isSelected ? Colors.indigo : Colors.grey[600]),
                    title: Text(l.translate(item['title']), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.indigo : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700]), fontSize: 13)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    selectedTileColor: Colors.indigo.withValues(alpha: 0.08),
                  ),
                );
              },
            ),
          ),
          // Sidebar Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[100]!))),
            child: Row(
              children: [
                const CircleAvatar(radius: 16, backgroundColor: Colors.orange, child: Icon(Icons.person, size: 16, color: Colors.white)),
                const SizedBox(width: 12),
                const Expanded(child: Text('Admin Manager', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.logout, size: 18, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(UserModel user) {
    final l = AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.indigo, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.translate('app_title'), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.normal)),
                Text(user.fullName, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNav() {
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 72, // Slightly taller for better touch targets
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final isSelected = _currentIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => _onTabTapped(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.indigo.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? item['activeIcon'] : item['icon'],
                              color: isSelected ? Colors.indigo : Colors.grey[500],
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.translate(item['title']),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.indigo : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 0: TỔNG QUAN ---
  Widget _buildOverviewTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.indigo));
        }

        final stats = snapshot.data ?? {};
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildWelcomeHeader(stats),
                const SizedBox(height: 24),
                _buildStatsGrid(stats),
                const SizedBox(height: 24),
                _buildSectionHeader('Biểu đồ Tăng trưởng', onExport: () => _exportDashboardData(stats)),
                const SizedBox(height: 12),
                _buildOverviewChart(stats),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildSectionHeader('Hoạt động mới nhất'),
                const SizedBox(height: 12),
                _buildRecentActivities(stats),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chào buổi sáng, Admin! 👋',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          'Hệ thống đang hoạt động ổn định. Kiểm tra ngay hôm nay.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 500 ? 3 : 2;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildPremiumStatCard(
              'Doanh thu', 
              _currencyFormat.format(stats['revenue'] ?? 0), 
              Icons.payments, 
              [const Color(0xFF6366F1), const Color(0xFF818CF8)],
              '+12.5%',
            ),
            _buildPremiumStatCard(
              'Đơn hàng', 
              '${stats['orders'] ?? 0}', 
              Icons.shopping_cart, 
              [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
              '+5.2%',
            ),
            _buildPremiumStatCard(
              'Người dùng', 
              '${stats['userCount'] ?? 0}', 
              Icons.people, 
              [const Color(0xFF10B981), const Color(0xFF34D399)],
              '+8.1%',
            ),
            _buildPremiumStatCard(
              'Cửa hàng', 
              '${stats['storeCount'] ?? 0}', 
              Icons.storefront, 
              [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
              '+2.0%',
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumStatCard(String title, String value, IconData icon, List<Color> gradient, String trend) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: gradient.first.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Text(trend, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 2),
                Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewChart(Map<String, dynamic> stats) {
    final List<OrderModel> orders = stats['recentOrders']?.cast<OrderModel>() ?? [];
    
    // Simple logic to group revenue by the last 7 days
    final now = DateTime.now();
    final Map<int, double> dailyRevenue = {};
    for (int i = 0; i < 7; i++) {
      dailyRevenue[i] = 0;
    }

    for (var order in orders) {
      if (order.status == 'DELIVERED' && order.createdAt != null) {
        final dt = DateTime.tryParse(order.createdAt!);
        if (dt != null) {
          final diff = now.difference(dt).inDays;
          if (diff >= 0 && diff < 7) {
            final dayIndex = 6 - diff;
            dailyRevenue[dayIndex] = (dailyRevenue[dayIndex] ?? 0) + (order.totalAmount ?? 0);
          }
        }
      }
    }

    final spots = dailyRevenue.entries.map((e) {
      // Scale down for chart display (to millions or similar)
      double value = e.value / 1000000; 
      return FlSpot(e.key.toDouble(), value == 0 ? 0.1 : value);
    }).toList();

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[100]!, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  // Generate last 7 days labels
                  if (val.toInt() >= 0 && val.toInt() < 7) {
                    final day = now.subtract(Duration(days: 6 - val.toInt()));
                    final label = DateFormat('dd/MM').format(day);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.bold)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.indigo,
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true, 
                gradient: LinearGradient(
                  colors: [Colors.indigo.withValues(alpha: 0.2), Colors.indigo.withValues(alpha: 0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'title': 'Người dùng', 'icon': Icons.people, 'color': const Color(0xFF10B981), 'index': 1},
      {'title': 'Cửa hàng', 'icon': Icons.storefront, 'color': const Color(0xFF3B82F6), 'index': 2},
      {'title': 'Shipper', 'icon': Icons.local_shipping, 'color': const Color(0xFFF59E0B), 'index': 3},
      {'title': 'Sản phẩm', 'icon': Icons.inventory_2, 'color': const Color(0xFF6366F1), 'index': 8}, // Mock index or handled in PageView
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Truy cập nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            itemBuilder: (context, i) {
              final action = actions[i];
              return GestureDetector(
                onTap: () {
                   final idx = action['index'] as int;
                   if (idx <= 6) _onTabTapped(idx);
                },
                child: Container(
                  width: 90,
                  margin: EdgeInsets.only(right: i < actions.length - 1 ? 12 : 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: (action['color'] as Color).withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(action['title'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onExport}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        if (onExport != null)
          TextButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.description_outlined, size: 16),
            label: const Text('Xuất báo cáo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(foregroundColor: Colors.indigo),
          ),
      ],
    );
  }

  void _exportDashboardData(Map<String, dynamic> stats) async {
    final List<Map<String, dynamic>> exportData = [
      {'Thông số': 'Tổng doanh thu', 'Giá trị': stats['revenue']},
      {'Thông số': 'Tổng đơn hàng', 'Giá trị': stats['orders']},
      {'Thông số': 'Tổng người dùng', 'Giá trị': stats['userCount']},
      {'Thông số': 'Tổng cửa hàng', 'Giá trị': stats['storeCount']},
      {'Thông số': 'Lợi nhuận ước tính', 'Giá trị': stats['profit']},
    ];
    
    await ExportService.exportToCsv(
      context: context,
      data: exportData,
      fileName: 'baocao_tongquan_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  Widget _buildRecentActivities(Map<String, dynamic> stats) {
    final List<UserModel> topUsers = stats['recentUsers']?.cast<UserModel>() ?? [];
    final List<OrderModel> recentOrders = stats['recentOrders']?.cast<OrderModel>() ?? [];
    
    final List<Map<String, dynamic>> combined = [
      ...recentOrders.map((o) => {
        'title': 'Đơn #${o.id?.toString().toUpperCase().padLeft(6, '0').substring((o.id?.toString().length ?? 6) > 6 ? (o.id?.toString().length ?? 6) - 6 : 0) ?? "N/A"}', 
        'subtitle': 'Khách: ${o.customerName ?? "N/A"}', 
        'icon': Icons.shopping_bag, 
        'color': Colors.orange
      }),
      ...topUsers.map((u) => {
        'title': u.fullName, 
        'subtitle': 'Khách hàng mới', 
        'icon': Icons.person, 
        'color': Colors.green
      }),
    ];

    if (combined.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(Icons.history_outlined, color: Colors.grey[300], size: 40),
            const SizedBox(height: 8),
            Text('Chưa có hoạt động mới', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: combined.take(5).map((item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 18, backgroundColor: (item['color'] as Color).withValues(alpha: 0.1), child: Icon(item['icon'] as IconData, size: 16, color: item['color'] as Color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                   Text(item['subtitle'] as String, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Text(DateFormat('HH:mm').format(DateTime.now().subtract(const Duration(minutes: 15))), style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ],
        ),
      )).toList(),
    );
  }

  Future<Map<String, dynamic>> _loadDashboardStats() async {
    try {
      final orderService = OrderService();
      final results = await Future.wait([
        _userRepository.getUsers(),
        _storeRepository.getStores(),
        orderService.getAllOrdersAdmin(),
      ]);

      final users = results[0] as List<UserModel>;
      final stores = results[1] as List<Map<String, dynamic>>;
      final orders = results[2] as List<OrderModel>;
      
      final customerCount = users.where((u) => u.role == UserRole.customer).length;
      final storeCount = stores.length;
      final totalUsers = users.length;
      
      // Calculate real revenue from DELIVERED orders
      double totalRevenue = 0;
      int deliveredCount = 0;
      for (var order in orders) {
        if (order.status == 'DELIVERED') {
          totalRevenue += (order.totalAmount ?? 0).toDouble();
          deliveredCount++;
        }
      }

      // Profit estimation (e.g. 10% of revenue)
      double estimatedProfit = totalRevenue * 0.1;

      // Sort users by ID or something to get "recent" ones
      final recentUsers = users.reversed.take(3).toList();
      
      // Recent activities: Combine new orders and new users
      final recentActivities = orders.take(5).toList();

      return {
        'userCount': totalUsers,
        'storeCount': storeCount,
        'revenue': totalRevenue,
        'orders': orders.length,
        'deliveredCount': deliveredCount,
        'profit': estimatedProfit,
        'topStores': stores.take(3).toList(),
        'recentUsers': recentUsers,
        'recentOrders': recentActivities,
        'customerCount': customerCount,
      };
    } catch (e) {
      AppLogger.error('Dashboard Stats Load Error: $e');
      return {
        'userCount': 0, 
        'storeCount': 0, 
        'revenue': 0.0, 
        'orders': 0, 
        'topStores': [], 
        'recentUsers': [], 
        'recentOrders': []
      };
    }
  }
}
