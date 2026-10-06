import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../../../shared/widgets/pp_input.dart';
import '../../../shared/widgets/workspace_page_scaffold.dart';

/// Ficha da pessoa logada. O nome daqui é o que a banda vê em integrantes e tarefas.
class PersonCardPage extends ConsumerStatefulWidget {
  const PersonCardPage({super.key});

  @override
  ConsumerState<PersonCardPage> createState() => _PersonCardPageState();
}

class _PersonCardPageState extends ConsumerState<PersonCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final Set<String> _instruments = {};
  String _state = '';
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final card = await ref.read(profileServiceProvider).getPerson(user.uid);
      if (!mounted) return;
      setState(() {
        _nameController.text = card?.displayName ?? '';
        _cityController.text = card?.city ?? '';
        _state = card?.state ?? '';
        _instruments
          ..clear()
          ..addAll(card?.instruments ?? const []);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Não foi possível abrir sua ficha. Tente de novo.';
        _loading = false;
      });
    }
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.length < 2) return 'Use pelo menos 2 caracteres';
    if (name.length > 60) return 'Use no máximo 60 caracteres';
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final user = ref.read(currentUserProvider);
      await ref.read(profileServiceProvider).savePersonCard(
            displayName: _nameController.text,
            instruments: _instruments.toList(),
            city: _cityController.text,
            state: _state,
          );
      if (user != null) {
        ref.invalidate(personCardProvider(user.uid));
      }
      ref.invalidate(projectPeopleProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ficha salva. A banda passa a ver esse nome.')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar a ficha.${userFacingErrorSuffix(e)}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorkspacePageScaffold(
      title: 'Minha ficha',
      subtitle: 'Quem você é na banda',
      leading: IconButton.filledTonal(
        onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Voltar',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: PPErrorState(
                    debugDetails: _loadError!,
                    onRetry: () {
                      setState(() {
                        _loading = true;
                        _loadError = null;
                      });
                      _load();
                    },
                  ),
                )
              : PageContainer(
                  maxWidth: 560,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Esse nome aparece para os integrantes, nas tarefas e no caixa da banda. '
                          'A banda continua sendo um projeto separado da sua ficha.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PPInput(
                          label: 'Seu nome',
                          hint: 'Como a banda te chama',
                          controller: _nameController,
                          validator: _validateName,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Instrumentos',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final instrument in AppConstants.instrumentOptions)
                              FilterChip(
                                label: Text(instrument),
                                selected: _instruments.contains(instrument),
                                onSelected: _saving
                                    ? null
                                    : (selected) {
                                        setState(() {
                                          if (selected) {
                                            _instruments.add(instrument);
                                          } else {
                                            _instruments.remove(instrument);
                                          }
                                        });
                                      },
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PPInput(
                          label: 'Cidade (opcional)',
                          controller: _cityController,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<String>(
                          value: _state.isEmpty ? '' : _state,
                          decoration: const InputDecoration(labelText: 'Estado (opcional)'),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Não informar')),
                            ...AppConstants.brazilianStates.map(
                              (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                            ),
                          ],
                          onChanged: _saving ? null : (v) => setState(() => _state = v ?? ''),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        PPButton(
                          label: 'Salvar ficha',
                          icon: Icons.check_rounded,
                          onPressed: _saving ? null : _save,
                          isLoading: _saving,
                          fullWidth: true,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
