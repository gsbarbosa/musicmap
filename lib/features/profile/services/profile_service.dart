import 'dart:async';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/firebase/app_firebase_database.dart';
import '../../../../core/firebase/rtdb_rest_client.dart';
import '../../../../core/utils/profile_lookup.dart';
import '../../../../shared/models/profile_member.dart';
import '../../../../shared/models/user_profile.dart';

/// Serviço de perfil com Firebase Realtime Database
/// Um usuário pode ter vários perfis (várias bandas/artistas)
class ProfileService {
  final DatabaseReference _db = appFirebaseDatabase.ref();

  /// No Web o [FirebaseException.code] costuma ser `firebase_database/permission-denied`,
  /// não só `permission-denied` — comparação estrita impedia o fallback REST.
  static bool _isRtdbPermissionDenied(Object e) {
    if (e is FirebaseException) {
      return e.code.toLowerCase().contains('permission-denied');
    }
    return e.toString().toLowerCase().contains('permission-denied');
  }

  /// Garante sessão válida e token JWT atualizado (evita permission-denied no RTDB Web).
  Future<void> _refreshAuthTokenForRtdb() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      throw StateError('not_authenticated');
    }
    await u.getIdToken(true);
    final db = appFirebaseDatabase;
    try {
      db.goOffline();
      db.goOnline();
    } catch (_) {
      // Algumas plataformas podem não suportar; token já foi renovado
    }
  }

  /// Mobile/desktop: SDK + retry + REST. No Web, [saveProfile] usa REST direto.
  Future<void> _setProfileOrRetry(String profileId, Map<String, dynamic> profileData) async {
    final ref = _db.child(AppConstants.profilesPath).child(profileId);
    try {
      await ref.set(profileData);
      return;
    } catch (e) {
      if (!_isRtdbPermissionDenied(e)) rethrow;
    }
    await _refreshAuthTokenForRtdb();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    try {
      await ref.set(profileData);
      return;
    } catch (e) {
      if (!_isRtdbPermissionDenied(e)) rethrow;
    }
    await RtdbRestClient.putJson(
      '${AppConstants.profilesPath}/$profileId',
      profileData,
    );
  }

  /// Busca perfil duplicado por nome + Instagram (normalizados)
  /// Retorna o perfil existente se encontrar, null caso contrário
  Future<UserProfile?> findDuplicateProfile(String artistName, String instagram) async {
    await _refreshAuthTokenForRtdb();
    final key = normalizeProfileLookupKey(artistName, instagram);
    final Map<dynamic, dynamic> data;
    if (kIsWeb) {
      final raw = await RtdbRestClient.getJson(AppConstants.profilesPath);
      if (raw == null) return null;
      if (raw is! Map) return null;
      data = raw;
    } else {
      final snapshot = await _db.child(AppConstants.profilesPath).get();
      if (!snapshot.exists || snapshot.value == null) return null;
      data = snapshot.value as Map<dynamic, dynamic>;
    }
    for (final entry in data.entries) {
      final map = Map<String, dynamic>.from(entry.value as Map);
      final existingKey = normalizeProfileLookupKey(
        map['artistName']?.toString() ?? '',
        map['instagram']?.toString() ?? '',
      );
      if (existingKey == key) {
        return UserProfile.fromMap(entry.key as String, map);
      }
    }
    return null;
  }

  /// Cria ou atualiza perfil
  /// Se profile.id estiver vazio, cria novo
  Future<String> saveProfile(UserProfile profile) async {
    await _refreshAuthTokenForRtdb();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final isNew = profile.id.isEmpty;
    if (isNew) {
      if (profile.ownerUserId != uid) {
        throw StateError('owner_mismatch');
      }
    } else {
      final existing = await getProfile(profile.id);
      if (existing == null) throw StateError('not_found');
      if (profile.ownerUserId != existing.ownerUserId) {
        throw StateError('owner_mismatch');
      }
      final allowed = await canEditProfileMetadata(uid, profile.id);
      if (!allowed) throw StateError('forbidden');
    }

    final profileId = isNew ? _db.child(AppConstants.profilesPath).push().key! : profile.id;

    final profileData = profile.toMap();

    if (kIsWeb) {
      await RtdbRestClient.putJson(
        '${AppConstants.profilesPath}/$profileId',
        profileData,
      );
      if (isNew) {
        try {
          await RtdbRestClient.putJson(
            '${AppConstants.profilesByOwnerPath}/${profile.ownerUserId}/$profileId',
            true,
          );
        } catch (e) {
          try {
            await RtdbRestClient.delete('${AppConstants.profilesPath}/$profileId');
          } catch (_) {}
          rethrow;
        }
        try {
          await RtdbRestClient.incrementAtPath(AppConstants.totalProfilesPath, 1);
        } catch (_) {}
      }
    } else {
      await _setProfileOrRetry(profileId, profileData);
      if (isNew) {
        try {
          await _db
              .child(AppConstants.profilesByOwnerPath)
              .child(profile.ownerUserId)
              .child(profileId)
              .set(true);
        } on FirebaseException catch (e) {
          if (_isRtdbPermissionDenied(e)) {
            try {
              await RtdbRestClient.putJson(
                '${AppConstants.profilesByOwnerPath}/${profile.ownerUserId}/$profileId',
                true,
              );
            } catch (_) {
              try {
                await _db.child(AppConstants.profilesPath).child(profileId).remove();
              } catch (_) {
                try {
                  await RtdbRestClient.delete('${AppConstants.profilesPath}/$profileId');
                } catch (_) {}
              }
              rethrow;
            }
          } else {
            try {
              await _db.child(AppConstants.profilesPath).child(profileId).remove();
            } catch (_) {
              try {
                await RtdbRestClient.delete('${AppConstants.profilesPath}/$profileId');
              } catch (_) {}
            }
            rethrow;
          }
        } catch (e) {
          try {
            await _db.child(AppConstants.profilesPath).child(profileId).remove();
          } catch (_) {
            try {
              await RtdbRestClient.delete('${AppConstants.profilesPath}/$profileId');
            } catch (_) {}
          }
          rethrow;
        }
        try {
          await _db.child(AppConstants.totalProfilesPath).set(ServerValue.increment(1));
        } catch (_) {}
      }
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

  /// Lista perfis **próprios** + **compartilhados** (`user_profile_access`)
  Future<List<UserProfile>> getProfilesForUser(String userId) async {
    final ids = <String>{};

    final ownedSnap =
        await _db.child(AppConstants.profilesByOwnerPath).child(userId).get();
    if (ownedSnap.exists && ownedSnap.value != null) {
      ids.addAll(Map<String, dynamic>.from(ownedSnap.value as Map).keys.cast<String>());
    }

    final accessSnap =
        await _db.child(AppConstants.userProfileAccessPath).child(userId).get();
    if (accessSnap.exists && accessSnap.value != null) {
      ids.addAll(Map<String, dynamic>.from(accessSnap.value as Map).keys.cast<String>());
    }

    if (ids.isEmpty) {
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

    final profiles = <UserProfile>[];
    for (final id in ids) {
      final profile = await getProfile(id);
      if (profile != null) profiles.add(profile);
    }
    profiles.sort((a, b) => a.artistName.compareTo(b.artistName));
    return profiles;
  }

  /// Stream dos perfis do usuário (donos + compartilhados)
  Stream<List<UserProfile>> profilesStreamForUser(String userId) {
    StreamSubscription<DatabaseEvent>? subOwned;
    StreamSubscription<DatabaseEvent>? subAccess;

    Future<void> emit(StreamController<List<UserProfile>> c) async {
      try {
        if (!c.isClosed) c.add(await getProfilesForUser(userId));
      } catch (e, st) {
        if (!c.isClosed) c.addError(e, st);
      }
    }

    late final StreamController<List<UserProfile>> controller;
    controller = StreamController<List<UserProfile>>(
      onListen: () {
        subOwned = _db
            .child(AppConstants.profilesByOwnerPath)
            .child(userId)
            .onValue
            .listen((_) => emit(controller));
        subAccess = _db
            .child(AppConstants.userProfileAccessPath)
            .child(userId)
            .onValue
            .listen((_) => emit(controller));
        emit(controller);
      },
      onCancel: () async {
        await subOwned?.cancel();
        await subAccess?.cancel();
      },
    );

    return controller.stream;
  }

  /// Atualiza flag profileCompleted no nó users
  /// Se o nó não existir (ex.: conta Google sem `createUserRecord`), cria registro mínimo.
  Future<void> markProfileCompleted(String userId) async {
    await _refreshAuthTokenForRtdb();
    if (FirebaseAuth.instance.currentUser!.uid != userId) {
      throw StateError('owner_mismatch');
    }
    final now = DateTime.now().toIso8601String();
    if (kIsWeb) {
      final existing = await RtdbRestClient.getJson('${AppConstants.usersPath}/$userId');
      if (existing is Map && existing.isNotEmpty) {
        await RtdbRestClient.patchJson('${AppConstants.usersPath}/$userId', {
          'profileCompleted': true,
          'updatedAt': now,
        });
      } else {
        final email = FirebaseAuth.instance.currentUser?.email ?? '';
        await RtdbRestClient.putJson('${AppConstants.usersPath}/$userId', {
          'email': email,
          'accountType': 'person',
          'createdAt': now,
          'updatedAt': now,
          'profileCompleted': true,
        });
      }
      return;
    }
    final ref = _db.child(AppConstants.usersPath).child(userId);
    final snap = await ref.get();
    if (snap.exists && snap.value != null) {
      try {
        await ref.update({
          'profileCompleted': true,
          'updatedAt': now,
        });
      } catch (e) {
        if (!_isRtdbPermissionDenied(e)) rethrow;
        await RtdbRestClient.patchJson('${AppConstants.usersPath}/$userId', {
          'profileCompleted': true,
          'updatedAt': now,
        });
      }
    } else {
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      final payload = {
        'email': email,
        'accountType': 'person',
        'createdAt': now,
        'updatedAt': now,
        'profileCompleted': true,
      };
      try {
        await ref.set(payload);
      } catch (e) {
        if (!_isRtdbPermissionDenied(e)) rethrow;
        await RtdbRestClient.putJson('${AppConstants.usersPath}/$userId', payload);
      }
    }
  }

  /// Retorna o total de bandas/artistas cadastradas (apenas dados reais do banco)
  /// Lê de stats/totalProfiles (público) para exibir na landing para visitantes
  Future<int> getTotalProfileCount() async {
    final snapshot = await _db.child(AppConstants.totalProfilesPath).get();
    if (!snapshot.exists || snapshot.value == null) return 0;
    final v = snapshot.value;
    if (v is num) return v.toInt();
    return 0;
  }

  /// Retorna contagem de bandas/artistas por estado (visualização no Brasil)
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
    String? representationDeclarationAcceptedAt,
    String? referralSource,
  }) async {
    final ref = _db.child(AppConstants.usersPath).child(userId);
    final now = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
      'email': email,
      'accountType': accountType,
      'createdAt': now,
      'updatedAt': now,
      'profileCompleted': false,
    };
    if (representationDeclarationAcceptedAt != null) {
      data['representationDeclarationAcceptedAt'] = representationDeclarationAcceptedAt;
    }
    if (referralSource != null && referralSource.trim().isNotEmpty) {
      data['referralSource'] = referralSource.trim();
    }
    await ref.set(data);
  }

  /// Origem do cadastro (`?ref=`), para o admin
  Future<String?> getUserReferralSource(String userId) async {
    final snapshot =
        await _db.child(AppConstants.usersPath).child(userId).child('referralSource').get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return snapshot.value.toString();
  }

  /// Visualizações do link público (incrementado por Cloud Function)
  Stream<int> profileViewCountStream(String profileId) {
    return _db
        .child(AppConstants.profileViewsPath)
        .child(profileId)
        .onValue
        .map((event) {
      final v = event.snapshot.value;
      if (v is num) return v.toInt();
      return 0;
    });
  }

  Future<int> getProfileViewCount(String profileId) async {
    final snapshot = await _db.child(AppConstants.profileViewsPath).child(profileId).get();
    final v = snapshot.value;
    if (v is num) return v.toInt();
    return 0;
  }

  /// Retorna o tipo de conta do usuário
  Future<String> getUserAccountType(String userId) async {
    final snapshot = await _db.child(AppConstants.usersPath).child(userId).get();
    if (!snapshot.exists || snapshot.value == null) return 'person';
    final map = Map<String, dynamic>.from(snapshot.value as Map);
    final type = map['accountType'] as String? ?? 'person';
    return type == 'band' ? 'band' : 'person';
  }

  /// Lista [AppConstants.adminEmails] ou nó `admin_users/{uid}` no Realtime Database
  Future<bool> isAdmin(String uid, String? email) async {
    final e = email?.toLowerCase().trim();
    if (e != null && e.isNotEmpty) {
      for (final a in AppConstants.adminEmails) {
        if (a.toLowerCase().trim() == e) return true;
      }
    }
    final snap = await _db.child(AppConstants.adminUsersPath).child(uid).get();
    if (!snap.exists || snap.value == null) return false;
    final v = snap.value;
    return v == true || v == 'true';
  }

  /// Lista todos os perfis (uso interno / admin)
  Future<List<UserProfile>> getAllProfiles() async {
    final snapshot = await _db.child(AppConstants.profilesPath).get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final data = snapshot.value as Map<dynamic, dynamic>;
    final list = <UserProfile>[];
    for (final entry in data.entries) {
      list.add(
        UserProfile.fromMap(
          entry.key as String,
          Map<String, dynamic>.from(entry.value as Map),
        ),
      );
    }
    list.sort((a, b) => a.artistName.compareTo(b.artistName));
    return list;
  }

  // --- Acesso compartilhado (banda / projeto) ---

  /// Papel do usuário: `owner`, [AppConstants.roleAdmin], [roleEditor], [roleViewer] ou `none`
  Future<String> getWorkspaceRole(String userId, String profileId) async {
    final p = await getProfile(profileId);
    if (p == null) return 'none';
    if (p.ownerUserId == userId) return 'owner';
    final snap =
        await _db.child(AppConstants.userProfileAccessPath).child(userId).child(profileId).get();
    if (!snap.exists || snap.value == null) return 'none';
    final map = Map<String, dynamic>.from(snap.value as Map);
    return map['role']?.toString() ?? 'editor';
  }

  /// Lê agenda, GigBag etc. (qualquer membro ou dono)
  Future<bool> canAccessProfile(String userId, String profileId) async {
    final role = await getWorkspaceRole(userId, profileId);
    return role != 'none';
  }

  /// Editar metadados do perfil público / formulário
  Future<bool> canEditProfileMetadata(String userId, String profileId) async {
    final role = await getWorkspaceRole(userId, profileId);
    return role == 'owner' || role == AppConstants.roleAdmin;
  }

  /// Criar convites ou remover membros
  Future<bool> canManageMembers(String userId, String profileId) async {
    final role = await getWorkspaceRole(userId, profileId);
    return role == 'owner' || role == AppConstants.roleAdmin;
  }

  /// Escrita em shows, tarefas, GigBag (não inclui viewer)
  Future<bool> canWriteWorkspace(String userId, String profileId) async {
    final role = await getWorkspaceRole(userId, profileId);
    return role == 'owner' ||
        role == AppConstants.roleAdmin ||
        role == AppConstants.roleEditor;
  }

  /// Gera convite. Só dono (recomendado) ou admin; grava `invite_by_code/{token}`.
  Future<String> createProfileInvite(
    String profileId, {
    String role = AppConstants.roleEditor,
    int maxUses = 30,
    int expiresInDays = 60,
  }) async {
    await _refreshAuthTokenForRtdb();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    if (!await canManageMembers(uid, profileId)) {
      throw StateError('forbidden');
    }
    final r = role.trim();
    if (r != AppConstants.roleAdmin &&
        r != AppConstants.roleEditor &&
        r != AppConstants.roleViewer) {
      throw StateError('invalid_role');
    }
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789abcdefghijkmnpqrstuvwxyz';
    final rand = Random.secure();
    final token = List.generate(28, (_) => alphabet[rand.nextInt(alphabet.length)]).join();
    final now = DateTime.now();
    final expiresAt = now.add(Duration(days: expiresInDays)).millisecondsSinceEpoch;
    final payload = <String, dynamic>{
      'profileId': profileId,
      'role': r,
      'maxUses': maxUses,
      'uses': 0,
      'createdAt': now.toIso8601String(),
      'expiresAt': expiresAt,
      'createdBy': uid,
    };
    final path = '${AppConstants.inviteByCodePath}/$token';
    if (kIsWeb) {
      await RtdbRestClient.putJson(path, payload);
    } else {
      await _db.child(AppConstants.inviteByCodePath).child(token).set(payload);
    }
    return token;
  }

  /// Entra no projeto pelo convite.
  ///
  /// A Cloud Function `acceptInvite` está indisponível (HTTP 503). As regras do
  /// RTDB já deixam o usuário autenticado ler o convite e gravar o próprio acesso.
  Future<Map<String, dynamic>> acceptInviteWithCallable(String token) async {
    final trimmed = token.trim();
    if (trimmed.length < 8 || trimmed.length > 64) {
      throw FirebaseFunctionsException(
        code: 'invalid-argument',
        message: 'Código de convite inválido',
      );
    }
    await _refreshAuthTokenForRtdb();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final rawInvite = await _readJson('${AppConstants.inviteByCodePath}/$trimmed');
    if (rawInvite is! Map) {
      throw FirebaseFunctionsException(
        code: 'not-found',
        message: 'Convite não encontrado',
      );
    }
    final inv = Map<String, dynamic>.from(
      rawInvite.map((k, v) => MapEntry(k.toString(), v)),
    );
    final profileId = inv['profileId']?.toString() ?? '';
    if (profileId.isEmpty) {
      throw FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'Convite corrompido',
      );
    }
    final roleRaw = inv['role']?.toString();
    final role = (roleRaw == AppConstants.roleAdmin || roleRaw == AppConstants.roleViewer)
        ? roleRaw!
        : AppConstants.roleEditor;
    final maxUses = inv['maxUses'] is num ? (inv['maxUses'] as num).toInt() : 30;
    final uses = inv['uses'] is num ? (inv['uses'] as num).toInt() : 0;
    final expiresAt = inv['expiresAt'] is num ? (inv['expiresAt'] as num).toInt() : null;
    if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt) {
      throw FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'Este convite expirou',
      );
    }
    if (uses >= maxUses) {
      throw FirebaseFunctionsException(
        code: 'resource-exhausted',
        message: 'Este convite atingiu o limite de usos',
      );
    }

    final profileRaw = await _readJson('${AppConstants.profilesPath}/$profileId');
    if (profileRaw is! Map) {
      throw FirebaseFunctionsException(
        code: 'not-found',
        message: 'Projeto não existe mais',
      );
    }
    final ownerId = profileRaw['ownerUserId']?.toString();
    if (ownerId == uid) {
      return {'ok': true, 'profileId': profileId, 'alreadyOwner': true};
    }

    final existing = await _readJson('${AppConstants.userProfileAccessPath}/$uid/$profileId');
    if (existing != null) {
      return {'ok': true, 'profileId': profileId, 'alreadyMember': true};
    }

    final member = <String, dynamic>{
      'role': role,
      'joinedAt': DateTime.now().toIso8601String(),
    };
    try {
      await _writeJson('${AppConstants.userProfileAccessPath}/$uid/$profileId', member);
      await _writeJson('${AppConstants.profileMembersPath}/$profileId/$uid', member);
    } catch (e) {
      throw FirebaseFunctionsException(
        code: 'permission-denied',
        message: 'Não foi possível entrar no projeto.',
      );
    }
    return {'ok': true, 'profileId': profileId, 'role': role};
  }

  Future<dynamic> _readJson(String path) async {
    if (kIsWeb) return RtdbRestClient.getJson(path);
    final snap = await _db.child(path).get();
    if (!snap.exists || snap.value == null) return null;
    return snap.value;
  }

  Future<void> _writeJson(String path, Map<String, dynamic> value) async {
    if (kIsWeb) {
      await RtdbRestClient.putJson(path, value);
      return;
    }
    await _db.child(path).set(value);
  }

  /// Membros com linha em `profile_members` (não inclui o dono, que vem do perfil)
  Future<Map<String, ProfileMemberEntry>> listProfileMemberEntries(String profileId) async {
    final snap = await _db.child(AppConstants.profileMembersPath).child(profileId).get();
    if (!snap.exists || snap.value == null) return {};
    final raw = Map<String, dynamic>.from(snap.value as Map);
    return raw.map(
      (k, v) => MapEntry(
        k,
        ProfileMemberEntry.fromMap(k, Map<String, dynamic>.from(v as Map)),
      ),
    );
  }

  /// Remove membro (dono ou admin). Não remove o dono do projeto.
  Future<void> removeMemberFromProfile(String profileId, String memberUid) async {
    await _refreshAuthTokenForRtdb();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    if (!await canManageMembers(uid, profileId)) throw StateError('forbidden');
    final p = await getProfile(profileId);
    if (p != null && p.ownerUserId == memberUid) {
      throw StateError('cannot_remove_owner');
    }
    if (kIsWeb) {
      await RtdbRestClient.delete(
        '${AppConstants.userProfileAccessPath}/$memberUid/$profileId',
      );
      await RtdbRestClient.delete(
        '${AppConstants.profileMembersPath}/$profileId/$memberUid',
      );
    } else {
      await _db.child(AppConstants.userProfileAccessPath).child(memberUid).child(profileId).remove();
      await _db.child(AppConstants.profileMembersPath).child(profileId).child(memberUid).remove();
    }
  }

  /// Integrante sai do projeto (não se aplica ao dono)
  Future<void> leaveSharedProject(String profileId) async {
    await _refreshAuthTokenForRtdb();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final p = await getProfile(profileId);
    if (p != null && p.ownerUserId == uid) {
      throw StateError('owner_cannot_leave');
    }
    if (kIsWeb) {
      await RtdbRestClient.delete('${AppConstants.userProfileAccessPath}/$uid/$profileId');
      await RtdbRestClient.delete('${AppConstants.profileMembersPath}/$profileId/$uid');
    } else {
      await _db.child(AppConstants.userProfileAccessPath).child(uid).child(profileId).remove();
      await _db.child(AppConstants.profileMembersPath).child(profileId).child(uid).remove();
    }
  }

  Future<void> _removeAllSharedAccessForUser(String userId) async {
    final snap = await _db.child(AppConstants.userProfileAccessPath).child(userId).get();
    if (!snap.exists || snap.value == null) return;
    final ids = Map<String, dynamic>.from(snap.value as Map).keys.cast<String>();
    for (final profileId in ids) {
      try {
        if (kIsWeb) {
          await RtdbRestClient.delete(
            '${AppConstants.userProfileAccessPath}/$userId/$profileId',
          );
          await RtdbRestClient.delete(
            '${AppConstants.profileMembersPath}/$profileId/$userId',
          );
        } else {
          await _db.child(AppConstants.userProfileAccessPath).child(userId).child(profileId).remove();
          await _db.child(AppConstants.profileMembersPath).child(profileId).child(userId).remove();
        }
      } catch (_) {}
    }
  }

  /// Desativa todos os perfis e marca a conta como inativa (soft delete)
  Future<void> deactivateUserAccount(String userId) async {
    await _removeAllSharedAccessForUser(userId);

    final ownedSnap =
        await _db.child(AppConstants.profilesByOwnerPath).child(userId).get();
    final ownedIds = <String>{};
    if (ownedSnap.exists && ownedSnap.value != null) {
      ownedIds.addAll(Map<String, dynamic>.from(ownedSnap.value as Map).keys.cast<String>());
    }

    final now = DateTime.now();
    for (final id in ownedIds) {
      final p = await getProfile(id);
      if (p != null) {
        final updated = p.copyWith(
          status: 'inactive',
          publicProfile: false,
          updatedAt: now,
        );
        await _db.child(AppConstants.profilesPath).child(p.id).set(updated.toMap());
      }
    }
    await _db.child(AppConstants.usersPath).child(userId).update({
      'accountStatus': 'inactive',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Remove perfis **próprios**, vínculos e registro do usuário (não apaga projetos só compartilhados)
  Future<void> deleteUserDatabaseData(String userId) async {
    await _removeAllSharedAccessForUser(userId);

    final ownedSnap =
        await _db.child(AppConstants.profilesByOwnerPath).child(userId).get();
    final ownedIds = <String>[];
    if (ownedSnap.exists && ownedSnap.value != null) {
      ownedIds.addAll(Map<String, dynamic>.from(ownedSnap.value as Map).keys.cast<String>());
    }

    for (final id in ownedIds) {
      try {
        await _db.child(AppConstants.profileMembersPath).child(id).remove();
      } catch (_) {}
      await _db.child(AppConstants.profilesPath).child(id).remove();
      try {
        await _db.child(AppConstants.profileViewsPath).child(id).remove();
      } catch (_) {}
      try {
        await _db.child(AppConstants.totalProfilesPath).set(ServerValue.increment(-1));
      } catch (_) {}
    }
    await _db.child(AppConstants.profilesByOwnerPath).child(userId).remove();
    try {
      await _db.child(AppConstants.userProfileAccessPath).child(userId).remove();
    } catch (_) {}
    await _db.child(AppConstants.usersPath).child(userId).remove();
  }
}
