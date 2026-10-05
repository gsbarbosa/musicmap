import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../../shared/models/gigbag_checklist.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../../../shared/widgets/workspace_page_scaffold.dart';

String _gigbagTypeLabel(String t) {
  switch (t) {
    case GigBagChecklist.typeShow:
      return 'Show';
    case GigBagChecklist.typeRehearsal:
      return 'Ensaio';
    case GigBagChecklist.typeRecording:
      return 'Gravação';
    case GigBagChecklist.typeTravel:
      return 'Viagem';
    default:
      return t;
  }
}

class GigbagPage extends ConsumerWidget {
  final String profileId;

  const GigbagPage({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Faça login')));
    }
    final profilesAsync = ref.watch(userProfilesProvider(user.uid));
    return profilesAsync.when(
      data: (profiles) {
        UserProfile? profile;
        for (final p in profiles) {
          if (p.id == profileId) {
            profile = p;
            break;
          }
        }
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('GigBag')),
            body: const Center(child: Text('Perfil não encontrado')),
          );
        }
        return _GigbagBody(profile: profile);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('GigBag')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('GigBag')),
        body: Center(
          child: PPErrorState(
            debugDetails: e.toString(),
            onRetry: () => ref.invalidate(userProfilesProvider(user.uid)),
          ),
        ),
      ),
    );
  }
}

class _GigbagBody extends ConsumerWidget {
  final UserProfile profile;

  const _GigbagBody({required this.profile});

  Future<void> _newChecklist(BuildContext context, WidgetRef ref) async {
    final svc = ref.read(artistWorkspaceServiceProvider);
    final titleCtrl = TextEditingController();
    var type = GigBagChecklist.typeShow;
    var isTemplate = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Nova checklist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Nome da checklist'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: [
                  GigBagChecklist.typeShow,
                  GigBagChecklist.typeRehearsal,
                  GigBagChecklist.typeRecording,
                  GigBagChecklist.typeTravel,
                ]
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(_gigbagTypeLabel(t)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSt(() => type = v ?? type),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Salvar como modelo'),
                value: isTemplate,
                onChanged: (v) => setSt(() => isTemplate = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Criar')),
          ],
        ),
      ),
    );

    if (ok != true || !context.mounted) return;
    if (titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um nome')),
      );
      return;
    }

    final c = GigBagChecklist(
      id: '',
      profileId: profile.id,
      title: titleCtrl.text.trim(),
      type: type,
      isTemplate: isTemplate,
      items: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      final id = await svc.saveChecklist(c);
      if (context.mounted) {
        context.push('/gigbag/${profile.id}/checklist/$id');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível salvar.${userFacingErrorSuffix(e)}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gigbagStreamProvider(profile.id));
    final canWrite = ref.watch(workspaceCanWriteProvider(profile.id)).valueOrNull ?? false;

    return WorkspacePageScaffold(
      title: 'GigBag — checklists de palco e estrada',
      subtitle: profile.artistName,
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () => _newChecklist(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova checklist'),
            )
          : null,
      body: PageContainer(
        maxWidth: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Show, ensaio, viagem ou gravação — itens persistem até você limpar na checklist.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 24),
            async.when(
                data: (list) {
                  if (list.isEmpty) {
                    return PPCard(
                      child: Text(
                        'Nenhuma checklist. Crie uma para show, ensaio, viagem ou gravação.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    );
                  }
                  return Column(
                    children: list.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PPCard(
                          onTap: () => context.push(
                            '/gigbag/${profile.id}/checklist/${c.id}',
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.title,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _gigbagTypeLabel(c.type),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    if (c.linkedShowId != null && c.linkedShowId!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Vinculada a um compromisso na agenda',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    if (c.isTemplate)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Chip(
                                          label: const Text('Modelo'),
                                          visualDensity: VisualDensity.compact,
                                          side: BorderSide(color: AppColors.border),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => PPErrorState(
                  title: 'GigBag indisponível',
                  message: 'Não foi possível carregar as checklists.',
                  debugDetails: e.toString(),
                  onRetry: () =>
                      ref.invalidate(gigbagStreamProvider(profile.id)),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
