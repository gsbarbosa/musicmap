import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../../shared/models/artist_show.dart';
import '../../../shared/models/gigbag_checklist.dart';
import '../../../shared/models/music_release.dart';
import '../../../shared/models/operational_task.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../../../shared/widgets/workspace_page_scaffold.dart';
import '../widgets/operational_task_editor_dialog.dart';

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

class TasksPage extends ConsumerWidget {
  final String profileId;

  const TasksPage({super.key, required this.profileId});

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
            appBar: AppBar(title: const Text('Tarefas')),
            body: const Center(child: Text('Perfil não encontrado')),
          );
        }
        return _TasksScaffold(profile: profile);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Tarefas')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Tarefas')),
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

class _TasksScaffold extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _TasksScaffold({required this.profile});

  @override
  ConsumerState<_TasksScaffold> createState() => _TasksScaffoldState();
}

class _TasksScaffoldState extends ConsumerState<_TasksScaffold> {
  String _statusFilter = 'all';
  String? _assigneeFilter;
  String _dueFilter = 'all';

  Future<void> _openEditor(
    OperationalTask? existing, {
    required List<ArtistShow> shows,
    required List<MusicRelease> releases,
    required List<GigBagChecklist> gigbag,
  }) async {
    await showOperationalTaskEditor(
      context,
      ref,
      profile: widget.profile,
      existing: existing,
      shows: shows,
      releases: releases,
      gigbag: gigbag,
    );
  }

  List<OperationalTask> _filteredAndSorted(List<OperationalTask> tasks) {
    final now = DateTime.now();
    final today = _startOfDay(now);
    Iterable<OperationalTask> t = tasks;

    if (_statusFilter == 'open') {
      t = t.where((x) => x.isOpen);
    } else if (_statusFilter == 'done') {
      t = t.where((x) => !x.isOpen);
    }

    if (_assigneeFilter == '__empty__') {
      t = t.where((x) => x.assignee.trim().isEmpty);
    } else if (_assigneeFilter != null && _assigneeFilter!.isNotEmpty) {
      t = t.where((x) => x.assignee.trim() == _assigneeFilter);
    }

    if (_dueFilter == 'overdue') {
      t = t.where((x) => x.isOpen && x.isOverdueAt(now));
    } else if (_dueFilter == 'week') {
      final end = today.add(const Duration(days: 7));
      t = t.where((x) {
        if (x.dueDate == null) return false;
        final d = _startOfDay(x.dueDate!);
        return !d.isBefore(today) && d.isBefore(end.add(const Duration(days: 1)));
      });
    } else if (_dueFilter == 'none') {
      t = t.where((x) => x.dueDate == null);
    }

    final list = t.toList();
    list.sort((a, b) {
      final oa = a.isOpen ? 0 : 1;
      final ob = b.isOpen ? 0 : 1;
      if (oa != ob) return oa.compareTo(ob);
      final oa2 = a.isOpen && a.isOverdueAt(now) ? 0 : 1;
      final ob2 = b.isOpen && b.isOverdueAt(now) ? 0 : 1;
      if (oa2 != ob2) return oa2.compareTo(ob2);
      final da = a.dueDate;
      final db = b.dueDate;
      if (da != null && db != null) {
        final c = da.compareTo(db);
        if (c != 0) return c;
      } else if (da != null) {
        return -1;
      } else if (db != null) {
        return 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  Future<void> _toggleDone(OperationalTask task, bool done) async {
    final svc = ref.read(artistWorkspaceServiceProvider);
    final now = DateTime.now();
    try {
      if (done) {
        await svc.saveOperationalTask(
          task.copyWith(
            status: OperationalTask.statusDone,
            completedAt: now,
            clearCompletedAt: false,
          ),
        );
      } else {
        await svc.saveOperationalTask(
          task.copyWith(
            status: OperationalTask.statusOpen,
            clearCompletedAt: true,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível atualizar a tarefa.${userFacingErrorSuffix(e)}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(OperationalTask task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir tarefa?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await ref.read(artistWorkspaceServiceProvider).deleteOperationalTask(widget.profile.id, task.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Não foi possível excluir a tarefa.${userFacingErrorSuffix(e)}',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncTasks = ref.watch(operationalTasksStreamProvider(widget.profile.id));
    final asyncShows = ref.watch(showsStreamProvider(widget.profile.id));
    final asyncReleases = ref.watch(releasesStreamProvider(widget.profile.id));
    final asyncGigbag = ref.watch(gigbagStreamProvider(widget.profile.id));

    final shows = asyncShows.valueOrNull ?? [];
    final releases = asyncReleases.valueOrNull ?? [];
    final gigbag = asyncGigbag.valueOrNull ?? [];

    final assigneesList = <String>{
      for (final t in asyncTasks.valueOrNull ?? [])
        if (t.assignee.trim().isNotEmpty) t.assignee.trim(),
    }.toList()
      ..sort();

    final canWrite =
        ref.watch(workspaceCanWriteProvider(widget.profile.id)).valueOrNull ?? false;

    return WorkspacePageScaffold(
      title: 'Tarefas operacionais',
      subtitle: widget.profile.artistName,
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: asyncTasks.isLoading
                  ? null
                  : () => _openEditor(null, shows: shows, releases: releases, gigbag: gigbag),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova tarefa'),
            )
          : null,
      body: PageContainer(
        maxWidth: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Responsável, prazo e prioridade. Vencidas aparecem na Central.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 20),
            PPCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Filtros',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _statusFilter,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Todos')),
                        DropdownMenuItem(value: 'open', child: Text('Abertas')),
                        DropdownMenuItem(value: 'done', child: Text('Concluídas')),
                      ],
                      onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: _assigneeFilter,
                      decoration: const InputDecoration(labelText: 'Responsável'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                        const DropdownMenuItem<String?>(
                          value: '__empty__',
                          child: Text('Sem responsável'),
                        ),
                        ...assigneesList.map(
                          (a) => DropdownMenuItem<String?>(value: a, child: Text(a)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _assigneeFilter = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _dueFilter,
                      decoration: const InputDecoration(labelText: 'Prazo'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Qualquer')),
                        DropdownMenuItem(value: 'overdue', child: Text('Vencidas (abertas)')),
                        DropdownMenuItem(value: 'week', child: Text('Próximos 7 dias')),
                        DropdownMenuItem(value: 'none', child: Text('Sem prazo')),
                      ],
                      onChanged: (v) => setState(() => _dueFilter = v ?? 'all'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              asyncTasks.when(
                data: (tasks) {
                  final visible = _filteredAndSorted(tasks);
                  if (tasks.isEmpty) {
                    return PPCard(
                      child: Text(
                        'Nenhuma tarefa ainda. Use Nova tarefa para começar.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    );
                  }
                  if (visible.isEmpty) {
                    return PPCard(
                      child: Text(
                        'Nenhuma tarefa com os filtros atuais.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    );
                  }
                  return Column(
                    children: visible
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TaskTile(
                              task: t,
                              canWrite: canWrite,
                              onEdit: () => _openEditor(
                                t,
                                shows: shows,
                                releases: releases,
                                gigbag: gigbag,
                              ),
                              onDelete: () => _confirmDelete(t),
                              onToggleDone: () => _toggleDone(t, t.isOpen),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => PPErrorState(
                  title: 'Tarefas indisponíveis',
                  message: 'Não foi possível carregar a lista de tarefas.',
                  debugDetails: e.toString(),
                  onRetry: () => ref.invalidate(
                    operationalTasksStreamProvider(widget.profile.id),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final OperationalTask task;
  final bool canWrite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleDone;

  const _TaskTile({
    required this.task,
    required this.canWrite,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final overdue = task.isOpen && task.isOverdueAt(now);
    final priorityLabel = switch (task.priority) {
      OperationalTask.priorityHigh => 'Alta',
      OperationalTask.priorityLow => 'Baixa',
      _ => 'Média',
    };
    final dueStr = task.dueDate != null ? _formatDate(task.dueDate!) : 'Sem prazo';

    return PPCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: task.isOpen ? null : TextDecoration.lineThrough,
                        color: task.isOpen ? null : AppColors.textSecondary,
                      ),
                ),
              ),
              if (canWrite) ...[
                if (task.isOpen)
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    tooltip: 'Concluir',
                    onPressed: onToggleDone,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.undo_rounded),
                    tooltip: 'Reabrir',
                    onPressed: onToggleDone,
                  ),
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
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(task.isOpen ? 'Aberta' : 'Concluída'),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: AppColors.border),
              ),
              Chip(
                label: Text('Prioridade: $priorityLabel'),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: AppColors.border),
              ),
              if (overdue)
                Chip(
                  label: const Text('Vencida'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$dueStr${task.assignee.trim().isNotEmpty ? ' · ${task.assignee}' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: overdue ? Colors.orange.shade900 : AppColors.textSecondary,
                ),
          ),
          if (task.linkedShowId != null ||
              task.linkedReleaseId != null ||
              task.linkedChecklistId != null) ...[
            const SizedBox(height: 6),
            Text(
              [
                if (task.linkedShowId != null) 'Show vinculado',
                if (task.linkedReleaseId != null) 'Lançamento vinculado',
                if (task.linkedChecklistId != null) 'Checklist vinculada',
              ].join(' · '),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Editar detalhes'),
            ),
          ),
        ],
      ),
    );
  }
}
