import 'package:flutter/material.dart';

import 'custom_text.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double height;
  final Color? backgroundColor;

  const CommonAppBar({
    super.key,
    required this.title,
    this.height = 40.0,
    this.backgroundColor = const Color(0xFFFFF8E1),
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: AppBar(
        backgroundColor: backgroundColor,
        title: CustomText(title),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
