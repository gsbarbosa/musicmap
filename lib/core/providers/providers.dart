import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/services/auth_service.dart';
import '../../features/profile/services/profile_service.dart';
import '../../shared/models/user_profile.dart';

/// Providers Riverpod para injeção de dependência
/// Escolha: Riverpod é moderno, type-safe, testável e não depende de BuildContext

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final userProfileProvider = StreamProvider.family<UserProfile?, String>((ref, userId) {
  return ref.watch(profileServiceProvider).profileStream(userId);
});
