import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../../shared/models/music_release.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../../../shared/widgets/pp_input.dart';
import '../../../shared/widgets/workspace_page_scaffold.dart';

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _releaseTypeLabel(String t) {
  switch (t) {
    case MusicRelease.typeSingle:
      return 'Single';
    case MusicRelease.typeEp:
      return 'EP';
    case MusicRelease.typeAlbum:
      return 'Álbum';
    default:
      return t;
  }
}

String _releaseStatusLabel(String s) {
  switch (s) {
    case MusicRelease.statusPlanning:
      return 'Planejamento';
    case MusicRelease.statusInProgress:
      return 'Em andamento';
    case MusicRelease.statusReleased:
      return 'Lançado';
    case MusicRelease.statusCancelled:
      return 'Cancelado';
    default:
      return s;
  }
}

String _milestoneLabel(String key) {
  switch (key) {
    case MusicRelease.milestoneCover:
      return 'Capa pronta';
    case MusicRelease.milestoneDistribution:
      return 'Distribuição enviada';
    case MusicRelease.milestoneTeaser:
      return 'Teaser/post agendado';
    case MusicRelease.milestonePress:
      return 'Press release';
    case MusicRelease.milestonePromotion:
      return 'Divulgação concluída';
    default:
      return key;
  }
}

class ReleasesPage extends ConsumerWidget {
  final String profileId;

  const ReleasesPage({super.key, required this.profileId});

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
            appBar: AppBar(title: const Text('Lançamentos')),
            body: const Center(child: Text('Perfil não encontrado')),
          );
        }
        return _ReleasesBody(profile: profile);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Lançamentos')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Lançamentos')),
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

class _ReleasesBody extends ConsumerWidget {
  final UserProfile profile;

  const _ReleasesBody({required this.profile});

  Map<String, bool> _defaultMilestones() {
    return {
      MusicRelease.milestoneCover: false,
      MusicRelease.milestoneDistribution: false,
      MusicRelease.milestoneTeaser: false,
      MusicRelease.milestonePress: false,
      MusicRelease.milestonePromotion: false,
    };
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    MusicRelease? existing,
  ) async {
    final svc = ref.read(artistWorkspaceServiceProvider);
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var type = existing?.type ?? MusicRelease.typeSingle;
    var status = existing?.status ?? MusicRelease.statusPlanning;
    var date = existing?.releaseDate ?? DateTime.now();
    final milestones = _defaultMilestones();
    if (existing != null) {
      for (final e in existing.milestones.entries) {
        milestones[e.key] = e.value;
      }
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(existing == null ? 'Novo lançamento' : 'Editar lançamento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PPInput(label: 'Nome do projeto', controller: titleCtrl),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: [
                    MusicRelease.typeSingle,
                    MusicRelease.typeEp,
                    MusicRelease.typeAlbum,
                  ]
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(_releaseTypeLabel(t)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setSt(() => type = v ?? type),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data de lançamento'),
                  subtitle: Text(_formatDate(date)),
                  trailing: const Icon(Icons.calendar_today_rounded),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setSt(() => date = picked);
                  },
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    MusicRelease.statusPlanning,
                    MusicRelease.statusInProgress,
                    MusicRelease.statusReleased,
                    MusicRelease.statusCancelled,
                  ]
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(_releaseStatusLabel(s)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setSt(() => status = v ?? status),
                ),
                PPInput(label: 'Observações', controller: notesCtrl, maxLines: 3),
                const SizedBox(height: 12),
                Text(
                  'Marcos (opcional)',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                ...milestones.keys.map((k) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_milestoneLabel(k)),
                    value: milestones[k] ?? false,
                    onChanged: (v) => setSt(() => milestones[k] = v ?? false),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
          ],
        ),
      ),
    );

    if (ok != true || !context.mounted) return;
    if (titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do projeto')),
      );
      return;
    }

    final r = MusicRelease(
      id: existing?.id ?? '',
      profileId: profile.id,
      title: titleCtrl.text.trim(),
      type: type,
      releaseDate: date,
      status: status,
      notes: notesCtrl.text.trim(),
      milestones: milestones,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      await svc.saveRelease(r);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lançamento salvo')),
        );
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
    final async = ref.watch(releasesStreamProvider(profile.id));
    final canWrite = ref.watch(workspaceCanWriteProvider(profile.id)).valueOrNull ?? false;

    return WorkspacePageScaffold(
      title: 'Planejar lançamentos',
      subtitle: profile.artistName,
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(context, ref, null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo lançamento'),
            )
          : null,
      body: PageContainer(
        maxWidth: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Datas, status e marcos para equipe e divulgação. Histórico preservado.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 24),
            async.when(
                data: (releases) {
                  if (releases.isEmpty) {
                    return PPCard(
                      child: Text(
                        'Nenhum lançamento cadastrado.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    );
                  }
                  final upcoming = releases.where((r) => !r.isPastReleased).toList();
                  final past = releases.where((r) => r.isPastReleased).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Próximos e em andamento',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (upcoming.isEmpty)
                        Text(
                          'Nada nesta lista.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        )
                      else
                        ...upcoming.map((r) => _ReleaseTile(
                              release: r,
                              canWrite: canWrite,
                              onEdit: () => _openEditor(context, ref, r),
                              onDelete: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Excluir lançamento?'),
                                    content: const Text('Esta ação não pode ser desfeita.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  await ref
                                      .read(artistWorkspaceServiceProvider)
                                      .deleteRelease(profile.id, r.id);
                                }
                              },
                            )),
                      const SizedBox(height: 28),
                      Text(
                        'Histórico (data passada)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (past.isEmpty)
                        Text(
                          'Nenhum lançamento passado.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        )
                      else
                        ...past.map((r) => _ReleaseTile(
                              release: r,
                              canWrite: canWrite,
                              onEdit: () => _openEditor(context, ref, r),
                              onDelete: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Excluir lançamento?'),
                                    content: const Text('Esta ação não pode ser desfeita.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  await ref
                                      .read(artistWorkspaceServiceProvider)
                                      .deleteRelease(profile.id, r.id);
                                }
                              },
                            )),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => PPErrorState(
                  title: 'Lançamentos indisponíveis',
                  message: 'Não foi possível carregar os lançamentos.',
                  debugDetails: e.toString(),
                  onRetry: () =>
                      ref.invalidate(releasesStreamProvider(profile.id)),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _ReleaseTile extends StatelessWidget {
  final MusicRelease release;
  final bool canWrite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReleaseTile({
    required this.release,
    required this.canWrite,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final doneCount = release.milestones.values.where((v) => v).length;
    final total = release.milestones.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PPCard(
        onTap: canWrite ? onEdit : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    release.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (canWrite)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${_releaseTypeLabel(release.type)} · ${_formatDate(release.releaseDate)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(_releaseStatusLabel(release.status)),
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: AppColors.border),
            ),
            if (total > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Marcos: $doneCount / $total',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
