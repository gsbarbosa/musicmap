import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/profile_completeness.dart';
import '../../../core/utils/share_url.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_badge.dart';

/// Hero da Central: saudação + resumo do projeto no mesmo bloco (sem card).
class DashboardHeroSection extends StatelessWidget {
  const DashboardHeroSection({
    super.key,
    required this.greetName,
    required this.profile,
  });

  final String greetName;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final comp = evaluateProfileCompleteness(profile);
    final photo = profile.photoUrl;
    final hasPhoto = photo != null && photo.isNotEmpty;
    final location = [profile.city, profile.state].where((e) => e.trim().isNotEmpty).join(' · ');
    final meta = [
      if (location.isNotEmpty) location,
      if (profile.genre.trim().isNotEmpty) profile.genre,
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: AppGradients.subtleGlow,
      ),
      child: PageContainer(
        maxWidth: AppSpacing.maxContent,
        centered: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, $greetName',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.surfaceSecondary,
                  backgroundImage: hasPhoto ? NetworkImage(photo) : null,
                  child: hasPhoto
                      ? null
                      : const Icon(Icons.music_note_rounded, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          PPBadge(
                            label: 'Early Access',
                            variant: PPBadgeVariant.primary,
                            compact: true,
                          ),
                          PPBadge(
                            label: 'Cena fundadora',
                            variant: PPBadgeVariant.secondary,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.artistName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          meta,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _ProfileRing(percent: comp.percent),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/artist/${profile.id}'),
                  icon: const Icon(Icons.public_rounded, size: 20),
                  label: const Text('Ver página pública'),
                  style: FilledButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: artistSocialShareUrl(profile.id)));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link para redes copiado')),
                      );
                    }
                  },
                  icon: const Icon(Icons.content_copy_rounded, size: 18),
                  label: const Text('Copiar link'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRing extends StatelessWidget {
  const _ProfileRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: 5,
              backgroundColor: AppColors.surfaceSecondary,
              color: AppColors.primary,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                'perfil',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      height: 1,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
