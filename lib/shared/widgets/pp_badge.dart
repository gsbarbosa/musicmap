import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum PPBadgeVariant { primary, secondary, success }

/// Badge reutilizável do Palace Pulse
class PPBadge extends StatelessWidget {
  final String label;
  final PPBadgeVariant variant;

  const PPBadge({
    super.key,
    required this.label,
    this.variant = PPBadgeVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _backgroundColor.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _backgroundColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color get _backgroundColor {
    switch (variant) {
      case PPBadgeVariant.primary:
        return AppColors.primary;
      case PPBadgeVariant.secondary:
        return AppColors.secondary;
      case PPBadgeVariant.success:
        return AppColors.success;
    }
  }
}
