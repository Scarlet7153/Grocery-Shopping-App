import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';
import 'package:grocery_shopping_app/apps/shipper/bloc/shipper_dashboard_bloc.dart';
import 'package:grocery_shopping_app/apps/shipper/models/shipper_order.dart';
import 'package:grocery_shopping_app/apps/shipper/repository/shipper_repository.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/dashboard/widgets/available_orders.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/dashboard/widgets/dashboard_stats.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/dashboard/widgets/online_toggle.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/profile/shipper_profile_screen.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/delivery/delivery_flow_screen.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/delivery/order_map_screen.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/order_detail/order_detail_screen.dart';
import 'package:grocery_shopping_app/apps/shipper/services/shipper_realtime_stomp_service.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/chat/shipper_chat_list_screen.dart';
import 'package:grocery_shopping_app/core/widgets/chat_badge_icon.dart';
import 'package:grocery_shopping_app/features/notification/presentation/widgets/notification_icon_button.dart';
import 'package:grocery_shopping_app/features/notification/bloc/notification_bloc.dart';
import 'package:grocery_shopping_app/features/notification/data/notification_model.dart';

/// A tiny fake repository that returns sample data immediately. Used by the
/// preview constructor so we can open the dashboard without a backend/token.
class _PreviewRepo extends ShipperRepository {
  _PreviewRepo() : super(dio: null);

  @override
  Future<Map<String, dynamic>> fetchDashboardData() async {
    final sampleOrders = [
      ShipperOrder(
        id: 101,
        customerId: 1,
        customerName: 'Nguyen Van A',
        customerPhone: '0901234567',
        storeId: 1,
        storeName: 'Bách Hóa Xanh',
        storeAddress: '456 Lê Lợi, Quận 1, TP.HCM',
        deliveryAddress: '123 Đường Nguyễn Trãi, Quận 1, TP.HCM',
        status: OrderStatus.CONFIRMED,
        totalAmount: 30000,
        shippingFee: 15000,
        grandTotal: 45000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        stores: [
          StoreInfo(
            id: 1,
            name: 'Bách Hóa Xanh',
            address: '456 Lê Lợi, Quận 1, TP.HCM',
          ),
        ],
        distanceKm: 2.3,
      ),
      ShipperOrder(
        id: 102,
        customerId: 2,
        customerName: 'Tran Thi B',
        customerPhone: '0912345678',
        storeId: 2,
        storeName: 'Co.opmart',
        storeAddress: '789 Nguyễn Huệ, Quận 1, TP.HCM',
        deliveryAddress: '456 Đường Lý Thường Kiệt, Quận 10, TP.HCM',
        status: OrderStatus.PICKING_UP,
        totalAmount: 23000,
        shippingFee: 15000,
        grandTotal: 38000,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        stores: [
          StoreInfo(
            id: 2,
            name: 'Co.opmart',
            address: '789 Nguyễn Huệ, Quận 1, TP.HCM',
          ),
        ],
        distanceKm: 4.1,
      ),
      ShipperOrder(
        id: 103,
        customerId: 3,
        customerName: 'Le Van C',
        customerPhone: '0923456789',
        storeId: 3,
        storeName: 'WinCommerce',
        storeAddress: '101 Hai Bà Trưng, Quận 1, TP.HCM',
        deliveryAddress: '88 Đường Pasteur, Quận 1, TP.HCM',
        status: OrderStatus.DELIVERING,
        totalAmount: 45000,
        shippingFee: 20000,
        grandTotal: 65000,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        stores: [
          StoreInfo(
            id: 3,
            name: 'WinCommerce',
            address: '101 Hai Bà Trưng, Quận 1, TP.HCM',
          ),
        ],
        distanceKm: 1.8,
      ),
    ];

    return {
      'isOnline': true,
      'earnings': 150000.0,
      'availableOrders':
          sampleOrders.where((o) => o.status == OrderStatus.CONFIRMED).toList(),
      'deliveries':
          sampleOrders.where((o) => o.status != OrderStatus.CONFIRMED).toList(),
      'completedCount': 15,
      'acceptanceRate': 92.0,
    };
  }
}

enum HistoryFilter { all, completed, cancelled }

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
  HistoryFilter _historyFilter = HistoryFilter.all;
  BuildContext? _dashboardBlocContext;
  Timer? _autoRefreshTimer;
  Timer? _realtimeRefreshDebounce;
  StreamSubscription<ShipperRealtimeEvent>? _realtimeSubscription;
  final ShipperRealtimeStompService _realtimeService =
      ShipperRealtimeStompService();
  Map<String, dynamic>? _userData;

  String _tr(BuildContext context, String vi, String en) {
    final l = AppLocalizations.of(context);
    if (l == null) return vi;
    return l.byLocale(vi: vi, en: en);
  }

  @override
  void initState() {
    super.initState();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshData(),
    );
    _loadUserProfile();
    _requestLocationPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initRealtimeStreaming();
      }
    });
  }

  Future<void> _initRealtimeStreaming() async {
    if (widget.preview) return;

    _realtimeSubscription?.cancel();
    _realtimeSubscription = _realtimeService.events.listen((event) {
      switch (event.type) {
        case ShipperRealtimeEventType.orderCreated:
        case ShipperRealtimeEventType.orderAccepted:
        case ShipperRealtimeEventType.orderStatusChanged:
          _scheduleRealtimeRefresh();
          break;
        case ShipperRealtimeEventType.profileUpdated:
          _loadUserProfile();
          break;
        case ShipperRealtimeEventType.error:
          debugPrint('STOMP error: ${event.message}');
          break;
        case ShipperRealtimeEventType.connected:
        case ShipperRealtimeEventType.disconnected:
          break;
        case ShipperRealtimeEventType.notificationReceived:
          if (event.payload != null) {
            final notification = NotificationModel.fromJson(event.payload!);
            if (mounted) {
              context
                  .read<NotificationBloc>()
                  .add(ReceiveRealtimeNotification(notification));
            }
          }
          break;
        case ShipperRealtimeEventType.notificationUnreadCountUpdated:
          if (event.payload != null && event.payload!['count'] != null) {
            final count = event.payload!['count'] as int;
            if (mounted) {
              context.read<NotificationBloc>().add(UpdateUnreadCount(count));
            }
          }
          break;
      }
    });

    await _realtimeService.connect();
  }

  void _scheduleRealtimeRefresh() {
    if (!mounted) return;
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        _refreshData();
      }
    });
  }

  Future<void> _requestLocationPermission() async {
    if (widget.preview) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }

      // Pre-fetch location to warm up
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    if (widget.preview) return;
    try {
      final repository = context.read<ShipperRepository>();
      final data = await repository.getCurrentUser();
      if (mounted) {
        setState(() => _userData = data);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _realtimeRefreshDebounce?.cancel();
    _realtimeSubscription?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    final blocContext = _dashboardBlocContext;
    if (blocContext == null) return;

    // Trigger refresh
    blocContext.read<ShipperDashboardBloc>().add(RefreshDashboardData());

    // Wait for BLoC to finish loading (not loading anymore = finished)
    await blocContext.read<ShipperDashboardBloc>().stream.firstWhere(
          (state) => state.status != DashboardStatus.loading,
          orElse: () => const ShipperDashboardState.initial(),
        );

    // Then refresh user profile
    await _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final repo = widget.preview
                ? _PreviewRepo()
                : context.read<ShipperRepository>();
            return ShipperDashboardBloc(repository: repo)
              ..add(LoadDashboardData());
          },
        ),
      ],
      child: Builder(
        builder: (innerContext) {
          _dashboardBlocContext = innerContext;
          return Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: [
                _overviewPage(),
                _historyPage(),
                _chatPage(),
                _statisticsPage(),
                _profilePage(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              selectedItemColor: ShipperTheme.primaryColor,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              onTap: (idx) {
                setState(() => _currentIndex = idx);
                // Refresh user profile when accessing profile tab
                if (idx == 4) {
                  _loadUserProfile();
                }
              },
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.dashboard),
                  label: _tr(context, 'Tổng quan', 'Overview'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.receipt_long),
                  label: _tr(context, 'Đơn hàng', 'Orders'),
                ),
                BottomNavigationBarItem(
                  icon: const ChatBadgeIcon(),
                  label: _tr(context, 'Chat', 'Chat'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.bar_chart),
                  label: _tr(context, 'Thống kê', 'Stats'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person),
                  label: _tr(context, 'Cá nhân', 'Profile'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _overviewPage() {
    return BlocBuilder<ShipperDashboardBloc, ShipperDashboardState>(
      builder: (context, state) {
        if (state.status == DashboardStatus.loading &&
            state.availableOrders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == DashboardStatus.error &&
            state.availableOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _tr(context, 'Không thể tải dữ liệu', 'Unable to load data'),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(_tr(context, 'Thử lại', 'Retry')),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _refreshData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _buildUserAvatar(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userData?['fullName'] ?? 'Shipper',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ) ??
                                    TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _tr(
                                  context,
                                  'Đối tác giao hàng',
                                  'Delivery partner',
                                ),
                                style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ) ??
                                    TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const NotificationIconButton(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OnlineToggle(
                      isOnline: state.isOnline,
                      onToggle: () => context.read<ShipperDashboardBloc>().add(
                            ToggleOnlineStatus(),
                          ),
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
                Text(
                  _tr(context, 'Đơn hàng sẵn có', 'Available orders'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ) ??
                      TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                if (state.availableOrders.isEmpty)
                  _buildEmptyAvailableOrders()
                else
                  AvailableOrdersList(
                    orders: state.availableOrders,
                    onAccept: (order) async {
                      // Accept order via API
                      final updatedOrder = await context
                          .read<ShipperDashboardBloc>()
                          .acceptOrder(order.id);

                      // Navigate to map immediately after accepting
                      if (updatedOrder != null && context.mounted) {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderMapScreen(
                              order: updatedOrder,
                              showDeliveryRoute:
                                  false, // Show route to store first
                            ),
                          ),
                        );

                        if (result == true && context.mounted) {
                          context.read<ShipperDashboardBloc>().add(
                                RefreshDashboardData(),
                              );
                        }
                      }

                      return updatedOrder;
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar() {
    final avatarUrl = _userData?['avatarUrl'];
    final name = _userData?['fullName'] ?? 'S';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return CircleAvatar(
      radius: 26,
      backgroundColor: ShipperTheme.primaryColor,
      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
          ? NetworkImage(avatarUrl)
          : null,
      child: (avatarUrl == null || avatarUrl.isEmpty)
          ? Text(
              initial,
              style: const TextStyle(fontSize: 24, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyAvailableOrders() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _tr(context, 'Chưa có đơn hàng nào', 'No orders yet'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tr(
              context,
              'Đơn hàng mới sẽ xuất hiện ở đây\nkhi cửa hàng xác nhận đơn',
              'New orders will appear here\nwhen stores confirm orders',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyPage() {
    return BlocBuilder<ShipperDashboardBloc, ShipperDashboardState>(
      builder: (context, state) {
        if (state.status == DashboardStatus.loading &&
            state.deliveries.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == DashboardStatus.error && state.deliveries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _tr(context, 'Không thể tải dữ liệu', 'Unable to load data'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(_tr(context, 'Thử lại', 'Retry')),
                ),
              ],
            ),
          );
        }

        final filteredOrders = state.deliveries.where((o) {
          switch (_historyFilter) {
            case HistoryFilter.all:
              return true;
            case HistoryFilter.completed:
              return o.status == OrderStatus.DELIVERED;
            case HistoryFilter.cancelled:
              return o.status == OrderStatus.CANCELLED;
          }
        }).toList();

        return RefreshIndicator(
          onRefresh: () async => _refreshData(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _tr(context, 'Lịch sử đơn hàng', 'Order history'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ShipperTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${state.deliveries.length} ${_tr(context, 'đơn', 'orders')}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ShipperTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: HistoryFilter.values.map((filter) {
                    final label = switch (filter) {
                      HistoryFilter.all => _tr(context, 'Tất cả', 'All'),
                      HistoryFilter.completed =>
                        _tr(context, 'Hoàn thành', 'Completed'),
                      HistoryFilter.cancelled =>
                        _tr(context, 'Đã hủy', 'Cancelled'),
                    };
                    final count = switch (filter) {
                      HistoryFilter.all => state.deliveries.length,
                      HistoryFilter.completed => state.deliveries
                          .where((o) => o.status == OrderStatus.DELIVERED)
                          .length,
                      HistoryFilter.cancelled => state.deliveries
                          .where((o) => o.status == OrderStatus.CANCELLED)
                          .length,
                    };
                    final selected = filter == _historyFilter;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _historyFilter = filter),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? ShipperTheme.primaryColor
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: selected
                                  ? null
                                  : Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? Colors.white
                                        : ShipperTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredOrders.isEmpty
                      ? _buildEmptyHistory()
                      : ListView.separated(
                          itemCount: filteredOrders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            return GestureDetector(
                              onTap: () {
                                final isActiveDelivery =
                                    order.status == OrderStatus.PICKING_UP ||
                                        order.status == OrderStatus.DELIVERING;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => isActiveDelivery
                                        ? DeliveryFlowScreen(order: order)
                                        : OrderDetailScreen(order: order),
                                  ),
                                );
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: ShipperTheme.primaryColor
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              _statusIcon(order.status),
                                              color: _statusColor(order.status),
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${_tr(context, 'Đơn', 'Order')} #${order.id}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  order.deliveryAddress,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${_tr(context, 'Khách', 'Customer')}: ${order.customerName}',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
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
                                                  color:
                                                      ShipperTheme.primaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _statusColor(
                                                    order.status,
                                                  ).withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  order.status.label,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: _statusColor(
                                                      order.status,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Icon(
                                            Icons.chevron_right,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _tr(context, 'Chưa có đơn hàng nào', 'No orders yet'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tr(
              context,
              'Lịch sử đơn hàng sẽ xuất hiện ở đây',
              'Order history will appear here',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.CONFIRMED:
        return Colors.blue;
      case OrderStatus.PICKING_UP:
        return Colors.orange;
      case OrderStatus.DELIVERING:
        return Colors.teal;
      case OrderStatus.DELIVERED:
        return Colors.green;
      case OrderStatus.CANCELLED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.CONFIRMED:
        return Icons.check_circle_outline;
      case OrderStatus.PICKING_UP:
        return Icons.store;
      case OrderStatus.DELIVERING:
        return Icons.delivery_dining;
      case OrderStatus.DELIVERED:
        return Icons.done_all;
      case OrderStatus.CANCELLED:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Widget _statisticsPage() {
    return BlocBuilder<ShipperDashboardBloc, ShipperDashboardState>(
      builder: (context, state) {
        if (state.status == DashboardStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == DashboardStatus.error) {
          return Center(
            child: Text('${_tr(context, 'Lỗi', 'Error')}: ${state.error}'),
          );
        }

        // Placeholder values while backend details are not available
        final onlineHours = state.isOnline ? 5.5 : 0.0;
        final weeklyIncome = state.earnings;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _tr(context, 'Thống kê', 'Statistics'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _tr(context, 'Chi tiết', 'Details'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow(
                        _tr(context, 'Giờ online', 'Online hours'),
                        '${onlineHours.toStringAsFixed(1)} ${_tr(context, 'giờ', 'h')}',
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        _tr(context, 'Thu nhập tuần', 'Weekly earnings'),
                        '${weeklyIncome.toStringAsFixed(0)}₫',
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        _tr(context, 'Tỷ lệ nhận đơn', 'Acceptance rate'),
                        '${state.acceptanceRate.toStringAsFixed(1)}%',
                      ),
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
    return const ShipperProfileScreen();
  }

  Widget _chatPage() {
    return const ShipperChatListScreen();
  }

  Widget _buildStatRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
