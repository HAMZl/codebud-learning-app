import 'package:flutter/material.dart';

class IconMapper {
  static const Map<String, Map<String, dynamic>> _map = {
    'Up': {'icon': Icons.arrow_upward, 'label': 'Up'},
    'Down': {'icon': Icons.arrow_downward, 'label': 'Down'},
    'Left': {'icon': Icons.arrow_back, 'label': 'Left'},
    'Right': {'icon': Icons.arrow_forward, 'label': 'Right'},
    'Loop': {'icon': Icons.loop, 'label': 'Loop'},
  };

  static IconData getIcon(String type) {
    return _map[type]?['icon'] ?? Icons.help;
  }

  static String getLabel(String type) {
    return _map[type]?['label'] ?? type;
  }

  static Map<String, dynamic> getIconAndLabel(String type) {
    return {'icon': getIcon(type), 'label': getLabel(type)};
  }
}
