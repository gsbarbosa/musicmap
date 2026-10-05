import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Abre o passo a passo “caminho feliz” para novos usuários (overlay estilo tutorial).
void showAppUsageTutorial(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const _AppUsageTutorialDialog(),
  );
}

class _TutorialStep {
  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

List<_TutorialStep> _steps() => [
      const _TutorialStep(
        icon: Icons.waving_hand_rounded,
        title: 'Bem-vindo ao hub',
        body:
            'O ${AppConstants.appName} reúne agenda, checklists, tarefas, lançamentos e seu perfil '
            'público em um só lugar. Uma conta pode ter vários projetos (bandas ou artistas).',
      ),
      const _TutorialStep(
        icon: Icons.layers_rounded,
        title: 'Projeto ativo',
        body:
            'No topo da tela, o seletor define qual projeto está em foco. Compromisso, Lançamentos, '
            'GigBag e Tarefas sempre usam essa banda — troque aqui quando trabalhar em outro projeto.',
      ),
      const _TutorialStep(
        icon: Icons.explore_rounded,
        title: 'Central',
        body:
            'Comece pela Central: resumo do que importa hoje e atalhos ao menu lateral '
            '(Compromisso → Lançamentos → GigBag → Tarefas). É o painel de comando do projeto ativo.',
      ),
      const _TutorialStep(
        icon: Icons.event_rounded,
        title: 'Compromisso — agenda',
        body:
            'Cadastre compromissos (show, ensaio, gravação…). Toque no card para abrir o hub do '
            'compromisso: resumo do evento, checklists ligadas e tarefas vinculadas àquele evento.',
      ),
      const _TutorialStep(
        icon: Icons.album_rounded,
        title: 'Lançamentos',
        body:
            'Planeje singles, EPs e álbuns com datas, status e marcos (capa, distribuição, divulgação). '
            'Tudo fica registrado para a equipe acompanhar.',
      ),
      const _TutorialStep(
        icon: Icons.checklist_rounded,
        title: 'GigBag',
        body:
            'Monte checklists de palco e estrada. Você pode duplicar modelos, criar listas vazias e '
            'vincular ao compromisso na agenda quando fizer sentido.',
      ),
      const _TutorialStep(
        icon: Icons.task_alt_rounded,
        title: 'Tarefas',
        body:
            'Organize pendências com prazo, prioridade e responsável. Ideal para lembretes que não '
            'cabem só na checklist de um show.',
      ),
      const _TutorialStep(
        icon: Icons.person_rounded,
        title: 'Meu espaço',
        body:
            'Ajuste dados do projeto, veja a página pública, convide integrantes (código de convite) '
            'e gerencie quem acessa o hub. No celular, use a barra inferior; na tela larga, o menu à esquerda.',
      ),
    ];

class _AppUsageTutorialDialog extends StatefulWidget {
  const _AppUsageTutorialDialog();

  @override
  State<_AppUsageTutorialDialog> createState() => _AppUsageTutorialDialogState();
}

class _AppUsageTutorialDialogState extends State<_AppUsageTutorialDialog> {
  int _index = 0;

  List<_TutorialStep> get _all => _steps();

  void _next() {
    if (_index >= _all.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
  }

  void _prev() {
    if (_index <= 0) return;
    setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final step = _all[_index];
    final last = _index == _all.length - 1;
    final progress = (_index + 1) / _all.length;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 24),
      backgroundColor: AppColors.surfaceSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(step.icon, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Como usar o app',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Passo ${_index + 1} de ${_all.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                step.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Pular'),
                  ),
                  const Spacer(),
                  if (_index > 0)
                    TextButton(
                      onPressed: _prev,
                      child: const Text('Voltar'),
                    ),
                  if (_index > 0) const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _next,
                    child: Text(last ? 'Concluir' : 'Próximo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
