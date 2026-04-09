import 'package:flutter/material.dart';

class RecentOrders extends StatelessWidget {
  const RecentOrders({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          "Đơn hàng gần đây",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        SizedBox(height: 10),

        ListTile(
          title: Text("Đơn #1234"),
          subtitle: Text("150.000₫"),
          trailing: Text("Hoàn thành"),
        ),

        ListTile(
          title: Text("Đơn #1235"),
          subtitle: Text("80.000₫"),
          trailing: Text("Đang giao"),
        ),
      ],
    );
  }
}
