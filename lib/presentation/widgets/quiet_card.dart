import 'package:flutter/material.dart';

class QuietCard extends StatelessWidget {
  final Widget child;
  final Color color;

  const QuietCard({super.key, required this.child, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}
