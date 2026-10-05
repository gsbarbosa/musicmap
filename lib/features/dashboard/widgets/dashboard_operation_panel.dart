import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/profile_completeness.dart';
import '../../../shared/models/artist_show.dart';
import '../../../shared/models/music_release.dart';
import '../../../shared/models/operational_task.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_error_state.dart';

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

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

String _priorityLabel(String p) {
  switch (p) {
    case OperationalTask.priorityHigh:
      return 'Alta';
    case OperationalTask.priorityLow:
      return 'Baixa';
    default:
      return 'Média';
  }
}

/// Painel consolidado da operação do projeto (Entrega 1 + destaque de tarefas — Entrega 2)
class DashboardOperationPanel extends ConsumerWidget {
  final UserProfile profile;

  const DashboardOperationPanel({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileId = profile.id;
    final showsAsync = ref.watch(showsStreamProvider(profileId));
    final releasesAsync = ref.watch(releasesStreamProvider(profileId));
    final gigbagAsync = ref.watch(gigbagStreamProvider(profileId));
    final tasksAsync = ref.watch(operationalTasksStreamProvider(profileId));

    if (showsAsync.isLoading ||
        releasesAsync.isLoading ||
        gigbagAsync.isLoading ||
        tasksAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (showsAsync.hasError ||
        releasesAsync.hasError ||
        gigbagAsync.hasError ||
        tasksAsync.hasError) {
      final detail = [
        if (showsAsync.hasError) 'shows: ${showsAsync.error}',
        if (releasesAsync.hasError) 'releases: ${releasesAsync.error}',
        if (gigbagAsync.hasError) 'gigbag: ${gigbagAsync.error}',
        if (tasksAsync.hasError) 'tasks: ${tasksAsync.error}',
      ].join('\n');
      return PPCard(
        padding: const EdgeInsets.all(16),
        child: PPErrorState(
          title: 'Painel indisponível',
          message:
              'Não foi possível carregar uma ou mais partes do resumo. Tente novamente.',
          debugDetails: detail,
          onRetry: () {
            ref.invalidate(showsStreamProvider(profileId));
            ref.invalidate(releasesStreamProvider(profileId));
            ref.invalidate(gigbagStreamProvider(profileId));
            ref.invalidate(operationalTasksStreamProvider(profileId));
          },
        ),
      );
    }

    final shows = showsAsync.value ?? [];
    final releases = releasesAsync.value ?? [];
    final gigbag = gigbagAsync.value ?? [];
    final tasks = tasksAsync.value ?? [];
    final now = DateTime.now();
    final today = _startOfDay(now);

    final upcomingRows = _buildUpcomingRows(
      context: context,
      profileId: profileId,
      shows: shows,
      releases: releases,
      today: today,
    );

    final nonTemplates = gigbag.where((c) => !c.isTemplate).toList();
    final completeness = evaluateProfileCompleteness(profile);

    final completedShows =
        shows.where((s) => s.isPast && s.status == ArtistShow.statusConfirmed).length;
    final overdueOpen =
        tasks.where((t) => t.isOpen && t.isOverdueAt(now)).length;

    final taskSpotlight = _taskSpotlightList(tasks, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Painel da operação',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 20),
        _sectionCard(
          context,
          child: upcomingRows.isEmpty
              ? _emptyBlock(
                  context,
                  'Nada agendado à frente.',
                  'Cadastre um show ou um lançamento para ver datas importantes aqui.',
                  onPrimary: () => context.push('/shows/$profileId'),
                  primaryLabel: 'Agendar show',
                  onSecondary: () => context.push('/releases/$profileId'),
                  secondaryLabel: 'Planejar lançamento',
                )
              : _upcomingCommitmentsCarousel(context, upcomingRows.take(8).toList()),
        ),
        if (overdueOpen > 0) ...[
          const SizedBox(height: 12),
          Material(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => context.push('/tasks/$profileId'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: AppColors.warning, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        overdueOpen == 1
                            ? '1 tarefa passou do prazo — toque para resolver'
                            : '$overdueOpen tarefas passaram do prazo — toque para ver',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Resumo do projeto',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statLine(context, 'Completude do perfil', '${completeness.percent}%'),
              _statLine(context, 'Shows realizados (confirmados)', '$completedShows'),
              _statLine(context, 'Lançamentos cadastrados', '${releases.length}'),
              _statLine(context, 'Checklists (exceto modelos)', '${nonTemplates.length}'),
              _statLine(
                context,
                'Tarefas abertas / total',
                '${tasks.where((t) => t.isOpen).length} / ${tasks.length}',
              ),
            ],
          ),
        ),
        if (taskSpotlight.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionCard(
            context,
            title: 'Tarefas em destaque',
            child: Column(
              children: taskSpotlight
                  .map((t) => _taskTile(context, profileId, t, now))
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Atalhos',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ctaChip(
                context,
                label: 'Novo show',
                icon: Icons.event_rounded,
                onTap: () => context.push('/shows/$profileId'),
              ),
              _ctaChip(
                context,
                label: 'Novo lançamento',
                icon: Icons.album_rounded,
                onTap: () => context.push('/releases/$profileId'),
              ),
              _ctaChip(
                context,
                label: 'Nova checklist',
                icon: Icons.checklist_rounded,
                onTap: () => context.push('/gigbag/$profileId'),
              ),
              _ctaChip(
                context,
                label: 'Tarefas',
                icon: Icons.task_alt_rounded,
                onTap: () => context.push('/tasks/$profileId'),
              ),
              _ctaChip(
                context,
                label: 'Completar perfil',
                icon: Icons.person_rounded,
                onTap: () => context.push('/edit-profile/$profileId'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<_UpcomingRow> _buildUpcomingRows({
    required BuildContext context,
    required String profileId,
    required List<ArtistShow> shows,
    required List<MusicRelease> releases,
    required DateTime today,
  }) {
    final rows = <_UpcomingRow>[];

    for (final s in shows) {
      if (s.status == ArtistShow.statusCancelled) continue;
      final d = _startOfDay(s.date);
      if (d.isBefore(today)) continue;
      rows.add(
        _UpcomingRow(
          sortDate: d,
          icon: Icons.event_rounded,
          title: s.title.isEmpty ? 'Show' : s.title,
          subtitle: '${_formatDate(s.date)} · ${s.city.isNotEmpty ? s.city : s.venue}',
          onTap: () => context.push('/shows/$profileId/commitment/${s.id}'),
        ),
      );
    }

    for (final r in releases) {
      if (r.status == MusicRelease.statusReleased || r.status == MusicRelease.statusCancelled) {
        continue;
      }
      final d = _startOfDay(r.releaseDate);
      if (d.isBefore(today)) continue;
      rows.add(
        _UpcomingRow(
          sortDate: d,
          icon: Icons.album_rounded,
          title: r.title.isEmpty ? 'Lançamento' : r.title,
          subtitle: '${_formatDate(r.releaseDate)} · ${_releaseStatusLabel(r.status)}',
          onTap: () => context.push('/releases/$profileId'),
        ),
      );
    }

    rows.sort((a, b) => a.sortDate.compareTo(b.sortDate));
    return rows;
  }

  List<OperationalTask> _taskSpotlightList(List<OperationalTask> tasks, DateTime now) {
    final open = tasks.where((t) => t.isOpen).toList();
    if (open.isEmpty) return [];
    final weekEnd = _startOfDay(now).add(const Duration(days: 8));

    bool isSoon(OperationalTask t) {
      if (t.dueDate == null) return false;
      final d = _startOfDay(t.dueDate!);
      final t0 = _startOfDay(now);
      return !d.isBefore(t0) && d.isBefore(weekEnd);
    }

    final overdue = open.where((t) => t.isOverdueAt(now)).toList()
      ..sort((a, b) {
        final da = a.dueDate;
        final db = b.dueDate;
        if (da != null && db != null) return da.compareTo(db);
        return 0;
      });
    final soon = open.where((t) => !t.isOverdueAt(now) && isSoon(t)).toList()
      ..sort((a, b) {
        final da = a.dueDate!;
        final db = b.dueDate!;
        return da.compareTo(db);
      });
    final rest = open
        .where((t) => !t.isOverdueAt(now) && !isSoon(t))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final out = <OperationalTask>[...overdue, ...soon, ...rest];
    return out.take(4).toList();
  }

  Widget _sectionCard(
    BuildContext context, {
    String? title,
    String? subtitle,
    required Widget child,
  }) {
    return PPCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
              ),
            ],
            const SizedBox(height: 14),
          ] else if (subtitle != null) ...[
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }

  Widget _statLine(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBlock(
    BuildContext context,
    String title,
    String body, {
    required VoidCallback onPrimary,
    required String primaryLabel,
    VoidCallback? onSecondary,
    String? secondaryLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PPButton(
              label: primaryLabel,
              onPressed: onPrimary,
              variant: PPButtonVariant.primary,
            ),
            if (onSecondary != null && secondaryLabel != null)
              PPButton(
                label: secondaryLabel,
                onPressed: onSecondary,
                variant: PPButtonVariant.outline,
              ),
          ],
        ),
      ],
    );
  }

  static const _carouselCardWidth = 264.0;
  static const _carouselHeight = 128.0;

  Widget _upcomingCommitmentsCarousel(BuildContext context, List<_UpcomingRow> rows) {
    return SizedBox(
      height: _carouselHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => SizedBox(
          width: _carouselCardWidth,
          child: _upcomingCarouselCard(context, rows[i]),
        ),
      ),
    );
  }

  Widget _upcomingCarouselCard(BuildContext context, _UpcomingRow row) {
    return Material(
      color: AppColors.surfaceSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: row.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(row.icon, size: 20, color: AppColors.primary),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 22),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                row.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                row.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskTile(BuildContext context, String profileId, OperationalTask t, DateTime now) {
    final overdue = t.isOverdueAt(now);
    final dueText = t.dueDate != null ? _formatDate(t.dueDate!) : 'Sem prazo';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/tasks/$profileId'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  overdue ? Icons.error_outline_rounded : Icons.task_alt_rounded,
                  size: 22,
                  color: overdue ? AppColors.warning : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title.isEmpty ? 'Tarefa' : t.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dueText · ${_priorityLabel(t.priority)}'
                        '${t.assignee.trim().isNotEmpty ? ' · ${t.assignee}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: overdue ? AppColors.warning : AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ctaChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label),
      onPressed: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
    );
  }
}

class _UpcomingRow {
  final DateTime sortDate;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _UpcomingRow({
    required this.sortDate,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
