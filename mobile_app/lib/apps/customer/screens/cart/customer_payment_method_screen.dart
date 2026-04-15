import 'package:flutter/material.dart';

import '../../shared/customer_payment_method.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
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
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Phương thức thanh toán'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                _sectionHeader('VÍ ĐIỆN TỬ'),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _tile(
                        value: CustomerPaymentMethod.momo,
                        leading: _leadingLogo(
                          text: 'M',
                          bg: const Color(0xFFE91E63),
                          fg: Colors.white,
                        ),
                        title: 'MoMo',
                        subtitle: 'Thanh toán online',
                      ),
                      const Divider(height: 1),
                      _tile(
                        value: CustomerPaymentMethod.vnpay,
                        leading: _leadingLogo(
                          text: 'VNP',
                          bg: const Color(0xFFD32F2F),
                          fg: Colors.white,
                        ),
                        title: 'VNPay',
                        subtitle: 'Thanh toán online',
                      ),
                    ],
                  ),
                ),
                _sectionHeader('KHÁC'),
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
                        color: const Color(0xFF2E7D32).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.payments_outlined, color: Color(0xFF2E7D32)),
                    ),
                    title: 'Tiền mặt khi nhận hàng',
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
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Xác nhận',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
