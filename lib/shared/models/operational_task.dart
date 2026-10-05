/// Tarefa operacional da banda/projeto (Realtime Database por perfil)
class OperationalTask {
  final String id;
  final String profileId;
  final String title;
  final String description;
  final String assignee;
  final DateTime? dueDate;
  /// low | medium | high
  final String priority;
  /// open | done
  final String status;
  final String? linkedShowId;
  final String? linkedReleaseId;
  final String? linkedChecklistId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const OperationalTask({
    required this.id,
    required this.profileId,
    required this.title,
    required this.description,
    required this.assignee,
    this.dueDate,
    required this.priority,
    required this.status,
    this.linkedShowId,
    this.linkedReleaseId,
    this.linkedChecklistId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  static const priorityLow = 'low';
  static const priorityMedium = 'medium';
  static const priorityHigh = 'high';

  static const statusOpen = 'open';
  static const statusDone = 'done';

  static const List<String> prioritiesOrdered = [
    priorityHigh,
    priorityMedium,
    priorityLow,
  ];

  factory OperationalTask.fromMap(String id, String profileId, Map<String, dynamic> map) {
    final dueRaw = map['dueDate']?.toString();
    return OperationalTask(
      id: id,
      profileId: profileId,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      assignee: map['assignee']?.toString() ?? '',
      dueDate: dueRaw != null && dueRaw.isNotEmpty ? DateTime.parse(dueRaw) : null,
      priority: map['priority']?.toString() ?? priorityMedium,
      status: map['status']?.toString() ?? statusOpen,
      linkedShowId: map['linkedShowId']?.toString(),
      linkedReleaseId: map['linkedReleaseId']?.toString(),
      linkedChecklistId: map['linkedChecklistId']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'assignee': assignee,
      if (dueDate != null)
        'dueDate': DateTime(dueDate!.year, dueDate!.month, dueDate!.day).toIso8601String(),
      'priority': priority,
      'status': status,
      if (linkedShowId != null && linkedShowId!.isNotEmpty) 'linkedShowId': linkedShowId,
      if (linkedReleaseId != null && linkedReleaseId!.isNotEmpty) 'linkedReleaseId': linkedReleaseId,
      if (linkedChecklistId != null && linkedChecklistId!.isNotEmpty)
        'linkedChecklistId': linkedChecklistId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }

  OperationalTask copyWith({
    String? title,
    String? description,
    String? assignee,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? priority,
    String? status,
    String? linkedShowId,
    String? linkedReleaseId,
    String? linkedChecklistId,
    bool clearLinkedShow = false,
    bool clearLinkedRelease = false,
    bool clearLinkedChecklist = false,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return OperationalTask(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      status: status ?? this.status,
      linkedShowId: clearLinkedShow ? null : (linkedShowId ?? this.linkedShowId),
      linkedReleaseId: clearLinkedRelease ? null : (linkedReleaseId ?? this.linkedReleaseId),
      linkedChecklistId:
          clearLinkedChecklist ? null : (linkedChecklistId ?? this.linkedChecklistId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  bool get isOpen => status == statusOpen;

  bool isOverdueAt(DateTime now) {
    if (!isOpen || dueDate == null) return false;
    final d = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final t0 = DateTime(now.year, now.month, now.day);
    return d.isBefore(t0);
  }
}
