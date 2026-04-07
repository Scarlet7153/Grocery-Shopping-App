import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = (AuthSession.fullName == null || AuthSession.fullName!.isEmpty)
        ? 'Khách hàng'
        : AuthSession.fullName!;
    final phone = (AuthSession.phoneNumber == null ||
            AuthSession.phoneNumber!.isEmpty)
        ? 'Chưa có số điện thoại'
        : AuthSession.phoneNumber!;
    final defaultAddress =
        (AuthSession.address == null || AuthSession.address!.isEmpty)
            ? 'Chưa có địa chỉ'
            : AuthSession.address!;

    final addresses = [
      _SavedAddress(
        label: 'Nhà',
        name: name,
        phone: phone,
        address: defaultAddress,
        isDefault: true,
      ),
      _SavedAddress(
        label: 'Công ty',
        name: name,
        phone: phone,
        address: 'Tòa nhà Bitexco, 2 Hải Triều, Quận 1, TP.HCM',
      ),
      _SavedAddress(
        label: 'Nhà bố mẹ',
        name: name,
        phone: '0918 888 999',
        address: '456 Nguyễn Trãi, Phường 8, Quận 5, TP.HCM',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Địa chỉ đã lưu'),
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
          ...addresses.map(
            (item) => _AddressCard(item: item),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Thêm địa chỉ mới'),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                const Icon(Icons.home, color: Color(0xFF2F80ED)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (item.isDefault)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Mặc định',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${item.name} · ${item.phone}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
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
