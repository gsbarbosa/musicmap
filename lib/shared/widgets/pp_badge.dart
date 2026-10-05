import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum PPBadgeVariant { primary, secondary, success }

/// Badge reutilizável do Music Map
class PPBadge extends StatelessWidget {
  final String label;
  final PPBadgeVariant variant;

  /// Pill menor (ex.: hero da Central).
  final bool compact;

  const PPBadge({
    super.key,
    required this.label,
    this.variant = PPBadgeVariant.primary,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 0)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    final radius = compact ? 6.0 : 20.0;
    final fontSize = compact ? 8.0 : 12.0;
    final letter = compact ? 0.08 : 0.5;
    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: _backgroundColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _backgroundColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _backgroundColor,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
          letterSpacing: letter,
          height: compact ? 1.05 : null,
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
