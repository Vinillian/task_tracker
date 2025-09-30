import 'package:flutter/material.dart';

class NestingIndicator extends StatelessWidget {
  final int level;
  final double size;

  const NestingIndicator({
    Key? key,
    required this.level,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForLevel(level);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        border: Border.all(
          color: colors.borderColor,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          '${level + 1}',
          style: TextStyle(
            color: colors.textColor,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  _LevelColors _getColorsForLevel(int level) {
    switch (level) {
      case 0:
        return _LevelColors(
          backgroundColor: Colors.blue.shade50,
          borderColor: Colors.blue,
          textColor: Colors.blue.shade800,
        );
      case 1:
        return _LevelColors(
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green,
          textColor: Colors.green.shade800,
        );
      case 2:
        return _LevelColors(
          backgroundColor: Colors.orange.shade50,
          borderColor: Colors.orange,
          textColor: Colors.orange.shade800,
        );
      default:
        return _LevelColors(
          backgroundColor: Colors.grey.shade50,
          borderColor: Colors.grey,
          textColor: Colors.grey.shade800,
        );
    }
  }
}

class _LevelColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  _LevelColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}