import 'package:flutter/material.dart';

class TierLabelWidget extends StatelessWidget {
  final String label;
  final Color color;
  final double size;
  final VoidCallback? onTap;
  final double? fontSize;

  const TierLabelWidget({
    super.key,
    required this.label,
    required this.color,
    required this.size,
    this.onTap,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    Widget box = Container(
      width: size,
      color: color,
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w300,
          fontSize: fontSize ?? size * 0.4,
          color: Colors.black,
        ),
      ),
    );

    if (onTap != null) {
      box = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: box),
      );
    }

    return box;
  }
}
