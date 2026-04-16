import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/shipper_dashboard_bloc.dart';
import '../../models/shipper_order.dart';
import '../../repository/shipper_repository.dart';
import '../../services/shipper_realtime_stomp_service.dart';
import '../../../../core/theme/shipper_theme.dart';
import '../order_detail/order_detail_screen.dart';
import 'order_map_screen.dart';

class DeliveryFlowScreen extends StatefulWidget {
  final ShipperOrder order;

  const DeliveryFlowScreen({super.key, required this.order});

  @override
  State<DeliveryFlowScreen> createState() => _DeliveryFlowScreenState();
}

class _DeliveryFlowScreenState extends State<DeliveryFlowScreen> {
  late ShipperOrder _order;
  bool _isLoading = false;
  bool _isRealtimeSyncing = false;
  StreamSubscription<ShipperRealtimeEvent>? _realtimeSubscription;
  final ShipperRealtimeStompService _realtimeService =
      ShipperRealtimeStompService();

  Future<void> _initRealtimeStreaming() async {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _realtimeService.events.listen((event) {
      if (!_isEventForCurrentOrder(event)) return;

      switch (event.type) {
        case ShipperRealtimeEventType.orderAccepted:
        case ShipperRealtimeEventType.orderStatusChanged:
          _refreshOrderFromRealtime();
          break;
        case ShipperRealtimeEventType.error:
          debugPrint('DeliveryFlow STOMP error: ${event.message}');
          break;
        case ShipperRealtimeEventType.connected:
        case ShipperRealtimeEventType.disconnected:
        case ShipperRealtimeEventType.orderCreated:
        case ShipperRealtimeEventType.profileUpdated:
          break;
      }
    });

    await _realtimeService.connect();
  }

  bool _isEventForCurrentOrder(ShipperRealtimeEvent event) {
    final payload = event.payload;
    if (payload == null) return false;

    final rawOrderId = payload['orderId'] ?? payload['id'];
    final eventOrderId = rawOrderId is int
        ? rawOrderId
        : int.tryParse(rawOrderId?.toString() ?? '');

    return eventOrderId == _order.id;
  }

  Future<void> _refreshOrderFromRealtime() async {
    if (!mounted || _isRealtimeSyncing) return;

    _isRealtimeSyncing = true;
    try {
      final repository = context.read<ShipperRepository>();
      final refreshed = await repository.getOrderById(_order.id);
      if (!mounted || refreshed == null) return;

      setState(() {
        _order = refreshed;
      });
    } catch (e) {
      debugPrint('Realtime refresh failed in DeliveryFlow: $e');
    } finally {
      _isRealtimeSyncing = false;
    }
  }

  Future<void> _openMapAndRefresh({required bool showDeliveryRoute}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderMapScreen(
          order: _order,
          showDeliveryRoute: showDeliveryRoute,
        ),
      ),
    );

    if (!mounted || result != true) return;

    context.read<ShipperDashboardBloc>().add(RefreshDashboardData());

    try {
      final refreshed = await context.read<ShipperRepository>().getOrderById(
        _order.id,
      );
      if (refreshed != null && mounted) {
        setState(() {
          _order = refreshed;
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initRealtimeStreaming();
      }
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  int get _currentStep {
    switch (_order.status) {
      case OrderStatus.PICKING_UP:
        return 0;
      case OrderStatus.DELIVERING:
        return 1;
      case OrderStatus.DELIVERED:
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelivered = _order.status == OrderStatus.DELIVERED;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Giao đơn #${_order.id}'),
        backgroundColor: ShipperTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepper(),
                  const SizedBox(height: 24),
                  if (_currentStep == 0) _buildPickingUpStep(),
                  if (_currentStep == 1) _buildDeliveringStep(),
                  if (_currentStep == 2) _buildDeliveredStep(),
                ],
              ),
            ),
          ),
          if (!isDelivered) _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final steps = [
      _StepData(
        'Lấy hàng',
        'Đến cửa hàng',
        Icons.store,
        OrderStatus.PICKING_UP,
      ),
      _StepData(
        'Giao hàng',
        'Đến khách hàng',
        Icons.delivery_dining,
        OrderStatus.DELIVERING,
      ),
      _StepData(
        'Hoàn thành',
        'Giao thành công',
        Icons.check_circle,
        OrderStatus.DELIVERED,
      ),
    ];

    return Row(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isCompleted = i < _currentStep;
        final isCurrent = i == _currentStep;

        return Expanded(
          child: Row(
            children: [
              _buildStepIcon(step.icon, isCompleted, isCurrent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                        color: isCompleted || isCurrent
                            ? ShipperTheme.primaryColor
                            : Colors.grey[400],
                      ),
                    ),
                    Text(
                      step.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isCompleted || isCurrent
                            ? Colors.grey[600]
                            : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < _currentStep
                        ? ShipperTheme.primaryColor
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStepIcon(IconData icon, bool isCompleted, bool isCurrent) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isCompleted || isCurrent
            ? ShipperTheme.primaryColor
            : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(
        isCompleted ? Icons.check : icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildPickingUpStep() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Đến cửa hàng lấy hàng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              icon: Icons.storefront,
              title: 'Cửa hàng',
              value: _order.storeName,
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.location_on,
              title: 'Địa chỉ',
              value: _order.storeAddress,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('tel:${_order.customerPhone}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                icon: const Icon(Icons.phone, size: 18),
                label: const Text('Gọi cửa hàng'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  side: const BorderSide(color: Colors.purple),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openMapAndRefresh(showDeliveryRoute: false),
                icon: const Icon(Icons.map, size: 18),
                label: const Text('Xem bản đồ đến cửa hàng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveringStep() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    color: Colors.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Giao đến khách hàng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              icon: Icons.person,
              title: 'Khách hàng',
              value: _order.customerName,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.phone,
              title: 'SĐT',
              value: _order.customerPhone,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.location_on,
              title: 'Địa chỉ giao',
              value: _order.deliveryAddress,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse('tel:${_order.customerPhone}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Gọi khách'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _openMapAndRefresh(showDeliveryRoute: true),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Chỉ đường'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(order: _order),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Chi tiết'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShipperTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveredStep() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Giao hàng thành công!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Đơn #${_order.id} đã được giao cho ${_order.customerName}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ShipperTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng thanh toán',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _formatCurrency(_order.grandTotal),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ShipperTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    final isPickingUp = _order.status == OrderStatus.PICKING_UP;
    final isDelivering = _order.status == OrderStatus.DELIVERING;

    if (!isPickingUp && !isDelivering) return const SizedBox.shrink();

    final buttonText = isPickingUp
        ? 'Đã lấy hàng, bắt đầu giao'
        : 'Xác nhận đã giao thành công';
    final buttonIcon = isPickingUp ? Icons.motorcycle : Icons.done_all;
    final newStatus = isPickingUp ? 'DELIVERING' : 'DELIVERED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _updateStatus(newStatus),
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(buttonIcon),
          label: Text(
            buttonText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ShipperTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<ShipperRepository>();
      final updated = await repository.updateOrderStatus(_order.id, newStatus);
      if (mounted && updated != null) {
        setState(() => _order = updated);
        context.read<ShipperDashboardBloc>().add(RefreshDashboardData());
        if (newStatus == 'DELIVERED') {
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫';
  }
}

class _StepData {
  final String title;
  final String subtitle;
  final IconData icon;
  final OrderStatus status;

  _StepData(this.title, this.subtitle, this.icon, this.status);
}
