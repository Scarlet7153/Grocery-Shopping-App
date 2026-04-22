// ignore_for_file: prefer_const_declarations
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/customer_payment_method.dart';
import '../../shared/customer_state_view.dart';
import '../../services/customer_realtime_service.dart';
import '../cart/customer_payment_tracking_screen.dart';
import '../../../../core/format/formatters.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/snackbar_utils.dart';
import '../../utils/customer_l10n.dart';
import 'customer_review_screen.dart';
import '../chat/customer_chat_screen.dart';
import '../../../../features/customer/home/data/chat_api.dart';
import '../../../../features/notification/bloc/notification_bloc.dart';
import '../../../../features/notification/data/notification_model.dart';

class CustomerOrderDetailScreen extends StatefulWidget {
  const CustomerOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<CustomerOrderDetailScreen> createState() =>
      _CustomerOrderDetailScreenState();
}

class _CustomerOrderDetailScreenState extends State<CustomerOrderDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _order;
  bool _cancelling = false;
  bool _retryingPayment = false;
  bool _hasReviewed = false;
  final CustomerRealtimeService _realtimeService = CustomerRealtimeService();
  StreamSubscription<CustomerRealtimeEvent>? _realtimeSubscription;
  bool _isRealtimeSyncing = false;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _initRealtimeStreaming() async {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _realtimeService.events.listen((event) {
      if (!_isEventForCurrentOrder(event)) return;

      switch (event.type) {
        case CustomerRealtimeEventType.orderStatusChanged:
        case CustomerRealtimeEventType.orderCreated:
          _refreshOrderFromRealtime();
          break;
        case CustomerRealtimeEventType.error:
        case CustomerRealtimeEventType.connected:
        case CustomerRealtimeEventType.disconnected:
          break;
        case CustomerRealtimeEventType.notificationReceived:
          if (event.payload != null) {
            final notification = NotificationModel.fromJson(event.payload!);
            if (mounted) {
              context
                  .read<NotificationBloc>()
                  .add(ReceiveRealtimeNotification(notification));
            }
          }
          break;
        case CustomerRealtimeEventType.notificationUnreadCountUpdated:
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

  bool _isEventForCurrentOrder(CustomerRealtimeEvent event) {
    final payload = event.payload;
    if (payload == null) return true;

    final rawOrderId = payload['orderId'] ?? payload['id'];
    final eventOrderId = rawOrderId is int
        ? rawOrderId
        : int.tryParse(rawOrderId?.toString() ?? '');
    final currentOrderId = int.tryParse(widget.orderId);

    if (eventOrderId == null || currentOrderId == null) {
      return true;
    }

    return eventOrderId == currentOrderId;
  }

  Future<void> _refreshOrderFromRealtime() async {
    if (!mounted || _isRealtimeSyncing || _loading) return;

    _isRealtimeSyncing = true;
    try {
      await _load();
    } finally {
      _isRealtimeSyncing = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.dio.get('/orders/${widget.orderId}');
      final data = res.data;
      if (data is Map && data['data'] is Map) {
        _order = Map<String, dynamic>.from(data['data'] as Map);
      } else {
        _order = null;
      }

      final orderIdInt = int.tryParse(widget.orderId);
      if (orderIdInt != null) {
        await _checkIfReviewed(orderIdInt);
      }
    } catch (_) {
      _error = context.tr(
        vi: 'Không thể tải chi tiết đơn hàng',
        en: 'Unable to load order details',
      );
      _order = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkIfReviewed(int orderId) async {
    try {
      await ApiClient.dio.get('/reviews/order/$orderId');
      if (mounted) _hasReviewed = true;
    } catch (_) {
      if (mounted) _hasReviewed = false;
    }
  }

  String _statusOf(Map<String, dynamic> order) =>
      (order['status'] ?? '').toString();

  bool _canCancel(String status) =>
      status == 'PENDING' || status == 'CONFIRMED';

  Future<Map<String, dynamic>> _initiatePayment({
    required int orderId,
    required CustomerPaymentMethod method,
  }) async {
    final res = await ApiClient.dio.post(
      '/payments/initiate',
      data: {
        'orderId': orderId,
        'paymentMethod': method.backendValue,
      },
    );

    final body = res.data;
    if (body is Map) {
      return {
        'paymentId': body['paymentId'],
        'redirectUrl': body['redirectUrl'] ?? body['redirectUrl'] ?? '',
      };
    }
    return const {'paymentId': null, 'redirectUrl': ''};
  }

  Future<void> _onRetryPaymentPressed(String status) async {
    if (_order == null || _retryingPayment) return;
    final orderId = int.tryParse(widget.orderId);
    if (orderId == null) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(context.tr(
                    vi: 'Thanh toán lại với MoMo', en: 'Retry with MoMo')),
                subtitle: Text(CustomerPaymentMethod.momo.labelOf(context)),
                onTap: () => Navigator.of(context).pop('MOMO'),
              ),
            ],
          ),
        );
      },
    );

    if (selected is! String) return;
    final method = CustomerPaymentMethod.momo;
    setState(() {
      _retryingPayment = true;
    });
    try {
      final result = await _initiatePayment(orderId: orderId, method: method);
      final paymentId = result['paymentId'];
      final redirectUrl = (result['redirectUrl'] ?? '').toString();
      if (paymentId != null && redirectUrl.isNotEmpty) {
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CustomerPaymentTrackingScreen(
            orderId: orderId,
            paymentId: paymentId,
            redirectUrl: redirectUrl,
            paymentMethod: method,
          ),
        ));
      } else {
        SnackBarUtils.showError(
          context: context,
          message: context.tr(
            vi: 'Không thể khởi tạo lại thanh toán. Vui lòng thử lại.',
            en: 'Unable to restart payment. Please try again.',
          ),
        );
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      SnackBarUtils.showError(
        context: context,
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : context.tr(
                vi: 'Không thể kết nối đến máy chủ',
                en: 'Cannot connect to server'),
      );
    } catch (e) {
      SnackBarUtils.showError(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _retryingPayment = false);
    }
  }

  num _asNum(dynamic v) {
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<void> _cancelOrder() async {
    if (_order == null || _cancelling) return;

    final status = _statusOf(_order!);
    if (!_canCancel(status)) return;

    final reasonController = TextEditingController(
      text: context.tr(vi: 'Khách hàng hủy đơn', en: 'Customer canceled order'),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr(vi: 'Hủy đơn hàng', en: 'Cancel order')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.tr(
                  vi: 'Vui lòng nhập lý do hủy đơn:',
                  en: 'Please enter the cancel reason:')),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: context.tr(
                    vi: 'Ví dụ: Đổi địa chỉ, đặt nhầm...',
                    en: 'Example: Wrong address, accidental order...',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr(vi: 'Không', en: 'No')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.tr(vi: 'Hủy đơn', en: 'Cancel order')),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      SnackBarUtils.showWarning(
        context: context,
        message: context.tr(
            vi: 'Vui lòng nhập lý do hủy đơn',
            en: 'Please enter cancel reason'),
      );
      return;
    }

    setState(() => _cancelling = true);
    try {
      final payload = {
        'newStatus': 'CANCELLED',
        'cancelReason': reason,
      };
      final res = await ApiClient.dio.patch(
        '/orders/${widget.orderId}/status',
        data: payload,
      );
      final data = res.data;
      if (data is Map && data['success'] == true && data['data'] is Map) {
        _order = Map<String, dynamic>.from(data['data'] as Map);
        if (mounted) {
          setState(() {});
          SnackBarUtils.showSuccess(
            context: context,
            message: context.tr(vi: 'Đã hủy đơn hàng', en: 'Order canceled'),
          );
        }
      } else {
        throw Exception(
          (data is Map && data['message'] != null)
              ? data['message'].toString()
              : context.tr(
                  vi: 'Không thể hủy đơn hàng', en: 'Unable to cancel order'),
        );
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      SnackBarUtils.showError(
        context: context,
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : context.tr(
                vi: 'Không thể kết nối đến máy chủ',
                en: 'Cannot connect to server'),
      );
    } catch (e) {
      SnackBarUtils.showError(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
            title: Text(context.tr(vi: 'Chi tiết đơn', en: 'Order details'))),
        body: CustomerStateView.loading(
          compact: true,
          title: context.tr(vi: 'Đang tải dữ liệu', en: 'Loading data'),
          message: context.tr(
              vi: 'Vui lòng chờ trong giây lát...',
              en: 'Please wait a moment...'),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
            title: Text(context.tr(vi: 'Chi tiết đơn', en: 'Order details'))),
        body: CustomerStateView.error(
          compact: true,
          message: _error!,
          onAction: _load,
        ),
      );
    }

    final order = _order;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(
            title: Text(context.tr(vi: 'Chi tiết đơn', en: 'Order details'))),
        body: CustomerStateView.empty(
          compact: true,
          title:
              context.tr(vi: 'Không có dữ liệu đơn hàng', en: 'No order data'),
          message: context.tr(
            vi: 'Đơn hàng có thể đã bị xóa hoặc chưa được đồng bộ.',
            en: 'This order may be deleted or not synced yet.',
          ),
          actionLabel: context.tr(vi: 'Tải lại', en: 'Reload'),
          onAction: _load,
        ),
      );
    }

    final id = (order['id'] ?? widget.orderId).toString();
    final status = _statusOf(order);
    final storeName = (order['storeName'] ?? '').toString();
    final deliveryAddress = (order['deliveryAddress'] ?? '').toString();
    final createdAt = (order['createdAt'] ?? '').toString();
    final totalAmount = _asNum(order['totalAmount']);
    final shippingFee = _asNum(order['shippingFee']);
    final grandTotal = _asNum(order['grandTotal']);
    final cancelReason = (order['cancelReason'] ?? '').toString();
    final rawItems = order['items'];
    final items = (rawItems is List)
        ? rawItems
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : const <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(vi: 'Đơn #$id', en: 'Order #$id')),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: context.tr(vi: 'Tải lại', en: 'Reload'),
          ),
        ],
      ),
      body: Container(
        color: scheme.surfaceContainerLowest,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            storeName.isEmpty
                                ? context.tr(vi: 'Cửa hàng', en: 'Store')
                                : storeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StatusChip(status: status),
                      ],
                    ),
                    if (createdAt.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        createdAt,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (deliveryAddress.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        context.tr(
                            vi: 'Địa chỉ giao hàng', en: 'Delivery address'),
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(deliveryAddress),
                    ],
                    if (status == 'CANCELLED' && cancelReason.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        context.tr(vi: 'Lý do hủy', en: 'Cancel reason'),
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(cancelReason),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(vi: 'Sản phẩm', en: 'Products'),
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    if (items.isEmpty)
                      Text(context.tr(
                          vi: 'Không có danh sách sản phẩm',
                          en: 'No product list'))
                    else
                      ...items.map((it) {
                        final name = (it['productName'] ?? '').toString();
                        final unitName = (it['unitName'] ?? '').toString();
                        final qty = _asNum(it['quantity']);
                        final unitPrice = _asNum(it['unitPrice']);
                        final subtotal = _asNum(it['subtotal']);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isEmpty
                                          ? context.tr(
                                              vi: 'Sản phẩm', en: 'Product')
                                          : name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      unitName,
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'x$qty · ${formatVnd(unitPrice)}',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatVnd(subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(vi: 'Thanh toán', en: 'Payment'),
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: context.tr(vi: 'Tiền hàng', en: 'Subtotal'),
                      value: formatVnd(totalAmount),
                    ),
                    const SizedBox(height: 6),
                    _SummaryRow(
                      label:
                          context.tr(vi: 'Phí vận chuyển', en: 'Shipping fee'),
                      value: formatVnd(shippingFee),
                    ),
                    const Divider(height: 18),
                    _SummaryRow(
                      label: context.tr(vi: 'Tổng', en: 'Total'),
                      value: formatVnd(grandTotal),
                      isTotal: true,
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: context.tr(vi: 'Phương thức', en: 'Method'),
                      value: _order?['paymentMethod']?.toString() ?? 'COD',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_canCancel(status))
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _cancelling ? null : _cancelOrder,
                      icon: _cancelling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cancel),
                      label:
                          Text(context.tr(vi: 'Hủy đơn', en: 'Cancel order')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                        side: BorderSide(color: scheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            if (status == 'DELIVERING')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openChatWithShipper(),
                  icon: const Icon(Icons.chat),
                  label: Text(context.tr(
                      vi: 'Chat với Shipper', en: 'Chat with Shipper')),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.secondary,
                    foregroundColor: scheme.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            if (status == 'PENDING' &&
                ((_order?['paymentStatus']?.toString() ?? '').toUpperCase() == 'PENDING' ||
                (_order?['paymentStatus']?.toString() ?? '').toUpperCase() == 'FAILED'))
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _retryingPayment
                      ? null
                      : () => _onRetryPaymentPressed(status),
                  icon: _retryingPayment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.replay),
                  label: Text(
                      context.tr(vi: 'Thanh toán lại', en: 'Retry payment')),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            if (status == 'DELIVERED' && !_hasReviewed)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openReviewScreen(),
                  icon: const Icon(Icons.star),
                  label: Text(context.tr(vi: 'Đánh giá', en: 'Review')),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.tertiary,
                    foregroundColor: scheme.onTertiary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            if (status == 'DELIVERED' && _hasReviewed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: scheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle,
                        color: scheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      context.tr(vi: 'Đã đánh giá', en: 'Reviewed'),
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
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

  void _openReviewScreen() {
    if (_order == null) return;
    final orderIdInt = int.tryParse(widget.orderId);
    if (orderIdInt == null) return;
    final storeName = (_order!['storeName'] ?? '').toString();

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => CustomerReviewScreen(
          orderId: orderIdInt,
          storeName: storeName,
        ),
      ),
    )
        .then((reviewed) {
      if (reviewed == true && mounted) {
        setState(() => _hasReviewed = true);
      }
    });
  }

  void _openChatWithShipper() async {
    if (_order == null) return;
    final orderIdInt = int.tryParse(widget.orderId);
    if (orderIdInt == null) return;
    final shipperId = _order!['shipperId'] as int?;
    final shipperName = (_order!['shipperName'] ?? 'Shipper').toString();
    final shipperAvatar = _order!['shipperAvatar']?.toString();

    if (shipperId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(
                vi: 'Chưa có thông tin shipper',
                en: 'No shipper information yet')),
          ),
        );
      }
      return;
    }

    final chatApi = ChatApi();
    try {
      final conv = await chatApi.createOrGetConversation(orderIdInt, shipperId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CustomerChatScreen(
            conversationId: conv.id,
            shipperName: shipperName,
            shipperAvatar: shipperAvatar,
            orderId: orderIdInt,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              context.tr(vi: 'Không thể mở chat', en: 'Unable to open chat')),
        ),
      );
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  String _label(BuildContext context) {
    switch (status) {
      case 'PENDING':
        return context.tr(vi: 'Chờ xác nhận', en: 'Pending');
      case 'CONFIRMED':
        return context.tr(vi: 'Đã xác nhận', en: 'Confirmed');
      case 'PICKING_UP':
        return context.tr(vi: 'Đang lấy hàng', en: 'Picking up');
      case 'DELIVERING':
        return context.tr(vi: 'Đang giao', en: 'Delivering');
      case 'DELIVERED':
        return context.tr(vi: 'Đã giao', en: 'Delivered');
      case 'CANCELLED':
        return context.tr(vi: 'Đã hủy', en: 'Cancelled');
      default:
        return status;
    }
  }

  Color _color(ColorScheme scheme) {
    switch (status) {
      case 'DELIVERED':
        return Colors.green;
      case 'DELIVERING':
        return Colors.orange;
      case 'PICKING_UP':
        return Colors.deepOrange;
      case 'CONFIRMED':
        return scheme.primary;
      case 'CANCELLED':
        return scheme.error;
      default:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _color(scheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label(context),
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final style = TextStyle(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: isTotal ? scheme.onSurface : scheme.onSurface,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(
          value,
          style: style.copyWith(
            color: isTotal ? scheme.error : scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
