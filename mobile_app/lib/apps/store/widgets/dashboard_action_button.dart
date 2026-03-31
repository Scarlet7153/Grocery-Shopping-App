import 'package:flutter/material.dart';

class RecentOrders extends StatelessWidget {

  const RecentOrders({super.key});

  @override
  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(
          "Đơn hàng gần đây",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        ListTile(
          title: const Text("Đơn #1234"),
          subtitle: const Text("150.000₫"),
          trailing: const Text("Hoàn thành"),
        ),

        ListTile(
          title: const Text("Đơn #1235"),
          subtitle: const Text("80.000₫"),
          trailing: const Text("Đang giao"),
        ),

      ],
    );
  }
}