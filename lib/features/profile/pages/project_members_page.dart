import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/band_role_label.dart';
import '../../../core/utils/share_url.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../../shared/models/person_card.dart';
import '../../../shared/models/profile_member.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_input.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../../../shared/widgets/workspace_page_scaffold.dart';

String _memberTitle({
  required bool self,
  PersonCard? person,
  String membershipName = '',
}) {
  final fromCard = person?.displayName.trim() ?? '';
  final fromMembership = membershipName.trim();
  final name = fromCard.isNotEmpty ? fromCard : fromMembership;
  if (name.isEmpty) {
    return self ? 'Você — complete sua ficha' : 'Nome ainda não definido';
  }
  return self ? '$name (você)' : name;
}

String _ownerLine(PersonCard? person, bool self) {
  final name = _memberTitle(self: self, person: person);
  final instruments = person?.instruments ?? const <String>[];
  if (instruments.isEmpty) return name;
  return '$name · ${instruments.join(', ')}';
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

  Future<void> _editMemberFicha(ProfileMemberEntry member, PersonCard? person) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _MemberFichaDialog(
        initialName: (person?.displayName.trim().isNotEmpty ?? false)
            ? person!.displayName
            : member.displayName,
        initialInstruments: (person != null && person.instruments.isNotEmpty)
            ? person.instruments
            : member.instruments,
        initialCity: (person?.city.trim().isNotEmpty ?? false) ? person!.city : member.city,
        initialState: (person?.state.trim().isNotEmpty ?? false) ? person!.state : member.state,
        onSave: (name, instruments, city, state) {
          return ref.read(profileServiceProvider).saveMemberFicha(
                profileId: widget.profile.id,
                memberUid: member.userId,
                displayName: name,
                instruments: instruments,
                city: city,
                state: state,
              );
        },
      ),
    );
    if (saved != true || !mounted) return;
    ref.invalidate(profileMembersMapProvider(widget.profile.id));
    ref.invalidate(projectPeopleProvider(widget.profile.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ficha do integrante salva')),
    );
  }

  Future<void> _removeMember(ProfileMemberEntry m, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover integrante?'),
        content: Text('$name sai da banda e perde o acesso à agenda.'),
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
          SnackBar(content: Text('Não foi possível sair da banda.${userFacingErrorSuffix(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(profileMembersMapProvider(widget.profile.id));
    final isOwner = widget.profile.ownerUserId == widget.currentUid;

    final people = ref.watch(projectPeopleProvider(widget.profile.id)).valueOrNull ??
        const <String, PersonCard>{};

    return membersAsync.when(
      data: (members) {
        final owner = people[widget.profile.ownerUserId];
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push('/eu'),
                    icon: const Icon(Icons.badge_outlined),
                    label: const Text('Minha ficha'),
                  ),
                ),
                PPCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ownerLine(owner, widget.profile.ownerUserId == widget.currentUid),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dono da banda',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
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
                    final person = people[m.userId];
                    final instruments = (person != null && person.instruments.isNotEmpty)
                        ? person.instruments
                        : m.instruments;
                    final title = _memberTitle(
                      self: self,
                      person: person,
                      membershipName: m.displayName,
                    );
                    final email = m.email.trim().isNotEmpty
                        ? m.email.trim()
                        : (self ? (FirebaseAuth.instance.currentUser?.email ?? '') : '');
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
                                    title,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  Text(
                                    instruments.isEmpty
                                        ? 'Instrumento ainda não definido'
                                        : instruments.join(', '),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  Text(
                                    email.isEmpty ? 'Email ainda não confirmado' : email,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  Text(
                                    bandRoleLabel(m.role),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.canManage && !self && m.userId != widget.profile.ownerUserId) ...[
                              IconButton(
                                icon: const Icon(Icons.edit_rounded),
                                tooltip: 'Preencher ficha',
                                onPressed: () => _editMemberFicha(m, person),
                              ),
                              IconButton(
                                icon: const Icon(Icons.person_remove_rounded),
                                tooltip: 'Remover',
                                onPressed: () => _removeMember(m, title),
                              ),
                            ],
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
                        child: Text(bandRoleLabel(AppConstants.roleEditor)),
                      ),
                      DropdownMenuItem(
                        value: AppConstants.roleAdmin,
                        child: Text(bandRoleLabel(AppConstants.roleAdmin)),
                      ),
                      DropdownMenuItem(
                        value: AppConstants.roleViewer,
                        child: Text(bandRoleLabel(AppConstants.roleViewer)),
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

class _MemberFichaDialog extends StatefulWidget {
  const _MemberFichaDialog({
    required this.initialName,
    required this.initialInstruments,
    required this.initialCity,
    required this.initialState,
    required this.onSave,
  });

  final String initialName;
  final List<String> initialInstruments;
  final String initialCity;
  final String initialState;
  final Future<void> Function(String name, List<String> instruments, String city, String state) onSave;

  @override
  State<_MemberFichaDialog> createState() => _MemberFichaDialogState();
}

class _MemberFichaDialogState extends State<_MemberFichaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.initialName);
  late final TextEditingController _city = TextEditingController(text: widget.initialCity);
  late final Set<String> _instruments = {...widget.initialInstruments};
  late String _state = widget.initialState;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_name.text, _instruments.toList(), _city.text, _state);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Não foi possível salvar a ficha.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ficha do integrante'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'A banda passa a ver esse nome. Se a pessoa preencher a própria ficha depois, a dela vale.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                PPInput(
                  label: 'Nome',
                  controller: _name,
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.length < 2) return 'Use pelo menos 2 caracteres';
                    if (name.length > 60) return 'Use no máximo 60 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final instrument in AppConstants.instrumentOptions)
                      FilterChip(
                        label: Text(instrument),
                        selected: _instruments.contains(instrument),
                        onSelected: _saving
                            ? null
                            : (selected) {
                                setState(() {
                                  if (selected) {
                                    _instruments.add(instrument);
                                  } else {
                                    _instruments.remove(instrument);
                                  }
                                });
                              },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                PPInput(label: 'Cidade (opcional)', controller: _city),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: _state.isEmpty ? '' : _state,
                  decoration: const InputDecoration(labelText: 'Estado (opcional)'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Não informar')),
                    ...AppConstants.brazilianStates.map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _state = v ?? ''),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}
