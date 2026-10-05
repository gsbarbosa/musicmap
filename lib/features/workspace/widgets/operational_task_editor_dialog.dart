import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../../shared/models/artist_show.dart';
import '../../../shared/models/gigbag_checklist.dart';
import '../../../shared/models/music_release.dart';
import '../../../shared/models/operational_task.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/pp_input.dart';

String _formatTaskDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _lockedShowSubtitle(List<ArtistShow> shows, String showId) {
  for (final s in shows) {
    if (s.id == showId) {
      return s.title.isNotEmpty ? s.title : 'Compromisso';
    }
  }
  return 'Este compromisso';
}

/// Editor de tarefa operacional. Com [lockedLinkedShowId], o vínculo com o show fica fixo (detalhe do compromisso).
Future<void> showOperationalTaskEditor(
  BuildContext context,
  WidgetRef ref, {
  required UserProfile profile,
  OperationalTask? existing,
  required List<ArtistShow> shows,
  required List<MusicRelease> releases,
  required List<GigBagChecklist> gigbag,
  String? lockedLinkedShowId,
}) async {
  final svc = ref.read(artistWorkspaceServiceProvider);
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  final assigneeCtrl = TextEditingController(text: existing?.assignee ?? '');
  var priority = existing?.priority ?? OperationalTask.priorityMedium;
  var status = existing?.status ?? OperationalTask.statusOpen;
  DateTime? due = existing?.dueDate;
  String? linkedShow = lockedLinkedShowId ?? existing?.linkedShowId;
  String? linkedRelease = existing?.linkedReleaseId;
  String? linkedChecklist = existing?.linkedChecklistId;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: Text(existing == null ? 'Nova tarefa' : 'Editar tarefa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PPInput(label: 'Título', controller: titleCtrl),
              const SizedBox(height: 12),
              PPInput(label: 'Descrição (opcional)', controller: descCtrl, maxLines: 3),
              const SizedBox(height: 12),
              PPInput(label: 'Responsável', controller: assigneeCtrl, hint: 'Nome ou função'),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Prazo'),
                subtitle: Text(due != null ? _formatTaskDate(due!) : 'Sem data limite'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (due != null)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setSt(() => due = null),
                        tooltip: 'Remover prazo',
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today_rounded),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: due ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setSt(() => due = picked);
                      },
                    ),
                  ],
                ),
              ),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: OperationalTask.prioritiesOrdered
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(switch (p) {
                          OperationalTask.priorityHigh => 'Alta',
                          OperationalTask.priorityLow => 'Baixa',
                          _ => 'Média',
                        }),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSt(() => priority = v ?? priority),
              ),
              if (existing != null) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: OperationalTask.statusOpen, child: Text('Aberta')),
                    DropdownMenuItem(value: OperationalTask.statusDone, child: Text('Concluída')),
                  ],
                  onChanged: (v) => setSt(() => status = v ?? status),
                ),
              ],
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Vínculos opcionais',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              if (lockedLinkedShowId != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show / compromisso'),
                  subtitle: Text(_lockedShowSubtitle(shows, lockedLinkedShowId)),
                ),
              ] else
                DropdownButtonFormField<String?>(
                  value: linkedShow,
                  decoration: const InputDecoration(labelText: 'Show'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Nenhum')),
                    ...shows.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s.id,
                        child: Text(s.title.isEmpty ? 'Show ${s.id}' : s.title),
                      ),
                    ),
                  ],
                  onChanged: (v) => setSt(() => linkedShow = v),
                ),
              DropdownButtonFormField<String?>(
                value: linkedRelease,
                decoration: const InputDecoration(labelText: 'Lançamento'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Nenhum')),
                  ...releases.map(
                    (r) => DropdownMenuItem<String?>(
                      value: r.id,
                      child: Text(r.title.isEmpty ? 'Lançamento ${r.id}' : r.title),
                    ),
                  ),
                ],
                onChanged: (v) => setSt(() => linkedRelease = v),
              ),
              DropdownButtonFormField<String?>(
                value: linkedChecklist,
                decoration: const InputDecoration(labelText: 'Checklist GigBag'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Nenhum')),
                  ...gigbag.map(
                    (c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.title.isEmpty ? 'Lista ${c.id}' : c.title),
                    ),
                  ),
                ],
                onChanged: (v) => setSt(() => linkedChecklist = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );

  if (ok != true || !context.mounted) return;
  if (titleCtrl.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informe o título da tarefa')),
    );
    return;
  }

  final now = DateTime.now();
  final isNew = existing == null;
  final completedAt = status == OperationalTask.statusDone
      ? (existing?.completedAt ?? now)
      : null;

  final effectiveShowId = lockedLinkedShowId ?? linkedShow;

  final task = OperationalTask(
    id: existing?.id ?? '',
    profileId: profile.id,
    title: titleCtrl.text.trim(),
    description: descCtrl.text.trim(),
    assignee: assigneeCtrl.text.trim(),
    dueDate: due,
    priority: priority,
    status: status,
    linkedShowId: effectiveShowId,
    linkedReleaseId: linkedRelease,
    linkedChecklistId: linkedChecklist,
    createdAt: existing?.createdAt ?? now,
    updatedAt: now,
    completedAt: status == OperationalTask.statusDone ? completedAt : null,
  );

  try {
    await svc.saveOperationalTask(task);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNew ? 'Tarefa criada' : 'Tarefa atualizada')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível salvar a tarefa.${userFacingErrorSuffix(e)}',
          ),
        ),
      );
    }
  }
}
