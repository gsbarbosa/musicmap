import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/artist_show.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../../../shared/widgets/workspace_page_scaffold.dart';
import '../widgets/artist_show_editor_dialog.dart';

class ShowsPage extends ConsumerWidget {
  final String profileId;

  const ShowsPage({super.key, required this.profileId});

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
            appBar: AppBar(title: const Text('Agenda')),
            body: const Center(child: Text('Perfil não encontrado')),
          );
        }
        return _ShowsScaffold(profile: profile);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Agenda')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Agenda')),
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

class _ShowsScaffold extends ConsumerWidget {
  final UserProfile profile;

  const _ShowsScaffold({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncShows = ref.watch(showsStreamProvider(profile.id));
    final canWrite = ref.watch(workspaceCanWriteProvider(profile.id)).valueOrNull ?? false;

    return WorkspacePageScaffold(
      title: 'Agenda de compromissos',
      subtitle: profile.artistName,
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () => showArtistShowEditor(context, ref, profile: profile, existing: null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo compromisso'),
            )
          : null,
      body: PageContainer(
        maxWidth: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Toque no card para abrir GigBag e tarefas deste compromisso. Menu ⋮ para editar rápido ou excluir.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 24),
            asyncShows.when(
              data: (shows) {
                if (shows.isEmpty) {
                  return PPCard(
                    child: Text(
                      'Nenhum compromisso ainda. Use Novo compromisso para começar (show, ensaio ou gravação).',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  );
                }
                final upcoming = shows.where((s) => !s.isPast).toList();
                final past = shows.where((s) => s.isPast).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Futuros',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (upcoming.isEmpty)
                      Text(
                        'Sem compromissos futuros.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      )
                    else
                      ...upcoming.map((s) => _ShowTile(
                            show: s,
                            canWrite: canWrite,
                            onOpenDetail: () => context.push(
                              '/shows/${profile.id}/commitment/${s.id}',
                            ),
                            onEdit: () => showArtistShowEditor(
                              context,
                              ref,
                              profile: profile,
                              existing: s,
                            ),
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Excluir compromisso?'),
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
                                    .deleteShow(profile.id, s.id);
                              }
                            },
                          )),
                    const SizedBox(height: 28),
                    Text(
                      'Histórico (passados)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (past.isEmpty)
                      Text(
                        'Nenhum compromisso passado.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      )
                    else
                      ...past.map((s) => _ShowTile(
                            show: s,
                            canWrite: canWrite,
                            onOpenDetail: () => context.push(
                              '/shows/${profile.id}/commitment/${s.id}',
                            ),
                            onEdit: () => showArtistShowEditor(
                              context,
                              ref,
                              profile: profile,
                              existing: s,
                            ),
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Excluir compromisso?'),
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
                                    .deleteShow(profile.id, s.id);
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
                title: 'Agenda indisponível',
                message: 'Não foi possível carregar os compromissos.',
                debugDetails: e.toString(),
                onRetry: () => ref.invalidate(showsStreamProvider(profile.id)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowTile extends StatelessWidget {
  final ArtistShow show;
  final bool canWrite;
  final VoidCallback onOpenDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShowTile({
    required this.show,
    required this.canWrite,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = formatShowDate(show.date);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PPCard(
        onTap: onOpenDetail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    show.title,
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
            const SizedBox(height: 8),
            Text(
              '$dateStr${show.time.isNotEmpty ? ' · ${show.time}' : ''}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (show.venue.isNotEmpty || show.city.isNotEmpty)
              Text(
                [show.venue, show.city].where((x) => x.isNotEmpty).join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
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
                if (show.status == ArtistShow.statusCancelled)
                  const Chip(
                    label: Text('Histórico'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
