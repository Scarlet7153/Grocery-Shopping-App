import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/format/formatters.dart';
import '../auth/customer_login_screen.dart';

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
              gradient: const LinearGradient(
                colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Color(0xFF2F80ED)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('\u0110\u1ecba ch\u1ec9'),
              subtitle: Text(address),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('T\u1ed5ng chi ti\u00eau (mock)'),
              subtitle: Text(formatVnd(320000)),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(Icons.notifications_none),
              title: const Text('Th\u00f4ng b\u00e1o'),
              subtitle: const Text('B\u1eadt nh\u1eadn th\u00f4ng b\u00e1o khuy\u1ebfn m\u00e3i'),
              trailing: Switch(
                value: true,
                onChanged: (_) {},
              ),
            ),
          ),
          const SizedBox(height: 16),
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
