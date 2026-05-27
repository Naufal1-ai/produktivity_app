import 'package:cloud_firestore/cloud_firestore.dart';

const kKanbanColumns = [
  'Todo',
  'In Progress',
  'Review',
  'Done',
];

class ChecklistItem {
  final String id;
  final String title;
  final bool isDone;

  ChecklistItem({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      isDone: map['isDone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isDone': isDone,
      };

  ChecklistItem copyWith({
    String? title,
    bool? isDone,
  }) {
    return ChecklistItem(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}

class KanbanChecklist {
  final String id;
  final String title;
  final List<ChecklistItem> items;

  KanbanChecklist({
    required this.id,
    required this.title,
    required this.items,
  });

  factory KanbanChecklist.fromMap(Map<String, dynamic> map) {
    final itemsData = map['items'] as List? ?? [];
    return KanbanChecklist(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Checklist',
      items: itemsData
          .map((item) => ChecklistItem.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'items': items.map((item) => item.toMap()).toList(),
      };

  KanbanChecklist copyWith({
    String? title,
    List<ChecklistItem>? items,
  }) {
    return KanbanChecklist(
      id: id,
      title: title ?? this.title,
      items: items ?? this.items,
    );
  }
}

class KanbanCard {
  final String id;
  final String title;
  final String description;
  final String column; // Kolom board saat ini
  final int order;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? taskId;
  final DateTime? dueDate;
  final String? category;
  final String? priority;
  
  // Fitur Trello-like premium
  final String boardId; // ID Board tempat kartu ini berada
  final List<KanbanChecklist> checklists; // Multiple Checklist
  final List<String> labels; // Format: 'color:text', contoh: ['red:High Priority']
  final List<String> members; // Inisial nama member, contoh: ['ZR', 'NA']

  KanbanCard({
    required this.id,
    required this.title,
    required this.description,
    required this.column,
    required this.order,
    required this.createdAt,
    this.updatedAt,
    this.taskId,
    this.dueDate,
    this.category,
    this.priority,
    this.boardId = 'default',
    this.checklists = const <KanbanChecklist>[],
    this.labels = const <String>[],
    this.members = const <String>[],
  });

  factory KanbanCard.fromDoc(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      
      // Parse checklists dengan backward compatibility yang super tangguh
      final List<KanbanChecklist> checklistList = [];
      final rawChecklist = data['checklist'] as List? ?? const [];
      
      for (final item in rawChecklist) {
        if (item == null) continue;
        try {
          if (item is Map) {
            final itemMap = Map<String, dynamic>.from(item);
            if (itemMap.containsKey('items')) {
              // Format baru: Multiple checklists
              checklistList.add(KanbanChecklist.fromMap(itemMap));
            } else {
              // Format lama: Item checklist tunggal
              final checklistItem = ChecklistItem.fromMap(itemMap);
              
              int legacyIndex = checklistList.indexWhere((c) => c.id == 'legacy');
              if (legacyIndex == -1) {
                checklistList.add(KanbanChecklist(
                  id: 'legacy',
                  title: 'Checklist Utama',
                  items: [checklistItem],
                ));
              } else {
                final oldL = checklistList[legacyIndex];
                checklistList[legacyIndex] = oldL.copyWith(
                  items: [...oldL.items, checklistItem],
                );
              }
            }
          } else if (item is String) {
            // Format sangat lama: List string biasa
            final checklistItem = ChecklistItem(
              id: DateTime.now().millisecondsSinceEpoch.toString() + item.hashCode.toString(),
              title: item,
              isDone: false,
            );
            
            int legacyIndex = checklistList.indexWhere((c) => c.id == 'legacy');
            if (legacyIndex == -1) {
              checklistList.add(KanbanChecklist(
                id: 'legacy',
                title: 'Checklist Utama',
                items: [checklistItem],
              ));
            } else {
              final oldL = checklistList[legacyIndex];
              checklistList[legacyIndex] = oldL.copyWith(
                items: [...oldL.items, checklistItem],
              );
            }
          }
        } catch (e) {
          print("Error parsing individual checklist item: $e");
        }
      }

      return KanbanCard(
        id: doc.id,
        title: data['title'] as String? ?? '',
        description: data['description'] as String? ?? '',
        column: data['column'] as String? ?? 'Todo',
        order: (data['order'] as num?)?.toInt() ?? 0,
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : null,
        taskId: data['taskId'] as String?,
        dueDate: data['dueDate'] != null
            ? (data['dueDate'] as Timestamp).toDate()
            : null,
        category: data['category'] as String?,
        priority: data['priority'] as String?,
        boardId: (data['boardId'] as String?) != null && (data['boardId'] as String).isNotEmpty
            ? data['boardId'] as String
            : 'default',
        checklists: checklistList,
        labels: List<String>.from(data['labels'] as List? ?? const <String>[]),
        members: List<String>.from(data['members'] as List? ?? const <String>[]),
      );
    } catch (e, stack) {
      print("ERROR PARSING CARD ${doc.id}: $e");
      print(stack.toString());
      return KanbanCard(
        id: doc.id,
        title: 'Gagal Memuat Kartu',
        description: 'Error: $e',
        column: 'Todo',
        order: 0,
        createdAt: DateTime.now(),
        checklists: const <KanbanChecklist>[],
        labels: const <String>[],
        members: const <String>[],
      );
    }
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'column': column,
        'order': order,
        'createdAt': createdAt,
        'updatedAt': FieldValue.serverTimestamp(),
        'taskId': taskId,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'category': category,
        'priority': priority,
        'boardId': boardId,
        'checklist': checklists.map((item) => item.toMap()).toList(),
        'labels': labels,
        'members': members,
      };

  KanbanCard copyWith({
    String? title,
    String? description,
    String? column,
    int? order,
    String? taskId,
    DateTime? dueDate,
    String? category,
    String? priority,
    String? boardId,
    List<KanbanChecklist>? checklists,
    List<String>? labels,
    List<String>? members,
  }) {
    return KanbanCard(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      column: column ?? this.column,
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      taskId: taskId ?? this.taskId,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      boardId: boardId ?? this.boardId,
      checklists: checklists ?? this.checklists,
      labels: labels ?? this.labels,
      members: members ?? this.members,
    );
  }
}
