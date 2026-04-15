import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/format/formatters.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/snackbar_utils.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
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
    } catch (_) {
      _error = 'Không thể tải chi tiết đơn hàng';
      _order = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statusOf(Map<String, dynamic> order) =>
      (order['status'] ?? '').toString();

  bool _canCancel(String status) =>
      status == 'PENDING' || status == 'CONFIRMED';

  num _asNum(dynamic v) {
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<void> _cancelOrder() async {
    if (_order == null || _cancelling) return;

    final status = _statusOf(_order!);
    if (!_canCancel(status)) return;

    final reasonController = TextEditingController(text: 'Khách hàng hủy đơn');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hủy đơn hàng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Vui lòng nhập lý do hủy đơn:'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ví dụ: Đổi địa chỉ, đặt nhầm...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Không'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hủy đơn'),
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
        message: 'Vui lòng nhập lý do hủy đơn',
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
            message: 'Đã hủy đơn hàng',
          );
        }
      } else {
        throw Exception(
          (data is Map && data['message'] != null)
              ? data['message'].toString()
              : 'Không thể hủy đơn hàng',
        );
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      SnackBarUtils.showError(
        context: context,
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Không thể kết nối đến máy chủ',
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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết đơn')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết đơn')),
        body: Center(child: Text(_error!)),
      );
    }

    final order = _order;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết đơn')),
        body: const Center(child: Text('Không có dữ liệu đơn hàng')),
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
        ? rawItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn #$id'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF6F8FB),
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
                            storeName.isEmpty ? 'Cửa hàng' : storeName,
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
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                    if (deliveryAddress.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Địa chỉ giao hàng',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(deliveryAddress),
                    ],
                    if (status == 'CANCELLED' && cancelReason.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Lý do hủy',
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
                    const Text(
                      'Sản phẩm',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    if (items.isEmpty)
                      const Text('Không có danh sách sản phẩm')
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
                                      name.isEmpty ? 'Sản phẩm' : name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      unitName,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'x$qty · ${formatVnd(unitPrice)}',
                                      style: const TextStyle(
                                        color: Colors.black54,
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
                    const Text(
                      'Thanh toán',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(label: 'Tiền hàng', value: formatVnd(totalAmount)),
                    const SizedBox(height: 6),
                    _SummaryRow(label: 'Phí vận chuyển', value: formatVnd(shippingFee)),
                    const Divider(height: 18),
                    _SummaryRow(
                      label: 'Tổng',
                      value: formatVnd(grandTotal),
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_canCancel(status))
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
                  label: const Text('Hủy đơn'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'DELIVERED':
        color = Colors.green;
        break;
      case 'DELIVERING':
        color = Colors.orange;
        break;
      case 'PICKING_UP':
        color = Colors.deepOrange;
        break;
      case 'CONFIRMED':
        color = Colors.blue;
        break;
      case 'CANCELLED':
        color = Colors.red;
        break;
      case 'PENDING':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
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
    final style = TextStyle(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: isTotal ? Colors.black : Colors.black87,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(
          value,
          style: style.copyWith(color: isTotal ? Colors.red : Colors.black87),
        ),
      ],
    );
  }
}
