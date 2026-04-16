import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/snackbar_utils.dart';
import '../../shared/customer_payment_method.dart';
import '../orders/customer_order_detail_screen.dart';
import '../../utils/customer_l10n.dart';

class CustomerPaymentTrackingScreen extends StatefulWidget {
  const CustomerPaymentTrackingScreen({
    super.key,
    this.orderId,
    required this.paymentId,
    required this.redirectUrl,
    required this.paymentMethod,
  });

  final int? orderId;
  final dynamic paymentId;
  final String redirectUrl;
  final CustomerPaymentMethod paymentMethod;

  @override
  State<CustomerPaymentTrackingScreen> createState() =>
      _CustomerPaymentTrackingScreenState();
}

class _CustomerPaymentTrackingScreenState
    extends State<CustomerPaymentTrackingScreen> with WidgetsBindingObserver {
  bool _loading = false;
  String _status = 'PENDING';
  String _message = '';
  int? _orderId;
  bool _hasOpenedPaymentApp = false;
  Timer? _pollingTimer;
  static const _pollingIntervalSeconds = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _orderId = widget.orderId;
    _refreshStatus();
    _startPolling();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPaymentAppIfNeeded();
    });
  }

  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: _pollingIntervalSeconds),
      (_) => _refreshStatus(),
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
      if (_status == 'PENDING') {
        _startPolling();
      }
    } else if (state == AppLifecycleState.paused) {
      _stopPolling();
    } else if (state == AppLifecycleState.inactive) {
      _stopPolling();
    }
  }

  Future<void> _refreshStatus() async {
    if (widget.paymentId == null) return;
    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      final response = await ApiClient.dio.get('/payments/${widget.paymentId}');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final status = (data['status'] ?? '').toString().toUpperCase();
        final orderId = data['orderId'];
        setState(() {
          _status = status.isEmpty ? 'PENDING' : status;
          _orderId = orderId is int
              ? orderId
              : int.tryParse(orderId?.toString() ?? '');
          _message = data['message']?.toString() ?? '';
        });

        if (_status == 'SUCCESS') {
          _stopPolling();
          SnackBarUtils.showSuccess(
            context: context,
            message: context.tr(
                vi: 'Thanh toán đã hoàn tất', en: 'Payment completed'),
          );
        } else if (_status == 'FAILED') {
          _stopPolling();
          SnackBarUtils.showError(
            context: context,
            message: context.tr(
                vi: 'Thanh toán chưa thành công',
                en: 'Payment did not complete'),
          );
        }
      } else {
        setState(() {
          _status = 'PENDING';
        });
      }
    } catch (_) {
      setState(() {
        _message = context.tr(
          vi: 'Không lấy được trạng thái thanh toán. Vui lòng thử lại.',
          en: 'Unable to fetch payment status. Please try again.',
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openPaymentApp() async {
    if (widget.redirectUrl.isEmpty) {
      SnackBarUtils.showWarning(
        context: context,
        message: context.tr(
          vi: 'Không có đường dẫn thanh toán để mở.',
          en: 'No payment link available to open.',
        ),
      );
      return;
    }

    final uri = Uri.tryParse(widget.redirectUrl);
    if (uri == null) {
      SnackBarUtils.showError(
        context: context,
        message: context.tr(
            vi: 'Link thanh toán không hợp lệ', en: 'Invalid payment link'),
      );
      return;
    }

    final ok = await launchUrl(
      uri,
      mode: uri.scheme == 'http' || uri.scheme == 'https'
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
    if (!ok) {
      SnackBarUtils.showError(
        context: context,
        message: context.tr(
            vi: 'Không thể mở ứng dụng thanh toán',
            en: 'Unable to open payment app'),
      );
    }
  }

  Future<void> _openPaymentAppIfNeeded() async {
    if (_hasOpenedPaymentApp || widget.redirectUrl.isEmpty) return;
    _hasOpenedPaymentApp = true;
    await _openPaymentApp();
  }

  bool get _isSuccess => _status == 'SUCCESS';
  bool get _isFailed => _status == 'FAILED';

  void _goToOrderDetail() {
    final orderId = _orderId ?? widget.orderId;
    if (orderId == null) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CustomerOrderDetailScreen(orderId: orderId.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paymentLabel = widget.paymentMethod.labelOf(context);
    final statusLabel = _status == 'PENDING'
        ? context.tr(vi: 'Chờ xử lý', en: 'Pending')
        : _status == 'SUCCESS'
            ? context.tr(vi: 'Thành công', en: 'Success')
            : _status == 'FAILED'
                ? context.tr(vi: 'Thất bại', en: 'Failed')
                : _status;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(vi: 'Thanh toán đơn hàng', en: 'Order payment')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                          vi: 'Phương thức thanh toán', en: 'Payment method'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(paymentLabel),
                    const SizedBox(height: 16),
                    Text(
                      context.tr(vi: 'Mã đơn hàng', en: 'Order ID'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text('#${_orderId ?? widget.orderId ?? widget.paymentId}'),
                    const SizedBox(height: 16),
                    Text(
                      context.tr(
                        vi: 'Trạng thái thanh toán',
                        en: 'Payment status',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_loading) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _message,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr(
                vi: 'Mở ứng dụng thanh toán để hoàn tất. Sau khi thanh toán xong, quay lại cửa hàng và kiểm tra trạng thái.',
                en: 'Open the payment app to complete payment. After payment, return to the store app and check status.',
              ),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: widget.redirectUrl.isEmpty ? null : _openPaymentApp,
              child: Text(context.tr(
                  vi: 'Mở ứng dụng thanh toán', en: 'Open payment app')),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _refreshStatus,
              child: Text(
                  context.tr(vi: 'Kiểm tra trạng thái', en: 'Check status')),
            ),
            const SizedBox(height: 10),
            if (_isFailed)
              OutlinedButton(
                onPressed: _openPaymentApp,
                child:
                    Text(context.tr(vi: 'Thanh toán lại', en: 'Retry payment')),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSuccess ? _goToOrderDetail : null,
              child: Text(context.tr(vi: 'Xem đơn hàng', en: 'View order')),
            ),
          ],
        ),
      ),
    );
  }
}
