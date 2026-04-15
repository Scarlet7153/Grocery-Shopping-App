import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/cart/cart_session.dart';
import '../../../../core/format/formatters.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/snackbar_utils.dart';
import '../../shared/customer_payment_method.dart';
import '../../shared/customer_payment_preferences.dart';
import '../profile/recipient_info_screen.dart';

class CustomerCartScreen extends StatelessWidget {
  const CustomerCartScreen({super.key});

  String _norm(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    s = s.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    s = s.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    s = s.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    s = s.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    s = s.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    s = s.replaceAll(RegExp(r'[đ]'), 'd');
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  Future<int?> _resolveStoreIdByName(String storeName) async {
    final keyword = storeName.trim();
    if (keyword.isEmpty) return null;
    final keywordNorm = _norm(keyword);

    Map<String, dynamic>? pickBest(List<Map<String, dynamic>> list) {
      if (list.isEmpty) return null;
      Map<String, dynamic>? best;
      var bestScore = -1;

      for (final s in list) {
        final nameRaw = (s['storeName'] ?? '').toString();
        final nameNorm = _norm(nameRaw);
        if (nameNorm.isEmpty) continue;

        var score = 0;
        if (nameNorm == keywordNorm) {
          score = 100;
        } else if (nameNorm.contains(keywordNorm) || keywordNorm.contains(nameNorm)) {
          score = 80;
        } else {
          final a = nameNorm.split(' ').where((t) => t.isNotEmpty).toSet();
          final b = keywordNorm.split(' ').where((t) => t.isNotEmpty).toSet();
          score = a.intersection(b).length;
        }

        if (score > bestScore) {
          bestScore = score;
          best = s;
        }
      }

      if (bestScore <= 0) return null;
      return best;
    }

    try {
      final res = await ApiClient.dio.get(
        '/stores/search',
        queryParameters: {'keyword': keyword},
      );
      final data = res.data;
      if (data is Map && data['data'] is List) {
        final list = List<Map<String, dynamic>>.from(data['data'] as List);
        final picked = pickBest(list);
        final id = picked?['id'];
        if (id == null) return null;
        return int.tryParse(id.toString());
      }
    } catch (_) {
      // ignore
    }

    try {
      final res = await ApiClient.dio.get('/stores');
      final data = res.data;
      if (data is Map && data['data'] is List) {
        final list = List<Map<String, dynamic>>.from(data['data'] as List);
        final picked = pickBest(list);
        final id = picked?['id'];
        if (id == null) return null;
        return int.tryParse(id.toString());
      }
    } catch (_) {
      // ignore
    }

    return null;
  }

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
      final paymentId = body['paymentId'] ?? body['id'];
      final redirectUrl = (body['redirectUrl'] ?? '').toString();
      return {
        'paymentId': paymentId,
        'redirectUrl': redirectUrl,
      };
    }

    return const {'paymentId': null, 'redirectUrl': ''};
  }

  Future<Map<String, dynamic>?> _getPaymentStatus(dynamic paymentId) async {
    if (paymentId == null) return null;
    final res = await ApiClient.dio.get('/payments/$paymentId');
    final body = res.data;
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    return null;
  }

  Future<void> _placeOrder(BuildContext context, List<CartItem> items) async {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      SnackBarUtils.showError(context: context, message: 'Bạn cần đăng nhập để đặt hàng');
      return;
    }

    final address = (AuthSession.address ?? '').trim();
    if (address.isEmpty) {
      SnackBarUtils.showWarning(
        context: context,
        message: 'Vui lòng chọn địa chỉ giao hàng trước',
      );
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RecipientInfoScreen()),
      );
      return;
    }

    final hasInvalid = items.any((i) => i.productUnitMappingId <= 0);
    if (hasInvalid) {
      SnackBarUtils.showError(
        context: context,
        message: 'Giỏ hàng có sản phẩm thiếu thông tin đơn vị bán',
      );
      return;
    }

    final Map<String, List<CartItem>> grouped = {};
    for (final item in items) {
      final key = item.storeName.trim();
      grouped.putIfAbsent(key, () => <CartItem>[]).add(item);
    }

    final method = CustomerPaymentPreferences.method.value;
    if (method != CustomerPaymentMethod.cod && grouped.length > 1) {
      SnackBarUtils.showWarning(
        context: context,
        message: 'Thanh toán online hiện chỉ hỗ trợ 1 cửa hàng. Vui lòng đặt từng cửa hàng hoặc chọn COD.',
      );
      return;
    }

    SnackBarUtils.showLoading(context: context, message: 'Đang đặt hàng...');

    int created = 0;
    int? lastOrderId;
    try {
      for (final entry in grouped.entries) {
        final storeName = entry.key;
        if (storeName.isEmpty) {
          throw Exception('Không xác định được cửa hàng cho sản phẩm trong giỏ');
        }

        final storeId = await _resolveStoreIdByName(storeName);
        if (storeId == null) {
          throw Exception('Không tìm thấy cửa hàng: $storeName');
        }

        final payload = <String, dynamic>{
          'storeId': storeId,
          'deliveryAddress': address,
          'items': entry.value
              .map(
                (i) => {
                  'productUnitMappingId': i.productUnitMappingId,
                  'quantity': i.quantity,
                },
              )
              .toList(),
        };

        final res = await ApiClient.dio.post('/orders', data: payload);
        final data = res.data;
        if (data is Map && data['success'] == true) {
          created += 1;
          final order = data['data'];
          final id = (order is Map) ? order['id'] : null;
          if (id != null) lastOrderId = int.tryParse(id.toString());
        } else {
          throw Exception(
            (data is Map && data['message'] != null)
                ? data['message'].toString()
                : 'Đặt hàng thất bại',
          );
        }
      }

      SnackBarUtils.hide(context);
      CartSession.clear();

      final rootContext = context;
      Map<String, dynamic>? paymentInit;
      if (created == 1 && lastOrderId != null) {
        try {
          paymentInit = await _initiatePayment(orderId: lastOrderId!, method: method);
        } catch (_) {
          paymentInit = null;
        }
      }

      if (!rootContext.mounted) return;

      final paymentId = paymentInit?['paymentId'];
      final redirectUrl = (paymentInit?['redirectUrl'] ?? '').toString();

      await showDialog<void>(
        context: rootContext,
        builder: (dialogContext) {
          Future<void> openPaymentUrl() async {
            final uri = Uri.tryParse(redirectUrl);
            if (uri == null) {
              SnackBarUtils.showError(context: rootContext, message: 'Link thanh toán không hợp lệ');
              return;
            }
            final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
            if (!ok) {
              SnackBarUtils.showError(context: rootContext, message: 'Không thể mở trang thanh toán');
            }
          }

          Future<void> checkPayment() async {
            final statusBody = await _getPaymentStatus(paymentId);
            final status = (statusBody?['status'] ?? '').toString().toUpperCase();
            if (status.isEmpty) {
              SnackBarUtils.showWarning(context: rootContext, message: 'Không lấy được trạng thái thanh toán');
              return;
            }
            if (status == 'SUCCESS') {
              SnackBarUtils.showSuccess(context: rootContext, message: 'Thanh toán thành công');
            } else if (status == 'FAILED') {
              SnackBarUtils.showError(context: rootContext, message: 'Thanh toán thất bại');
            } else {
              SnackBarUtils.showWarning(context: rootContext, message: 'Trạng thái thanh toán: $status');
            }
          }

          return AlertDialog(
            title: const Text('Đặt hàng thành công'),
            content: Text(
              created <= 1
                  ? 'Đơn hàng của bạn đã được ghi nhận.'
                  : 'Bạn đã tạo $created đơn hàng (theo từng cửa hàng).',
            ),
            actions: [
              if (redirectUrl.isNotEmpty)
                TextButton(
                  onPressed: openPaymentUrl,
                  child: const Text('Thanh toán'),
                ),
              if (paymentId != null)
                TextButton(
                  onPressed: checkPayment,
                  child: const Text('Kiểm tra'),
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
    } on DioException catch (e) {
      SnackBarUtils.hide(context);
      final data = e.response?.data;
      SnackBarUtils.showError(
        context: context,
        message: (data is Map && data['message'] != null) ? data['message'].toString() : 'Không thể kết nối đến máy chủ',
      );
    } catch (e) {
      SnackBarUtils.hide(context);
      SnackBarUtils.showError(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> _confirmRemove(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text('Bạn có chắc chắn muốn bỏ sản phẩm này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Không'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Đồng ý'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: CartSession.items,
      builder: (context, items, _) {
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text('Giỏ hàng đang trống'),
              ],
            ),
          );
        }

        final total = items.fold<num>(0, (sum, item) => sum + item.unitPrice * item.quantity);
        final itemCount = items.length;
        const shippingFee = 0;
        final grandTotal = total + shippingFee;

        final Map<String, List<CartItem>> grouped = {};
        for (final item in items) {
          final key = item.storeName.isEmpty ? 'Cửa hàng' : item.storeName;
          grouped.putIfAbsent(key, () => <CartItem>[]).add(item);
        }

        final address = (AuthSession.address == null || AuthSession.address!.isEmpty)
            ? 'Chưa có địa chỉ'
            : AuthSession.address!;

        final receiverName = (AuthSession.defaultHasOtherReceiver &&
                (AuthSession.defaultOtherReceiverName ?? '').isNotEmpty &&
                (AuthSession.defaultOtherReceiverPhone ?? '').isNotEmpty)
            ? '${(AuthSession.defaultOtherReceiverTitle ?? '').isEmpty ? '' : '${AuthSession.defaultOtherReceiverTitle} '}${AuthSession.defaultOtherReceiverName} - ${AuthSession.defaultOtherReceiverPhone}'
            : '${(AuthSession.fullName ?? '').isEmpty ? 'Khách hàng' : AuthSession.fullName!} - ${(AuthSession.phoneNumber ?? '').isEmpty ? 'Chưa có số điện thoại' : AuthSession.phoneNumber!}';

        Widget paymentOption({
          required CustomerPaymentMethod value,
          required IconData icon,
          required String title,
          String? subtitle,
        }) {
          return ValueListenableBuilder<CustomerPaymentMethod>(
            valueListenable: CustomerPaymentPreferences.method,
            builder: (context, selected, _) {
              final isSelected = selected == value;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => CustomerPaymentPreferences.method.value = value,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2E7D32).withOpacity(0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2E7D32) : Colors.black12,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? const Color(0xFF2E7D32) : Colors.black38,
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: const Color(0xFF2E7D32)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return Container(
          color: const Color(0xFFF6F8FB),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Giỏ hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(address, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(receiverName, style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RecipientInfoScreen()),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...grouped.entries.expand((entry) {
                final storeName = entry.key;
                final storeItems = entry.value;
                return [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.store, size: 18, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(storeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  ...storeItems.map((item) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item.imageUrl.isEmpty
                              ? Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                )
                              : (item.imageUrl.startsWith('assets/'))
                                  ? Image.asset(item.imageUrl, width: 56, height: 56, fit: BoxFit.cover)
                                  : Image.network(
                                      item.imageUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) {
                                        return Container(
                                          width: 56,
                                          height: 56,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image),
                                        );
                                      },
                                    ),
                        ),
                        title: Text(item.name),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _QuantityButton(
                                icon: Icons.remove,
                                onPressed: () async {
                                  if (item.quantity <= 1) {
                                    final ok = await _confirmRemove(context);
                                    if (ok) {
                                      CartSession.removeProduct(item.productId);
                                    }
                                    return;
                                  }
                                  CartSession.updateQuantity(item.productId, item.quantity - 1);
                                },
                              ),
                              Container(
                                width: 36,
                                alignment: Alignment.center,
                                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              _QuantityButton(
                                icon: Icons.add,
                                onPressed: () => CartSession.updateQuantity(item.productId, item.quantity + 1),
                              ),
                            ],
                          ),
                        ),
                        trailing: Text(
                          formatVnd(item.unitPrice * item.quantity),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
                        ),
                      ),
                    );
                  }),
                ];
              }),
              const SizedBox(height: 6),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hình thức thanh toán', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      paymentOption(
                        value: CustomerPaymentMethod.cod,
                        icon: Icons.payments_outlined,
                        title: 'Thanh toán khi nhận hàng',
                      ),
                      const SizedBox(height: 10),
                      paymentOption(
                        value: CustomerPaymentMethod.momo,
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'MoMo',
                        subtitle: 'Thanh toán online',
                      ),
                      const SizedBox(height: 10),
                      paymentOption(
                        value: CustomerPaymentMethod.vnpay,
                        icon: Icons.credit_card_outlined,
                        title: 'VNPay',
                        subtitle: 'Thanh toán online',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chi tiết thanh toán', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      _SummaryRow(label: 'Tạm tính ($itemCount món)', value: formatVnd(total)),
                      const SizedBox(height: 6),
                      _SummaryRow(label: 'Phí vận chuyển', value: formatVnd(shippingFee)),
                      const Divider(height: 18),
                      _SummaryRow(label: 'Tổng tiền', value: formatVnd(grandTotal), isTotal: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _placeOrder(context, items),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Đặt hàng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Icon(icon, size: 16),
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
