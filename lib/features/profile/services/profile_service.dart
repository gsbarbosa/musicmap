import 'package:firebase_database/firebase_database.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/user_profile.dart';

/// Serviço de perfil com Firebase Realtime Database
/// Um usuário pode ter vários perfis (várias bandas/artistas)
class ProfileService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Cria ou atualiza perfil
  /// Se profile.id estiver vazio, cria novo
  Future<String> saveProfile(UserProfile profile) async {
    final isNew = profile.id.isEmpty;
    final profileId = isNew ? _db.child(AppConstants.profilesPath).push().key! : profile.id;

    final profileData = profile.toMap();
    await _db.child(AppConstants.profilesPath).child(profileId).set(profileData);

    if (isNew) {
      await _db
          .child(AppConstants.profilesByOwnerPath)
          .child(profile.ownerUserId)
          .child(profileId)
          .set(true);
    }

    return profileId;
  }

  /// Stream de um perfil específico
  Stream<UserProfile?> profileStream(String profileId) {
    return _db
        .child(AppConstants.profilesPath)
        .child(profileId)
        .onValue
        .map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        return UserProfile.fromMap(
          profileId,
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
      }
      return null;
    });
  }

  /// Busca perfil pelo profileId
  Future<UserProfile?> getProfile(String profileId) async {
    final snapshot = await _db
        .child(AppConstants.profilesPath)
        .child(profileId)
        .get();

    if (snapshot.exists && snapshot.value != null) {
      return UserProfile.fromMap(profileId, Map<String, dynamic>.from(snapshot.value as Map));
    }
    return null;
  }

  /// Lista todos os perfis do usuário
  Future<List<UserProfile>> getProfilesForUser(String userId) async {
    final snapshot = await _db
        .child(AppConstants.profilesByOwnerPath)
        .child(userId)
        .get();

    if (snapshot.exists && snapshot.value != null) {
      final profileIds =
          Map<String, dynamic>.from(snapshot.value as Map).keys.cast<String>();
    final profiles = <UserProfile>[];

    for (final id in profileIds) {
      final profile = await getProfile(id);
      if (profile != null) profiles.add(profile);
    }

      profiles.sort((a, b) => a.artistName.compareTo(b.artistName));
      return profiles;
    }

    final legacySnapshot =
        await _db.child(AppConstants.profilesPath).child(userId).get();
    if (legacySnapshot.exists && legacySnapshot.value != null) {
      final p = UserProfile.fromMap(
        userId,
        Map<String, dynamic>.from(legacySnapshot.value as Map),
        ownerUserIdOverride: userId,
      );
      return [p];
    }
    return [];
  }

  /// Stream dos perfis do usuário (reativo)
  Stream<List<UserProfile>> profilesStreamForUser(String userId) {
    return _db
        .child(AppConstants.profilesByOwnerPath)
        .child(userId)
        .onValue
        .asyncMap((event) async {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final profileIds =
            Map<String, dynamic>.from(event.snapshot.value as Map).keys.cast<String>();
        final profiles = <UserProfile>[];
        for (final id in profileIds) {
          final profile = await getProfile(id);
          if (profile != null) profiles.add(profile);
        }
        profiles.sort((a, b) => a.artistName.compareTo(b.artistName));
        return profiles;
      }
      final legacySnapshot =
          await _db.child(AppConstants.profilesPath).child(userId).get();
      if (legacySnapshot.exists && legacySnapshot.value != null) {
        final p = UserProfile.fromMap(
          userId,
          Map<String, dynamic>.from(legacySnapshot.value as Map),
          ownerUserIdOverride: userId,
        );
        return [p];
      }
      return [];
    });
  }

  /// Atualiza flag profileCompleted no nó users
  Future<void> markProfileCompleted(String userId) async {
    await _db.child(AppConstants.usersPath).child(userId).update({
      'profileCompleted': true,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Retorna contagem de bandas/artistas por estado (para o mapa)
  Future<Map<String, int>> getLocationCountsByState() async {
    final snapshot = await _db.child(AppConstants.profilesPath).get();
    if (!snapshot.exists || snapshot.value == null) return {};

    final data = snapshot.value as Map<dynamic, dynamic>;
    final counts = <String, int>{};

    for (final entry in data.values) {
      final map = Map<String, dynamic>.from(entry as Map);
      final state = (map['state'] as String? ?? '').toUpperCase().trim();
      if (state.length == 2) {
        counts[state] = (counts[state] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Cria/atualiza registro básico do usuário (chamado no sign up)
  /// accountType: 'band' (conta da banda) ou 'person' (pessoa que gerencia bandas)
  Future<void> createUserRecord(
    String userId,
    String email, {
    String accountType = 'person',
  }) async {
    final ref = _db.child(AppConstants.usersPath).child(userId);
    final now = DateTime.now().toIso8601String();
    await ref.set({
      'email': email,
      'accountType': accountType,
      'createdAt': now,
      'updatedAt': now,
      'profileCompleted': false,
    });
  }

  /// Retorna o tipo de conta do usuário
  Future<String> getUserAccountType(String userId) async {
    final snapshot = await _db.child(AppConstants.usersPath).child(userId).get();
    if (!snapshot.exists || snapshot.value == null) return 'person';
    final map = Map<String, dynamic>.from(snapshot.value as Map);
    final type = map['accountType'] as String? ?? 'person';
    return type == 'band' ? 'band' : 'person';
  }
}
