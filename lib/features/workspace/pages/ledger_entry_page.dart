import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../../shared/models/artist_show.dart';
import '../../../shared/models/ledger_entry.dart';
import '../../../shared/models/person_card.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../../../shared/widgets/pp_input.dart';
import '../../../shared/widgets/workspace_page_scaffold.dart';
import '../ledger/ledger_math.dart';

class LedgerEntryPage extends ConsumerStatefulWidget {
  final String profileId;
  final String? entryId;

  const LedgerEntryPage({super.key, required this.profileId, this.entryId});

  @override
  ConsumerState<LedgerEntryPage> createState() => _LedgerEntryPageState();
}

class _LedgerEntryPageState extends ConsumerState<LedgerEntryPage> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _weights = <String, TextEditingController>{};
  final _parts = <String, TextEditingController>{};
  final _selected = <String>{};

  String _kind = LedgerEntry.kindExpense;
  String _category = LedgerEntry.categoryTransporte;
  String _splitMode = LedgerEntry.splitEqual;
  String _paidBy = '';
  String _showId = '';
  DateTime _date = DateTime.now();
  bool _hydrated = false;
  bool _saving = false;
  Map<String, String> _savedNames = {};

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    for (final controller in _weights.values) {
      controller.dispose();
    }
    for (final controller in _parts.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _ensureControllers(Iterable<String> ids) {
    for (final id in ids) {
      _weights.putIfAbsent(id, () => TextEditingController(text: '1'));
      _parts.putIfAbsent(id, () => TextEditingController());
    }
  }

  void _hydrate({
    required LedgerEntry? existing,
    required Map<String, PersonCard> people,
    required String? currentUid,
  }) {
    final ids = <String>{
      ...people.keys,
      ...?existing?.participants.keys,
      if (existing != null && existing.paidBy.isNotEmpty) existing.paidBy,
    };
    _ensureControllers(ids);
    if (_hydrated) return;
    if (widget.entryId != null && existing == null) return;
    _hydrated = true;
    if (existing == null) {
      _paidBy = currentUid != null && people.containsKey(currentUid)
          ? currentUid
          : (people.keys.isEmpty ? '' : people.keys.first);
      _selected.addAll(people.keys);
      _date = DateTime.now();
      return;
    }
    _titleCtrl.text = existing.title;
    _amountCtrl.text = centsToInput(existing.amountCents);
    _kind = existing.kind;
    _category = existing.category;
    _splitMode = existing.splitMode;
    _paidBy = existing.paidBy;
    _showId = existing.showId ?? '';
    _date = existing.date;
    _savedNames = Map<String, String>.from(existing.names);
    _selected
      ..clear()
      ..addAll(existing.participants.keys);
    if (existing.splitMode == LedgerEntry.splitShares) {
      for (final item in existing.participants.entries) {
        _weights[item.key]?.text = '${item.value}';
      }
    }
    if (existing.splitMode == LedgerEntry.splitAmounts || existing.kind == LedgerEntry.kindSettlement) {
      for (final item in existing.participants.entries) {
        _parts[item.key]?.text = centsToInput(item.value);
      }
    }
  }

  String _label(String uid, Map<String, PersonCard> people) {
    final live = people[uid]?.displayName.trim() ?? '';
    if (live.isNotEmpty) return live;
    final saved = _savedNames[uid]?.trim() ?? '';
    if (saved.isNotEmpty) return saved;
    return 'Nome não definido';
  }

  List<String> _categories() {
    if (_kind == LedgerEntry.kindIncome) return LedgerEntry.incomeCategories;
    if (_kind == LedgerEntry.kindSettlement) return const [LedgerEntry.categoryAcerto];
    return LedgerEntry.expenseCategories;
  }

  Map<String, String> _namesFor(Map<String, PersonCard> people, Iterable<String> uids) {
    return {
      for (final uid in uids) uid: _label(uid, people),
    };
  }

  LedgerEntry? _preview(Map<String, PersonCard> people) {
    final amount = parseReaisToCents(_amountCtrl.text);
    if (amount == null || _paidBy.isEmpty || _selected.isEmpty) return null;
    final participants = _participants(amount);
    if (participants == null) return null;
    final now = DateTime.now();
    return LedgerEntry(
      id: widget.entryId ?? '',
      profileId: widget.profileId,
      title: _titleCtrl.text.trim().isEmpty ? 'Prévia' : _titleCtrl.text.trim(),
      kind: _kind,
      amountCents: amount,
      date: _date,
      category: _category,
      paidBy: _paidBy,
      splitMode: _splitMode,
      participants: participants,
      createdBy: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, int>? _participants(int amountCents) {
    if (_kind == LedgerEntry.kindSettlement) {
      if (_selected.length != 1) return null;
      final receiver = _selected.first;
      if (receiver == _paidBy) return null;
      return {receiver: amountCents};
    }
    if (_selected.isEmpty) return null;
    if (_splitMode == LedgerEntry.splitEqual) {
      return {for (final uid in _selected) uid: 1};
    }
    if (_splitMode == LedgerEntry.splitShares) {
      final weights = <String, int>{};
      for (final uid in _selected) {
        final weight = int.tryParse(_weights[uid]?.text.trim() ?? '');
        if (weight == null || weight <= 0) return null;
        weights[uid] = weight;
      }
      return weights;
    }
    final parts = <String, int>{};
    for (final uid in _selected) {
      final cents = parseReaisToCents(_parts[uid]?.text ?? '');
      if (cents == null) return null;
      parts[uid] = cents;
    }
    return parts;
  }

  Future<void> _save(Map<String, PersonCard> people, LedgerEntry? existing) async {
    final amount = parseReaisToCents(_amountCtrl.text);
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Informe um título');
      return;
    }
    if (amount == null) {
      _snack('Informe um valor maior que zero');
      return;
    }
    if (_paidBy.isEmpty) {
      _snack(_kind == LedgerEntry.kindIncome ? 'Informe quem recebeu' : 'Informe quem pagou');
      return;
    }
    final participants = _participants(amount);
    if (participants == null) {
      _snack(
        _kind == LedgerEntry.kindSettlement
            ? 'Escolha quem recebeu o acerto'
            : 'Confira quem entra na divisão e os valores',
      );
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final now = DateTime.now();
    final entry = LedgerEntry(
      id: existing?.id ?? '',
      profileId: widget.profileId,
      title: _titleCtrl.text.trim(),
      kind: _kind,
      amountCents: amount,
      date: _date,
      category: _category,
      paidBy: _paidBy,
      splitMode: _kind == LedgerEntry.kindSettlement ? LedgerEntry.splitAmounts : _splitMode,
      participants: participants,
      names: _namesFor(people, {...participants.keys, _paidBy}),
      showId: _showId.isEmpty ? null : _showId,
      createdBy: existing?.createdBy ?? user.uid,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    final error = validateLedgerEntry(entry);
    if (error != null) {
      _snack(error);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(artistWorkspaceServiceProvider).saveLedgerEntry(entry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(existing == null ? 'Lançamento criado' : 'Lançamento atualizado')),
      );
      context.pop();
    } catch (e) {
      final message = e is ArgumentError
          ? e.message?.toString() ?? 'Não foi possível salvar'
          : 'Não foi possível salvar.${userFacingErrorSuffix(e)}';
      _snack(message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(projectPeopleProvider(widget.profileId));
    final entriesAsync = ref.watch(ledgerStreamProvider(widget.profileId));
    final shows = ref.watch(showsStreamProvider(widget.profileId)).valueOrNull ?? const <ArtistShow>[];
    final user = ref.watch(currentUserProvider);

    return peopleAsync.when(
      data: (people) {
        if (widget.entryId != null && !entriesAsync.hasValue) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final existing = widget.entryId == null
            ? null
            : entriesAsync.valueOrNull?.where((entry) => entry.id == widget.entryId).firstOrNull;
        if (widget.entryId != null && entriesAsync.hasValue && existing == null) {
          return const Scaffold(body: Center(child: Text('Lançamento não encontrado')));
        }
        _hydrate(existing: existing, people: people, currentUid: user?.uid);
        final ids = <String>{
          ...people.keys,
          ..._selected,
          if (_paidBy.isNotEmpty) _paidBy,
        }.toList()
          ..sort((a, b) => _label(a, people).toLowerCase().compareTo(_label(b, people).toLowerCase()));
        final preview = _preview(people);
        final payerLabel = _kind == LedgerEntry.kindIncome ? 'Quem recebeu' : 'Quem pagou';

        return WorkspacePageScaffold(
          title: existing == null ? 'Novo lançamento' : 'Editar lançamento',
          subtitle: _kind == LedgerEntry.kindSettlement ? 'Acerto entre duas pessoas' : 'Caixa da banda',
          leading: IconButton.filledTonal(
            onPressed: () => context.canPop() ? context.pop() : context.go('/caixa/${widget.profileId}'),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Voltar',
          ),
          body: PageContainer(
            maxWidth: 560,
            child: people.isEmpty && existing == null
                ? const Text('Preencha as fichas da banda antes de lançar no caixa.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_kind != LedgerEntry.kindSettlement) ...[
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: LedgerEntry.kindExpense, label: Text('Despesa')),
                            ButtonSegment(value: LedgerEntry.kindIncome, label: Text('Receita')),
                          ],
                          selected: {_kind},
                          onSelectionChanged: _saving
                              ? null
                              : (values) {
                                  setState(() {
                                    _kind = values.first;
                                    final options = _categories();
                                    if (!options.contains(_category)) _category = options.first;
                                  });
                                },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      PPInput(label: 'Título', controller: _titleCtrl, hint: 'Ensaio, van, cachê do Sesc'),
                      const SizedBox(height: AppSpacing.md),
                      PPInput(
                        label: 'Valor',
                        controller: _amountCtrl,
                        hint: '0,00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Data'),
                        subtitle: Text(_formatDate(_date)),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today_rounded),
                          onPressed: _saving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _date,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) setState(() => _date = picked);
                                },
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: _categories().contains(_category) ? _category : _categories().first,
                        decoration: const InputDecoration(labelText: 'Categoria'),
                        items: [
                          for (final category in _categories())
                            DropdownMenuItem(
                              value: category,
                              child: Text(LedgerEntry.categoryLabel(category)),
                            ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _category = value ?? _categories().first),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        value: ids.contains(_paidBy) ? _paidBy : null,
                        decoration: InputDecoration(labelText: payerLabel),
                        items: [
                          for (final id in ids)
                            DropdownMenuItem(value: id, child: Text(_label(id, people))),
                        ],
                        onChanged: _saving ? null : (value) => setState(() => _paidBy = value ?? ''),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_kind != LedgerEntry.kindSettlement) ...[
                        DropdownButtonFormField<String>(
                          value: _splitMode,
                          decoration: const InputDecoration(labelText: 'Divisão'),
                          items: const [
                            DropdownMenuItem(value: LedgerEntry.splitEqual, child: Text('Igual')),
                            DropdownMenuItem(value: LedgerEntry.splitShares, child: Text('Por cotas')),
                            DropdownMenuItem(value: LedgerEntry.splitAmounts, child: Text('Por valor')),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _splitMode = value ?? LedgerEntry.splitEqual),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<String>(
                          value: _showId.isEmpty || shows.any((show) => show.id == _showId) ? _showId : '',
                          decoration: const InputDecoration(labelText: 'Compromisso (opcional)'),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Sem vínculo')),
                            for (final show in shows)
                              DropdownMenuItem(
                                value: show.id,
                                child: Text(show.title.isEmpty ? 'Compromisso' : show.title),
                              ),
                          ],
                          onChanged: _saving ? null : (value) => setState(() => _showId = value ?? ''),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        _kind == LedgerEntry.kindSettlement ? 'Quem recebeu' : 'Quem entra na divisão',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final id in ids)
                        if (_kind != LedgerEntry.kindSettlement || id != _paidBy)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _selected.contains(id),
                            title: Text(_label(id, people)),
                            subtitle: !_selected.contains(id)
                                ? null
                                : _splitMode == LedgerEntry.splitShares && _kind != LedgerEntry.kindSettlement
                                    ? TextField(
                                        controller: _weights[id],
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: const InputDecoration(labelText: 'Cotas'),
                                        onChanged: (_) => setState(() {}),
                                      )
                                    : _splitMode == LedgerEntry.splitAmounts &&
                                            _kind != LedgerEntry.kindSettlement
                                        ? TextField(
                                            controller: _parts[id],
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(labelText: 'Valor da parte'),
                                            onChanged: (_) => setState(() {}),
                                          )
                                        : null,
                            onChanged: _saving
                                ? null
                                : (checked) {
                                    setState(() {
                                      if (_kind == LedgerEntry.kindSettlement) {
                                        _selected
                                          ..clear()
                                          ..add(id);
                                      } else if (checked == true) {
                                        _selected.add(id);
                                      } else {
                                        _selected.remove(id);
                                      }
                                    });
                                  },
                          ),
                      if (preview != null && _kind != LedgerEntry.kindSettlement) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Prévia da divisão',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        for (final share in sharesOf(preview).entries)
                          Text(
                            '${_label(share.key, people)} · ${formatCents(share.value)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      PPButton(
                        label: 'Salvar',
                        icon: Icons.check_rounded,
                        onPressed: _saving ? null : () => _save(people, existing),
                        isLoading: _saving,
                        fullWidth: true,
                      ),
                      const SizedBox(height: AppSpacing.xl),
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
            onRetry: () => ref.invalidate(projectPeopleProvider(widget.profileId)),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
