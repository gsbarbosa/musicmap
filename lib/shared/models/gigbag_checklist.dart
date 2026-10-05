/// Item de checklist GigBag
class GigBagItem {
  final String id;
  final String description;
  final bool checked;
  final int order;

  const GigBagItem({
    required this.id,
    required this.description,
    required this.checked,
    required this.order,
  });

  factory GigBagItem.fromMap(String id, Map<String, dynamic> map) {
    return GigBagItem(
      id: id,
      description: map['description']?.toString() ?? '',
      checked: map['checked'] == true,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'checked': checked,
      'order': order,
    };
  }

  GigBagItem copyWith({
    String? description,
    bool? checked,
    int? order,
  }) {
    return GigBagItem(
      id: id,
      description: description ?? this.description,
      checked: checked ?? this.checked,
      order: order ?? this.order,
    );
  }
}

/// Checklist operacional GigBag
class GigBagChecklist {
  final String id;
  final String profileId;
  final String title;
  /// show | rehearsal | recording | travel
  final String type;
  final bool isTemplate;
  /// Quando preenchido, checklist ligada a um compromisso (show) na agenda
  final String? linkedShowId;
  final List<GigBagItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GigBagChecklist({
    required this.id,
    required this.profileId,
    required this.title,
    required this.type,
    required this.isTemplate,
    this.linkedShowId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  static const typeShow = 'show';
  static const typeRehearsal = 'rehearsal';
  static const typeRecording = 'recording';
  static const typeTravel = 'travel';

  factory GigBagChecklist.fromMap(
    String id,
    String profileId,
    Map<String, dynamic> map,
  ) {
    final itemsRaw = map['items'];
    final items = <GigBagItem>[];
    if (itemsRaw is Map) {
      final m = Map<String, dynamic>.from(itemsRaw);
      for (final e in m.entries) {
        items.add(
          GigBagItem.fromMap(
            e.key,
            Map<String, dynamic>.from(e.value as Map),
          ),
        );
      }
      items.sort((a, b) => a.order.compareTo(b.order));
    }
    final link = map['linkedShowId']?.toString();
    return GigBagChecklist(
      id: id,
      profileId: profileId,
      title: map['title']?.toString() ?? '',
      type: map['type']?.toString() ?? typeShow,
      isTemplate: map['isTemplate'] == true,
      linkedShowId: link != null && link.isNotEmpty ? link : null,
      items: items,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final itemsMap = <String, dynamic>{};
    for (final i in items) {
      itemsMap[i.id] = i.toMap();
    }
    return {
      'title': title,
      'type': type,
      'isTemplate': isTemplate,
      if (linkedShowId != null && linkedShowId!.isNotEmpty) 'linkedShowId': linkedShowId,
      'items': itemsMap,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  GigBagChecklist copyWith({
    String? title,
    String? type,
    bool? isTemplate,
    String? linkedShowId,
    bool clearLinkedShow = false,
    List<GigBagItem>? items,
    DateTime? updatedAt,
  }) {
    return GigBagChecklist(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      type: type ?? this.type,
      isTemplate: isTemplate ?? this.isTemplate,
      linkedShowId: clearLinkedShow ? null : (linkedShowId ?? this.linkedShowId),
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
