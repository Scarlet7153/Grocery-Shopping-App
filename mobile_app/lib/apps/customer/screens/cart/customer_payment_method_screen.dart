// ignore_for_file: deprecated_member_use, unused_element, unused_local_variable
import 'package:flutter/material.dart';

import '../../shared/customer_payment_method.dart';
import '../../utils/customer_l10n.dart';

class CustomerPaymentMethodScreen extends StatefulWidget {
  const CustomerPaymentMethodScreen({
    super.key,
    required this.initial,
  });

  final CustomerPaymentMethod initial;

  @override
  State<CustomerPaymentMethodScreen> createState() =>
      _CustomerPaymentMethodScreenState();
}

class _CustomerPaymentMethodScreenState
    extends State<CustomerPaymentMethodScreen> {
  late CustomerPaymentMethod _selected = widget.initial;

  Widget _sectionHeader(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _tile({
    required CustomerPaymentMethod value,
    required Widget leading,
    required String title,
    required String subtitle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selected == value;
    return InkWell(
      onTap: () => setState(() => _selected = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<CustomerPaymentMethod>(
              value: value,
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v ?? _selected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leadingLogo({
    required String text,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
            context.tr(vi: 'Phương thức thanh toán', en: 'Payment method')),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                _sectionHeader(context.tr(vi: 'VÍ ĐIỆN TỬ', en: 'E-WALLETS')),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _tile(
                        value: CustomerPaymentMethod.momo,
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(
                            'assets/icons/momo.png',
                            fit: BoxFit.cover,
                            width: 42,
                            height: 42,
                          ),
                        ),
                        title: CustomerPaymentMethod.momo.labelOf(context),
                        subtitle: context.tr(
                            vi: 'Thanh toán online', en: 'Online payment'),
                      ),
                    ],
                  ),
                ),
                _sectionHeader(context.tr(vi: 'KHÁC', en: 'OTHERS')),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _tile(
                    value: CustomerPaymentMethod.cod,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.payments_outlined,
                          color: Color(0xFF2E7D32)),
                    ),
                    title: context.tr(
                        vi: 'Tiền mặt khi nhận hàng', en: 'Cash on delivery'),
                    subtitle: 'COD',
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  context.tr(vi: 'Xác nhận', en: 'Confirm'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
