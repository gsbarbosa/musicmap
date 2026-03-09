import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_badge.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_logo.dart';

/// Landing page - ponto de entrada para novos visitantes
class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalProfileCountProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(context, ref, totalAsync),
            _buildWhatIs(context),
            _buildBenefits(context),
            _buildCta(context, totalAsync),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, WidgetRef ref, AsyncValue<int> totalAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: PageContainer(
        centered: true,
        maxWidth: 700,
        child: Column(
          children: [
            const PPLogo(showTagline: true, fontSize: 48),
            const SizedBox(height: 32),
            totalAsync.when(
              data: (total) => _buildVagasCounter(context, total),
              loading: () => _buildVagasCounter(context, null),
              error: (_, __) => _buildVagasCounter(context, null),
            ),
            const SizedBox(height: 32),
            Text(
              'Entre agora para a base inicial do ${AppConstants.appName}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cadastre sua banda ou projeto musical e garanta acesso antecipado '
              'ao mapa da cena musical. Estamos preparando novas funcionalidades '
              'para conectar artistas, bandas e oportunidades.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 40),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 400;
                final atLimit = totalAsync.valueOrNull != null && _isAtLimit(totalAsync.valueOrNull);
                return isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PPButton(
                            label: atLimit ? 'Vagas esgotadas' : 'Criar perfil',
                            icon: Icons.person_add_rounded,
                            onPressed: atLimit ? null : () => context.go('/register'),
                            variant: PPButtonVariant.primary,
                            fullWidth: true,
                          ),
                          const SizedBox(height: 12),
                          PPButton(label: 'Entrar', onPressed: () => context.go('/login'), variant: PPButtonVariant.outline, fullWidth: true),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PPButton(
                            label: atLimit ? 'Vagas esgotadas' : 'Criar perfil',
                            icon: Icons.person_add_rounded,
                            onPressed: atLimit ? null : () => context.go('/register'),
                            variant: PPButtonVariant.primary,
                            fullWidth: false,
                          ),
                          const SizedBox(width: 16),
                          PPButton(label: 'Entrar', onPressed: () => context.go('/login'), variant: PPButtonVariant.outline, fullWidth: false),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isAtLimit(int? total) {
    final realCount = total ?? 0;
    final count = AppConstants.earlyAccessReserved + realCount;
    return count >= AppConstants.earlyAccessLimit;
  }

  Widget _buildVagasCounter(BuildContext context, int? total) {
    final realCount = total ?? 0;
    final count = AppConstants.earlyAccessReserved + realCount;
    final limit = AppConstants.earlyAccessLimit;
    final remaining = (limit - count).clamp(0, limit);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            'Apenas $limit vagas para o pré-lançamento',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                ' / $limit',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(width: 12),
              Text(
                '• $remaining vagas restantes',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatIs(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      color: AppColors.surface.withOpacity(0.5),
      child: PageContainer(
        centered: true,
        maxWidth: 600,
        child: Column(
          children: [
            Text(
              'O que é o Music Map?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Uma plataforma para mapear e conectar a cena musical independente. '
              'Artistas e bandas se cadastram, garantem acesso antecipado e fazem '
              'parte da base que vai alimentar o mapa da cena.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefits(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: PageContainer(
        centered: true,
        maxWidth: 800,
        child: Column(
          children: [
            Text(
              'Por que garantir acesso antecipado?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _benefitCard(context, 'Primeiro no mapa', 'Seu perfil será priorizado quando o mapa público for lançado.'),
                _benefitCard(context, 'Novas funcionalidades', 'Acesso antecipado a buscas, descobertas e conexões.'),
                _benefitCard(context, 'Cena musical', 'Faça parte da base que conecta artistas e oportunidades.'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefitCard(BuildContext context, String title, String text) {
    return SizedBox(
      width: 220,
      child: PPCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PPBadge(label: title, variant: PPBadgeVariant.primary),
            const SizedBox(height: 12),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            GestureDetector(
              onTap: () => context.go('/terms'),
              child: Text(
                'Termos de Uso',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
            Text(
              '•',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            GestureDetector(
              onTap: () => context.go('/privacy'),
              child: Text(
                'Política de Privacidade',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCta(BuildContext context, AsyncValue<int> totalAsync) {
    final atLimit = totalAsync.valueOrNull != null && _isAtLimit(totalAsync.valueOrNull);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: PageContainer(
        centered: true,
        maxWidth: 500,
        child: Column(
          children: [
            const PPLogo(showTagline: false, fontSize: 36),
            const SizedBox(height: 24),
            Text(
              atLimit ? 'Vagas esgotadas' : 'Garanta seu acesso antecipado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            PPButton(
              label: atLimit ? 'Vagas esgotadas' : 'Criar perfil',
              icon: Icons.arrow_forward_rounded,
              onPressed: atLimit ? null : () => context.go('/register'),
              variant: PPButtonVariant.primary,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
