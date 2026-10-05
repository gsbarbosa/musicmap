import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../../shared/models/artist_show.dart';
import '../../../shared/models/gigbag_checklist.dart';
import '../../../shared/models/operational_task.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../widgets/artist_show_editor_dialog.dart';
import '../widgets/operational_task_editor_dialog.dart';

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

String _taskPriorityLabel(String p) {
  switch (p) {
    case OperationalTask.priorityHigh:
      return 'Alta';
    case OperationalTask.priorityLow:
      return 'Baixa';
    default:
      return 'Média';
  }
}

/// Hub do compromisso: resumo, GigBag vinculado e tarefas vinculadas.
class CommitmentDetailPage extends ConsumerStatefulWidget {
  const CommitmentDetailPage({
    super.key,
    required this.profileId,
    required this.showId,
  });

  final String profileId;
  final String showId;

  @override
  ConsumerState<CommitmentDetailPage> createState() => _CommitmentDetailPageState();
}

class _CommitmentDetailPageState extends ConsumerState<CommitmentDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteShow(
    BuildContext context,
    UserProfile profile,
    ArtistShow show,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir compromisso?'),
        content: const Text('Tarefas e checklists continuam no projeto (com vínculo a este evento, se já existia).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(artistWorkspaceServiceProvider).deleteShow(profile.id, show.id);
      if (context.mounted) context.go('/shows/${profile.id}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível excluir.${userFacingErrorSuffix(e)}')),
        );
      }
    }
  }

  Future<void> _addChecklistFromTemplate(
    BuildContext context,
    UserProfile profile,
    ArtistShow show,
    List<GigBagChecklist> templates,
  ) async {
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum modelo no GigBag. Crie um modelo na aba GigBag do hub.'),
        ),
      );
      return;
    }
    final picked = await showModalBottomSheet<GigBagChecklist>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Usar modelo',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...templates.map(
              (t) => ListTile(
                title: Text(t.title.isEmpty ? 'Modelo' : t.title),
                subtitle: Text(_gigbagTypeLabel(t.type)),
                onTap: () => Navigator.pop(ctx, t),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    try {
      final id = await ref.read(artistWorkspaceServiceProvider).duplicateChecklistForCommitment(
            source: picked,
            linkedShowId: show.id,
            title: '${picked.title} · ${show.title}',
          );
      if (context.mounted) {
        context.push('/gigbag/${profile.id}/checklist/$id');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível criar a lista.${userFacingErrorSuffix(e)}')),
        );
      }
    }
  }

  Future<void> _addEmptyChecklist(
    BuildContext context,
    UserProfile profile,
    ArtistShow show,
  ) async {
    final c = GigBagChecklist(
      id: '',
      profileId: profile.id,
      title: 'Checklist · ${show.title}',
      type: show.eventKind == ArtistShow.eventKindRehearsal
          ? GigBagChecklist.typeRehearsal
          : show.eventKind == ArtistShow.eventKindRecording
              ? GigBagChecklist.typeRecording
              : GigBagChecklist.typeShow,
      isTemplate: false,
      linkedShowId: show.id,
      items: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      final id = await ref.read(artistWorkspaceServiceProvider).saveChecklist(c);
      if (context.mounted) {
        context.push('/gigbag/${profile.id}/checklist/$id');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível criar.${userFacingErrorSuffix(e)}')),
        );
      }
    }
  }

  void _showAddChecklistSheet(
    BuildContext context,
    UserProfile profile,
    ArtistShow show,
    List<GigBagChecklist> allLists,
  ) {
    final templates = allLists.where((c) => c.isTemplate).toList();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_all_rounded),
              title: const Text('A partir de modelo'),
              subtitle: const Text('Copia itens do GigBag; fica vinculada a este compromisso'),
              onTap: () {
                Navigator.pop(ctx);
                _addChecklistFromTemplate(context, profile, show, templates);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: const Text('Lista vazia'),
              subtitle: const Text('Nova checklist só para este compromisso'),
              onTap: () {
                Navigator.pop(ctx);
                _addEmptyChecklist(context, profile, show);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Faça login')));
    }

    final profilesAsync = ref.watch(userProfilesProvider(user.uid));
    return profilesAsync.when(
      data: (profiles) {
        UserProfile? profile;
        for (final p in profiles) {
          if (p.id == widget.profileId) {
            profile = p;
            break;
          }
        }
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Compromisso')),
            body: const Center(child: Text('Perfil não encontrado')),
          );
        }
        final prof = profile;
        final canWrite =
            ref.watch(workspaceCanWriteProvider(prof.id)).valueOrNull ?? false;

        final showsAsync = ref.watch(showsStreamProvider(prof.id));
        final gigbagAsync = ref.watch(gigbagStreamProvider(prof.id));
        final tasksAsync = ref.watch(operationalTasksStreamProvider(prof.id));

        return showsAsync.when(
          data: (shows) {
            ArtistShow? show;
            for (final s in shows) {
              if (s.id == widget.showId) {
                show = s;
                break;
              }
            }
            if (show == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Compromisso')),
                body: Center(
                  child: PageContainer(
                    maxWidth: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Compromisso não encontrado ou removido.'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.go('/shows/${prof.id}'),
                          child: const Text('Voltar à agenda'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final currentShow = show;

            final allGigbag = gigbagAsync.valueOrNull ?? [];
            final linkedLists = allGigbag
                .where((c) => !c.isTemplate && c.linkedShowId == currentShow.id)
                .toList();
            final allTasks = tasksAsync.valueOrNull ?? [];
            final linkedTasks =
                allTasks.where((t) => t.linkedShowId == currentShow.id).toList();

            Widget? fab;
            if (canWrite && _tabController.index == 1) {
              fab = FloatingActionButton.extended(
                onPressed: gigbagAsync.isLoading
                    ? null
                    : () => _showAddChecklistSheet(context, prof, currentShow, allGigbag),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Checklist'),
              );
            } else if (canWrite && _tabController.index == 2) {
              fab = FloatingActionButton.extended(
                onPressed: tasksAsync.isLoading
                    ? null
                    : () => showOperationalTaskEditor(
                          context,
                          ref,
                          profile: prof,
                          existing: null,
                          shows: shows,
                          releases: ref.read(releasesStreamProvider(prof.id)).valueOrNull ?? [],
                          gigbag: allGigbag,
                          lockedLinkedShowId: currentShow.id,
                        ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tarefa'),
              );
            }

            return Scaffold(
              floatingActionButton: fab,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => context.go('/shows/${prof.id}'),
                          icon: const Icon(Icons.arrow_back_rounded),
                          tooltip: 'Agenda',
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentShow.title.isEmpty ? 'Compromisso' : currentShow.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                prof.artistName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (canWrite) ...[
                          IconButton(
                            tooltip: 'Editar',
                            onPressed: () => showArtistShowEditor(
                              context,
                              ref,
                              profile: prof,
                              existing: currentShow,
                            ),
                            icon: const Icon(Icons.edit_rounded),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'delete') {
                                _confirmDeleteShow(context, prof, currentShow);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Excluir compromisso'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Resumo'),
                      Tab(text: 'GigBag'),
                      Tab(text: 'Tarefas'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _ResumoTab(show: currentShow),
                        _GigbagTab(
                          checklists: linkedLists,
                          loading: gigbagAsync.isLoading,
                          error: gigbagAsync.hasError ? gigbagAsync.error : null,
                          onOpenChecklist: (id) =>
                              context.push('/gigbag/${prof.id}/checklist/$id'),
                          onRetry: () => ref.invalidate(gigbagStreamProvider(prof.id)),
                        ),
                        _TasksTab(
                          tasks: linkedTasks,
                          loading: tasksAsync.isLoading,
                          error: tasksAsync.hasError ? tasksAsync.error : null,
                          canWrite: canWrite,
                          onRetry: () => ref.invalidate(operationalTasksStreamProvider(prof.id)),
                          onEditTask: (t) => showOperationalTaskEditor(
                            context,
                            ref,
                            profile: prof,
                            existing: t,
                            shows: shows,
                            releases: ref.read(releasesStreamProvider(prof.id)).valueOrNull ?? [],
                            gigbag: allGigbag,
                            lockedLinkedShowId: currentShow.id,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            body: Center(
              child: PPErrorState(
                debugDetails: e.toString(),
                onRetry: () => ref.invalidate(showsStreamProvider(prof.id)),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
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

class _ResumoTab extends StatelessWidget {
  const _ResumoTab({required this.show});

  final ArtistShow show;

  @override
  Widget build(BuildContext context) {
    final dateStr = formatShowDate(show.date);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        PageContainer(
          maxWidth: 560,
          child: PPCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalhes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                _row(context, 'Tipo', eventKindLabel(show.eventKind)),
                _row(context, 'Data', '$dateStr${show.time.isNotEmpty ? ' · ${show.time}' : ''}'),
                if (show.venue.isNotEmpty) _row(context, 'Local', show.venue),
                if (show.city.isNotEmpty) _row(context, 'Cidade', show.city),
                _row(context, 'Status', showStatusLabel(show.status)),
                if (show.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Observações',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(show.notes),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(eventKindLabel(show.eventKind)),
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text(showStatusLabel(show.status)),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: AppColors.border),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              k,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(child: Text(v, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _GigbagTab extends StatelessWidget {
  const _GigbagTab({
    required this.checklists,
    required this.loading,
    required this.error,
    required this.onOpenChecklist,
    required this.onRetry,
  });

  final List<GigBagChecklist> checklists;
  final bool loading;
  final Object? error;
  final void Function(String checklistId) onOpenChecklist;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading && checklists.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && checklists.isEmpty) {
      return Center(
        child: PPErrorState(
          title: 'GigBag indisponível',
          debugDetails: error.toString(),
          onRetry: onRetry,
        ),
      );
    }
    if (checklists.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Nenhuma checklist só deste compromisso. Use o botão Checklist: modelo ou lista vazia.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: checklists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final c = checklists[i];
        final pending = c.items.where((x) => !x.checked).length;
        return PPCard(
          onTap: () => onOpenChecklist(c.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_gigbagTypeLabel(c.type)} · $pending de ${c.items.length} pendentes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab({
    required this.tasks,
    required this.loading,
    required this.error,
    required this.canWrite,
    required this.onRetry,
    required this.onEditTask,
  });

  final List<OperationalTask> tasks;
  final bool loading;
  final Object? error;
  final bool canWrite;
  final VoidCallback onRetry;
  final void Function(OperationalTask t) onEditTask;

  @override
  Widget build(BuildContext context) {
    if (loading && tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && tasks.isEmpty) {
      return Center(
        child: PPErrorState(
          title: 'Tarefas indisponíveis',
          debugDetails: error.toString(),
          onRetry: onRetry,
        ),
      );
    }
    if (tasks.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Nenhuma tarefa vinculada a este compromisso. Toque em Tarefa para criar — o vínculo já vem preenchido.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final t = tasks[i];
        return PPCard(
          onTap: canWrite ? () => onEditTask(t) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (t.description.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  t.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(t.isOpen ? 'Aberta' : 'Concluída'),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: AppColors.border),
                  ),
                  Chip(
                    label: Text('Prioridade ${_taskPriorityLabel(t.priority)}'),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (t.assignee.trim().isNotEmpty)
                    Chip(
                      label: Text(t.assignee),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
