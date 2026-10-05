import 'package:firebase_database/firebase_database.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/firebase/app_firebase_database.dart';
import '../../../shared/models/artist_show.dart';
import '../../../shared/models/gigbag_checklist.dart';
import '../../../shared/models/music_release.dart';
import '../../../shared/models/operational_task.dart';

/// Persistência de shows, GigBag e lançamentos (Realtime Database, por perfil)
class ArtistWorkspaceService {
  final DatabaseReference _db = appFirebaseDatabase.ref();

  DatabaseReference _showsRef(String profileId) =>
      _db.child(AppConstants.showsPath).child(profileId);

  DatabaseReference _gigbagRef(String profileId) =>
      _db.child(AppConstants.gigbagPath).child(profileId);

  DatabaseReference _releasesRef(String profileId) =>
      _db.child(AppConstants.releasesPath).child(profileId);

  DatabaseReference _tasksRef(String profileId) =>
      _db.child(AppConstants.operationalTasksPath).child(profileId);

  // --- Shows ---

  Stream<List<ArtistShow>> showsStream(String profileId) {
    return _showsRef(profileId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return <ArtistShow>[];
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final list = <ArtistShow>[];
      for (final e in data.entries) {
        list.add(
          ArtistShow.fromMap(
            e.key as String,
            profileId,
            Map<String, dynamic>.from(e.value as Map),
          ),
        );
      }
      list.sort((a, b) {
        final dc = a.date.compareTo(b.date);
        if (dc != 0) return dc;
        return a.time.compareTo(b.time);
      });
      return list;
    });
  }

  Future<String> saveShow(ArtistShow show) async {
    final id = show.id.isEmpty ? _showsRef(show.profileId).push().key! : show.id;
    final toSave = ArtistShow(
      id: id,
      profileId: show.profileId,
      title: show.title,
      date: show.date,
      time: show.time,
      venue: show.venue,
      city: show.city,
      notes: show.notes,
      status: show.status,
      eventKind: show.eventKind,
      createdAt: show.id.isEmpty ? DateTime.now() : show.createdAt,
      updatedAt: DateTime.now(),
    );
    await _showsRef(show.profileId).child(id).set(toSave.toMap());
    return id;
  }

  Future<void> deleteShow(String profileId, String showId) async {
    await _showsRef(profileId).child(showId).remove();
  }

  // --- GigBag ---

  Stream<List<GigBagChecklist>> gigbagStream(String profileId) {
    return _gigbagRef(profileId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return <GigBagChecklist>[];
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final list = <GigBagChecklist>[];
      for (final e in data.entries) {
        list.add(
          GigBagChecklist.fromMap(
            e.key as String,
            profileId,
            Map<String, dynamic>.from(e.value as Map),
          ),
        );
      }
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  Future<String> saveChecklist(GigBagChecklist c) async {
    final id = c.id.isEmpty ? _gigbagRef(c.profileId).push().key! : c.id;
    final toSave = GigBagChecklist(
      id: id,
      profileId: c.profileId,
      title: c.title,
      type: c.type,
      isTemplate: c.isTemplate,
      linkedShowId: c.linkedShowId,
      items: c.items,
      createdAt: c.id.isEmpty ? DateTime.now() : c.createdAt,
      updatedAt: DateTime.now(),
    );
    await _gigbagRef(c.profileId).child(id).set(toSave.toMap());
    return id;
  }

  Future<void> deleteChecklist(String profileId, String checklistId) async {
    await _gigbagRef(profileId).child(checklistId).remove();
  }

  Future<String> duplicateChecklist(GigBagChecklist source) async {
    final ref = _gigbagRef(source.profileId);
    final newId = ref.push().key!;
    final now = DateTime.now();
    final itemsMap = <String, dynamic>{};
    for (var i = 0; i < source.items.length; i++) {
      final it = source.items[i];
      final itemId = ref.child(newId).child('items').push().key!;
      itemsMap[itemId] = {
        'description': it.description,
        'checked': false,
        'order': i,
      };
    }
    await ref.child(newId).set({
      'title': '${source.title} (cópia)',
      'type': source.type,
      'isTemplate': false,
      'items': itemsMap,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
    return newId;
  }

  /// Instância de checklist para um compromisso (itens desmarcados), a partir de um modelo ou de outra lista.
  Future<String> duplicateChecklistForCommitment({
    required GigBagChecklist source,
    required String linkedShowId,
    required String title,
  }) async {
    final dbRef = _gigbagRef(source.profileId);
    final newId = dbRef.push().key!;
    final now = DateTime.now();
    final itemsMap = <String, dynamic>{};
    for (var i = 0; i < source.items.length; i++) {
      final it = source.items[i];
      final itemId = dbRef.child(newId).child('items').push().key!;
      itemsMap[itemId] = {
        'description': it.description,
        'checked': false,
        'order': i,
      };
    }
    await dbRef.child(newId).set({
      'title': title,
      'type': source.type,
      'isTemplate': false,
      'linkedShowId': linkedShowId,
      'items': itemsMap,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
    return newId;
  }

  // --- Releases ---

  Stream<List<MusicRelease>> releasesStream(String profileId) {
    return _releasesRef(profileId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return <MusicRelease>[];
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final list = <MusicRelease>[];
      for (final e in data.entries) {
        list.add(
          MusicRelease.fromMap(
            e.key as String,
            profileId,
            Map<String, dynamic>.from(e.value as Map),
          ),
        );
      }
      list.sort((a, b) => a.releaseDate.compareTo(b.releaseDate));
      return list;
    });
  }

  Future<String> saveRelease(MusicRelease r) async {
    final id = r.id.isEmpty ? _releasesRef(r.profileId).push().key! : r.id;
    final toSave = MusicRelease(
      id: id,
      profileId: r.profileId,
      title: r.title,
      type: r.type,
      releaseDate: r.releaseDate,
      status: r.status,
      notes: r.notes,
      milestones: r.milestones,
      createdAt: r.id.isEmpty ? DateTime.now() : r.createdAt,
      updatedAt: DateTime.now(),
    );
    await _releasesRef(r.profileId).child(id).set(toSave.toMap());
    return id;
  }

  Future<void> deleteRelease(String profileId, String releaseId) async {
    await _releasesRef(profileId).child(releaseId).remove();
  }

  // --- Tarefas operacionais ---

  Stream<List<OperationalTask>> operationalTasksStream(String profileId) {
    return _tasksRef(profileId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <OperationalTask>[];
      }
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final list = <OperationalTask>[];
      for (final e in data.entries) {
        list.add(
          OperationalTask.fromMap(
            e.key as String,
            profileId,
            Map<String, dynamic>.from(e.value as Map),
          ),
        );
      }
      list.sort((a, b) {
        final openA = a.isOpen ? 0 : 1;
        final openB = b.isOpen ? 0 : 1;
        if (openA != openB) return openA.compareTo(openB);
        final da = a.dueDate;
        final db = b.dueDate;
        if (da != null && db != null) {
          final c = da.compareTo(db);
          if (c != 0) return c;
        } else if (da != null) {
          return -1;
        } else if (db != null) {
          return 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return list;
    });
  }

  Future<String> saveOperationalTask(OperationalTask task) async {
    final id = task.id.isEmpty ? _tasksRef(task.profileId).push().key! : task.id;
    final now = DateTime.now();
    final toSave = OperationalTask(
      id: id,
      profileId: task.profileId,
      title: task.title,
      description: task.description,
      assignee: task.assignee,
      dueDate: task.dueDate,
      priority: task.priority,
      status: task.status,
      linkedShowId: task.linkedShowId,
      linkedReleaseId: task.linkedReleaseId,
      linkedChecklistId: task.linkedChecklistId,
      createdAt: task.id.isEmpty ? now : task.createdAt,
      updatedAt: now,
      completedAt: task.completedAt,
    );
    await _tasksRef(task.profileId).child(id).set(toSave.toMap());
    return id;
  }

  Future<void> deleteOperationalTask(String profileId, String taskId) async {
    await _tasksRef(profileId).child(taskId).remove();
  }
}
