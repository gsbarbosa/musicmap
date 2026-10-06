import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../../shared/models/artist_show.dart';
import '../../../shared/models/ledger_entry.dart';
import '../../../shared/models/person_card.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../../../shared/widgets/workspace_page_scaffold.dart';
import '../ledger/ledger_math.dart';

class LedgerPage extends ConsumerWidget {
  final String profileId;

  const LedgerPage({super.key, required this.profileId});

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
        for (final item in profiles) {
          if (item.id == profileId) profile = item;
        }
        if (profile == null) {
          return const Scaffold(body: Center(child: Text('Projeto não encontrado')));
        }
        return _LedgerBody(profile: profile);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: PPErrorState(
            debugDetails: error.toString(),
            onRetry: () => ref.invalidate(userProfilesProvider(user.uid)),
          ),
        ),
      ),
    );
  }
}

class _LedgerBody extends ConsumerWidget {
  final UserProfile profile;

  const _LedgerBody({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(ledgerStreamProvider(profile.id));
    final people = ref.watch(projectPeopleProvider(profile.id)).valueOrNull ??
        const <String, PersonCard>{};
    final canWrite = ref.watch(workspaceCanWriteProvider(profile.id)).valueOrNull ?? false;
    final role = ref.watch(profileWorkspaceRoleProvider(profile.id)).valueOrNull;
    final canDelete = role == 'owner' || role == AppConstants.roleAdmin;
    final shows = ref.watch(showsStreamProvider(profile.id)).valueOrNull ?? const <ArtistShow>[];

    return entriesAsync.when(
      data: (entries) {
        final balances = ledgerBalances(entries);
        final transfers = simplifyBalances(balances);
        return WorkspacePageScaffold(
          title: 'Caixa da banda',
          subtitle: profile.artistName,
          floatingActionButton: canWrite && people.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => context.push('/caixa/${profile.id}/lancamento'),
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
                  'Quem pagou entra com o valor cheio. Cada participante sai com a própria parte. '
                  'Saldo positivo: a banda deve a essa pessoa.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (people.isEmpty)
                  const PPCard(
                    child: Text(
                      'O caixa divide entre integrantes com ficha. Abra Minha ficha e peça para a banda fazer o mesmo.',
                    ),
                  ),
                if (people.isEmpty) const SizedBox(height: AppSpacing.lg),
                Text(
                  'Quem deve quem',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (transfers.isEmpty)
                  Text(
                    entries.isEmpty
                        ? 'Nenhum lançamento ainda.'
                        : 'A banda está quite.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  )
                else
                  ...transfers.map(
                    (transfer) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PPCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_name(transfer.fromUid, people, entries)} deve ${formatCents(transfer.amountCents)} para ${_name(transfer.toUid, people, entries)}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            if (canWrite) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () => _registerSettlement(
                                    context,
                                    ref,
                                    transfer,
                                    people,
                                    entries,
                                  ),
                                  child: const Text('Registrar acerto'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Saldos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (balances.isEmpty)
                  Text(
                    'Sem saldo em aberto.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  )
                else
                  PPCard(
                    child: Column(
                      children: [
                        for (final item in _sortedBalances(balances))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(_name(item.key, people, entries))),
                                Text(
                                  formatCents(item.value),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: item.value > 0 ? AppColors.primary : AppColors.error,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Lançamentos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (entries.isEmpty)
                  Text(
                    'Despesas, cachês e acertos aparecem aqui.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  )
                else
                  ...entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PPCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _EntrySummary(entry: entry, people: people, shows: shows, entries: entries)),
                            if (canWrite || canDelete)
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    context.push('/caixa/${profile.id}/lancamento/${entry.id}');
                                  } else if (value == 'delete') {
                                    _delete(context, ref, entry);
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (canWrite)
                                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                  if (canDelete)
                                    const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 88),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: PPErrorState(
            debugDetails: error.toString(),
            onRetry: () => ref.invalidate(ledgerStreamProvider(profile.id)),
          ),
        ),
      ),
    );
  }

  Future<void> _registerSettlement(
    BuildContext context,
    WidgetRef ref,
    LedgerTransfer transfer,
    Map<String, PersonCard> people,
    List<LedgerEntry> entries,
  ) async {
    final from = _name(transfer.fromUid, people, entries);
    final to = _name(transfer.toUid, people, entries);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar acerto'),
        content: Text('$from pagou ${formatCents(transfer.amountCents)} para $to.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Registrar')),
        ],
      ),
    );
    if (ok != true) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final now = DateTime.now();
    try {
      await ref.read(artistWorkspaceServiceProvider).saveLedgerEntry(
            LedgerEntry(
              id: '',
              profileId: profile.id,
              title: 'Acerto',
              kind: LedgerEntry.kindSettlement,
              amountCents: transfer.amountCents,
              date: now,
              category: LedgerEntry.categoryAcerto,
              paidBy: transfer.fromUid,
              splitMode: LedgerEntry.splitAmounts,
              participants: {transfer.toUid: transfer.amountCents},
              names: {
                transfer.fromUid: from,
                transfer.toUid: to,
              },
              createdBy: user.uid,
              createdAt: now,
              updatedAt: now,
            ),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acerto registrado')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        final message = error is ArgumentError
            ? error.message?.toString() ?? 'Não foi possível registrar o acerto'
            : 'Não foi possível registrar o acerto.${userFacingErrorSuffix(error)}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, LedgerEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir lançamento'),
        content: Text('Excluir "${entry.title}"? O saldo da banda é recalculado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(artistWorkspaceServiceProvider).deleteLedgerEntry(profile.id, entry.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível excluir.${userFacingErrorSuffix(error)}')),
        );
      }
    }
  }
}

class _EntrySummary extends StatelessWidget {
  final LedgerEntry entry;
  final Map<String, PersonCard> people;
  final List<ArtistShow> shows;
  final List<LedgerEntry> entries;

  const _EntrySummary({
    required this.entry,
    required this.people,
    required this.shows,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final payer = _name(entry.paidBy, people, entries);
    final date = _formatDate(entry.date);
    String subtitle;
    if (entry.kind == LedgerEntry.kindSettlement) {
      final receiverId = entry.participants.keys.isEmpty ? '' : entry.participants.keys.first;
      subtitle = '$payer pagou ${formatCents(entry.amountCents)} para ${_name(receiverId, people, entries)} · $date';
    } else {
      final showTitle = _showTitle(shows, entry.showId);
      subtitle = '$payer · ${LedgerEntry.categoryLabel(entry.category)} · $date'
          '${showTitle == null ? '' : ' · $showTitle'}';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${LedgerEntry.kindLabel(entry.kind)} · ${formatCents(entry.amountCents)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

List<MapEntry<String, int>> _sortedBalances(Map<String, int> balances) {
  final list = balances.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return list;
}

String _name(String uid, Map<String, PersonCard> people, List<LedgerEntry> entries) {
  final live = people[uid]?.displayName.trim() ?? '';
  if (live.isNotEmpty) return live;
  for (final entry in entries) {
    final snapshot = entry.names[uid]?.trim() ?? '';
    if (snapshot.isNotEmpty) return snapshot;
  }
  return 'Nome não definido';
}

String? _showTitle(List<ArtistShow> shows, String? showId) {
  if (showId == null || showId.isEmpty) return null;
  for (final show in shows) {
    if (show.id == showId && show.title.trim().isNotEmpty) return show.title;
  }
  return null;
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
