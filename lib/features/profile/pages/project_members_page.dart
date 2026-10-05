import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/share_url.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../../shared/models/profile_member.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../../../shared/widgets/workspace_page_scaffold.dart';

String _roleLabel(String r) {
  switch (r) {
    case AppConstants.roleAdmin:
      return 'Administrador';
    case AppConstants.roleEditor:
      return 'Editor';
    case AppConstants.roleViewer:
      return 'Somente leitura';
    default:
      return r;
  }
}

class ProjectMembersPage extends ConsumerWidget {
  final String profileId;

  const ProjectMembersPage({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Faça login')));
    }

    final profileAsync = ref.watch(userProfileProvider(profileId));
    final canManageAsync = ref.watch(profileWorkspaceRoleProvider(profileId));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Integrantes')),
            body: const Center(child: Text('Projeto não encontrado')),
          );
        }
        return canManageAsync.when(
          data: (role) {
            final canManage = role == 'owner' || role == AppConstants.roleAdmin;
            return _ProjectMembersBody(
              profile: profile,
              currentUid: user.uid,
              canManage: canManage,
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            body: Center(child: PPErrorState(debugDetails: e.toString())),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: PPErrorState(
            debugDetails: e.toString(),
            onRetry: () => ref.invalidate(userProfileProvider(profileId)),
          ),
        ),
      ),
    );
  }
}

class _ProjectMembersBody extends ConsumerStatefulWidget {
  final UserProfile profile;
  final String currentUid;
  final bool canManage;

  const _ProjectMembersBody({
    required this.profile,
    required this.currentUid,
    required this.canManage,
  });

  @override
  ConsumerState<_ProjectMembersBody> createState() => _ProjectMembersBodyState();
}

class _ProjectMembersBodyState extends ConsumerState<_ProjectMembersBody> {
  String _inviteRole = AppConstants.roleEditor;
  bool _creatingInvite = false;

  Future<void> _createInvite() async {
    setState(() => _creatingInvite = true);
    try {
      final token = await ref.read(profileServiceProvider).createProfileInvite(
            widget.profile.id,
            role: _inviteRole,
          );
      if (!mounted) return;
      final link = projectInviteUrl(token);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Link do convite'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Envie este link. Quem abrir entra na banda com a própria conta, sem cadastrar outro perfil.',
              ),
              const SizedBox(height: 12),
              SelectableText(
                link,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: link));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copiado')),
                );
              },
              child: const Text('Copiar link'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar convite.${userFacingErrorSuffix(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingInvite = false);
    }
  }

  Future<void> _removeMember(ProfileMemberEntry m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover integrante?'),
        content: Text('UID: ${m.userId}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(profileServiceProvider).removeMemberFromProfile(widget.profile.id, m.userId);
      ref.invalidate(userProfilesProvider(FirebaseAuth.instance.currentUser!.uid));
      ref.invalidate(profileMembersMapProvider(widget.profile.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Integrante removido')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível remover.${userFacingErrorSuffix(e)}')),
        );
      }
    }
  }

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair deste projeto?'),
        content: const Text('Você perde acesso à agenda e ao GigBag desta banda até receber novo convite.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sair')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(profileServiceProvider).leaveSharedProject(widget.profile.id);
      ref.invalidate(userProfilesProvider(FirebaseAuth.instance.currentUser!.uid));
      if (mounted) {
        context.go('/perfil');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você saiu do projeto')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(profileMembersMapProvider(widget.profile.id));
    final isOwner = widget.profile.ownerUserId == widget.currentUid;

    return membersAsync.when(
      data: (members) {
        return WorkspacePageScaffold(
          title: 'Integrantes',
          subtitle: widget.profile.artistName,
          leading: IconButton.filledTonal(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Voltar',
          ),
          body: PageContainer(
            maxWidth: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PPCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dono do projeto',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conta vinculada ao cadastro original (responsável pelo projeto).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'UID: ${widget.profile.ownerUserId}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Membros (${members.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (members.isEmpty)
                  Text(
                    'Nenhum integrante convidado ainda.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  )
                else
                  ...members.values.map((m) {
                    final self = m.userId == widget.currentUid;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PPCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    self ? 'Você' : 'Integrante',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  Text(
                                    '${m.userId} · ${_roleLabel(m.role)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.canManage && !self && m.userId != widget.profile.ownerUserId)
                              IconButton(
                                icon: const Icon(Icons.person_remove_rounded),
                                tooltip: 'Remover',
                                onPressed: () => _removeMember(m),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                if (widget.canManage) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Novo convite',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'O link abre direto o convite. A pessoa entra com Google ou email e já participa da banda.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: _inviteRole,
                    decoration: const InputDecoration(labelText: 'Papel do convidado'),
                    items: [
                      DropdownMenuItem(
                        value: AppConstants.roleEditor,
                        child: Text(_roleLabel(AppConstants.roleEditor)),
                      ),
                      DropdownMenuItem(
                        value: AppConstants.roleAdmin,
                        child: Text(_roleLabel(AppConstants.roleAdmin)),
                      ),
                      DropdownMenuItem(
                        value: AppConstants.roleViewer,
                        child: Text(_roleLabel(AppConstants.roleViewer)),
                      ),
                    ],
                    onChanged: _creatingInvite
                        ? null
                        : (v) => setState(() => _inviteRole = v ?? AppConstants.roleEditor),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PPButton(
                    label: 'Gerar link de convite',
                    icon: Icons.add_link_rounded,
                    onPressed: _creatingInvite ? null : _createInvite,
                    isLoading: _creatingInvite,
                    fullWidth: true,
                  ),
                ],
                if (!isOwner && widget.profile.ownerUserId != widget.currentUid) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  OutlinedButton.icon(
                    onPressed: _leave,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sair deste projeto'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => WorkspacePageScaffold(
        title: 'Integrantes',
        subtitle: widget.profile.artistName,
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Voltar',
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => WorkspacePageScaffold(
        title: 'Integrantes',
        subtitle: widget.profile.artistName,
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Voltar',
        ),
        body: Center(
          child: PPErrorState(
            debugDetails: e.toString(),
            onRetry: () => ref.invalidate(profileMembersMapProvider(widget.profile.id)),
          ),
        ),
      ),
    );
  }
}
