import 'package:firebase_database/firebase_database.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/user_profile.dart';

/// Serviço de perfil com Firebase Realtime Database
/// Gerencia CRUD de perfis de artistas
class ProfileService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Cria ou atualiza perfil do usuário
  Future<void> saveProfile(UserProfile profile) async {
    final ref = _db.child(AppConstants.profilesPath).child(profile.userId);
    await ref.set(profile.toMap());
  }

  /// Busca perfil pelo userId
  Future<UserProfile?> getProfile(String userId) async {
    final snapshot = await _db
        .child(AppConstants.profilesPath)
        .child(userId)
        .get();

    if (snapshot.exists && snapshot.value != null) {
      return UserProfile.fromMap(userId, Map<String, dynamic>.from(snapshot.value as Map));
    }
    return null;
  }

  /// Stream do perfil para reatividade
  Stream<UserProfile?> profileStream(String userId) {
    return _db
        .child(AppConstants.profilesPath)
        .child(userId)
        .onValue
        .map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        return UserProfile.fromMap(
          userId,
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
      }
      return null;
    });
  }

  /// Atualiza flag profileCompleted no nó users (opcional, para facilitar queries)
  Future<void> markProfileCompleted(String userId) async {
    await _db.child(AppConstants.usersPath).child(userId).update({
      'profileCompleted': true,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Cria/atualiza registro básico do usuário (chamado no sign up)
  Future<void> createUserRecord(String userId, String email) async {
    final ref = _db.child(AppConstants.usersPath).child(userId);
    final now = DateTime.now().toIso8601String();
    await ref.set({
      'email': email,
      'createdAt': now,
      'updatedAt': now,
      'profileCompleted': false,
    });
  }
}
