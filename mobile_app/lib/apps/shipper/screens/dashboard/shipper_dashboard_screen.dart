import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/apps/shipper/bloc/shipper_dashboard_bloc.dart';
import 'package:grocery_shopping_app/apps/shipper/models/shipper_order.dart';
import 'package:grocery_shopping_app/apps/shipper/repository/shipper_repository.dart';
import 'package:grocery_shopping_app/apps/shipper/bloc/shipper_auth_bloc.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/auth/shipper_login_screen.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/dashboard/widgets/available_orders.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/dashboard/widgets/dashboard_stats.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/dashboard/widgets/online_toggle.dart';

/// A tiny fake repository that returns sample data immediately. Used by the
/// preview constructor so we can open the dashboard without a backend/token.
class _PreviewRepo extends ShipperRepository {
  _PreviewRepo() : super(dio: null);

  @override
  Future<Map<String, dynamic>> fetchDashboardData() async {
    // return static sample values
    final sampleOrders = [
      ShipperOrder(
        id: 101,
        customerName: 'Nguyen Van A',
        customerPhone: '0901234567',
        storeName: 'Bách Hóa Xanh',
        deliveryAddress: '123 Đường A, Quận 1',
        status: OrderStatus.AVAILABLE,
        grandTotal: 45000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      ShipperOrder(
        id: 102,
        customerName: 'Tran Thi B',
        customerPhone: '0912345678',
        storeName: 'Co.opmart',
        deliveryAddress: '456 Đường B, Quận 3',
        status: OrderStatus.PICKING_UP,
        grandTotal: 38000,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

    return {
      'isOnline': true,
      'earnings': 120000.0,
      'availableOrders': sampleOrders,
      'deliveries': sampleOrders.where((o) => o.status != OrderStatus.AVAILABLE).toList(),
      'completedCount': 12,
      'acceptanceRate': 87.5,
    };
  }
}

enum HistoryFilter { today, week, month }

class ShipperDashboardScreen extends StatefulWidget {
  final bool preview;

  /// Normal constructor: dashboard for authenticated shipper.
  const ShipperDashboardScreen({super.key, this.preview = false});

  /// Shortcut used only by developers to preview UI without logging in.
  const ShipperDashboardScreen.preview({super.key}) : preview = true;

  @override
  State<ShipperDashboardScreen> createState() => _ShipperDashboardScreenState();
}

class _ShipperDashboardScreenState extends State<ShipperDashboardScreen> {
  int _currentIndex = 0;
  HistoryFilter _historyFilter = HistoryFilter.today;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final repo = widget.preview
            ? _PreviewRepo()
            : context.read<ShipperRepository>();
        return ShipperDashboardBloc(repository: repo)..add(LoadDashboardData());
      },
      child: Scaffold(
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: ShipperTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          onTap: (idx) => setState(() => _currentIndex = idx),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Tổng quan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Lịch sử',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Thống kê',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 1:
        return _historyPage();
      case 2:
        return _statisticsPage();
      case 3:
        return _profilePage();
      case 0:
      default:
        return _overviewPage();
    }
  }

  Widget _overviewPage() {
    return BlocBuilder<ShipperDashboardBloc, ShipperDashboardState>(
      builder: (context, state) {
        if (state.status == DashboardStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == DashboardStatus.error) {
          return Center(child: Text('Lỗi: ${state.error}'));
        }
        final statusText = state.isOnline ? 'Đang hoạt động' : 'Ngoại tuyến';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: ShipperTheme.primaryColor,
                    child: Text(
                      'S',
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nguyễn Văn A',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ShipperTheme.textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  OnlineToggle(
                    isOnline: state.isOnline,
                    onToggle: () => context
                        .read<ShipperDashboardBloc>()
                        .add(ToggleOnlineStatus()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StatsCard(
                orders: state.completedCount,
                earnings: state.earnings,
                rating: state.acceptanceRate,
              ),
              const SizedBox(height: 16),
              const Text('Đơn hàng sẵn có',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ShipperTheme.textColor)),
              const SizedBox(height: 8),
              AvailableOrdersList(
                orders: state.availableOrders,
                onAccept: (orderId) =>
                    context.read<ShipperDashboardBloc>().add(AcceptOrder(orderId)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _historyPage() {
    return BlocBuilder<ShipperDashboardBloc, ShipperDashboardState>(
      builder: (context, state) {
        if (state.status == DashboardStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == DashboardStatus.error) {
          return Center(child: Text('Lỗi: ${state.error}'));
        }

        final now = DateTime.now();
        final startDate = () {
          switch (_historyFilter) {
            case HistoryFilter.today:
              return DateTime(now.year, now.month, now.day);
            case HistoryFilter.week:
              return now.subtract(const Duration(days: 7));
            case HistoryFilter.month:
              return DateTime(now.year, now.month - 1, now.day);
          }
        }();

        final filteredOrders = state.deliveries
            .where((o) => o.createdAt.isAfter(startDate))
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Lịch sử đơn hàng',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ShipperTheme.textColor),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: HistoryFilter.values.map((filter) {
                  final label = {
                    HistoryFilter.today: 'Hôm nay',
                    HistoryFilter.week: 'Tuần này',
                    HistoryFilter.month: 'Tháng này',
                  }[filter]!;
                  final selected = filter == _historyFilter;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              selected ? ShipperTheme.primaryColor : null,
                          foregroundColor:
                              selected ? Colors.white : ShipperTheme.textColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _historyFilter = filter;
                          });
                        },
                        child: Text(label),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredOrders.isEmpty
                    ? const Center(child: Text('Không có đơn hàng'))
                    : ListView.separated(
                        itemCount: filteredOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: ShipperTheme.primaryColor
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.history,
                                            color: ShipperTheme.primaryColor,
                                            size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Đơn #${order.id}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              order.deliveryAddress,
                                              style: const TextStyle(
                                                  color: Colors.black54),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Khách: ${order.customerName}',
                                              style: const TextStyle(
                                                  color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${order.grandTotal.toStringAsFixed(0)}₫',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: ShipperTheme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            order.status.label,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: order.status ==
                                                      OrderStatus.AVAILABLE
                                                  ? ShipperTheme.primaryColor
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statisticsPage() {
    return BlocBuilder<ShipperDashboardBloc, ShipperDashboardState>(
      builder: (context, state) {
        if (state.status == DashboardStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == DashboardStatus.error) {
          return Center(child: Text('Lỗi: ${state.error}'));
        }

        // Placeholder values while backend details are not available
        final onlineHours = state.isOnline ? 5.5 : 0.0;
        final weeklyIncome = state.earnings;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Thống kê',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ShipperTheme.textColor),
              ),
              const SizedBox(height: 12),
              StatsCard(
                orders: state.completedCount,
                earnings: weeklyIncome,
                rating: state.acceptanceRate,
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Chi tiết',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow('Giờ online', '${onlineHours.toStringAsFixed(1)} giờ'),
                      const SizedBox(height: 8),
                      _buildStatRow('Thu nhập tuần', '${weeklyIncome.toStringAsFixed(0)}₫'),
                      const SizedBox(height: 8),
                      _buildStatRow('Tỷ lệ nhận đơn', '${state.acceptanceRate.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: const [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: ShipperTheme.primaryColor,
                  child: Text(
                    'S',
                    style: TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Nguyễn Văn A',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Shipper',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Thông tin cá nhân'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: open personal info
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.support_agent),
                  title: const Text('Trung tâm trợ giúp'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: open help center
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Cài đặt ứng dụng'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: open app settings
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ShipperAuthBloc>().add(ShipperLogoutRequested());
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const ShipperLoginScreen(),
                ),
              );
            },
            icon: const Icon(Icons.power_settings_new),
            label: const Text('Đăng xuất'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ShipperTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
