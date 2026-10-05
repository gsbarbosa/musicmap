import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';

/// Card de módulo — remodelagem visual (borda gradiente + hierarquia forte)
class FeatureHubCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool comingSoon;
  final VoidCallback? onTap;
  /// Etapa na jornada (1–4) nos módulos ativos da central
  final int? journeyStep;

  const FeatureHubCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.comingSoon = false,
    this.onTap,
    this.journeyStep,
  });

  void _onComingSoonTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title — disponível em breve no ${AppConstants.appName}.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = onTap ??
        (comingSoon ? () => _onComingSoonTap(context) : null);

    final inner = Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: effectiveOnTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (journeyStep != null) ...[
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        '$journeyStep',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: comingSoon
                          ? null
                          : LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.2),
                                AppColors.secondary.withValues(alpha: 0.15),
                              ],
                            ),
                      color: comingSoon
                          ? AppColors.surfaceSecondary
                          : null,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      icon,
                      color: comingSoon ? AppColors.textSecondary : AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: comingSoon ? AppColors.textSecondary : null,
                              ),
                        ),
                        if (comingSoon)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                'Em breve',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget card = comingSoon
        ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg + 1),
              border: Border.all(color: AppColors.border),
            ),
            child: inner,
          )
        : Container(
            decoration: BoxDecoration(
              gradient: AppGradients.moduleCardBorder,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg + 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(1.5),
            child: inner,
          );

    return Semantics(
      button: true,
      enabled: true,
      label: comingSoon ? '$title, em breve' : title,
      hint: comingSoon
          ? 'Toque para ver mensagem sobre disponibilidade futura'
          : 'Abrir módulo',
      child: Tooltip(
        message: comingSoon
            ? 'Recurso em desenvolvimento — disponível em breve.'
            : 'Abrir $title',
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: comingSoon ? 0.82 : 1,
          child: card,
        ),
      ),
    );
  }
}
