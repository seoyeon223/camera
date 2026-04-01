import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum RiskLevel {
  low,
  medium,
  high,
}

class RiskBadge extends StatelessWidget {
  final RiskLevel level;

  const RiskBadge({
    super.key,
    required this.level,
  });

  Color get backgroundColor {
    switch (level) {
      case RiskLevel.low:
        return AppColors.safe.withValues(alpha: 0.12);
      case RiskLevel.medium:
        return AppColors.warning.withValues(alpha: 0.12);
      case RiskLevel.high:
        return AppColors.danger.withValues(alpha: 0.12);
    }
  }

  Color get textColor {
    switch (level) {
      case RiskLevel.low:
        return AppColors.safe;
      case RiskLevel.medium:
        return AppColors.warning;
      case RiskLevel.high:
        return AppColors.danger;
    }
  }

  String get label {
    switch (level) {
      case RiskLevel.low:
        return '낮음';
      case RiskLevel.medium:
        return '보통';
      case RiskLevel.high:
        return '높음';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}