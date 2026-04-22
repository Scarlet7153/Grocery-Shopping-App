import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/shipper_dashboard_bloc.dart';
import '../../models/shipper_order.dart';
import '../../repository/shipper_repository.dart';
import '../../repository/shipper_chat_api.dart';
import '../../services/shipper_realtime_stomp_service.dart';
import '../../../../core/theme/shipper_theme.dart';
import '../delivery/proof_of_delivery_screen.dart';
import '../chat/shipper_chat_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final ShipperOrder order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late ShipperOrder _order;
  bool _isLoading = false;
  bool _isRealtimeSyncing = false;
  StreamSubscription<ShipperRealtimeEvent>? _realtimeSubscription;
  final ShipperRealtimeStompService _realtimeService =
      ShipperRealtimeStompService();

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
          debugPrint('OrderDetail STOMP error: ${event.message}');
          break;
        case ShipperRealtimeEventType.connected:
        case ShipperRealtimeEventType.disconnected:
        case ShipperRealtimeEventType.notificationReceived:
        case ShipperRealtimeEventType.notificationUnreadCountUpdated:
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
      debugPrint('Realtime refresh failed in OrderDetail: $e');
    } finally {
      _isRealtimeSyncing = false;
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Đơn #${_order.id}'),
        backgroundColor: ShipperTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildStatusBadge(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerCard(),
                  const SizedBox(height: 16),
                  _buildStoreCard(),
                  const SizedBox(height: 16),
                  _buildDeliveryAddressCard(),
                  const SizedBox(height: 16),
                  _buildItemsCard(),
                  const SizedBox(height: 16),
                  _buildPaymentCard(),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    String label;

    switch (_order.status) {
      case OrderStatus.CONFIRMED:
        bgColor = Colors.blue;
        label = 'Đã xác nhận';
        break;
      case OrderStatus.PICKING_UP:
        bgColor = Colors.orange;
        label = 'Đang lấy hàng';
        break;
      case OrderStatus.DELIVERING:
        bgColor = Colors.teal;
        label = 'Đang giao';
        break;
      case OrderStatus.DELIVERED:
        bgColor = Colors.green;
        label = 'Đã giao';
        break;
      case OrderStatus.CANCELLED:
        bgColor = Colors.red;
        label = 'Đã hủy';
        break;
      default:
        bgColor = Colors.grey;
        label = 'Không rõ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
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
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person, color: Colors.blue, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Thông tin khách hàng',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ) ??
                      const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.badge, 'Tên', _order.customerName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, 'SĐT', _order.customerPhone),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callCustomer(),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Gọi'),
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
                if (_order.status == OrderStatus.DELIVERING) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openChat(),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('Chat'),
                      style: FilledButton.styleFrom(
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard() {
    final isMultiStore = _order.stores.length > 1;

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
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Colors.purple,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isMultiStore ? 'Cửa hàng (${_order.stores.length})' : 'Cửa hàng',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ) ??
                      const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isMultiStore)
              ..._order.stores.asMap().entries.expand((entry) {
                final i = entry.key;
                final store = entry.value;
                return [
                  _buildInfoRow(Icons.storefront, 'Tên', store.name),
                  const SizedBox(height: 4),
                  _buildInfoRow(Icons.location_on, 'Địa chỉ', store.address),
                  if (i < _order.stores.length - 1)
                    Divider(color: Colors.grey[200], height: 20),
                ];
              })
            else ...[
              _buildInfoRow(Icons.storefront, 'Tên', _order.storeName),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.location_on, 'Địa chỉ', _order.storeAddress),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAddressCard() {
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
                    color: ShipperTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    color: ShipperTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Địa chỉ giao hàng',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ) ??
                      const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_order.deliveryAddress, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
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
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_basket,
                    color: Colors.green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sản phẩm (${_order.items.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ) ??
                      const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._order.items.map((item) => _buildItemRow(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                'x${item.quantity}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                '${item.unitName} · ${_formatCurrency(item.unitPrice)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              Text(
                _formatCurrency(item.subtotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ShipperTheme.primaryColor,
                ),
              ),
            ],
          ),
          if (item != _order.items.last)
            Divider(color: Colors.grey[200], height: 16),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
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
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Colors.amber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Thanh toán',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ) ??
                      const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Tổng tiền hàng', _order.totalAmount),
            const SizedBox(height: 8),
            _buildPriceRow('Phí vận chuyển', _order.shippingFee),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ShipperTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng thanh toán',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _formatCurrency(_order.grandTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: ShipperTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Phương thức thanh toán',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                Text(
                  _order.paymentMethod ?? 'COD',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final canAccept = _order.status == OrderStatus.CONFIRMED;
    final canStartDelivery = _order.status == OrderStatus.PICKING_UP;
    final canComplete = _order.status == OrderStatus.DELIVERING;

    if (!canAccept && !canStartDelivery && !canComplete) {
      return const SizedBox.shrink();
    }

    String buttonText;
    IconData buttonIcon;
    VoidCallback onPressed;

    if (canAccept) {
      buttonText = 'Nhận đơn hàng';
      buttonIcon = Icons.check_circle;
      onPressed = _acceptOrder;
    } else if (canStartDelivery) {
      buttonText = 'Bắt đầu giao hàng';
      buttonIcon = Icons.motorcycle;
      onPressed = _startDelivery;
    } else {
      buttonText = 'Hoàn thành giao hàng';
      buttonIcon = Icons.camera_alt;
      onPressed = _openProofOfDelivery;
    }

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
          onPressed: _isLoading ? null : onPressed,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
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

  Widget _buildPriceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Text(
          _formatCurrency(amount),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Future<void> _callCustomer() async {
    final uri = Uri.parse('tel:${_order.customerPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể gọi điện')));
      }
    }
  }

  Future<void> _openChat() async {
    try {
      final chatApi = ShipperChatApi();
      final conv =
          await chatApi.createOrGetConversation(_order.id, _order.customerId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShipperChatScreen(
            conversationId: conv.id,
            customerName: _order.customerName,
            orderId: _order.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Không thể mở chat'),
        ),
      );
    }
  }

  Future<void> _acceptOrder() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<ShipperRepository>();
      await repository.assignOrder(_order.id);
      if (mounted) {
        context.read<ShipperDashboardBloc>().add(RefreshDashboardData());
        Navigator.pop(context, true);
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

  Future<void> _startDelivery() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<ShipperRepository>();
      await repository.updateOrderStatus(_order.id, 'DELIVERING');
      if (mounted) {
        context.read<ShipperDashboardBloc>().add(RefreshDashboardData());
        Navigator.pop(context, true);
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

  Future<void> _openProofOfDelivery() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProofOfDeliveryScreen(order: _order)),
    );
    if (mounted && result == true) {
      context.read<ShipperDashboardBloc>().add(RefreshDashboardData());
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫';
  }
}
