import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/firebase/app_firebase_database.dart';
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

class GigbagChecklistPage extends ConsumerWidget {
  final String profileId;
  final String checklistId;

  const GigbagChecklistPage({
    super.key,
    required this.profileId,
    required this.checklistId,
  });

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
            appBar: AppBar(title: const Text('Checklist')),
            body: const Center(child: Text('Perfil não encontrado')),
          );
        }
        return _GigbagChecklistBody(
          profile: profile,
          checklistId: checklistId,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Checklist')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Checklist')),
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

class _GigbagChecklistBody extends ConsumerWidget {
  final UserProfile profile;
  final String checklistId;

  const _GigbagChecklistBody({
    required this.profile,
    required this.checklistId,
  });

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    GigBagChecklist c,
  ) async {
    try {
      await ref.read(artistWorkspaceServiceProvider).saveChecklist(c);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salvo')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível concluir a ação.${userFacingErrorSuffix(e)}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gigbagStreamProvider(profile.id));

    return async.when(
      data: (list) {
        GigBagChecklist? c;
        for (final x in list) {
          if (x.id == checklistId) {
            c = x;
            break;
          }
        }
        if (c == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Checklist'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.go('/gigbag/${profile.id}'),
              ),
            ),
            body: const Center(child: Text('Checklist não encontrada')),
          );
        }
        final canWrite =
            ref.watch(workspaceCanWriteProvider(profile.id)).valueOrNull ?? false;
        return _ChecklistEditorView(
          profile: profile,
          initial: c,
          readOnly: !canWrite,
          onSave: (updated) => _save(context, ref, updated),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Checklist')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Checklist')),
        body: Center(
          child: PPErrorState(
            debugDetails: e.toString(),
            onRetry: () =>
                ref.invalidate(gigbagStreamProvider(profile.id)),
          ),
        ),
      ),
    );
  }
}

class _ChecklistEditorView extends StatefulWidget {
  final UserProfile profile;
  final GigBagChecklist initial;
  final bool readOnly;
  final Future<void> Function(GigBagChecklist) onSave;

  const _ChecklistEditorView({
    required this.profile,
    required this.initial,
    required this.readOnly,
    required this.onSave,
  });

  @override
  State<_ChecklistEditorView> createState() => _ChecklistEditorViewState();
}

class _ChecklistEditorViewState extends State<_ChecklistEditorView> {
  late GigBagChecklist _c;
  final _newItemCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c = widget.initial;
  }

  @override
  void didUpdateWidget(covariant _ChecklistEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial.id != widget.initial.id ||
        oldWidget.initial.updatedAt != widget.initial.updatedAt) {
      _c = widget.initial;
    }
  }

  @override
  void dispose() {
    _newItemCtrl.dispose();
    super.dispose();
  }

  Future<void> _persist(GigBagChecklist next) async {
    setState(() => _c = next);
    await widget.onSave(next);
  }

  Future<void> _addItem() async {
    if (widget.readOnly) return;
    final text = _newItemCtrl.text.trim();
    if (text.isEmpty) return;
    final ref = appFirebaseDatabase
        .ref()
        .child(AppConstants.gigbagPath)
        .child(_c.profileId)
        .child(_c.id)
        .child('items');
    final itemId = ref.push().key!;
    final order = _c.items.length;
    final items = List<GigBagItem>.from(_c.items)
      ..add(GigBagItem(id: itemId, description: text, checked: false, order: order));
    _newItemCtrl.clear();
    await _persist(_c.copyWith(items: items));
  }

  Future<void> _toggleItem(GigBagItem it) async {
    if (widget.readOnly) return;
    final items = _c.items
        .map(
          (x) => x.id == it.id ? x.copyWith(checked: !x.checked) : x,
        )
        .toList();
    await _persist(_c.copyWith(items: items));
  }

  Future<void> _removeItem(GigBagItem it) async {
    if (widget.readOnly) return;
    final items = _c.items.where((x) => x.id != it.id).toList();
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(order: i);
    }
    await _persist(_c.copyWith(items: items));
  }

  Future<void> _resetChecks() async {
    if (widget.readOnly) return;
    final items = _c.items.map((x) => x.copyWith(checked: false)).toList();
    await _persist(_c.copyWith(items: items));
  }

  Future<void> _editMeta(BuildContext context) async {
    if (widget.readOnly) return;
    final titleCtrl = TextEditingController(text: _c.title);
    var type = _c.type;
    var isTemplate = _c.isTemplate;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Editar checklist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
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
                title: const Text('Modelo'),
                value: isTemplate,
                onChanged: (v) => setSt(() => isTemplate = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    await _persist(
      _c.copyWith(
        title: titleCtrl.text.trim().isEmpty ? _c.title : titleCtrl.text.trim(),
        type: type,
        isTemplate: isTemplate,
      ),
    );
  }

  Future<void> _duplicate(BuildContext context, WidgetRef ref) async {
    if (widget.readOnly) return;
    try {
      await ref.read(artistWorkspaceServiceProvider).duplicateChecklist(_c);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist duplicada')),
        );
        context.go('/gigbag/${widget.profile.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível concluir a ação.${userFacingErrorSuffix(e)}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (widget.readOnly) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir checklist?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(artistWorkspaceServiceProvider).deleteChecklist(_c.profileId, _c.id);
    if (context.mounted) context.go('/gigbag/${widget.profile.id}');
  }

  @override
  Widget build(BuildContext context) {
        return Consumer(
      builder: (context, ref, _) {
        return WorkspacePageScaffold(
          title: _c.title,
          subtitle:
              '${_gigbagTypeLabel(_c.type)}${ _c.isTemplate ? ' · Modelo' : ''}',
          leading: IconButton.filledTonal(
            onPressed: () => context.go('/gigbag/${widget.profile.id}'),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Voltar ao GigBag',
          ),
          actions: widget.readOnly
              ? const <Widget>[]
              : [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: 'Editar nome e tipo',
                    onPressed: () => _editMeta(context),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'dup') _duplicate(context, ref);
                      if (v == 'reset') _resetChecks();
                      if (v == 'del') _delete(context, ref);
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'dup', child: Text('Duplicar')),
                      PopupMenuItem(value: 'reset', child: Text('Limpar marcações')),
                      PopupMenuItem(value: 'del', child: Text('Excluir')),
                    ],
                  ),
                ],
          body: PageContainer(
            maxWidth: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.readOnly) ...[
                  Text(
                    'Somente leitura — você pode ver a lista, mas não alterar itens.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!widget.readOnly)
                  PPCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newItemCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Novo item',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addItem(),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ),
                if (!widget.readOnly) const SizedBox(height: 16),
                if (_c.items.isEmpty)
                  Text(
                    widget.readOnly
                        ? 'Esta checklist ainda não tem itens.'
                        : 'Adicione itens acima. Nada é apagado ao marcar — só ao excluir o item.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  )
                else
                  ..._c.items.map((it) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PPCard(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: CheckboxListTile(
                          value: it.checked,
                          onChanged: widget.readOnly ? null : (_) => _toggleItem(it),
                          title: Text(
                            it.description,
                            style: TextStyle(
                              decoration:
                                  it.checked ? TextDecoration.lineThrough : null,
                              color: it.checked ? AppColors.textSecondary : null,
                            ),
                          ),
                          secondary: widget.readOnly
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  onPressed: () => _removeItem(it),
                                ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}
