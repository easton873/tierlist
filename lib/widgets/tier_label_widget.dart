import 'package:flutter/material.dart';

class TierLabelWidget extends StatelessWidget {
  final String label;
  final Color color;
  final double size;

  const TierLabelWidget({
    super.key,
    required this.label,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      color: color,
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
          color: Colors.black,
        ),
      ),
    );
  }
}
