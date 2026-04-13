import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_shopping_app/core/ui/ui_constants.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:intl/intl.dart';
import '../../block/store_dashboard_bloc.dart';
import '../../block/store_orders_bloc.dart';
import '../../block/store_products_bloc.dart';
import '../../store_order_status.dart';

import '../orders/store_orders_screen.dart';

String _dashboardOrderAmountText(double? v) {
  if (v == null) return '0đ';
  return '${NumberFormat('#,###', 'vi').format(v.round())}đ';
}

String _dashboardOrderStatusVi(String? status) {
  switch ((status ?? '').toUpperCase()) {
    case 'PENDING':
      return 'Chờ xác nhận';
    case 'CONFIRMED':
    case 'PICKING_UP':
      return 'Đang chuẩn bị';
    case 'DELIVERING':
      return 'Đang giao';
    case 'DELIVERED':
      return 'Hoàn thành';
    case 'CANCELLED':
      return 'Đã hủy';
    default:
      return status ?? '—';
  }
}

_DashboardRecentOrderKind _dashboardOrderKind(String? status) {
  switch ((status ?? '').toUpperCase()) {
    case 'DELIVERED':
      return _DashboardRecentOrderKind.done;
    case 'DELIVERING':
      return _DashboardRecentOrderKind.shipping;
    case 'CANCELLED':
      return _DashboardRecentOrderKind.cancelled;
    default:
      return _DashboardRecentOrderKind.processing;
  }
}

double _dashboardOrderMoney(OrderModel o) {
  if (o.grandTotal != null) return o.grandTotal!;
  return (o.totalAmount ?? 0) + (o.shippingFee ?? 0);
}

DateTime? _dashboardParseCreatedAt(OrderModel o) =>
    DateTime.tryParse(o.createdAt ?? '');

bool _dashboardSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int _dashboardCountTodayOrders(List<OrderModel> orders) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var c = 0;
  for (final o in orders) {
    final d = _dashboardParseCreatedAt(o);
    if (d == null) continue;
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) c++;
  }
  return c;
}

int _dashboardCountPreparing(List<OrderModel> orders) => orders
    .where((o) => storeOrderStatusIsPreparing(o.status))
    .length;

int _dashboardCountDelivering(List<OrderModel> orders) =>
    orders.where((o) => (o.status ?? '').toUpperCase() == 'DELIVERING').length;

int _dashboardCountDelivered(List<OrderModel> orders) =>
    orders.where((o) => (o.status ?? '').toUpperCase() == 'DELIVERED').length;

double _dashboardMonthRevenueDelivered(List<OrderModel> orders) {
  final now = DateTime.now();
  var sum = 0.0;
  for (final o in orders) {
    if ((o.status ?? '').toUpperCase() != 'DELIVERED') continue;
    final d = _dashboardParseCreatedAt(o);
    if (d == null) continue;
    if (d.year != now.year || d.month != now.month) continue;
    sum += _dashboardOrderMoney(o);
  }
  return sum;
}

int _dashboardCountCancelled(List<OrderModel> orders) => orders
    .where((o) => (o.status ?? '').toUpperCase() == 'CANCELLED')
    .length;

double _dashboardTodayRevenueDelivered(List<OrderModel> orders) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var sum = 0.0;
  for (final o in orders) {
    if ((o.status ?? '').toUpperCase() != 'DELIVERED') continue;
    final d = _dashboardParseCreatedAt(o);
    if (d == null) continue;
    final day = DateTime(d.year, d.month, d.day);
    if (day != today) continue;
    sum += _dashboardOrderMoney(o);
  }
  return sum;
}

/// Tuần T2–CN hiện tại; mỗi cột là tổng DELIVERED theo ngày đặt (createdAt).
List<double> _dashboardWeekDailyRevenueVnd(
  List<OrderModel> orders,
  DateTime now,
) {
  final weekday = now.weekday;
  final monday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: weekday - 1));
  final daily = List<double>.filled(7, 0);
  for (final o in orders) {
    if ((o.status ?? '').toUpperCase() != 'DELIVERED') continue;
    final d = _dashboardParseCreatedAt(o);
    if (d == null) continue;
    final dayOnly = DateTime(d.year, d.month, d.day);
    for (var i = 0; i < 7; i++) {
      final slot = monday.add(Duration(days: i));
      if (_dashboardSameCalendarDay(dayOnly, slot)) {
        daily[i] += _dashboardOrderMoney(o);
        break;
      }
    }
  }
  return daily;
}

String _dashboardOrdersStatOrDash(
  StoreOrdersState s,
  int Function(List<OrderModel>) compute,
) {
  if (s is StoreOrdersLoading || s is StoreOrdersInitial) return '—';
  if (s is StoreOrdersError) return '!';
  if (s is StoreOrdersLoaded) return '${compute(s.orders)}';
  return '—';
}

String _dashboardMonthRevenueText(StoreOrdersState s) {
  if (s is StoreOrdersLoading || s is StoreOrdersInitial) return '—';
  if (s is StoreOrdersError) return '!';
  if (s is StoreOrdersLoaded) {
    return _dashboardOrderAmountText(
      _dashboardMonthRevenueDelivered(s.orders),
    );
  }
  return '—';
}

String _dashboardCancelledText(StoreOrdersState s) {
  if (s is StoreOrdersLoading || s is StoreOrdersInitial) return '—';
  if (s is StoreOrdersError) return '!';
  if (s is StoreOrdersLoaded) {
    return '${_dashboardCountCancelled(s.orders)}';
  }
  return '—';
}

enum _DashboardRecentOrderKind { processing, shipping, done, cancelled }

/// Design system — Grab Merchant (#00B14F)
const Color _kPrimary = Color(0xFF00B14F);
const Color _kPrimaryLight = Color(0xFFE8F5E9);
const Color _kSurface = Color(0xFFF5F6FA);
const Color _kCardShadow = Color(0x0A000000);

const double _kTitleSize = 20;
const double _kLabelSize = 13;

class StoreDashboardScreen extends StatefulWidget {
  final String token;
  final ValueNotifier<int>? overviewRefresh;

  const StoreDashboardScreen({
    super.key,
    required this.token,
    this.overviewRefresh,
  });

  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen> {
  Map<String, dynamic>? _cachedHeaderStore;

  @override
  void initState() {
    super.initState();
    widget.overviewRefresh?.addListener(_onOverviewRefreshSignal);
    context.read<StoreDashboardBloc>().add(LoadStoreDashboard(widget.token));
  }

  @override
  void dispose() {
    widget.overviewRefresh?.removeListener(_onOverviewRefreshSignal);
    super.dispose();
  }

  void _onOverviewRefreshSignal() {
    if (!mounted) return;
    context.read<StoreDashboardBloc>().add(LoadStoreDashboard(widget.token));
    context.read<StoreProductsBloc>().add(LoadStoreProducts(token: widget.token));
    context.read<StoreOrdersBloc>().add(LoadStoreOrders());
  }

  Map<String, dynamic>? _headerStoreMap(StoreDashboardState state) {
    if (state is StoreDashboardLoaded) return state.store;
    if (state is StoreDashboardError) return null;
    return _cachedHeaderStore;
  }

  String _statusLabelFromStore(Map<String, dynamic>? m) {
    if (m == null) return '—';
    final v = m['isOpen'];
    if (v == true) return 'Đang mở';
    if (v == false) return 'Đang đóng';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width > 600;
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: Text(
          'Tổng quan',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: _kTitleSize,
            color: Colors.white,
          ),
        ),
        backgroundColor: _kPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 52,
      ),
      body: BlocConsumer<StoreDashboardBloc, StoreDashboardState>(
        listenWhen: (prev, curr) =>
            curr is StoreDashboardLoaded || curr is StoreDashboardError,
        listener: (context, state) {
          if (state is StoreDashboardLoaded) {
            setState(() => _cachedHeaderStore = state.store);
          } else if (state is StoreDashboardError) {
            setState(() => _cachedHeaderStore = null);
          }
        },
        buildWhen: (prev, curr) => prev != curr,
        builder: (context, state) {
          final isLoading = state is StoreDashboardLoading;
          final dashboardErr =
              state is StoreDashboardError ? state.message : null;
          final hm = _headerStoreMap(state);
          final headerName = hm?['storeName']?.toString() ?? '—';
          final headerStatus = _statusLabelFromStore(hm);
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: kPaddingLarge,
              vertical: kPaddingMedium,
            ).copyWith(bottom: isWide ? 48 : 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderSection(
                      storeName: headerName,
                      statusLabel: headerStatus,
                    ),
                    if (dashboardErr != null) ...[
                      const SizedBox(height: kCardPadding),
                      Text(
                        dashboardErr,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context
                            .read<StoreDashboardBloc>()
                            .add(LoadStoreDashboard(widget.token)),
                        child: const Text('Thử lại'),
                      ),
                    ],
                    const SizedBox(height: kSectionSpacing),
                    if (isLoading) _SkeletonStatisticsRow(),
                    if (!isLoading) _StatisticsRow(),
                    const SizedBox(height: kCardPadding),
                    if (isLoading) _SkeletonExtraStatsRow(),
                    if (!isLoading) _ExtraStatsRow(),
                    const SizedBox(height: kSectionSpacing),
                    if (isLoading) _SkeletonRecentOrdersPreview(),
                    if (!isLoading)
                      _RecentOrdersPreview(
                        onViewAll: () =>
                            _push(context, const StoreOrdersScreen()),
                      ),
                    const SizedBox(height: kSectionSpacing),
                    if (isLoading) _SkeletonRevenueSection(),
                    if (!isLoading) _RevenueSection(),
                    if (isLoading) const SizedBox(height: kSectionSpacing),
                    if (!isLoading) const SizedBox(height: kSectionSpacing),
                    if (isLoading) _SkeletonTopSellingSection(),
                    if (!isLoading) _TopSellingSection(),
                    if (isLoading) const SizedBox(height: kSectionSpacing),
                    if (!isLoading) const SizedBox(height: kSectionSpacing),
                    if (isLoading) _SkeletonRecentActivitySection(),
                    if (!isLoading) _RecentActivitySection(),
                    const SizedBox(height: kSectionSpacing),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

/// Lightweight skeleton placeholder (static grey box, no animation).
const Color _kSkeletonColor = Color(0xFFE8E8E8);

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    this.width,
    required this.height,
    this.borderRadius = kRadiusMedium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _kSkeletonColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _SkeletonStatisticsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        if (isNarrow) {
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: kCardPadding,
            crossAxisSpacing: kCardPadding,
            childAspectRatio: 1.4,
            children: List.generate(4, (_) => _SkeletonStatCard()),
          );
        }
        return Row(
          children: [
            Expanded(child: _SkeletonStatCard()),
            const SizedBox(width: kCardPadding),
            Expanded(child: _SkeletonStatCard()),
            const SizedBox(width: kCardPadding),
            Expanded(child: _SkeletonStatCard()),
            const SizedBox(width: kCardPadding),
            Expanded(child: _SkeletonStatCard()),
          ],
        );
      },
    );
  }
}

class _SkeletonStatCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: kCardPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(
          color: Colors.grey.shade200.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SkeletonBox(width: 44, height: 44, borderRadius: kRadiusMedium),
          SizedBox(height: 12),
          _SkeletonBox(width: 56, height: 28),
          SizedBox(height: 4),
          _SkeletonBox(width: 72, height: 13),
        ],
      ),
    );
  }
}

class _SkeletonExtraStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        if (isNarrow) {
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: kCardPadding,
            crossAxisSpacing: kCardPadding,
            childAspectRatio: 1.6,
            children: List.generate(3, (_) => _SkeletonStatCard()),
          );
        }
        return Row(
          children: [
            Expanded(child: _SkeletonStatCard()),
            const SizedBox(width: kCardPadding),
            Expanded(child: _SkeletonStatCard()),
            const SizedBox(width: kCardPadding),
            Expanded(child: _SkeletonStatCard()),
          ],
        );
      },
    );
  }
}

class _SkeletonRecentOrdersPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SkeletonBox(width: 140, height: 16),
        const SizedBox(height: kCardPadding),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(kCardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusLarge),
            border: Border.all(
              color: Colors.grey.shade200.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                const Row(
                  children: [
                    _SkeletonBox(width: 80, height: 14),
                    SizedBox(width: 12),
                    _SkeletonBox(width: 70, height: 14),
                    Spacer(),
                    _SkeletonBox(width: 90, height: 24),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const _SkeletonBox(width: double.infinity, height: 40),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonRevenueSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: _kSkeletonColor,
            borderRadius: BorderRadius.circular(kRadiusLarge),
          ),
          child: const Padding(
            padding: EdgeInsets.all(kCardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SkeletonBox(width: 120, height: 13),
                SizedBox(height: 8),
                _SkeletonBox(width: 160, height: 32),
              ],
            ),
          ),
        ),
        const SizedBox(height: kCardPadding),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(kCardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusLarge),
            border: Border.all(
              color: Colors.grey.shade200.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: 160, height: 16),
              SizedBox(height: kSectionSpacing),
              _SkeletonBox(width: double.infinity, height: 180),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonTopSellingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SkeletonBox(width: 220, height: 16),
        const SizedBox(height: kCardPadding),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(kCardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusLarge),
            border: Border.all(
              color: Colors.grey.shade200.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Column(
            children: List.generate(
              5,
              (i) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    _SkeletonBox(
                      width: 28,
                      height: 28,
                      borderRadius: kRadiusSmall,
                    ),
                    SizedBox(width: 14),
                    Expanded(child: _SkeletonBox(height: 14)),
                    _SkeletonBox(width: 70, height: 13),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonRecentActivitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SkeletonBox(width: 160, height: 16),
        const SizedBox(height: kCardPadding),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(kCardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusLarge),
            border: Border.all(
              color: Colors.grey.shade200.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Column(
            children: List.generate(
              5,
              (i) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    _SkeletonBox(
                      width: 40,
                      height: 40,
                      borderRadius: kRadiusSmall,
                    ),
                    SizedBox(width: 14),
                    Expanded(child: _SkeletonBox(height: 14)),
                    _SkeletonBox(width: 60, height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Header: compact — avatar, store name, status badge
class _HeaderSection extends StatelessWidget {
  final String storeName;
  final String statusLabel;

  const _HeaderSection({
    required this.storeName,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(Icons.store_rounded, color: _kPrimary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  storeName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _kPrimary.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Revenue: Doanh thu hôm nay (big number) + Doanh thu tuần này (chart)
class _RevenueSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreOrdersBloc, StoreOrdersState>(
      builder: (context, orderState) {
        final now = DateTime.now();
        String todayText;
        List<double> weekDaily;
        final todayIdx = now.weekday - 1;
        if (orderState is StoreOrdersLoaded) {
          todayText = _dashboardOrderAmountText(
            _dashboardTodayRevenueDelivered(orderState.orders),
          );
          weekDaily = _dashboardWeekDailyRevenueVnd(orderState.orders, now);
        } else if (orderState is StoreOrdersError) {
          todayText = '!';
          weekDaily = List<double>.filled(7, 0);
        } else {
          todayText = '—';
          weekDaily = List<double>.filled(7, 0);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(kCardPadding),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kPrimary, Color(0xFF008C39)],
                ),
                borderRadius: BorderRadius.circular(kRadiusLarge),
                boxShadow: const [
                  BoxShadow(
                    color: _kCardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doanh thu hôm nay',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: _kLabelSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    todayText,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: kCardPadding),
            _RevenueChartSection(
              dailyTotalsVnd: weekDaily,
              todayIndex: todayIdx,
            ),
          ],
        );
      },
    );
  }
}

const List<String> _kWeekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

class _RevenueChartSection extends StatefulWidget {
  final List<double> dailyTotalsVnd;
  final int todayIndex;

  const _RevenueChartSection({
    required this.dailyTotalsVnd,
    required this.todayIndex,
  });

  @override
  State<_RevenueChartSection> createState() => _RevenueChartSectionState();
}

class _RevenueChartSectionState extends State<_RevenueChartSection> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    final totals = widget.dailyTotalsVnd;
    final maxVal = totals.isEmpty
        ? 1.0
        : totals.reduce((a, b) => a > b ? a : b);
    final scale = maxVal > 0 ? maxVal : 1.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(
          color: Colors.grey.shade200.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(color: _kCardShadow, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu tuần này',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: kSectionSpacing),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final raw = i < totals.length ? totals[i] : 0.0;
                final h = (raw / scale) * 120.0;
                final barHeight = h.clamp(24.0, 120.0);
                final isHovered = _hoveredIndex == i;
                final isToday = i == widget.todayIndex;
                final amount =
                    '${NumberFormat('#,###', 'vi').format(raw.round())}đ';
                Widget bar = AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: barHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: isToday
                          ? [_kPrimary, const Color(0xFF008C39)]
                          : [
                              _kPrimary.withValues(alpha: 0.85),
                              _kPrimary.withValues(alpha: 0.5),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(kRadiusMedium),
                    border: isToday
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: isHovered
                        ? [
                            BoxShadow(
                              color: _kPrimary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                );
                if (kIsWeb) {
                  bar = MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = i),
                    onExit: (_) => setState(() => _hoveredIndex = -1),
                    child: AnimatedScale(
                      scale: isHovered ? 1.04 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      alignment: Alignment.bottomCenter,
                      child: bar,
                    ),
                  );
                }
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isHovered && kIsWeb)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(
                                  kRadiusSmall,
                                ),
                              ),
                              child: Text(
                                amount,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        bar,
                        const SizedBox(height: 10),
                        Text(
                          _kWeekDays[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isToday
                                ? _kPrimary
                                : (isHovered && kIsWeb
                                      ? _kPrimary
                                      : Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ thống kê bổ sung: Tổng sản phẩm, Doanh thu tháng, Đơn bị hủy
class _ExtraStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        final productCountCard = BlocBuilder<StoreProductsBloc, StoreProductsState>(
          buildWhen: (a, b) =>
              a.runtimeType != b.runtimeType ||
              (a is StoreProductsLoaded &&
                  b is StoreProductsLoaded &&
                  a.products.length != b.products.length),
          builder: (context, state) {
            final v = state is StoreProductsLoaded
                ? '${state.products.length}'
                : '—';
            return _StatCard(
              value: v,
              label: 'Tổng sản phẩm',
              icon: Icons.inventory_2_rounded,
            );
          },
        );
        final revenueCard = BlocBuilder<StoreOrdersBloc, StoreOrdersState>(
          builder: (context, orderState) => _StatCard(
            value: _dashboardMonthRevenueText(orderState),
            label: 'Doanh thu tháng',
            icon: Icons.trending_up_rounded,
          ),
        );
        final cancelledCard = BlocBuilder<StoreOrdersBloc, StoreOrdersState>(
          builder: (context, orderState) => _StatCard(
            value: _dashboardCancelledText(orderState),
            label: 'Đơn bị hủy',
            icon: Icons.cancel_rounded,
          ),
        );
        if (isNarrow) {
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: kCardPadding,
            crossAxisSpacing: kCardPadding,
            childAspectRatio: 1.6,
            children: [
              productCountCard,
              revenueCard,
              cancelledCard,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: productCountCard),
            const SizedBox(width: kCardPadding),
            Expanded(child: revenueCard),
            const SizedBox(width: kCardPadding),
            Expanded(child: cancelledCard),
          ],
        );
      },
    );
  }
}

class _StatisticsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreOrdersBloc, StoreOrdersState>(
      builder: (context, orderState) {
        final vToday = _dashboardOrdersStatOrDash(
          orderState,
          _dashboardCountTodayOrders,
        );
        final vPrep = _dashboardOrdersStatOrDash(
          orderState,
          _dashboardCountPreparing,
        );
        final vShip = _dashboardOrdersStatOrDash(
          orderState,
          _dashboardCountDelivering,
        );
        final vDone = _dashboardOrdersStatOrDash(
          orderState,
          _dashboardCountDelivered,
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 500;
            if (isNarrow) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: kCardPadding,
                crossAxisSpacing: kCardPadding,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(
                    value: vToday,
                    label: 'Đơn hôm nay',
                    icon: Icons.shopping_bag_rounded,
                  ),
                  _StatCard(
                    value: vPrep,
                    label: 'Đang chuẩn bị',
                    icon: Icons.hourglass_top_rounded,
                  ),
                  _StatCard(
                    value: vShip,
                    label: 'Đang giao',
                    icon: Icons.local_shipping_rounded,
                  ),
                  _StatCard(
                    value: vDone,
                    label: 'Hoàn thành',
                    icon: Icons.check_circle_rounded,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: vToday,
                    label: 'Đơn hôm nay',
                    icon: Icons.shopping_bag_rounded,
                  ),
                ),
                const SizedBox(width: kCardPadding),
                Expanded(
                  child: _StatCard(
                    value: vPrep,
                    label: 'Đang chuẩn bị',
                    icon: Icons.hourglass_top_rounded,
                  ),
                ),
                const SizedBox(width: kCardPadding),
                Expanded(
                  child: _StatCard(
                    value: vShip,
                    label: 'Đang giao',
                    icon: Icons.local_shipping_rounded,
                  ),
                ),
                const SizedBox(width: kCardPadding),
                Expanded(
                  child: _StatCard(
                    value: vDone,
                    label: 'Hoàn thành',
                    icon: Icons.check_circle_rounded,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatefulWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: kCardPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(
          color: _hover
              ? _kPrimary.withValues(alpha: 0.35)
              : Colors.grey.shade200.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _kCardShadow,
            blurRadius: _hover ? kCardShadowBlur : 8,
            offset: Offset(0, _hover ? kCardShadowOffset : 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: _hover ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPrimaryLight,
                borderRadius: BorderRadius.circular(kRadiusMedium),
              ),
              child: Icon(widget.icon, color: _kPrimary, size: kIconSizeMedium),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _kPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _kLabelSize,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
    if (kIsWeb) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: card,
      );
    }
    return card;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
        letterSpacing: -0.2,
      ),
    );
  }
}

/// Top selling products today — demo list (chỉ UI)
const List<({String name, int sold})> _kTopSellingToday = [
  (name: 'Nước suối', sold: 45),
  (name: 'Mì gói', sold: 35),
  (name: 'Rau muống', sold: 30),
  (name: 'Chuối', sold: 28),
  (name: 'Rau cải', sold: 25),
];

class _TopSellingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Sản phẩm bán chạy hôm nay'),
        const SizedBox(height: kCardPadding),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(kCardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusLarge),
            border: Border.all(
              color: Colors.grey.shade200.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: _kCardShadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < _kTopSellingToday.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                if (i > 0) const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i < 3
                              ? _kPrimary.withValues(alpha: 0.15)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(kRadiusSmall),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: i < 3 ? _kPrimary : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _kTopSellingToday[i].name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Text(
                        '${_kTopSellingToday[i].sold} đã bán',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Hoạt động gần đây — 📦 đơn, 🛒 sản phẩm, 💬 tin nhắn
const List<({String icon, String text, String time})> _kRecentActivity = [
  (icon: 'order', text: 'Đơn #1241 đã được chấp nhận', time: '5 phút trước'),
  (
    icon: 'product',
    text: 'Sản phẩm "Chuối" được cập nhật',
    time: '25 phút trước',
  ),
  (icon: 'chat', text: 'Khách hàng gửi tin nhắn', time: '1 giờ trước'),
  (icon: 'order', text: 'Đơn #1235 đang giao', time: '2 giờ trước'),
  (icon: 'product', text: 'Sản phẩm "Mì gói" thêm mới', time: '3 giờ trước'),
];

class _RecentActivitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Hoạt động gần đây'),
        const SizedBox(height: kCardPadding),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(kCardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusLarge),
            border: Border.all(
              color: Colors.grey.shade200.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: _kCardShadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < _kRecentActivity.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                if (i > 0) const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _kPrimaryLight,
                          borderRadius: BorderRadius.circular(kRadiusSmall),
                        ),
                        child: Text(
                          _kRecentActivity[i].icon == 'order'
                              ? '📦'
                              : _kRecentActivity[i].icon == 'chat'
                              ? '💬'
                              : '🛒',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _kRecentActivity[i].text,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Text(
                        _kRecentActivity[i].time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Đơn gần đây — compact preview (tối đa 3 đơn từ API + nút Xem tất cả)
class _RecentOrdersPreview extends StatelessWidget {
  final VoidCallback onViewAll;

  const _RecentOrdersPreview({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Đơn gần đây'),
        const SizedBox(height: kCardPadding),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(kCardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusLarge),
            border: Border.all(
              color: Colors.grey.shade200.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: _kCardShadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: BlocBuilder<StoreOrdersBloc, StoreOrdersState>(
            builder: (context, state) {
              if (state is StoreOrdersLoading ||
                  state is StoreOrdersInitial) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Đang tải đơn hàng…',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                );
              }
              if (state is StoreOrdersError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Không tải được danh sách đơn hàng: ${state.message}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                );
              }
              if (state is! StoreOrdersLoaded) {
                return const SizedBox.shrink();
              }
              final orders = state.orders;
              if (orders.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Chưa có đơn hàng nào',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                );
              }
              final preview = orders.take(3).toList();
              return Column(
                children: [
                  ...preview.map(
                    (OrderModel o) => _RecentOrderRow(
                      id: '#${o.id}',
                      amount: _dashboardOrderAmountText(o.grandTotal),
                      status: _dashboardOrderStatusVi(o.status),
                      statusKind: _dashboardOrderKind(o.status),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onViewAll,
                      style: TextButton.styleFrom(
                        foregroundColor: _kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem tất cả',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentOrderRow extends StatefulWidget {
  final String id;
  final String amount;
  final String status;
  final _DashboardRecentOrderKind statusKind;

  const _RecentOrderRow({
    required this.id,
    required this.amount,
    required this.status,
    required this.statusKind,
  });

  @override
  State<_RecentOrderRow> createState() => _RecentOrderRowState();
}

class _RecentOrderRowState extends State<_RecentOrderRow> {
  bool _hover = false;

  Color get _statusColor {
    switch (widget.statusKind) {
      case _DashboardRecentOrderKind.processing:
        return const Color(0xFFF57C00);
      case _DashboardRecentOrderKind.shipping:
        return const Color(0xFF1976D2);
      case _DashboardRecentOrderKind.done:
        return _kPrimary;
      case _DashboardRecentOrderKind.cancelled:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Text(
            'Đơn ${widget.id}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.amount,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Colors.grey.shade500,
          ),
        ],
      ),
    );
    row = Material(
      color: _hover
          ? _kPrimaryLight.withValues(alpha: 0.4)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: row,
    );
    if (kIsWeb) {
      row = MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: row,
      );
    }
    return row;
  }
}
