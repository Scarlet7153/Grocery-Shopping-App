import 'package:flutter/material.dart';

class HomeBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const HomeBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,

      backgroundColor: Colors.white, // nền trắng

      selectedItemColor: Colors.blue, // icon được chọn
      unselectedItemColor: Colors.grey, // icon chưa chọn

      type: BottomNavigationBarType.fixed,

      items: const [

        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: "Cart",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.receipt),
          label: "Orders",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),

      ],
    );
  }
}