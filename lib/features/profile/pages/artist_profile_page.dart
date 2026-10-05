import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_badge.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../../../shared/widgets/workspace_page_scaffold.dart';
import '../../dashboard/widgets/brazil_map_widget.dart';
import '../../dashboard/widgets/dashboard_gamification.dart';

/// Página "Meu espaço" — visão geral, progresso, links públicos, resumo e conta
class ArtistProfilePage extends ConsumerWidget {
  const ArtistProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profilesAsync = user != null ? ref.watch(userProfilesProvider(user.uid)) : null;

    return profilesAsync?.when(
      data: (profiles) {
        if (profiles.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Meu perfil')),
            body: Center(
              child: PageContainer(
                maxWidth: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nenhum projeto ainda',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Entre com o convite da banda ou crie o seu próprio projeto.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    PPButton(
                      label: 'Entrar com convite',
                      icon: Icons.group_add_rounded,
                      onPressed: () => context.push('/join-project'),
                      fullWidth: true,
                    ),
                    const SizedBox(height: 12),
                    PPButton(
                      label: 'Criar meu projeto',
                      onPressed: () => context.push('/complete-profile'),
                      variant: PPButtonVariant.outline,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return _ArtistProfileBody(userId: user!.uid, profiles: profiles);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Meu perfil')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Meu perfil')),
        body: Center(
          child: user != null
              ? PPErrorState(
                  debugDetails: e.toString(),
                  onRetry: () => ref.invalidate(userProfilesProvider(user.uid)),
                )
              : PPErrorState(debugDetails: e.toString()),
        ),
      ),
    ) ??
        const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
  }
}

class _ArtistProfileBody extends ConsumerStatefulWidget {
  final String userId;
  final List<UserProfile> profiles;

  const _ArtistProfileBody({required this.userId, required this.profiles});

  @override
  ConsumerState<_ArtistProfileBody> createState() => _ArtistProfileBodyState();
}

class _ArtistProfileBodyState extends ConsumerState<_ArtistProfileBody> {
  int _selectedIndex = 0;

  UserProfile get _selectedProfile => widget.profiles[_selectedIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncId = ref.read(dashboardWorkspaceProfileIdProvider);
      if (!mounted || syncId == null) return;
      final i = widget.profiles.indexWhere((p) => p.id == syncId);
      if (i >= 0 && i != _selectedIndex) {
        setState(() => _selectedIndex = i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WorkspacePageScaffold(
      title: 'Meu espaço no hub',
      subtitle: 'Visão geral, progresso, página pública e conta',
      body: Column(
        children: [
          if (widget.profiles.length > 1) _buildProfileSelector(context),
          _buildMainContent(context),
          _buildMapSection(context, ref),
          _buildGamification(context),
          _buildStatusCard(context),
          _buildProfileSummary(context),
          _buildAccountSection(context, ref),
          _buildActions(context, ref),
        ],
      ),
    );
  }

  Widget _buildGamification(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: PageContainer(
        maxWidth: 600,
        child: ProfileGamificationSection(profile: _selectedProfile),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: PageContainer(
        maxWidth: 600,
        child: PPCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Conta',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Desativar oculta seus perfis da página pública. Excluir remove dados e encerra a conta.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _confirmDeactivate(context, ref),
                child: const Text('Desativar conta'),
              ),
              TextButton(
                onPressed: () => _confirmDelete(context, ref),
                child: const Text(
                  'Excluir conta',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar conta'),
        content: const Text(
          'Seus perfis ficam inativos e deixam de aparecer na página pública. '
          'Você será desconectado.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desativar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(profileServiceProvider).deactivateUserAccount(widget.userId);
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) context.go('/');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível desativar.${userFacingErrorSuffix(e)}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text(
          'Esta ação remove seus perfis e dados da plataforma e encerra a sessão. Não dá para desfazer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(profileServiceProvider).deleteUserDatabaseData(widget.userId);
      await ref.read(authServiceProvider).deleteCurrentUser();
      if (context.mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      final msg = ref.read(authServiceProvider).getAuthErrorMessage(e.code);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg ?? e.message ?? 'Erro ao excluir')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível excluir a conta.${userFacingErrorSuffix(e)}',
            ),
          ),
        );
      }
    }
  }

  Widget _buildProfileSelector(BuildContext context) {
    final isBandAccount = ref.watch(userAccountTypeProvider(widget.userId)).valueOrNull == 'band';
    if (isBandAccount) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: PageContainer(
        maxWidth: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seus perfis',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(widget.profiles.length, (i) {
                final p = widget.profiles[i];
                final selected = _selectedIndex == i;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    ref.read(dashboardWorkspaceProfileIdProvider.notifier).state =
                        p.id;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      p.artistName,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w600 : null,
                        color: selected ? AppColors.primary : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                PPBadge(label: 'Early Access', variant: PPBadgeVariant.primary),
                PPBadge(label: 'Cena fundadora', variant: PPBadgeVariant.secondary),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _selectedProfile.artistName,
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
              'Você já faz parte da base inicial do Music Map — o hub onde sua operação musical se organiza. '
              'Estamos evoluindo a plataforma para conectar artistas, bandas e oportunidades. '
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

  Widget _buildMapSection(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(mapLocationCountsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: PageContainer(
        maxWidth: 700,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            countsAsync.when(
              data: (counts) => BrazilMapWidget(stateCounts: counts),
              loading: () => Container(
                height: 320,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
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
                  _statusItem(context, 'Hub', 'Ativo', AppColors.secondary),
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
    final profile = _selectedProfile;
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
    final canEditAsync = ref.watch(profileCanEditMetadataProvider(_selectedProfile.id));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: PageContainer(
        maxWidth: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            canEditAsync.when(
              data: (canEdit) {
                if (canEdit) {
                  return PPButton(
                    label: 'Editar perfil',
                    icon: Icons.edit_rounded,
                    onPressed: () => context.push('/edit-profile/${_selectedProfile.id}'),
                    variant: PPButtonVariant.primary,
                    fullWidth: true,
                  );
                }
                return OutlinedButton.icon(
                  onPressed: () => context.push('/edit-profile/${_selectedProfile.id}'),
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Ver dados do projeto'),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => OutlinedButton.icon(
                onPressed: () => context.push('/edit-profile/${_selectedProfile.id}'),
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Ver dados do projeto'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/project-members/${_selectedProfile.id}'),
              icon: const Icon(Icons.group_rounded),
              label: const Text('Integrantes'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/join-project'),
              icon: const Icon(Icons.vpn_key_rounded),
              label: const Text('Entrar com código de convite'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.dashboard_rounded),
              label: const Text('Voltar ao painel'),
            ),
          ],
        ),
      ),
    );
  }
}
