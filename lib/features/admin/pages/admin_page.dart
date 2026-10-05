import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_dropdown.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../../../shared/widgets/pp_logo.dart';

final adminProfilesProvider = FutureProvider.autoDispose<List<UserProfile>>((ref) async {
  return ref.read(profileServiceProvider).getAllProfiles();
});

/// Painel interno: lista de perfis e export CSV (apenas admins)
class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  String? _filterState;
  String? _filterGenre;

  List<UserProfile> _filter(List<UserProfile> all) {
    return all.where((p) {
      if (_filterState != null && _filterState!.isNotEmpty) {
        if (p.state.toUpperCase() != _filterState) return false;
      }
      if (_filterGenre != null && _filterGenre!.isNotEmpty) {
        if (p.genre != _filterGenre) return false;
      }
      return true;
    }).toList();
  }

  Future<String> _csv(List<UserProfile> rows) async {
    final svc = ref.read(profileServiceProvider);
    final header = [
      'id',
      'artistName',
      'city',
      'state',
      'genre',
      'instagram',
      'contact',
      'referral',
    ];
    final lines = <String>[header.map(_escapeCsv).join(',')];
    for (final p in rows) {
      final referral = await svc.getUserReferralSource(p.ownerUserId);
      lines.add([
        p.id,
        p.artistName,
        p.city,
        p.state,
        p.genre,
        p.instagram,
        p.contact,
        referral ?? '',
      ].map(_escapeCsv).join(','));
    }
    return lines.join('\n');
  }

  String _escapeCsv(String v) {
    final s = v.replaceAll('"', '""');
    return '"$s"';
  }

  Future<void> _export(List<UserProfile> list) async {
    final csv = await _csv(list);
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV copiado (${list.length} linhas). Cole em um editor ou planilha.'),
          backgroundColor: AppColors.surfaceSecondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — perfis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: async.when(
        data: (all) {
          final filtered = _filter(all);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: PageContainer(
              maxWidth: 1000,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PPLogo(showTagline: false, fontSize: 22),
                  const SizedBox(height: 8),
                  Text(
                    'Lista interna (export para análise e contato manual)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: PPDropdown<String>(
                          label: 'Estado (UF)',
                          hint: 'Todos',
                          value: _filterState,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Todos')),
                            ...AppConstants.brazilianStates.map(
                              (e) => DropdownMenuItem(value: e.key, child: Text(e.key)),
                            ),
                          ],
                          onChanged: (v) => setState(() => _filterState = v),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: PPDropdown<String>(
                          label: 'Gênero',
                          hint: 'Todos',
                          value: _filterGenre,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Todos')),
                            ...AppConstants.musicGenres.map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            ),
                          ],
                          onChanged: (v) => setState(() => _filterGenre = v),
                        ),
                      ),
                      PPButton(
                        label: 'Exportar CSV (copiar)',
                        icon: Icons.copy_rounded,
                        onPressed: filtered.isEmpty ? null : () => _export(filtered),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(adminProfilesProvider),
                        child: const Text('Atualizar lista'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${filtered.length} de ${all.length} perfis',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nome')),
                        DataColumn(label: Text('Cidade')),
                        DataColumn(label: Text('UF')),
                        DataColumn(label: Text('Gênero')),
                        DataColumn(label: Text('Instagram')),
                        DataColumn(label: Text('Contato')),
                      ],
                      rows: filtered
                          .map(
                            (p) => DataRow(
                              cells: [
                                DataCell(Text(p.artistName)),
                                DataCell(Text(p.city)),
                                DataCell(Text(p.state)),
                                DataCell(Text(p.genre)),
                                DataCell(Text(p.instagram)),
                                DataCell(Text(p.contact)),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: PPErrorState(
            title: 'Admin indisponível',
            message: 'Não foi possível carregar a lista de perfis.',
            debugDetails: e.toString(),
            onRetry: () => ref.invalidate(adminProfilesProvider),
          ),
        ),
      ),
    );
  }
}
