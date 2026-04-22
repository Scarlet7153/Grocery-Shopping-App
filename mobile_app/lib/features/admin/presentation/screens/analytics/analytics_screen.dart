import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../admin/domain/repositories/user_repository.dart';
import '../../../../admin/data/repositories/api_user_repository_impl.dart';
import '../../../../admin/domain/repositories/store_repository.dart';
import '../../../../admin/data/repositories/api_store_repository_impl.dart';
import 'package:grocery_shopping_app/features/auth/models/user_model.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';

enum TimeFilter { today, week, month, year }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  TimeFilter _selectedTimeFilter = TimeFilter.week;
  final List<TimeFilter> _timeFilters = [TimeFilter.today, TimeFilter.week, TimeFilter.month, TimeFilter.year];
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  final UserRepository _userRepository = ApiUserRepositoryImpl();
  final StoreRepository _storeRepository = ApiStoreRepositoryImpl();

  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final orderService = OrderService();
    _statsFuture = Future.wait<dynamic>([
      _userRepository.getUsers(),
      _storeRepository.getStores(),
      orderService.getAllOrdersAdmin(),
    ]).then((results) {
      final users = results[0] as List<UserModel>;
      final stores = results[1] as List<Map<String, dynamic>>;
      final orders = results[2] as List<OrderModel>;
      
      final uCount = users.length;
      final sCount = stores.length;
      final shippersList = users.where((u) => u.role == UserRole.shipper).toList();

      // 1. Lọc đơn hàng theo thời gian đã chọn
      final now = DateTime.now();
      final filteredOrders = orders.where((ord) {
        if (ord.createdAt == null) return false;
        final date = DateTime.tryParse(ord.createdAt!) ?? now;
        
        if (_selectedTimeFilter == TimeFilter.today) {
          return date.year == now.year && date.month == now.month && date.day == now.day;
        } else if (_selectedTimeFilter == TimeFilter.week) {
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return date.isAfter(weekStart.subtract(const Duration(seconds: 1)));
        } else if (_selectedTimeFilter == TimeFilter.month) {
          return date.year == now.year && date.month == now.month;
        } else if (_selectedTimeFilter == TimeFilter.year) {
          return date.year == now.year;
        }
        return true;
      }).toList();

      // 2. Tổng hợp dữ liệu thực tế (Doanh thu & Tổng đơn)
      double realRevenue = 0;
      int realOrdersCount = filteredOrders.length;
      
      Map<String, double> storeRevenueMap = {};
      Map<String, int> shipperOrdersMap = {};
      Map<int, double> chartDataMap = {}; // index -> revenue

      for (var order in filteredOrders) {
        final status = (order.status ?? '').toUpperCase();
        if (status != 'CANCELLED') {
          realRevenue += (order.totalAmount ?? 0).toDouble();
          
          // Thống kê theo cửa hàng
          final sId = (order.storeId ?? order.storeName ?? 'Khác').toString();
          storeRevenueMap[sId] = (storeRevenueMap[sId] ?? 0) + (order.totalAmount ?? 0).toDouble();
          
          // Thống kê theo shipper
          final shId = (order.shipperId ?? order.shipperName ?? 'Chưa gán').toString();
          shipperOrdersMap[shId] = (shipperOrdersMap[shId] ?? 0) + 1;
        }

        // Dữ liệu biểu đồ (Phân phối theo giờ/ngày/tháng)
        final date = DateTime.tryParse(order.createdAt!) ?? now;
        int chartIdx = 0;
        if (_selectedTimeFilter == TimeFilter.today) {
          chartIdx = (date.hour / 4).floor().clamp(0, 5); // 6 mốc
        } else if (_selectedTimeFilter == TimeFilter.week) {
          chartIdx = (date.weekday - 1).clamp(0, 6); // 7 ngày
        } else if (_selectedTimeFilter == TimeFilter.month) {
          chartIdx = ((date.day - 1) / 7).floor().clamp(0, 3); // 4 tuần
        } else if (_selectedTimeFilter == TimeFilter.year) {
          chartIdx = (date.month - 1).clamp(0, 11); // 12 tháng
        }
        final amount = (order.totalAmount ?? 0).toDouble();
        chartDataMap[chartIdx] = (chartDataMap[chartIdx] ?? 0) + amount;
      }

      // 3. Chuẩn bị danh sách Xếp hạng
      final List<Map<String, dynamic>> topStoreResults = [];
      storeRevenueMap.forEach((key, val) {
        topStoreResults.add({
          'name': key,
          'revenue': val,
        });
      });
      topStoreResults.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      final List<Map<String, dynamic>> topShipperResults = [];
      shipperOrdersMap.forEach((key, val) {
        topShipperResults.add({
          'id': key,
          'count': val,
        });
      });
      topShipperResults.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return {
        'userCount': uCount,
        'storeCount': sCount,
        'revenue': realRevenue,
        'orders': realOrdersCount,
        'allOrders': filteredOrders,
        'chartData': chartDataMap,
        'topStoresData': topStoreResults.take(5).toList(),
        'topShippersData': topShipperResults.take(5).toList(),
        'shippersList': shippersList,
      };
    }).catchError((e) {
      debugPrint('Analytics Load Error: $e');
      return <String, Object>{'userCount': 0, 'storeCount': 0, 'offline': true};
    });
  }

  String _timeFilterLabel(TimeFilter filter, AppLocalizations l) {
    switch (filter) {
      case TimeFilter.today:
        return l.byLocale(vi: 'Hôm nay', en: 'Today');
      case TimeFilter.week:
        return l.byLocale(vi: 'Tuần này', en: 'This week');
      case TimeFilter.month:
        return l.byLocale(vi: 'Tháng này', en: 'This month');
      case TimeFilter.year:
        return l.byLocale(vi: 'Năm nay', en: 'This year');
    }
  }

  String _selectedTimeFilterLabel(AppLocalizations l) {
    return _timeFilterLabel(_selectedTimeFilter, l);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
          final bool isOffline = snapshot.data?['offline'] == true;
          final int userCount = snapshot.data?['userCount'] ?? 0;
          final int storeCount = snapshot.data?['storeCount'] ?? 0;
          final double revenue = snapshot.data?['revenue'] ?? 0;
          final int orders = snapshot.data?['orders'] ?? 0;
          final List topStoresData = snapshot.data?['topStoresData'] ?? [];
          final List topShippersData = snapshot.data?['topShippersData'] ?? [];
          final List<UserModel> shippersList = snapshot.data?['shippersList'] ?? [];
          final Map<int, double> chartData = snapshot.data?['chartData'] ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loading indicator
                if (isLoading)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: Colors.indigo),
                          const SizedBox(height: 8),
                          Text(l.byLocale(vi: 'Đang tải dữ liệu...', en: 'Loading data...'), style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),

                // Offline notice
                if (isOffline)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off, color: Colors.orange[700], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.byLocale(
                              vi: 'Không kết nối được máy chủ. Số liệu User/Cửa hàng tạm thời là 0.',
                              en: 'Unable to connect to server. User/store counts may be temporarily 0.',
                            ),
                            style: TextStyle(color: Colors.orange[800], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bộ lọc thời gian
                // Header row with title and actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l.byLocale(vi: 'Báo Cáo Bán Hàng', en: 'Sales Report'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.file_download_outlined, color: Colors.indigo),
                          onPressed: () => _exportAnalytics(context),
                          tooltip: l.byLocale(vi: 'Xuất Báo cáo', en: 'Export report'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.indigo),
                          onPressed: () => setState(() => _loadStats()),
                          tooltip: l.byLocale(vi: 'Làm mới dữ liệu', en: 'Refresh data'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTimeFilter(l),
                const SizedBox(height: 20),

                Text(
                  '${l.byLocale(vi: 'Tổng quan', en: 'Overview')} ${_selectedTimeFilterLabel(l)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatCard(
                      l.byLocale(vi: 'Người dùng', en: 'Users'),
                      isLoading ? '...' : userCount.toString(),
                      Icons.people_outline,
                      Colors.green,
                      isReal: !isOffline,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      l.byLocale(vi: 'Cửa hàng', en: 'Stores'),
                      isLoading ? '...' : storeCount.toString(),
                      Icons.storefront,
                      Colors.blue,
                      isReal: !isOffline,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      l.byLocale(vi: 'Doanh thu', en: 'Revenue'),
                      isLoading ? '...' : _currencyFormat.format(revenue),
                      Icons.attach_money,
                      Colors.orange,
                      isReal: !isOffline,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      l.byLocale(vi: 'Đơn hàng', en: 'Orders'),
                      isLoading ? '...' : '$orders ${l.byLocale(vi: 'đơn', en: 'orders')}',
                      Icons.shopping_bag,
                      Colors.purple,
                      isReal: !isOffline,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                // Ghi chú nguồn dữ liệu
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                            children: [
                              TextSpan(text: l.byLocale(vi: '🟢 Xanh/Xanh lơ: ', en: '🟢 Green/Light blue: '), style: const TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: l.byLocale(vi: 'Dữ liệu thực từ API.  ', en: 'Actual API data.  ')),
                              TextSpan(text: l.byLocale(vi: '🟡 Cam/Tím: ', en: '🟡 Orange/Purple: '), style: const TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: l.byLocale(vi: 'Dữ liệu thực từ hệ thống quét.', en: 'Data from the scanning system.')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Text(l.byLocale(vi: 'Biểu đồ Doanh thu (Quét thực tế)', en: 'Revenue chart (Actual scan)'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildLineChart(chartData, l),

                const SizedBox(height: 32),
                Text(l.byLocale(vi: 'Bảng Xếp Hạng', en: 'Rankings'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildLeaderboards(topStoresData, topShippersData, shippersList),

                const SizedBox(height: 32),
                Text(l.byLocale(vi: 'Cơ cấu Thanh toán (Ước tính)', en: 'Payment breakdown (Estimate)'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildPieChart(context),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeFilter(AppLocalizations l) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(l.byLocale(vi: 'Khoảng thời gian:', en: 'Time range:'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const Spacer(),
            DropdownButtonHideUnderline(
              child: DropdownButton<TimeFilter>(
                value: _selectedTimeFilter,
                icon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary, size: 18),
                items: _timeFilters.map((t) => DropdownMenuItem(value: t, child: Text(_timeFilterLabel(t, l), style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTimeFilter = val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isReal = true}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              Text(title, style: TextStyle(fontSize: 8, color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(Map<int, double> chartData, AppLocalizations l) {
    int pointCount = 7;
    List<String> xLabels = [
      l.byLocale(vi: 'T2', en: 'Mon'),
      l.byLocale(vi: 'T3', en: 'Tue'),
      l.byLocale(vi: 'T4', en: 'Wed'),
      l.byLocale(vi: 'T5', en: 'Thu'),
      l.byLocale(vi: 'T6', en: 'Fri'),
      l.byLocale(vi: 'T7', en: 'Sat'),
      l.byLocale(vi: 'CN', en: 'Sun'),
    ];
    if (_selectedTimeFilter == TimeFilter.today) {
      pointCount = 6;
      xLabels = [
        l.byLocale(vi: 'Sau 0h', en: 'After 0h'),
        '4h',
        '8h',
        '12h',
        '16h',
        '20h',
      ];
    } else if (_selectedTimeFilter == TimeFilter.month) {
      pointCount = 4;
      xLabels = [
        l.byLocale(vi: 'Tuần 1', en: 'Week 1'),
        l.byLocale(vi: 'Tuần 2', en: 'Week 2'),
        l.byLocale(vi: 'Tuần 3', en: 'Week 3'),
        l.byLocale(vi: 'Tuần 4', en: 'Week 4'),
      ];
    } else if (_selectedTimeFilter == TimeFilter.year) {
      pointCount = 12;
      xLabels = List.generate(12, (index) => '${index + 1}');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.only(top: 32, right: 24, left: 16, bottom: 16),
        child: SizedBox(
          height: 250,
          child: LineChart(LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 30, interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < pointCount) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(xLabels[value.toInt()], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    );
                  }
                  return const Text('');
                },
              )),
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 55,
                getTitlesWidget: (value, meta) {
                   String text = '';
                   if (value >= 1000000) {
                     text = '${(value / 1000000).toStringAsFixed(1)}Tr';
                   } else if (value >= 1000) {
                     text = '${(value / 1000).toStringAsFixed(0)}K';
                   } else {
                     text = value.toStringAsFixed(0);
                   }
                   return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(text, style: const TextStyle(fontSize: 10)),
                  );
                },
              )),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
                LineChartBarData(
                spots: List.generate(pointCount, (index) {
                  double val = chartData[index] ?? 0;
                  return FlSpot(index.toDouble(), val);
                }),
                isCurved: true, color: Colors.deepPurple, barWidth: 4,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: Colors.deepPurple.withValues(alpha: 0.2)),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildLeaderboards(List topStoresData, List topShippersData, List<UserModel> shippersList) {
    final l = AppLocalizations.of(context)!;
    // Chuẩn bị dữ liệu hiển thị cho Cửa hàng
    final storeItems = topStoresData.map((s) {
      return {
        'name': s['name'] ?? l.byLocale(vi: 'Khác', en: 'Other'),
        'metric': _currencyFormat.format(s['revenue']),
        'subtitle': l.byLocale(vi: 'Doanh thu đóng góp', en: 'Revenue contribution'),
      };
    }).toList();

    // Chuẩn bị dữ liệu hiển thị cho Shipper (mapping tên từ ID nếu cần)
    final shipperItems = topShippersData.map((s) {
      final shipperObj = shippersList.firstWhere(
        (u) => u.id == s['id'].toString(), 
        orElse: () => UserModel(
          id: s['id'].toString(), 
          fullName: s['id'].toString(), 
          phoneNumber: 'N/A', 
          role: UserRole.shipper, 
          status: UserStatus.active, 
          createdAt: DateTime.now(), 
          updatedAt: DateTime.now()
        )
      );
      return {
        'name': shipperObj.fullName,
        'metric': '${s['count']} ${l.byLocale(vi: 'Đơn', en: 'Orders')}',
        'subtitle': '${l.byLocale(vi: 'SĐT', en: 'Phone')}: ${shipperObj.phoneNumber}',
      };
    }).toList();

    return Column(
      children: [
        if (storeItems.isNotEmpty)
          _buildLeaderboardCard(l.byLocale(vi: '🏆 Top Cửa Hàng Xuất Sắc', en: '🏆 Top Stores'), storeItems, Colors.amber),
        if (storeItems.isNotEmpty) const SizedBox(height: 16),
        if (shipperItems.isNotEmpty)
          _buildLeaderboardCard(l.byLocale(vi: '🚀 Top Shipper Nổi Bật', en: '🚀 Top Shippers'), shipperItems, Colors.blueAccent),
        if (storeItems.isEmpty && shipperItems.isEmpty)
          Center(child: Text(l.byLocale(vi: 'Chưa có dữ liệu xếp hạng', en: 'No ranking data available'))),
      ],
    );
  }

  Widget _buildLeaderboardCard(String title, List<Map<String, dynamic>> items, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color)),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(items[index]['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(items[index]['subtitle'], style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
                trailing: Text(items[index]['metric'], style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 150,
                child: PieChart(PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: [
                    PieChartSectionData(value: 70, color: Colors.green, title: '70%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: 20, color: Colors.blue, title: '20%', radius: 35, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: 10, color: Colors.orange, title: '10%', radius: 30, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                )),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIndicator(Colors.green, l.byLocale(vi: 'TT Trực tuyến (70%)', en: 'Online payment (70%)')),
                const SizedBox(height: 8),
                _buildIndicator(Colors.blue, l.byLocale(vi: 'COD Giao hàng (20%)', en: 'Cash on delivery (20%)')),
                const SizedBox(height: 8),
                _buildIndicator(Colors.orange, l.byLocale(vi: 'Ví Điện Tử (10%)', en: 'E-wallet (10%)')),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _exportAnalytics(BuildContext context) async {
    final snapshot = await _statsFuture;
    final l = AppLocalizations.of(context)!;
    final List<Map<String, dynamic>> exportData = [
      {l.byLocale(vi: 'Hạng mục', en: 'Item'): l.byLocale(vi: 'Khoảng thời gian', en: 'Time range'), 'value': _selectedTimeFilterLabel(l)},
      {l.byLocale(vi: 'Hạng mục', en: 'Item'): l.byLocale(vi: 'Tổng người dùng', en: 'Total users'), 'value': snapshot['userCount']},
      {l.byLocale(vi: 'Hạng mục', en: 'Item'): l.byLocale(vi: 'Tổng cửa hàng', en: 'Total stores'), 'value': snapshot['storeCount']},
      {l.byLocale(vi: 'Hạng mục', en: 'Item'): l.byLocale(vi: 'Doanh thu thực', en: 'Actual revenue'), 'value': _currencyFormat.format(snapshot['revenue'])},
      {l.byLocale(vi: 'Hạng mục', en: 'Item'): l.byLocale(vi: 'Số lượng đơn hàng', en: 'Order count'), 'value': snapshot['orders']},
      {l.byLocale(vi: 'Hạng mục', en: 'Item'): l.byLocale(vi: 'Nguồn dữ liệu', en: 'Data source'), 'value': l.byLocale(vi: 'Hệ thống Quét thực tế', en: 'Scan system')},
    ];

    if (mounted) {
      await ExportService.exportToCsv(
        context: context,
        data: exportData,
        fileName: 'baocao_phantich_thuc_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );
    }
  }

  Widget _buildIndicator(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
