import 'package:flutter/material.dart';

class RevenueCard extends StatelessWidget {

  const RevenueCard({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16),
      ),

      child: const Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(
            "Doanh thu hôm nay",
            style: TextStyle(color: Colors.white),
          ),

          SizedBox(height: 10),

          Text(
            "2.500.000₫",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

        ],
      ),
    );
  }
}