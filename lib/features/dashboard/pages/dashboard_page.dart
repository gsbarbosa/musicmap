import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/profile_member.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../widgets/dashboard_operation_panel.dart';

/// Central do hub — operação ligada ao projeto ativo no shell
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  void _syncWorkspaceProfile(WidgetRef ref, List<UserProfile> profiles) {
    final selected = ref.read(dashboardWorkspaceProfileIdProvider);
    final valid = selected != null && profiles.any((p) => p.id == selected);
    final resolved = !valid
        ? profiles.first.id
        : profiles.firstWhere((p) => p.id == selected).id;
    if (!valid) {
      Future.microtask(() {
        ref.read(dashboardWorkspaceProfileIdProvider.notifier).state = resolved;
      });
    }
  }

  String _resolveProfileId(WidgetRef ref, List<UserProfile> profiles) {
    final selected = ref.watch(dashboardWorkspaceProfileIdProvider);
    if (selected != null && profiles.any((p) => p.id == selected)) {
      return selected;
    }
    return profiles.first.id;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profilesAsync = user != null ? ref.watch(userProfilesProvider(user.uid)) : null;

    return profilesAsync?.when(
      data: (profiles) {
        if (profiles.isEmpty) {
          return Scaffold(
            body: Center(
              child: PageContainer(
                maxWidth: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Entre num projeto ou crie o seu',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Diga seu nome pelo convite da banda, ou marque o primeiro ensaio se o projeto for seu.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PPButton(
                      label: 'Diga seu nome',
                      icon: Icons.badge_outlined,
                      onPressed: () => context.push('/eu'),
                      variant: PPButtonVariant.outline,
                      fullWidth: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PPButton(
                      label: 'Entrar com convite',
                      icon: Icons.group_add_rounded,
                      onPressed: () => context.push('/join-project'),
                      variant: PPButtonVariant.primary,
                      fullWidth: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PPButton(
                      label: 'Criar meu projeto',
                      icon: Icons.rocket_launch_rounded,
                      onPressed: () => context.push('/complete-profile'),
                      variant: PPButtonVariant.outline,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        _syncWorkspaceProfile(ref, profiles);
        final profileId = _resolveProfileId(ref, profiles);
        final active = profiles.firstWhere((p) => p.id == profileId);
        final personAsync = user == null ? null : ref.watch(personCardProvider(user.uid));
        final personName = personAsync?.valueOrNull?.displayName.trim();
        final displayName = user?.displayName;
        final email = user?.email;
        final greetName = (personName != null && personName.isNotEmpty)
            ? personName
            : (displayName != null && displayName.trim().isNotEmpty)
                ? displayName.trim()
                : (email ?? 'artista');
        final needsPersonCard = personAsync?.hasValue == true &&
            (personName == null || personName.isEmpty);

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: PageContainer(
                    maxWidth: AppSpacing.maxContent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Olá, $greetName',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          active.artistName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _MissingFichaBanner(profileId: profileId, currentUid: user?.uid),
                        if (needsPersonCard) ...[
                          _PersonCardBanner(onOpen: () => context.push('/eu')),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        DashboardOperationPanel(profile: active),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: user != null
              ? PPErrorState(
                  debugDetails: e.toString(),
                  onRetry: () {
                    ref.invalidate(userProfilesProvider(user.uid));
                  },
                )
              : PPErrorState(debugDetails: e.toString()),
        ),
      ),
    ) ??
        const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
  }
}

class _MissingFichaBanner extends ConsumerWidget {
  const _MissingFichaBanner({required this.profileId, required this.currentUid});

  final String profileId;
  final String? currentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(profileMembersMapProvider(profileId)).valueOrNull;
    final people = ref.watch(projectPeopleProvider(profileId)).valueOrNull ?? const {};
    if (members == null || members.isEmpty) return const SizedBox.shrink();

    final missing = members.values.where((member) {
      if (member.userId == currentUid) return false;
      return _memberHasNoName(member, people[member.userId]?.displayName);
    }).toList();
    if (missing.isEmpty) return const SizedBox.shrink();

    final firstEmail = missing
        .map((member) => member.email.trim())
        .firstWhere((email) => email.isNotEmpty, orElse: () => '');
    final count = missing.length;
    final headline = count == 1 ? '1 integrante sem nome' : '$count integrantes sem nome';
    final detail = firstEmail.isEmpty
        ? 'A banda ainda não sabe quem é. Toque para preencher a ficha.'
        : '$firstEmail ainda não tem nome. Toque para preencher a ficha.';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Material(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push('/project-members/$profileId'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.person_off_rounded, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        detail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _memberHasNoName(ProfileMemberEntry member, String? personName) {
    final fromCard = personName?.trim() ?? '';
    if (fromCard.length >= 2) return false;
    return member.displayName.trim().length < 2;
  }
}

class _PersonCardBanner extends StatelessWidget {
  const _PersonCardBanner({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.badge_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Diga seu nome e o instrumento para a banda te reconhecer.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(onPressed: onOpen, child: const Text('Diga seu nome')),
          ],
        ),
      ),
    );
  }
}
