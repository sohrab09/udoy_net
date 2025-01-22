import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Color(0xFF65AA4B), // Color for the selected icon
      unselectedItemColor: Colors.grey, // Color for the unselected icons
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: "Scan",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: "Discover",
        ),
      ],
    );
  }
}
