

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class SeverityBadge extends StatelessWidget {
  final String severity;
  final bool   compact;

  const SeverityBadge({super.key, required this.severity, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.severityColor(severity);
    final icon  = AppTheme.severityIcon(severity);
    final label = severity == 'None' ? 'Healthy' : severity;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical:   compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 16, color: color),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}