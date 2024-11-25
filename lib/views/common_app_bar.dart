import 'package:flutter/material.dart';

import '../home.dart';
import 'custom_text.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double height;
  final Color? backgroundColor;
  final bool showHomeIcon;
  final bool showCartIcon;

  const CommonAppBar({
    super.key,
    required this.title,
    this.height = 40.0,
    this.backgroundColor = const Color(0xFFFFF8E1),
    this.showHomeIcon = true,
    this.showCartIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: AppBar(
        backgroundColor: backgroundColor,
        title: CustomText(title),
        actions: [
          if (showHomeIcon)
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          if (showCartIcon)
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.pushNamed(context, '/cart');
              },
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
