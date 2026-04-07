import 'package:flutter/material.dart';

class OrdersOverview extends StatelessWidget {

  const OrdersOverview({super.key});

  @override
  Widget build(BuildContext context) {

    return Row(

      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [

        _buildItem("Đơn hôm nay", "18"),
        _buildItem("Đang xử lý", "4"),
        _buildItem("Hoàn thành", "14"),

      ],

    );
  }

  Widget _buildItem(String title, String value) {

    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(title),
      ],
    );
  }
}