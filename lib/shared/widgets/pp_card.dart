import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Card reutilizável do Music Map
/// Cantos arredondados, fundo surface, borda discreta; toque com ripple (Material)
class PPCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? width;

  const PPCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final effectivePadding = padding ?? const EdgeInsets.all(24);

    final decorated = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );

    if (onTap == null) {
      return decorated;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: decorated,
      ),
    );
  }
}
