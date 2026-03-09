import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/landing/pages/landing_page.dart';
import '../../features/legal/pages/privacy_page.dart';
import '../../features/legal/pages/terms_page.dart';
import '../../features/profile/pages/complete_profile_page.dart';
import '../../features/profile/pages/edit_profile_page.dart';
import '../providers/providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router principal com GoRouter
/// Proteção de rotas: dashboard e edit-profile exigem auth + perfil completo
GoRouter createAppRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) async {
      final authState = ref.read(authStateProvider);
      final user = authState.valueOrNull ??
          ref.read(authServiceProvider).currentUser;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/';
      final isCompleteProfile = state.matchedLocation.startsWith('/complete-profile');
      final isDashboard = state.matchedLocation == '/dashboard';
      final isEditProfile = state.matchedLocation.startsWith('/edit-profile');

      if (user == null) {
        if (isDashboard || isEditProfile || isCompleteProfile) {
          return '/login';
        }
        return null;
      }

      final profiles =
          await ref.read(profileServiceProvider).getProfilesForUser(user.uid);

      if (profiles.isEmpty && !isCompleteProfile && (isDashboard || isEditProfile)) {
        return '/complete-profile';
      }

      if (isEditProfile) {
        final profileId = state.pathParameters['profileId'];
        if (profileId != null) {
          final profile = await ref.read(profileServiceProvider).getProfile(profileId);
          if (profile == null || profile.ownerUserId != user.uid) {
            return '/dashboard';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const LandingPage(),
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
        path: '/complete-profile',
        builder: (_, __) => const CompleteProfilePage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardPage(),
      ),
      GoRoute(
        path: '/edit-profile/:profileId',
        builder: (context, state) {
          final profileId = state.pathParameters['profileId'] ?? '';
          return EditProfilePage(profileId: profileId);
        },
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
