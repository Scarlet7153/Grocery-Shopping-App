import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_shopping_app/features/auth/bloc/auth_bloc.dart';
import 'package:grocery_shopping_app/features/auth/bloc/auth_event.dart';
import 'package:grocery_shopping_app/features/auth/bloc/auth_state.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/user_management/user_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/store_management/store_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/shipper_management/shipper_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/order_management/order_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/delivery_management/delivery_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/settings/settings_screen.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/core/utils/logger.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:grocery_shopping_app/features/auth/models/user_model.dart';

import '../../../../core/utils/app_localizations.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  String _chartPeriod = '12m'; // '7d', '30d', '12m'

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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isLargeScreen = constraints.maxWidth > 900;
                
                return Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  appBar: null,
                  body: Row(
                    children: [
                      if (isLargeScreen) _buildSidebar(),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) => setState(() => _currentIndex = index),
                          children: [
                            _buildOverviewTab(user),
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
      ),
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
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
            child: Row(
              children: [
                CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.primary, child: Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.onPrimary)),
                const SizedBox(width: 12),
                Expanded(child: Text('Admin Manager', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color), overflow: TextOverflow.ellipsis)),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Đăng xuất'),
                        content: const Text('Bạn có chắc chắn muốn thoát khỏi hệ thống?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.read<AuthBloc>().add(const LogoutRequested());
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.logout, size: 18, color: Theme.of(context).iconTheme.color)
                ),
              ],
            ),
          ),
        ],
      ),
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
                              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodySmall?.color,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.translate(item['title']),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodySmall?.color,
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
  Widget _buildOverviewTab(UserModel user) {
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
                _buildWelcomeHeader(user, stats),
                const SizedBox(height: 24),
                _buildStatsGrid(stats),
                const SizedBox(height: 24),
                _buildSectionHeader('Biểu đồ Doanh thu'),
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

  String _getGreeting(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return l.translate('greeting_morning');
    if (hour < 18) return l.translate('greeting_afternoon');
    return l.translate('greeting_evening');
  }

  Widget _buildWelcomeHeader(UserModel user, Map<String, dynamic> stats) {
    final l = AppLocalizations.of(context)!;
    final greeting = _getGreeting(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[800]!, Colors.indigo[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, ${user.fullName.split(' ').last}! 👋',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  l.translate('greeting_welcome_back'),
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Hệ thống đang hoạt động ổn định',
                        style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Background decoration icon
          Opacity(
            opacity: 0.1,
            child: Icon(Icons.auto_graph, size: 80, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 900 ? 4 : 2;
        final aspectRatio = width > 900 ? 2.4 : 1.4;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: aspectRatio,
          children: [
            _buildPremiumStatCard(
              'Doanh thu tháng này',
              _currencyFormat.format(stats['revenue'] ?? 0),
              Icons.payments,
              [const Color(0xFF6366F1), const Color(0xFF818CF8)],
              subtitle: stats['monthOverMonthGrowth'] != null
                  ? '${(stats['monthOverMonthGrowth'] as double) >= 0 ? '+' : ''}${(stats['monthOverMonthGrowth'] as double).toStringAsFixed(1)}% so với tháng trước'
                  : null,
            ),
            _buildPremiumStatCard(
              'Đơn hàng',
              '${stats['orders'] ?? 0}',
              Icons.shopping_cart,
              [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
            ),
            _buildPremiumStatCard(
              'Người dùng',
              '${stats['userCount'] ?? 0}',
              Icons.people,
              [const Color(0xFF10B981), const Color(0xFF34D399)],
            ),
            _buildPremiumStatCard(
              'Cửa hàng',
              '${stats['storeCount'] ?? 0}',
              Icons.storefront,
              [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumStatCard(String title, String value, IconData icon, List<Color> gradient, {String? subtitle}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: gradient.first.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 20, height: 1.2),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, height: 1.2),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewChart(Map<String, dynamic> stats) {
    final chartGridColor = Theme.of(context).dividerColor;
    final chartLabelColor = Theme.of(context).textTheme.bodySmall?.color;
    final primaryColor = Theme.of(context).colorScheme.primary;

    List<FlSpot> spots = [];
    double maxY = 10.0;
    List<String> bottomLabels = [];

    if (_chartPeriod == '12m') {
      // Dùng dữ liệu monthlyRevenue từ API
      final monthlyData = (stats['monthlyRevenue'] as List<dynamic>?) ?? [];
      for (int i = 0; i < monthlyData.length; i++) {
        final revenue = (monthlyData[i]['revenue'] ?? 0).toDouble();
        spots.add(FlSpot(i.toDouble(), revenue / 1000));
        bottomLabels.add(monthlyData[i]['monthLabel']?.toString() ?? '');
      }
      if (spots.isNotEmpty) {
        final maxRevenue = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
        maxY = maxRevenue > 0 ? maxRevenue * 1.2 : 10.0;
      }
    } else {
      // 7d hoặc 30d: tính từ recentOrders
      final days = _chartPeriod == '30d' ? 30 : 7;
      final List<OrderModel> orders = stats['recentOrders']?.cast<OrderModel>() ?? [];
      final now = DateTime.now();
      final Map<int, double> dailyRevenue = {};
      for (int i = 0; i < days; i++) dailyRevenue[i] = 0;

      for (var order in orders) {
        if (order.createdAt != null) {
          final dt = DateTime.tryParse(order.createdAt!);
          if (dt != null) {
            final diff = now.difference(dt).inDays;
            if (diff >= 0 && diff < days) {
              final dayIndex = days - 1 - diff;
              dailyRevenue[dayIndex] = (dailyRevenue[dayIndex] ?? 0) + (order.totalAmount ?? 0);
            }
          }
        }
      }

      spots = dailyRevenue.entries.map((e) => FlSpot(e.key.toDouble(), e.value / 1000)).toList();
      final maxRevenue = dailyRevenue.values.isEmpty ? 0.0 : dailyRevenue.values.reduce((a, b) => a > b ? a : b);
      maxY = maxRevenue > 0 ? (maxRevenue / 1000.0) * 1.2 : 10.0;

      for (int i = 0; i < days; i++) {
        final day = now.subtract(Duration(days: days - 1 - i));
        final weekday = day.weekday;
        final labels = {1: 'T2', 2: 'T3', 3: 'T4', 4: 'T5', 5: 'T6', 6: 'T7', 7: 'CN'};
        bottomLabels.add(labels[weekday] ?? '');
      }
    }

    return Column(
      children: [
        // Toggle buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildPeriodChip('7 ngày', '7d'),
            const SizedBox(width: 8),
            _buildPeriodChip('30 ngày', '30d'),
            const SizedBox(width: 8),
            _buildPeriodChip('12 tháng', '12m'),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 240,
          padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(color: chartGridColor, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _chartPeriod == '12m' ? 2 : (_chartPeriod == '30d' ? 5 : 2),
                    getTitlesWidget: (val, meta) {
                      final index = val.toInt();
                      if (index >= 0 && index < bottomLabels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(bottomLabels[index], style: TextStyle(color: chartLabelColor, fontSize: 9, fontWeight: FontWeight.w600)),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (val, meta) {
                      if (val == 0) return const SizedBox.shrink();
                      return Text('${val.toInt()}k', style: TextStyle(color: chartLabelColor, fontSize: 9, fontWeight: FontWeight.bold));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [primaryColor.withValues(alpha: 0.2), primaryColor.withValues(alpha: 0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _chartPeriod == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color)),
      selected: isSelected,
      onSelected: (_) => setState(() => _chartPeriod = value),
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF0F2F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
        Text('Truy cập nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
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
                    color: Theme.of(context).cardColor,
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
                      Text(action['title'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
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
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
        if (onExport != null)
          TextButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.description_outlined, size: 16),
            label: const Text('Xuất báo cáo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
          ),
      ],
    );
  }

  Widget _buildRecentActivities(Map<String, dynamic> stats) {
    final List rawUsers = stats['recentUsers'] ?? [];
    final List<UserModel> topUsers = rawUsers.map((u) {
      if (u is UserModel) return u;
      return UserModel.fromJson(Map<String, dynamic>.from(u as Map));
    }).toList();
    
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
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(Icons.history_outlined, color: Theme.of(context).disabledColor, size: 40),
            const SizedBox(height: 8),
            Text('Chưa có hoạt động mới', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: combined.take(5).map((item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
                   Text(item['title'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color), overflow: TextOverflow.ellipsis),
                   Text(item['subtitle'] as String, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ),
            ),
            Text(DateFormat('HH:mm').format(DateTime.now().subtract(const Duration(minutes: 15))), style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6))),
          ],
        ),
      )).toList(),
    );
  }

  Future<Map<String, dynamic>> _loadDashboardStats() async {
    try {
      final orderService = OrderService();
      // Use the centralized stats aggregation logic in OrderService
      // which utilizes ONLY existing backend endpoints.
      final stats = await orderService.getAdminStats();
      
      // Map the service results to the UI's expected keys if necessary
      return stats;
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
