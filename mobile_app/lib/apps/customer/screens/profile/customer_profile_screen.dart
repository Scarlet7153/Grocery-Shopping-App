import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../auth/customer_login_screen.dart';
import 'recipient_info_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = (AuthSession.fullName == null || AuthSession.fullName!.isEmpty)
        ? 'Kh\u00e1ch h\u00e0ng'
        : AuthSession.fullName!;
    final address =
        (AuthSession.address == null || AuthSession.address!.isEmpty)
            ? 'Ch\u01b0a c\u00f3 \u0111\u1ecba ch\u1ec9'
            : AuthSession.address!;
    final phone = (AuthSession.phoneNumber == null ||
            AuthSession.phoneNumber!.isEmpty)
        ? 'Ch\u01b0a c\u00f3 s\u1ed1 \u0111i\u1ec7n tho\u1ea1i'
        : AuthSession.phoneNumber!;

    return Container(
      color: const Color(0xFFF6F8FB),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(0xFFEAF2FF),
                  child: Icon(Icons.person, color: Color(0xFF2F80ED), size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  address,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('\u0110\u1ecba ch\u1ec9 c\u1ee7a t\u00f4i'),
                  subtitle: Text(address),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecipientInfoScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Ph\u01b0\u01a1ng th\u1ee9c thanh to\u00e1n'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('L\u1ecbch s\u1eed \u0111\u01a1n h\u00e0ng'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('\u0110\u0103ng xu\u1ea5t'),
              onTap: () {
                AuthSession.clear();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerLoginScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
