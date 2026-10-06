import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'pp_button.dart';

/// Estado de erro amigável com retry opcional (Music Map — spec UX/UI KNL-2026-UX-MUSICMAP)
class PPErrorState extends StatelessWidget {
  const PPErrorState({
    super.key,
    this.title = 'Algo deu errado',
    this.message =
        'Não foi possível carregar os dados. Verifique sua conexão e tente de novo.',
    this.debugDetails,
    this.onRetry,
    this.retryLabel = 'Tentar novamente',
  });

  final String title;
  final String message;
  // Os call sites ainda passam o detalhe. A tela mostra só a frase em português.
  // ignore: unused_field
  final String? debugDetails;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              PPButton(
                label: retryLabel,
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                variant: PPButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
