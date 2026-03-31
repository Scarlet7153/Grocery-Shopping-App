import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {

  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {

    return Row(

      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [

        _action(Icons.add_box, "Thêm sản phẩm"),
        _action(Icons.list_alt, "Quản lý đơn"),
        _action(Icons.store, "Cửa hàng"),

      ],
    );
  }

  Widget _action(IconData icon, String title) {

    return Column(

      children: [

        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.green,
          child: Icon(icon, color: Colors.white),
        ),

        const SizedBox(height: 8),

        Text(title),

      ],
    );
  }
}