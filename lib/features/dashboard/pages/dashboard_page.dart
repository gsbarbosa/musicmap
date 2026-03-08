import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../shared/models/user_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_badge.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_logo.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = user != null ? ref.watch(userProfileProvider(user.uid)) : null;

    return profileAsync?.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('Carregando perfil...')),
          );
        }
        return _DashboardContent(profile: profile, userEmail: user?.email ?? '');
      },
      loading: () => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Carregando...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erro: $e')),
      ),
    ) ?? const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final UserProfile profile;
  final String userEmail;

  const _DashboardContent({
    required this.profile,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildMainContent(context),
            _buildStatusCard(context),
            _buildProfileSummary(context),
            _buildActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: PageContainer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const PPLogo(showTagline: false, fontSize: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: PageContainer(
        maxWidth: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PPBadge(label: 'Early Access', variant: PPBadgeVariant.primary),
            const SizedBox(height: 24),
            Text(
              profile.artistName,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 24),
            Text(
              'Seu acesso antecipado está garantido',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Você já faz parte da base inicial do Palace Pulse e entrou no mapa da cena independente. '
              'Estamos construindo as próximas funcionalidades da plataforma para conectar artistas, bandas e oportunidades. '
              'Novidades em breve.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: PageContainer(
        maxWidth: 600,
        child: PPCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  _statusItem(context, 'Status', 'Ativo', AppColors.success),
                  _statusItem(context, 'Fase', 'Acesso antecipado', AppColors.primary),
                  _statusItem(context, 'Mapa', 'Confirmado', AppColors.secondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusItem(BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildProfileSummary(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: PageContainer(
        maxWidth: 600,
        child: PPCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumo do perfil',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _summaryRow('Tipo', profile.artistType),
              _summaryRow('Cidade', '${profile.city} - ${profile.state}'),
              _summaryRow('Gênero', profile.genre),
              _summaryRow('Instagram', profile.instagram),
              _summaryRow('Contato', profile.contact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: PageContainer(
        maxWidth: 600,
        child: Row(
          children: [
            Expanded(
              child: PPButton(
                label: 'Editar perfil',
                icon: Icons.edit_rounded,
                onPressed: () => context.push('/edit-profile'),
                variant: PPButtonVariant.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PPButton(
                label: 'Sair',
                icon: Icons.logout_rounded,
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/');
                },
                variant: PPButtonVariant.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
