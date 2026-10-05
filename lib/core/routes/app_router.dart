import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/pages/admin_page.dart';
import '../../features/auth/pages/forgot_password_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/shell/workspace_shell.dart';
import '../../features/workspace/pages/gigbag_checklist_page.dart';
import '../../features/workspace/pages/gigbag_page.dart';
import '../../features/workspace/pages/releases_page.dart';
import '../../features/workspace/pages/commitment_detail_page.dart';
import '../../features/workspace/pages/shows_page.dart';
import '../../features/workspace/pages/tasks_page.dart';
import '../../features/legal/pages/privacy_page.dart';
import '../../features/legal/pages/terms_page.dart';
import '../../features/profile/pages/artist_profile_page.dart';
import '../../features/profile/pages/complete_profile_page.dart';
import '../../features/profile/pages/edit_profile_page.dart';
import '../../features/profile/pages/join_project_page.dart';
import '../../features/profile/pages/project_members_page.dart';
import '../../features/public/pages/public_artist_page.dart';
import '../providers/providers.dart';
import '../utils/share_url.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Router principal com GoRouter + shell autenticado (navegação + contexto de projeto)
GoRouter createAppRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) async {
      final authState = ref.read(authStateProvider);
      final user = authState.valueOrNull ??
          ref.read(authServiceProvider).currentUser;

      final loc = state.matchedLocation;
      final isDashboard = loc == '/dashboard';
      final isPerfil = loc == '/perfil';
      final isEditProfile = loc.startsWith('/edit-profile');
      final isAdminRoute = loc.startsWith('/admin');
      final isWorkspaceModule = loc.startsWith('/shows/') ||
          loc.startsWith('/gigbag/') ||
          loc.startsWith('/releases/') ||
          loc.startsWith('/tasks/') ||
          loc.startsWith('/project-members/');

      final isJoinProject = loc.startsWith('/join-project');
      final isJoinLink = loc.startsWith('/join/');

      if (user == null) {
        if (isDashboard ||
            isPerfil ||
            isEditProfile ||
            loc.startsWith('/complete-profile') ||
            isAdminRoute ||
            isWorkspaceModule ||
            isJoinProject) {
          final next = safeJoinPath(state.uri.queryParameters['next']);
          if (next != null) return '/login?next=${Uri.encodeQueryComponent(next)}';
          return '/login';
        }
        return null;
      }

      if (loc == '/' || loc == '/login' || loc == '/register') {
        return safeJoinPath(state.uri.queryParameters['next']) ?? '/dashboard';
      }

      if (isJoinLink) return null;

      if (isAdminRoute) {
        final admin = await ref.read(profileServiceProvider).isAdmin(user.uid, user.email);
        if (!admin) return '/dashboard';
        return null;
      }

      if (isWorkspaceModule) {
        final segs = state.uri.pathSegments;
        String? workspaceProfileId;
          if (segs.length >= 2) {
          if (segs[0] == 'shows' || segs[0] == 'releases' || segs[0] == 'tasks') {
            workspaceProfileId = segs[1];
          } else if (segs[0] == 'gigbag' && segs[1] != 'checklist') {
            workspaceProfileId = segs[1];
          } else if (segs[0] == 'project-members') {
            workspaceProfileId = segs[1];
          }
        }
        if (workspaceProfileId != null) {
          final p = await ref.read(profileServiceProvider).getProfile(workspaceProfileId);
          final ok = p != null &&
              await ref.read(profileServiceProvider).canAccessProfile(user.uid, workspaceProfileId);
          if (!ok) {
            return '/dashboard';
          }
        }
      }

      if (isEditProfile) {
        final profileId = state.pathParameters['profileId'];
        if (profileId != null) {
          final profile = await ref.read(profileServiceProvider).getProfile(profileId);
          final canAccess = profile != null &&
              await ref.read(profileServiceProvider).canAccessProfile(user.uid, profileId);
          if (!canAccess) {
            return '/dashboard';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/artist/:profileId',
        builder: (context, state) {
          final id = state.pathParameters['profileId'] ?? '';
          return PublicArtistPage(profileId: id);
        },
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (_, __) => const CompleteProfilePage(),
      ),
      GoRoute(
        path: '/join/:token',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return JoinProjectPage(token: token);
        },
      ),
      GoRoute(
        path: '/join-project',
        builder: (_, __) => const JoinProjectPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => WorkspaceShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardPage(),
          ),
          GoRoute(
            path: '/shows/:profileId/commitment/:showId',
            builder: (context, state) {
              final profileId = state.pathParameters['profileId'] ?? '';
              final showId = state.pathParameters['showId'] ?? '';
              return CommitmentDetailPage(profileId: profileId, showId: showId);
            },
          ),
          GoRoute(
            path: '/shows/:profileId',
            builder: (context, state) {
              final id = state.pathParameters['profileId'] ?? '';
              return ShowsPage(profileId: id);
            },
          ),
          GoRoute(
            path: '/releases/:profileId',
            builder: (context, state) {
              final id = state.pathParameters['profileId'] ?? '';
              return ReleasesPage(profileId: id);
            },
          ),
          GoRoute(
            path: '/tasks/:profileId',
            builder: (context, state) {
              final id = state.pathParameters['profileId'] ?? '';
              return TasksPage(profileId: id);
            },
          ),
          GoRoute(
            path: '/gigbag/:profileId',
            builder: (context, state) {
              final id = state.pathParameters['profileId'] ?? '';
              return GigbagPage(profileId: id);
            },
            routes: [
              GoRoute(
                path: 'checklist/:checklistId',
                builder: (context, state) {
                  final profileId = state.pathParameters['profileId'] ?? '';
                  final checklistId = state.pathParameters['checklistId'] ?? '';
                  return GigbagChecklistPage(
                    profileId: profileId,
                    checklistId: checklistId,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/project-members/:profileId',
            builder: (context, state) {
              final id = state.pathParameters['profileId'] ?? '';
              return ProjectMembersPage(profileId: id);
            },
          ),
          GoRoute(
            path: '/perfil',
            builder: (_, __) => const ArtistProfilePage(),
          ),
          GoRoute(
            path: '/edit-profile/:profileId',
            builder: (context, state) {
              final profileId = state.pathParameters['profileId'] ?? '';
              return EditProfilePage(profileId: profileId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminPage(),
      ),
      GoRoute(
        path: '/terms',
        builder: (_, __) => const TermsPage(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (_, __) => const PrivacyPage(),
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter(ref);
  ref.listen(authStateProvider, (_, __) => router.refresh());
  return router;
});
