import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/profile_completion.dart';
import '../../../core/utils/share_url.dart';
import '../../../shared/models/music_release.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/pp_badge.dart';
import '../../../shared/widgets/pp_card.dart';

/// Barra de progresso, checklist e mini missões
class ProfileGamificationSection extends ConsumerWidget {
  final UserProfile profile;

  const ProfileGamificationSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ProfileCompletion.fromProfile(profile);
    final viewsAsync = ref.watch(profileViewCountProvider(profile.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PPCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progresso do perfil',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: c.percent / 100,
                  minHeight: 10,
                  backgroundColor: AppColors.surfaceSecondary,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${c.percent}% completo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const Divider(height: 24),
              Text('Checklist', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _checkRow('Perfil básico (nome, cidade, gênero, contato, Instagram)', c.basicComplete),
              _checkRow('Bio preenchida', c.bioComplete),
              _checkRow('Redes de streaming (Spotify / YouTube / TikTok)', c.streamingComplete),
              _checkRow('Interesses selecionados', c.interestsComplete),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _hubPistaCard(context, ref, profile),
        const SizedBox(height: 16),
        PPCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PPBadge(label: 'Early Access', variant: PPBadgeVariant.primary),
                  PPBadge(label: 'Cena fundadora', variant: PPBadgeVariant.secondary),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PPCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mini missões',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _mission(
                context,
                'Atualize sua bio com seu último lançamento.',
                c.bioComplete,
              ),
              _mission(
                context,
                'Confirme se suas redes e contato ainda estão corretos.',
                c.basicComplete,
              ),
              _mission(
                context,
                'Escolha seus interesses (shows, collabs, etc.).',
                c.interestsComplete,
              ),
              if (c.allComplete) ...[
                const SizedBox(height: 12),
                Text(
                  'Missão concluída – seu perfil está pronto para os próximos passos do Music Map.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        PPCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visualizações do link público',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              viewsAsync.when(
                data: (n) => Text(
                  '$n visualizações (aberturas da página pública)',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                loading: () => const LinearProgressIndicator(minHeight: 4),
                error: (_, __) => Text(
                  '—',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PPCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Link para redes (preview no WhatsApp/Instagram)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Use o link abaixo ao divulgar; ele inclui nome, descrição e foto quando houver.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              SelectableText(
                artistSocialShareUrl(profile.id),
                style: const TextStyle(color: AppColors.primary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                'Abrir perfil no app: ${artistPublicPageUrl(profile.id)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: artistSocialShareUrl(profile.id)));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link para redes copiado')),
                    );
                  }
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Copiar link para redes'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PPCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ideias premium',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Consultoria de IA para legendas, roteiros e calendário de posts — em breve.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _checkRow(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: done ? AppColors.textPrimary : AppColors.textSecondary,
                decoration: done ? TextDecoration.none : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mission(BuildContext context, String text, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.task_alt : Icons.circle_outlined,
            size: 18,
            color: done ? AppColors.secondary : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Missões da operação (GigBag, lançamentos, tarefas) — tom leve, integrado à gamificação.
Widget _hubPistaCard(BuildContext context, WidgetRef ref, UserProfile profile) {
  final id = profile.id;
  final gigAsync = ref.watch(gigbagStreamProvider(id));
  final relAsync = ref.watch(releasesStreamProvider(id));
  final taskAsync = ref.watch(operationalTasksStreamProvider(id));

  if (gigAsync.isLoading || relAsync.isLoading || taskAsync.isLoading) {
    return const PPCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  final gigbag = gigAsync.value ?? [];
  final releases = relAsync.value ?? [];
  final tasks = taskAsync.value ?? [];
  final now = DateTime.now();
  final nonTemplates = gigbag.where((c) => !c.isTemplate).toList();
  final pendingItems =
      nonTemplates.fold<int>(0, (acc, c) => acc + c.items.where((i) => !i.checked).length);
  final releasesWip = releases
      .where((r) =>
          r.status == MusicRelease.statusPlanning ||
          r.status == MusicRelease.statusInProgress)
      .length;
  final overdue = tasks.where((t) => t.isOpen && t.isOverdueAt(now)).length;

  final gigDone = pendingItems == 0;
  final relDone = releasesWip == 0;
  final taskDone = overdue == 0;

  return PPCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sua pista no hub',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Toque em cada linha para abrir o módulo.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        _hubPistaRow(
          context,
          done: gigDone,
          title: gigDone ? 'GigBag em dia' : 'GigBag com pendências',
          subtitle: gigDone
              ? 'Nada esperando check.'
              : '$pendingItems item(ns) ainda sem marcar.',
          onTap: () => context.push('/gigbag/$id'),
        ),
        _hubPistaRow(
          context,
          done: relDone,
          title: relDone ? 'Lançamentos tranquilos' : 'Lançamentos no radar',
          subtitle: relDone
              ? 'Nada em planejamento ativo.'
              : '$releasesWip lançamento(s) em andamento ou planejamento.',
          onTap: () => context.push('/releases/$id'),
        ),
        _hubPistaRow(
          context,
          done: taskDone,
          title: taskDone ? 'Tarefas no prazo' : 'Tarefas pedindo atenção',
          subtitle: taskDone
              ? 'Nenhuma tarefa aberta atrasada.'
              : overdue == 1
                  ? '1 tarefa passou do prazo.'
                  : '$overdue tarefas passaram do prazo.',
          onTap: () => context.push('/tasks/$id'),
        ),
        if (gigDone && relDone && taskDone) ...[
          const SizedBox(height: 8),
          Text(
            'Tudo certo por aqui — foca no show.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    ),
  );
}

Widget _hubPistaRow(
  BuildContext context, {
  required bool done,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                done ? Icons.check_circle : Icons.circle_outlined,
                size: 22,
                color: done ? AppColors.success : AppColors.secondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    ),
  );
}
