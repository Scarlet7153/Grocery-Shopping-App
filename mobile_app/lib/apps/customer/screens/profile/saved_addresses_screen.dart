import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../utils/customer_l10n.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final name = (AuthSession.fullName == null || AuthSession.fullName!.isEmpty)
        ? context.tr(vi: 'Khách hàng', en: 'Customer')
        : AuthSession.fullName!;
    final phone =
        (AuthSession.phoneNumber == null || AuthSession.phoneNumber!.isEmpty)
            ? context.tr(vi: 'Chưa có số điện thoại', en: 'No phone number')
            : AuthSession.phoneNumber!;
    final defaultAddress =
        (AuthSession.address == null || AuthSession.address!.isEmpty)
            ? context.tr(vi: 'Chưa có địa chỉ', en: 'No address yet')
            : AuthSession.address!;

    final addresses = [
      _SavedAddress(
        label: context.tr(vi: 'Nhà', en: 'Home'),
        name: name,
        phone: phone,
        address: defaultAddress,
        isDefault: true,
      ),
      _SavedAddress(
        label: context.tr(vi: 'Công ty', en: 'Office'),
        name: name,
        phone: phone,
        address: 'Tòa nhà Bitexco, 2 Hải Triều, Quận 1, TP.HCM',
      ),
      _SavedAddress(
        label: context.tr(vi: 'Nhà bố mẹ', en: 'Parents\' home'),
        name: name,
        phone: '0918 888 999',
        address: '456 Nguyễn Trãi, Phường 8, Quận 5, TP.HCM',
      ),
    ];

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(context.tr(vi: 'Địa chỉ đã lưu', en: 'Saved addresses')),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...addresses.map((item) => _AddressCard(item: item)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(context.tr(vi: 'Thêm địa chỉ mới', en: 'Add new address')),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedAddress {
  final String label;
  final String name;
  final String phone;
  final String address;
  final bool isDefault;

  _SavedAddress({
    required this.label,
    required this.name,
    required this.phone,
    required this.address,
    this.isDefault = false,
  });
}

class _AddressCard extends StatelessWidget {
  final _SavedAddress item;

  const _AddressCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (item.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      context.tr(vi: 'Mặc định', en: 'Default'),
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${item.name} · ${item.phone}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.address,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
