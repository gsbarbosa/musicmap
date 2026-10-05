import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gradientes da marca — identidade visual + contraste premium (Music Map)
class AppGradients {
  AppGradients._();

  /// Hero / topo de páginas autenticadas
  static const LinearGradient workspaceHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A2332),
      AppColors.backgroundPrimary,
      Color(0xFF151A12),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  /// Landing — aurora sutil (sem poluir legibilidade)
  static const LinearGradient landingAura = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1B2430),
      AppColors.backgroundPrimary,
      AppColors.backgroundPrimary,
    ],
    stops: [0.0, 0.35, 1.0],
  );

  /// Borda em cards de destaque (módulos)
  static LinearGradient moduleCardBorder = LinearGradient(
    colors: [
      AppColors.primary.withValues(alpha: 0.85),
      AppColors.secondary.withValues(alpha: 0.65),
    ],
  );

  static LinearGradient subtleGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primary.withValues(alpha: 0.08),
      Colors.transparent,
      AppColors.secondary.withValues(alpha: 0.06),
    ],
  );
}
