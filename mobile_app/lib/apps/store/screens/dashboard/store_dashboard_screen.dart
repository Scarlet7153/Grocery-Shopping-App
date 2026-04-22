import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../features/store/data/store_model.dart';
import '../../bloc/store_blocs.dart';
import '../../../../features/orders/data/order_model.dart';
import '../orders/store_order_detail_screen.dart';
import '../../utils/store_localizations.dart';
import '../../../../features/notification/presentation/widgets/notification_icon_button.dart';


class StoreDashboardScreen extends StatefulWidget {
  final VoidCallback? onViewAllOrders;

  const StoreDashboardScreen({super.key, this.onViewAllOrders});
  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StoreDashboardBloc>().add(LoadStoreDashboard());
    context.read<StoreOrdersBloc>().add(LoadStoreOrders());
  }

  void _toggleStoreStatus() {
    final state = context.read<StoreDashboardBloc>().state;
    if (state is StoreDashboardLoaded && state.store.id != null) {
      context
          .read<StoreDashboardBloc>()
          .add(ToggleStoreStatus(state.store.id!));
    }
  }

  double _calculateTodayRevenue(List<OrderModel> orders) {
    final now = DateTime.now();
    return orders.where((o) {
      if (o.status != 'DELIVERED' && o.status != 'COMPLETED') return false;
      if (o.createdAt == null) return false;
      final dt = DateTime.tryParse(o.createdAt!);
      if (dt == null) return false;
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    }).fold(0.0, (sum, o) => sum + (o.totalAmount ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.storeLoc;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
          title: Text(loc.tr('dashboard_title'),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: StoreTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: const [
            NotificationIconButton(color: Colors.white),
          ]),
      body: BlocBuilder<StoreDashboardBloc, StoreDashboardState>(
        builder: (context, state) {
          if (state is StoreDashboardLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is StoreDashboardError)
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<StoreDashboardBloc>()
                        .add(LoadStoreDashboard());
                  },
                  child: Text(loc.tr('retry')),
                ),
              ],
            ));
          if (state is StoreDashboardLoaded) {
            final store = state.store;
            return RefreshIndicator(
              onRefresh: () async {
                context.read<StoreDashboardBloc>().add(LoadStoreDashboard());
                context.read<StoreOrdersBloc>().add(LoadStoreOrders());
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StoreInfoCard(store: store, isUpdating: state.isStatusUpdating, onToggle: _toggleStoreStatus),
                    const SizedBox(height: 16),
                    BlocBuilder<StoreOrdersBloc, StoreOrdersState>(
                      builder: (ctx, orderState) {
                        final orders = orderState is StoreOrdersLoaded
                            ? orderState.orders
                            : <OrderModel>[];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RevenueCard(
                                revenue: _calculateTodayRevenue(orders),
                                loc: loc),
                            const SizedBox(height: 16),
                            _OrderStatsGrid(orders: orders, loc: loc),
                            const SizedBox(height: 16),
                            if (orders.isNotEmpty)
                              _RecentOrdersSection(
                                orders: orders.take(5).toList(),
                                loc: loc,
                                onViewAll: widget.onViewAllOrders,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _StoreInfoCard extends StatelessWidget {
  final StoreModel store;
  final bool isUpdating;
  final VoidCallback onToggle;
  const _StoreInfoCard({required this.store, required this.isUpdating, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final loc = context.storeLoc;
    final hasImage =
      store.imageUrl != null && store.imageUrl!.trim().isNotEmpty;
    final imageUrl = hasImage
      ? '${store.imageUrl}${store.imageUrl!.contains('?') ? '&' : '?'}t=${Uri.encodeComponent(store.updatedAt ?? DateTime.now().millisecondsSinceEpoch.toString())}'
      : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
          ]),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE8F5E9),
            child: ClipOval(
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.store,
                        color: StoreTheme.primaryColor,
                      ),
                    )
                  : const Icon(
                      Icons.store,
                      color: StoreTheme.primaryColor,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.storeName ?? loc.tr('store'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                if (store.address != null && store.address!.isNotEmpty)
                  Text(store.address!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: (store.isOpen ?? false)
                          ? StoreTheme.primaryColor.withValues(alpha: 0.1)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          store.isOpen == true
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 12,
                          color: store.isOpen == true
                              ? StoreTheme.primaryColor
                              : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                          store.isOpen == true
                              ? loc.tr('open_now')
                              : loc.tr('closed'),
                          style: TextStyle(
                              fontSize: 12,
                              color: store.isOpen == true
                                  ? StoreTheme.primaryColor
                                  : Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: (store.isOpen ?? false) ? loc.tr('open_now') : loc.tr('closed'),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashFactory: NoSplash.splashFactory,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
              ),
              child: Switch(
                value: store.isOpen == true,
                onChanged: isUpdating ? null : (_) => onToggle(),
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                splashRadius: 0,
                thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Icon(Icons.check, size: 14);
                  }
                  return const Icon(Icons.close, size: 14);
                }),
                activeThumbColor: StoreTheme.primaryColor,
                activeTrackColor: StoreTheme.primaryColor.withValues(alpha: 0.5),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade500,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final double revenue;
  final StoreLocalizations loc;
  const _RevenueCard({required this.revenue, required this.loc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              StoreTheme.primaryColor,
              StoreTheme.primaryColor.withValues(alpha: 0.8)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet,
              color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.tr('today_revenue'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              Text('${revenue.toStringAsFixed(0)}đ',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderStatsGrid extends StatelessWidget {
  final List<OrderModel> orders;
  final StoreLocalizations loc;
  const _OrderStatsGrid({required this.orders, required this.loc});

  @override
  Widget build(BuildContext context) {
    final pending = orders.where((o) => o.status == 'PENDING').length;
    final preparing = orders
        .where((o) => o.status == 'CONFIRMED' || o.status == 'PICKING_UP')
        .length;
    final delivering = orders.where((o) => o.status == 'DELIVERING').length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
            value: '${orders.length}',
            label: loc.tr('total_orders'),
            icon: Icons.shopping_bag,
            color: Colors.blue),
        _StatCard(
            value: '$pending',
            label: loc.tr('pending'),
            icon: Icons.schedule,
            color: Colors.orange),
        _StatCard(
            value: '$preparing',
            label: loc.tr('preparing'),
            icon: Icons.hourglass_top,
            color: Colors.purple),
        _StatCard(
            value: '$delivering',
            label: loc.tr('delivering'),
            icon: Icons.local_shipping,
            color: Colors.teal),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _RecentOrdersSection extends StatelessWidget {
  final List<OrderModel> orders;
  final StoreLocalizations loc;
  final VoidCallback? onViewAll;

  const _RecentOrdersSection({
    required this.orders,
    required this.loc,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(loc.tr('recent_orders'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: onViewAll,
              child: Text(loc.tr('view_all')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...orders.map((order) => _RecentOrderTile(order: order, loc: loc)),
      ],
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final OrderModel order;
  final StoreLocalizations loc;
  const _RecentOrderTile({required this.order, required this.loc});

  void _openOrderDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoreOrderDetailScreen(order: order)),
    );
  }

  Color _statusColor() {
    switch (order.status?.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
      case 'PICKING_UP':
        return Colors.blue;
      case 'DELIVERING':
        return Colors.purple;
      case 'DELIVERED':
        return StoreTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (order.status?.toUpperCase()) {
      case 'PENDING':
        return loc.tr('pending_status');
      case 'CONFIRMED':
        return loc.tr('confirmed_status');
      case 'PICKING_UP':
        return loc.tr('preparing_status');
      case 'DELIVERING':
        return loc.tr('delivering_status');
      case 'DELIVERED':
        return loc.tr('completed_status');
      default:
        return order.status ?? '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openOrderDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.receipt, color: _statusColor(), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(order.customerName ?? loc.tr('customer'),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${(order.totalAmount ?? 0).toStringAsFixed(0)}đ',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: StoreTheme.primaryColor)),
                Text(_statusLabel(),
                    style: TextStyle(fontSize: 10, color: _statusColor())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
