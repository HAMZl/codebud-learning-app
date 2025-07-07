import 'package:flutter/material.dart';

class IconMapper {
  static const Map<String, IconData> icons = {
    'Up': Icons.arrow_upward,
    'Down': Icons.arrow_downward,
    'Left': Icons.arrow_back,
    'Right': Icons.arrow_forward,
    'Loop': Icons.loop,
  };

  static IconData getIcon(String type) {
    return icons[type] ?? Icons.help;
  }
}
