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
        id: 103,
        customerName: 'Le Thi C',
        customerPhone: '0909876543',
        storeName: 'Mini Mart C',
        deliveryAddress: '789 Đường C, Quận 5',
        status: OrderStatus.AVAILABLE,
        grandTotal: 52000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
    ];

    return {
      'isOnline': true,
      'earnings': 120000.0,
      'availableOrders': sampleOrders,
      'deliveries': const [],
      'completedCount': 12,
      'acceptanceRate': 87.5,
    };
  }
}

enum HistoryFilter { today, week, month }

enum _ProfileSection { main, personalInfo, helpCenter, appSettings }

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
  _ProfileSection _profileSection = _ProfileSection.main;
  bool _pushNotifications = true;
  bool _soundAlerts = true;
  bool _autoAcceptOrders = false;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _plateController;
  late final TextEditingController _vehicleController;
  late final TextEditingController _idController;
  final Set<int> _skippedOrderIds = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Nguyễn Văn A');
    _phoneController = TextEditingController(text: '0901234567');
    _emailController = TextEditingController(text: 'shipper@example.com');
    _plateController = TextEditingController(text: '51C-123.45');
    _vehicleController = TextEditingController(text: 'Xe máy');
    _idController = TextEditingController(text: '123456789012');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _plateController.dispose();
    _vehicleController.dispose();
    _idController.dispose();
    super.dispose();
  }

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
              const Text('Đơn hàng mới',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ShipperTheme.textColor)),
              const SizedBox(height: 8),
              if (!state.isOnline)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.cloud_off,
                          size: 44,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Bạn đang ngoại tuyến',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Bật trạng thái hoạt động để bắt đầu nhận đơn hàng mới xung quanh bạn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                )
              else
                AvailableOrdersList(
                  orders: state.availableOrders
                      .where((order) => order.status == OrderStatus.AVAILABLE)
                      .where((order) => !_skippedOrderIds.contains(order.id))
                      .toList(),
                  onAccept: (orderId) {
                    final order = state.availableOrders.firstWhere((o) => o.id == orderId);
                    _showOrderFocusSheet(context, order);
                  },
                  onSkip: (orderId) {
                    setState(() {
                      _skippedOrderIds.add(orderId);
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showOrderFocusSheet(BuildContext context, ShipperOrder order) {
    int currentStep = 0;
    final steps = [
      'Đang đến điểm lấy hàng',
      'Chờ nhận hàng',
      'Đang giao hàng',
      'Giao hàng thành công',
    ];
    final buttonLabels = [
      'Đã đến điểm lấy',
      'Xác nhận đã lấy hàng',
      'Đã đến điểm giao',
      'Hoàn thành chuyến',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final actionLabel = buttonLabels[currentStep];
            final stepLabel = steps[currentStep];
            final isFinalStep = currentStep == buttonLabels.length - 1;

            return Container(
              margin: const EdgeInsets.only(top: 60),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Đơn hàng hiện tại',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.map,
                            size: 84,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        stepLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Đơn #${order.id}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Khách: ${order.customerName}'),
                              const SizedBox(height: 4),
                              Text('SĐT: ${order.customerPhone}'),
                              const SizedBox(height: 4),
                              Text('Địa chỉ: ${order.deliveryAddress}'),
                              const SizedBox(height: 4),
                              Text('Cửa hàng: ${order.storeName}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.call),
                              label: const Text('Gọi điện'),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.message),
                              label: const Text('Nhắn tin'),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF57C00),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          if (!isFinalStep) {
                            setLocalState(() {
                              currentStep += 1;
                            });
                          } else {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Hoàn thành chuyến')),
                            );
                          }
                        },
                        child: Text(actionLabel),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
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
    switch (_profileSection) {
      case _ProfileSection.personalInfo:
        return _personalInfoPage();
      case _ProfileSection.helpCenter:
        return _helpCenterPage();
      case _ProfileSection.appSettings:
        return _appSettingsPage();
      case _ProfileSection.main:
      default:
        return _profileMainPage();
    }
  }

  Widget _profileMainPage() {
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
                    setState(() {
                      _profileSection = _ProfileSection.personalInfo;
                    });
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.support_agent),
                  title: const Text('Trung tâm trợ giúp'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() {
                      _profileSection = _ProfileSection.helpCenter;
                    });
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Cài đặt ứng dụng'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() {
                      _profileSection = _ProfileSection.appSettings;
                    });
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

  Widget _profileHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _profileSection = _ProfileSection.main;
              });
            },
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _profileHeader('Thông tin cá nhân'),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        const CircleAvatar(
                          radius: 46,
                          backgroundColor: ShipperTheme.primaryColor,
                          child: Text(
                            'S',
                            style: TextStyle(fontSize: 32, color: Colors.white),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mô phỏng thay đổi ảnh đại diện'),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: ShipperTheme.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField('Họ và tên', controller: _nameController),
                  const SizedBox(height: 12),
                  _buildTextField('Số điện thoại', controller: _phoneController),
                  const SizedBox(height: 12),
                  _buildTextField('Email', controller: _emailController),
                  const SizedBox(height: 12),
                  _buildTextField('Biển số xe', controller: _plateController),
                  const SizedBox(height: 12),
                  _buildTextField('Phương tiện', controller: _vehicleController),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _idController,
                    decoration: InputDecoration(
                      labelText: 'Số CCCD/CMND',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.lock_outline),
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Để thay đổi CCCD/CMND, vui lòng liên hệ tổng đài hỗ trợ.',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã lưu thay đổi (mô phỏng)')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShipperTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Lưu thay đổi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _helpCenterPage() {
    final popularTopics = [
      {'title': 'Vấn đề đơn hàng', 'icon': Icons.shopping_cart},
      {'title': 'Thanh toán & Ví', 'icon': Icons.payment},
      {'title': 'Tài khoản', 'icon': Icons.person},
      {'title': 'Chính sách', 'icon': Icons.policy},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _profileHeader('Trung tâm trợ giúp'),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm câu hỏi...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chủ đề phổ biến',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: popularTopics.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.7,
                    ),
                    itemBuilder: (context, index) {
                      final topic = popularTopics[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(topic['icon'] as IconData,
                                color: ShipperTheme.primaryColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                topic['title'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Hỗ trợ trực tiếp',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gọi tổng đài 24/7 (mô phỏng)')),
                      );
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Gọi tổng đài'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShipperTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat với CSKH (mô phỏng)')),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat với CSKH'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ShipperTheme.textColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appSettingsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _profileHeader('Cài đặt ứng dụng'),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    title: const Text('Thông báo đẩy'),
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() {
                        _pushNotifications = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Âm thanh đơn hàng mới'),
                    value: _soundAlerts,
                    onChanged: (value) {
                      setState(() {
                        _soundAlerts = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Tự động nhận đơn'),
                    value: _autoAcceptOrders,
                    onChanged: (value) {
                      setState(() {
                        _autoAcceptOrders = value;
                      });
                    },
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Ngôn ngữ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Tiếng Việt'),
                        Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Phiên bản ứng dụng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1.0.0',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label,
      {required TextEditingController controller, bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
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
