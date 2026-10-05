import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/widgets/app_usage_tutorial.dart';
import '../../shared/widgets/pp_logo.dart';

/// Shell autenticado: navegação persistente + contexto de projeto sempre visível.
/// Alinha ao modelo mental de negócio: **uma conta, vários projetos no hub**.
class WorkspaceShell extends ConsumerStatefulWidget {
  const WorkspaceShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends ConsumerState<WorkspaceShell> {
  String? _lastPath;

  void _syncWorkspaceFromRoute(String path) {
    final parts = path.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      final head = parts[0];
      if (head == 'shows' || head == 'tasks' || head == 'releases' || head == 'gigbag') {
        final pid = parts[1];
        if (pid != 'checklist') {
          ref.read(dashboardWorkspaceProfileIdProvider.notifier).state = pid;
        }
      } else if (head == 'project-members') {
        ref.read(dashboardWorkspaceProfileIdProvider.notifier).state = parts[1];
      }
    }
  }

  int _railIndex(String path) {
    if (path.startsWith('/dashboard')) return 0;
    if (path.startsWith('/shows/')) return 1;
    if (path.startsWith('/releases/')) return 2;
    if (path.startsWith('/gigbag/')) return 3;
    if (path.startsWith('/tasks/')) return 4;
    if (path == '/perfil' || path.startsWith('/edit-profile')) return 5;
    return 0;
  }

  void _goRail(BuildContext context, int index, String profileId) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/shows/$profileId');
        break;
      case 2:
        context.go('/releases/$profileId');
        break;
      case 3:
        context.go('/gigbag/$profileId');
        break;
      case 4:
        context.go('/tasks/$profileId');
        break;
      case 5:
        context.go('/perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).matchedLocation;
    if (_lastPath != path) {
      _lastPath = path;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncWorkspaceFromRoute(path);
      });
    }

    final user = ref.watch(currentUserProvider);
    final profilesAsync =
        user != null ? ref.watch(userProfilesProvider(user.uid)) : null;

    return profilesAsync?.when(
          data: (profiles) {
            if (profiles.isEmpty) {
              return widget.child;
            }
            return _buildShell(context, profiles);
          },
          loading: () => widget.child,
          error: (_, __) => widget.child,
        ) ??
        widget.child;
  }

  Widget _buildShell(BuildContext context, List<UserProfile> profiles) {
    final selected = ref.watch(dashboardWorkspaceProfileIdProvider);
    final profileId = (selected != null && profiles.any((p) => p.id == selected))
        ? selected as String
        : profiles.first.id;
    final active = profiles.firstWhere((p) => p.id == profileId);
    final idx = _railIndex(GoRouterState.of(context).matchedLocation);
    final isAdmin = ref.watch(isAdminProvider).valueOrNull == true;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.workspaceHero,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  _WorkspaceRail(
                    selectedIndex: idx,
                    onSelect: (i) => _goRail(context, i, profileId),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WorkspaceTopBar(
                        profiles: profiles,
                        activeProfileId: profileId,
                        activeName: active.artistName,
                        isAdmin: isAdmin,
                        onProfileSelected: (id) {
                          ref.read(dashboardWorkspaceProfileIdProvider.notifier).state = id;
                          final loc = GoRouterState.of(context).matchedLocation;
                          if (loc.startsWith('/shows/')) {
                            context.go('/shows/$id');
                          } else if (loc.startsWith('/gigbag/')) {
                            context.go('/gigbag/$id');
                          } else if (loc.startsWith('/tasks/')) {
                            context.go('/tasks/$id');
                          } else if (loc.startsWith('/releases/')) {
                            context.go('/releases/$id');
                          }
                        },
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppSpacing.radiusXl),
                          ),
                          child: ColoredBox(
                            color: AppColors.backgroundPrimary,
                            child: widget.child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : _WorkspaceBottomNav(
                  selectedIndex: idx,
                  onSelect: (i) => _goRail(context, i, profileId),
                ),
        );
      },
    );
  }
}

class _WorkspaceRail extends StatelessWidget {
  const _WorkspaceRail({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _destinations = [
    _RailItem(Icons.explore_rounded, 'Central'),
    _RailItem(Icons.event_rounded, 'Compromisso'),
    _RailItem(Icons.album_rounded, 'Lançamentos'),
    _RailItem(Icons.checklist_rounded, 'GigBag'),
    _RailItem(Icons.task_alt_rounded, 'Tarefas'),
    _RailItem(Icons.person_rounded, 'Meu espaço'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        border: Border(
          right: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              AppConstants.appMonogram,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _destinations.length,
              itemBuilder: (context, i) {
                final d = _destinations[i];
                final sel = i == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Material(
                    color: sel
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: InkWell(
                      onTap: () => onSelect(i),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              d.icon,
                              size: 24,
                              color: sel ? AppColors.primary : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d.label,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: sel ? AppColors.primary : AppColors.textSecondary,
                                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RailItem {
  final IconData icon;
  final String label;
  const _RailItem(this.icon, this.label);
}

class _WorkspaceTopBar extends ConsumerWidget {
  const _WorkspaceTopBar({
    required this.profiles,
    required this.activeProfileId,
    required this.activeName,
    required this.isAdmin,
    required this.onProfileSelected,
  });

  final List<UserProfile> profiles;
  final String activeProfileId;
  final String activeName;
  final bool isAdmin;
  final ValueChanged<String> onProfileSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 960;

    Widget projectChip() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.layers_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PROJETO ATIVO NO HUB',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  profiles.length > 1
                      ? DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: activeProfileId,
                            dropdownColor: AppColors.surfaceSecondary,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                            items: profiles
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(p.artistName),
                                  ),
                                )
                                .toList(),
                            onChanged: (id) {
                              if (id != null) onProfileSelected(id);
                            },
                          ),
                        )
                      : Text(
                          activeName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: wide
            ? Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          AppConstants.appTagline,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 3,
                    child: projectChip(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (isAdmin)
                    TextButton(
                      onPressed: () => context.push('/admin'),
                      child: const Text('Admin'),
                    ),
                  IconButton(
                    tooltip: 'Como usar — tour passo a passo',
                    onPressed: () => showAppUsageTutorial(context),
                    icon: const Icon(Icons.school_rounded),
                  ),
                  IconButton(
                    tooltip: 'Sair',
                    onPressed: () async {
                      ref.read(dashboardWorkspaceProfileIdProvider.notifier).state = null;
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/');
                    },
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const PPLogo(showTagline: false, fontSize: 20),
                      const Spacer(),
                      if (isAdmin)
                        TextButton(
                          onPressed: () => context.push('/admin'),
                          child: const Text('Admin'),
                        ),
                      IconButton(
                        tooltip: 'Como usar — tour passo a passo',
                        onPressed: () => showAppUsageTutorial(context),
                        icon: const Icon(Icons.school_rounded),
                      ),
                      IconButton(
                        tooltip: 'Sair',
                        onPressed: () async {
                          ref.read(dashboardWorkspaceProfileIdProvider.notifier).state = null;
                          await ref.read(authServiceProvider).signOut();
                          if (context.mounted) context.go('/');
                        },
                        icon: const Icon(Icons.logout_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  projectChip(),
                ],
              ),
      ),
    );
  }
}

class _WorkspaceBottomNav extends StatelessWidget {
  const _WorkspaceBottomNav({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex.clamp(0, 5),
      height: 68,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.2),
      onDestinationSelected: onSelect,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined, color: AppColors.textSecondary),
          selectedIcon: Icon(Icons.explore_rounded, color: AppColors.primary),
          label: 'Central',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_outlined),
          selectedIcon: Icon(Icons.event_rounded),
          label: 'Comprom.',
        ),
        NavigationDestination(
          icon: Icon(Icons.album_outlined),
          selectedIcon: Icon(Icons.album_rounded),
          label: 'Lanç.',
        ),
        NavigationDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist_rounded),
          label: 'GigBag',
        ),
        NavigationDestination(
          icon: Icon(Icons.task_alt_outlined),
          selectedIcon: Icon(Icons.task_alt_rounded),
          label: 'Tarefas',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Espaço',
        ),
      ],
    );
  }
}
