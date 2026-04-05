import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_shopping_app/core/ui/ui_constants.dart';
import '../../block/store_dashboard_bloc.dart';

import '../orders/store_orders_screen.dart';

/// Design system — Grab Merchant (#00B14F)
const Color _kPrimary = Color(0xFF00B14F);
const Color _kPrimaryLight = Color(0xFFE8F5E9);
const Color _kSurface = Color(0xFFF5F6FA);
const Color _kCardShadow = Color(0x0A000000);

const double _kTitleSize = 20;
const double _kLabelSize = 13;

class StoreDashboardScreen extends StatefulWidget {
  final String token;

  const StoreDashboardScreen({
    super.key,
    required this.token,
  });

  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StoreDashboardBloc>().add(LoadStoreDashboard(widget.token));
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
      body: BlocBuilder<StoreDashboardBloc, StoreDashboardState>(
        buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
        builder: (context, state) {
          final isLoading = state is StoreDashboardLoading;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: kPaddingLarge, vertical: kPaddingMedium).copyWith(bottom: isWide ? 48 : 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderSection(),
                    const SizedBox(height: kSectionSpacing),
                    if (isLoading) _SkeletonStatisticsRow(),
                    if (!isLoading) _StatisticsRow(),
                    const SizedBox(height: kCardPadding),
                    if (isLoading) _SkeletonExtraStatsRow(),
                    if (!isLoading) _ExtraStatsRow(),
                    const SizedBox(height: kSectionSpacing),
                    if (isLoading) _SkeletonRecentOrdersPreview(),
                    if (!isLoading) _RecentOrdersPreview(onViewAll: () => _push(context, const StoreOrdersScreen())),
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

  const _SkeletonBox({this.width, required this.height, this.borderRadius = kRadiusMedium});

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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: kCardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.6), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _SkeletonBox(width: 44, height: 44, borderRadius: kRadiusMedium),
          const SizedBox(height: 12),
          const _SkeletonBox(width: 56, height: 28),
          const SizedBox(height: 4),
          const _SkeletonBox(width: 72, height: 13),
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
            border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.6), width: 1),
          ),
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                Row(
                  children: [
                    const _SkeletonBox(width: 80, height: 14),
                    const SizedBox(width: 12),
                    const _SkeletonBox(width: 70, height: 14),
                    const Spacer(),
                    const _SkeletonBox(width: 90, height: 24),
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
          child: Padding(
            padding: const EdgeInsets.all(kCardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _SkeletonBox(width: 120, height: 13),
                const SizedBox(height: 8),
                const _SkeletonBox(width: 160, height: 32),
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
            border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.6), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SkeletonBox(width: 160, height: 16),
              const SizedBox(height: kSectionSpacing),
              const _SkeletonBox(width: double.infinity, height: 180),
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
            border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.6), width: 1),
          ),
          child: Column(
            children: List.generate(5, (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const _SkeletonBox(width: 28, height: 28, borderRadius: kRadiusSmall),
                  const SizedBox(width: 14),
                  const Expanded(child: _SkeletonBox(height: 14)),
                  _SkeletonBox(width: 70, height: 13),
                ],
              ),
            )),
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
            border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.6), width: 1),
          ),
          child: Column(
            children: List.generate(5, (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const _SkeletonBox(width: 40, height: 40, borderRadius: kRadiusSmall),
                  const SizedBox(width: 14),
                  const Expanded(child: _SkeletonBox(height: 14)),
                  _SkeletonBox(width: 60, height: 12),
                ],
              ),
            )),
          ),
        ),
      ],
    );
  }
}

/// Header: compact — avatar, store name, status badge
class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          CircleAvatar(
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
                const Text(
                  'Siêu Thị Mini B',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kPrimary.withValues(alpha: 0.4), width: 1),
                  ),
                  child: const Text(
                    'Đang mở',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
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
            boxShadow: [
              BoxShadow(color: _kCardShadow, blurRadius: 8, offset: const Offset(0, 3)),
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
              const Text(
                '2.500.000đ',
                style: TextStyle(
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
        _RevenueChartSection(),
      ],
    );
  }
}

/// Biểu đồ doanh thu tuần — gradient, bo góc, hover + tooltip (web), highlight hôm nay (CN)
const List<double> _kWeeklyRevenue = [1.2, 1.8, 1.5, 2.0, 2.2, 2.5, 2.0];
const List<String> _kWeekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
int get _kTodayIndex => 6; // CN = Chủ nhật

class _RevenueChartSection extends StatefulWidget {
  @override
  State<_RevenueChartSection> createState() => _RevenueChartSectionState();
}

class _RevenueChartSectionState extends State<_RevenueChartSection> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    final maxVal = _kWeeklyRevenue.reduce((a, b) => a > b ? a : b);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.6), width: 1),
        boxShadow: [BoxShadow(color: _kCardShadow, blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doanh thu tuần này',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: kSectionSpacing),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final h = (_kWeeklyRevenue[i] / maxVal) * 120.0;
                final barHeight = h.clamp(24.0, 120.0);
                final isHovered = _hoveredIndex == i;
                final isToday = i == _kTodayIndex;
                final amount = '${(_kWeeklyRevenue[i] * 1000).round()}k';
                Widget bar = AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: barHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: isToday
                          ? [_kPrimary, const Color(0xFF008C39)]
                          : [_kPrimary.withValues(alpha: 0.85), _kPrimary.withValues(alpha: 0.5)],
                    ),
                    borderRadius: BorderRadius.circular(kRadiusMedium),
                    border: isToday ? Border.all(color: Colors.white, width: 2) : null,
                    boxShadow: isHovered
                        ? [BoxShadow(color: _kPrimary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 2))]
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(kRadiusSmall),
                              ),
                              child: Text(
                                '$amountđ',
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
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday ? _kPrimary : (isHovered && kIsWeb ? _kPrimary : Colors.grey.shade700),
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
        if (isNarrow) {
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: kCardPadding,
            crossAxisSpacing: kCardPadding,
            childAspectRatio: 1.6,
            children: const [
              _StatCard(value: '50', label: 'Tổng sản phẩm', icon: Icons.inventory_2_rounded),
              _StatCard(value: '45tr', label: 'Doanh thu tháng', icon: Icons.trending_up_rounded),
              _StatCard(value: '3', label: 'Đơn bị hủy', icon: Icons.cancel_rounded),
            ],
          );
        }
        return Row(
          children: [
            const Expanded(child: _StatCard(value: '50', label: 'Tổng sản phẩm', icon: Icons.inventory_2_rounded)),
            const SizedBox(width: kCardPadding),
            const Expanded(child: _StatCard(value: '45.000.000đ', label: 'Doanh thu tháng', icon: Icons.trending_up_rounded)),
            const SizedBox(width: kCardPadding),
            const Expanded(child: _StatCard(value: '3', label: 'Đơn bị hủy', icon: Icons.cancel_rounded)),
          ],
        );
      },
    );
  }
}

class _StatisticsRow extends StatelessWidget {
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
            children: const [
              _StatCard(value: '18', label: 'Đơn hôm nay', icon: Icons.shopping_bag_rounded),
              _StatCard(value: '4', label: 'Đang chuẩn bị', icon: Icons.hourglass_top_rounded),
              _StatCard(value: '2', label: 'Đang giao', icon: Icons.local_shipping_rounded),
              _StatCard(value: '14', label: 'Hoàn thành', icon: Icons.check_circle_rounded),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _StatCard(value: '18', label: 'Đơn hôm nay', icon: Icons.shopping_bag_rounded)),
            const SizedBox(width: kCardPadding),
            Expanded(child: _StatCard(value: '4', label: 'Đang chuẩn bị', icon: Icons.hourglass_top_rounded)),
            const SizedBox(width: kCardPadding),
            Expanded(child: _StatCard(value: '2', label: 'Đang giao', icon: Icons.local_shipping_rounded)),
            const SizedBox(width: kCardPadding),
            Expanded(child: _StatCard(value: '14', label: 'Hoàn thành', icon: Icons.check_circle_rounded)),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatefulWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({required this.value, required this.label, required this.icon});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: kCardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(
          color: _hover ? _kPrimary.withValues(alpha: 0.35) : Colors.grey.shade200.withValues(alpha: 0.6),
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
        _SectionTitle(title: 'Sản phẩm bán chạy hôm nay'),
        const SizedBox(height: kCardPadding),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(kCardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusLarge),
            border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.6), width: 1),
            boxShadow: [BoxShadow(color: _kCardShadow, blurRadius: 8, offset: const Offset(0, 3))],
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
                          color: i < 3 ? _kPrimary.withValues(alpha: 0.15) : Colors.grey.shade100,
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
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
                        ),
                      ),
                      Text(
                        '${_kTopSellingToday[i].sold} đã bán',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
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
  (icon: 'product', text: 'Sản phẩm "Chuối" được cập nhật', time: '25 phút trước'),
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
        _SectionTitle(title: 'Hoạt động gần đây'),
        const SizedBox(height: kCardPadding),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(kCardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusLarge),
            border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.6), width: 1),
            boxShadow: [BoxShadow(color: _kCardShadow, blurRadius: 8, offset: const Offset(0, 3))],
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
                          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                        ),
                      ),
                      Text(
                        _kRecentActivity[i].time,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

/// Đơn gần đây — compact preview (3 đơn + nút Xem tất cả)
class _RecentOrdersPreview extends StatelessWidget {
  final VoidCallback onViewAll;

  const _RecentOrdersPreview({required this.onViewAll});

  static const _recentOrders = [
    (id: '#1234', amount: '150.000đ', status: 'Đang chuẩn bị', statusType: OrderStatus.processing),
    (id: '#1235', amount: '80.000đ', status: 'Đang giao', statusType: OrderStatus.shipping),
    (id: '#1236', amount: '120.000đ', status: 'Hoàn thành', statusType: OrderStatus.done),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Đơn gần đây'),
        const SizedBox(height: kCardPadding),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(kCardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusLarge),
            border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.6), width: 1),
            boxShadow: [BoxShadow(color: _kCardShadow, blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              ..._recentOrders.map((o) => _RecentOrderRow(
                    id: o.id,
                    amount: o.amount,
                    status: o.status,
                    statusType: o.statusType,
                  )),
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
                      Text('Xem tất cả', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum OrderStatus { processing, shipping, done }

class _RecentOrderRow extends StatefulWidget {
  final String id;
  final String amount;
  final String status;
  final OrderStatus statusType;

  const _RecentOrderRow({
    required this.id,
    required this.amount,
    required this.status,
    required this.statusType,
  });

  @override
  State<_RecentOrderRow> createState() => _RecentOrderRowState();
}

class _RecentOrderRowState extends State<_RecentOrderRow> {
  bool _hover = false;

  Color get _statusColor {
    switch (widget.statusType) {
      case OrderStatus.processing:
        return const Color(0xFFF57C00);
      case OrderStatus.shipping:
        return const Color(0xFF1976D2);
      case OrderStatus.done:
        return _kPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Text('Đơn ${widget.id}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          const SizedBox(width: 12),
          Text(widget.amount, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(widget.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor)),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade500),
        ],
      ),
    );
    row = Material(
      color: _hover ? _kPrimaryLight.withValues(alpha: 0.4) : Colors.transparent,
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
