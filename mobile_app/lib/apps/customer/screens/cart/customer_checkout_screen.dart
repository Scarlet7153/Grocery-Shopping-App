import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/cart/cart_session.dart';
import '../../../../core/format/formatters.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/shipping_fee_calculator.dart';
import '../../../../apps/customer/services/customer_delivery_estimate_service.dart';
import '../../../../shared/widgets/snackbar_utils.dart';
import '../../shared/customer_payment_method.dart';
import '../../shared/customer_payment_preferences.dart';
import '../../utils/customer_l10n.dart';
import 'customer_payment_tracking_screen.dart';
import '../profile/recipient_info_screen.dart';

class CustomerCheckoutScreen extends StatefulWidget {
  final List<CartItem> selectedItems;

  const CustomerCheckoutScreen({super.key, required this.selectedItems});

  @override
  State<CustomerCheckoutScreen> createState() => _CustomerCheckoutScreenState();
}

class _CustomerCheckoutScreenState extends State<CustomerCheckoutScreen> {
  bool _placingOrder = false;
  double _shippingFee = 0;
  bool _calculatingShipping = false;

  List<CartItem> get _items => widget.selectedItems;

  @override
  void initState() {
    super.initState();
    _calculateShippingFee();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recalculate when returning from address edit
    _calculateShippingFee();
  }

  Future<void> _calculateShippingFee() async {
    setState(() => _calculatingShipping = true);

    final address = AuthSession.effectiveAddress;

    // Group items by store address (fallback to storeName if address empty)
    final storeAddresses = <String>{};
    for (final item in _items) {
      final addr = item.storeAddress.isNotEmpty ? item.storeAddress : item.storeName;
      debugPrint('[Shipping] item=${item.name} storeAddress="${item.storeAddress}" storeName="${item.storeName}" resolvedAddr="$addr"');
      if (addr.isNotEmpty) {
        storeAddresses.add(addr);
      }
    }

    // Count unique stores for fallback
    final uniqueStoreCount = _items.map((i) => i.storeName).where((n) => n.isNotEmpty).toSet().length;
    final storeCount = uniqueStoreCount > 0 ? uniqueStoreCount : 1;

    debugPrint('[Shipping] customerAddress="$address" storeCount=$storeCount storeAddresses=$storeAddresses');

    double totalFee = 0;

    if (address == null || address.isEmpty || storeAddresses.isEmpty) {
      // Không có địa chỉ để tính khoảng cách → dùng phí mặc định
      totalFee = ShippingFeeCalculator.defaultFee * storeCount;
      debugPrint('[Shipping] No address → defaultFee=${ShippingFeeCalculator.defaultFee} * $storeCount = $totalFee');
    } else {
      final estimateService = CustomerDeliveryEstimateService.instance;
      for (final storeAddress in storeAddresses) {
        try {
          final estimate = await estimateService.estimateByAddress(
            customerAddress: address,
            storeAddress: storeAddress,
          );
          debugPrint('[Shipping] estimate store="$storeAddress" distance=${estimate?.distanceKm}km fee=${estimate != null ? ShippingFeeCalculator.calculate(estimate.distanceKm) : "null"}');
          if (estimate != null) {
            // Sanity check: nếu khoảng cách > 20km, có thể geocode sai → fallback
            if (estimate.distanceKm > 20) {
              totalFee += ShippingFeeCalculator.defaultFee;
              debugPrint('[Shipping] distance >20km → fallback default');
            } else {
              totalFee += ShippingFeeCalculator.calculate(estimate.distanceKm);
            }
          } else {
            totalFee += ShippingFeeCalculator.defaultFee;
            debugPrint('[Shipping] estimate null → fallback default');
          }
        } catch (e, st) {
          debugPrint('[Shipping] ERROR store="$storeAddress" $e');
          debugPrint('[Shipping] Stack: $st');
          totalFee += ShippingFeeCalculator.defaultFee;
        }
      }
    }

    // Cap tối đa phí ship: 50k cho 1 cửa hàng, 80k cho 2+, 100k cho 3+
    double maxFee;
    if (storeCount == 1) {
      maxFee = 50000;
    } else if (storeCount == 2) {
      maxFee = 80000;
    } else {
      maxFee = 100000;
    }
    if (totalFee > maxFee) {
      totalFee = maxFee;
    }

    // Đảm bảo phí ship luôn > 0 nếu có sản phẩm
    if (totalFee <= 0 && _items.isNotEmpty) {
      totalFee = ShippingFeeCalculator.defaultFee * storeCount;
    }

    if (mounted) {
      setState(() {
        _shippingFee = totalFee;
        _calculatingShipping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final scheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr(vi: 'Thanh toán', en: 'Checkout')),
        ),
        body: Center(
          child: Text(context.tr(
              vi: 'Không có sản phẩm nào được chọn', en: 'No items selected')),
        ),
      );
    }

    final total =
        items.fold<num>(0, (sum, item) => sum + item.unitPrice * item.quantity);
    final itemCount = items.length;
    final shippingFee = _shippingFee;
    final grandTotal = total + shippingFee;

    final address =
        (AuthSession.address == null || AuthSession.address!.isEmpty)
            ? context.tr(vi: 'Chưa có địa chỉ', en: 'No address')
            : AuthSession.address!;

    final receiverName = (AuthSession.defaultHasOtherReceiver &&
            (AuthSession.defaultOtherReceiverName ?? '').isNotEmpty &&
            (AuthSession.defaultOtherReceiverPhone ?? '').isNotEmpty)
        ? '${(AuthSession.defaultOtherReceiverTitle ?? '').isEmpty ? '' : '${AuthSession.defaultOtherReceiverTitle} '}${AuthSession.defaultOtherReceiverName} - ${AuthSession.defaultOtherReceiverPhone}'
        : '${(AuthSession.fullName ?? '').isEmpty ? context.tr(vi: 'Khách hàng', en: 'Customer') : AuthSession.fullName!} - ${(AuthSession.phoneNumber ?? '').isEmpty ? context.tr(vi: 'Chưa có số điện thoại', en: 'No phone number') : AuthSession.phoneNumber!}';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(vi: 'Thanh toán', en: 'Checkout')),
      ),
      body: Container(
        color: scheme.surfaceContainerLowest,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(address,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            receiverName,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RecipientInfoScreen()),
                        );
                        // Refresh address and recalculate shipping fee after returning
                        if (mounted) {
                          setState(() {});
                          _calculateShippingFee();
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                          vi: 'Hình thức thanh toán', en: 'Payment method'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    _PaymentOptionTile(
                      value: CustomerPaymentMethod.cod,
                      icon: Icons.payments_outlined,
                      title: CustomerPaymentMethod.cod.labelOf(context),
                    ),
                    const SizedBox(height: 10),
                    _PaymentOptionTile(
                      value: CustomerPaymentMethod.momo,
                      icon: Icons.account_balance_wallet_outlined,
                      title: CustomerPaymentMethod.momo.labelOf(context),
                      subtitle: context.tr(
                          vi: 'Thanh toán online', en: 'Online payment'),
                      logoPath: 'assets/icons/momo.png',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                          vi: 'Chi tiết thanh toán', en: 'Payment details'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: context.tr(
                          vi: 'Tạm tính ($itemCount món)',
                          en: 'Subtotal ($itemCount items)'),
                      value: formatVnd(total),
                    ),
                    const SizedBox(height: 6),
                    _SummaryRow(
                      label:
                          context.tr(vi: 'Phí vận chuyển', en: 'Shipping fee'),
                      value: _calculatingShipping
                          ? context.tr(vi: 'Đang tính...', en: 'Calculating...')
                          : formatVnd(shippingFee),
                    ),
                    const Divider(height: 18),
                    _SummaryRow(
                      label: context.tr(vi: 'Tổng tiền', en: 'Total'),
                      value: formatVnd(grandTotal),
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.secondary],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton.icon(
              onPressed:
                  _placingOrder ? null : () => _placeOrder(context, items),
              icon: _placingOrder
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.shopping_cart),
              label: Text(_placingOrder
                  ? context.tr(vi: 'Đang xử lý...', en: 'Processing...')
                  : context.tr(vi: 'Đặt hàng', en: 'Place order')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, List<CartItem> items) async {
    if (_placingOrder) return;
    setState(() => _placingOrder = true);

    final method = CustomerPaymentPreferences.method.value;

    try {
      SnackBarUtils.showLoading(
        context: context,
        message: context.tr(vi: 'Đang đặt hàng...', en: 'Placing order...'),
      );

      final address = AuthSession.address;
      if (address == null || address.isEmpty) {
        throw Exception(context.tr(
            vi: 'Vui lòng thêm địa chỉ giao hàng',
            en: 'Please add delivery address'));
      }

      final payload = <String, dynamic>{
        'deliveryAddress': address,
        'shippingFee': _shippingFee,
        'items': items
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

      int? lastOrderId;
      if (data is Map && data['success'] == true) {
        final order = data['data'];
        final id = (order is Map) ? order['id'] : null;
        if (id != null) lastOrderId = int.tryParse(id.toString());
      } else {
        throw Exception(
          (data is Map && data['message'] != null)
              ? data['message'].toString()
              : context.tr(
                  vi: 'Đặt hàng thất bại', en: 'Order placement failed'),
        );
      }

      SnackBarUtils.hide(context);

      final rootContext = context;
      Map<String, dynamic>? paymentInit;
      if (lastOrderId != null) {
        try {
          paymentInit =
              await _initiatePayment(orderId: lastOrderId, method: method);
        } catch (_) {
          paymentInit = null;
        }
      }

      if (!rootContext.mounted) return;

      final paymentId = paymentInit?['paymentId'];
      final redirectUrl = (paymentInit?['redirectUrl'] ?? '').toString();

      if (paymentId != null && redirectUrl.isNotEmpty) {
        await Navigator.of(rootContext).push(
          MaterialPageRoute(
            builder: (_) => CustomerPaymentTrackingScreen(
              orderId: lastOrderId!,
              paymentId: paymentId,
              redirectUrl: redirectUrl,
              paymentMethod: method,
            ),
          ),
        );
        // Clear only checked out items after returning from payment
        for (final item in _items) {
          CartSession.removeProduct(item.productUnitMappingId);
        }
      } else if (method == CustomerPaymentMethod.cod) {
        // Clear only checked out items for COD
        for (final item in _items) {
          CartSession.removeProduct(item.productUnitMappingId);
        }
        Navigator.of(rootContext).popUntil((route) => route.isFirst);
        SnackBarUtils.showSuccess(
          context: rootContext,
          message: context.tr(
              vi: 'Đơn hàng đã được tạo thành công',
              en: 'Order was created successfully'),
        );
      } else {
        SnackBarUtils.showError(
          context: rootContext,
          message: context.tr(
            vi: 'Không thể khởi tạo thanh toán MoMo. Vui lòng thử lại hoặc kiểm tra đơn hàng.',
            en: 'Unable to initiate MoMo payment. Please retry or check your order.',
          ),
        );
      }
    } on DioException catch (e) {
      SnackBarUtils.hide(context);
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
      SnackBarUtils.hide(context);
      SnackBarUtils.showError(
        context: context,
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  Future<Map<String, dynamic>?> _initiatePayment({
    required int orderId,
    required CustomerPaymentMethod method,
  }) async {
    try {
      final res = await ApiClient.dio.post(
        '/payments/initiate',
        data: {
          'orderId': orderId,
          'paymentMethod': method.backendValue,
        },
      );
      final data = res.data;
      if (data is Map) {
        return {
          'paymentId': data['paymentId'],
          'redirectUrl': data['redirectUrl'],
        };
      }
    } catch (_) {}
    return null;
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final CustomerPaymentMethod value;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? logoPath;

  const _PaymentOptionTile({
    required this.value,
    required this.icon,
    required this.title,
    this.subtitle,
    this.logoPath,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
              color: isSelected
                  ? scheme.primary.withValues(alpha: 0.08)
                  : scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? scheme.primary : scheme.outlineVariant,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                if (logoPath != null)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      logoPath!,
                      fit: BoxFit.cover,
                      width: 38,
                      height: 38,
                    ),
                  )
                else
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: scheme.primary),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            fontSize: isTotal ? 18 : 14,
            color: isTotal ? scheme.error : scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
