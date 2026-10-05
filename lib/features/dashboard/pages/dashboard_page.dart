import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/dashboard_modules.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../widgets/dashboard_hero_section.dart';
import '../widgets/dashboard_operation_panel.dart';
import '../widgets/feature_hub_card.dart';

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
                      'Se você recebeu um convite da banda, entre por ele. '
                      'Não precisa cadastrar um perfil de artista só para ser integrante.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
        final displayName = user?.displayName;
        final email = user?.email;
        final greetName = (displayName != null && displayName.trim().isNotEmpty)
            ? displayName.trim()
            : (email ?? 'artista');

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardHeroSection(greetName: greetName, profile: active),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: PageContainer(
                    maxWidth: AppSpacing.maxContent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        DashboardOperationPanel(profile: active),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          'Ferramentas do projeto',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _DashboardModuleGrid(
                          profileId: profileId,
                          modules: DashboardModuleConfig.enabledInJourneyOrder,
                          cardExtent: 200,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          'Roadmap do produto',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _DashboardModuleGrid(
                          profileId: profileId,
                          modules: DashboardModuleConfig.roadmap,
                          cardExtent: 200,
                        ),
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

class _DashboardModuleGrid extends StatelessWidget {
  const _DashboardModuleGrid({
    required this.profileId,
    required this.modules,
    required this.cardExtent,
  });

  final String profileId;
  final List<DashboardModuleConfig> modules;
  final double cardExtent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cross = w >= 720 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            mainAxisExtent: cardExtent,
          ),
          itemCount: modules.length,
          itemBuilder: (context, i) {
            final m = modules[i];
            final enabled = m.status == DashboardModuleStatus.enabled;
            return FeatureHubCard(
              title: m.title,
              description: m.description,
              icon: m.icon,
              comingSoon: !enabled,
              journeyStep: m.journeyStep,
              onTap: enabled
                  ? () => context.push('${m.routePattern}/$profileId')
                  : null,
            );
          },
        );
      },
    );
  }
}
