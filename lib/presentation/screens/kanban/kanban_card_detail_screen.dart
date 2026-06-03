import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/utils/currency_utils.dart';
import 'package:productivity/data/models/kanban_board_model.dart';
import 'package:productivity/data/models/task_model.dart';
import 'package:productivity/providers/kanban_board_provider.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';

// Palet warna label Trello estetik
const Map<String, Color> kTrelloLabelColors = {
  'red': Color(0xFFEF4444),
  'orange': Color(0xFFF97316),
  'yellow': Color(0xFFEAB308),
  'green': Color(0xFF10B981),
  'blue': Color(0xFF1D4ED8),
  'purple': Color(0xFF7C3AED),
  'cyan': Color(0xFF06B6D4),
  'pink': Color(0xFFEC4899),
};

class KanbanCardDetailScreen extends StatefulWidget {
  final KanbanCard card;

  const KanbanCardDetailScreen({super.key, required this.card});

  @override
  State<KanbanCardDetailScreen> createState() => _KanbanCardDetailScreenState();
}

class _KanbanCardDetailScreenState extends State<KanbanCardDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  late String _column;
  late List<KanbanChecklist> _checklists;
  late List<String> _labels;
  late List<String> _members;
  
  bool _connectToTask = false;
  DateTime? _dueDate;
  String _category = kTaskCategories.first;
  String _priority = kTaskPriorities[1];

  bool _isSaving = false;
  bool _isEditingDescription = false;
  
  // Kontroler input dinamis untuk subtask
  final Map<String, TextEditingController> _subtaskControllers = {};
  final Map<String, bool> _isAddingSubtask = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card.title);
    _descriptionController = TextEditingController(text: widget.card.description);

    _column = widget.card.column;
    _checklists = List.from(widget.card.checklists);
    _labels = List.from(widget.card.labels);
    _members = List.from(widget.card.members);
    _connectToTask = widget.card.taskId != null;
    _dueDate = widget.card.dueDate;
    if (widget.card.category != null) _category = widget.card.category!;
    if (widget.card.priority != null) _priority = widget.card.priority!;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _subtaskControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // === LABELS ACTIONS ===
  void _openAddLabelDialog() {
    final nameController = TextEditingController();
    String selectedColor = 'blue';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: Text('Tambah Label', style: TextStyle(color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'Nama label (contoh: Fullstack)...'),
                    style: TextStyle(color: AppColors.textPrimary),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Pilih Warna:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kTrelloLabelColors.keys.map((colorKey) {
                      final isSelected = selectedColor == colorKey;
                      final color = kTrelloLabelColors[colorKey]!;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = colorKey;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      setState(() {
                        _labels.add('$selectedColor:$name');
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeLabel(String labelStr) {
    setState(() {
      _labels.remove(labelStr);
    });
  }

  // === MEMBERS ACTIONS ===
  void _openAddMemberDialog() {
    final initialsController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Tambah Anggota (Member)', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: initialsController,
          maxLength: 3,
          decoration: const InputDecoration(hintText: 'Inisial nama (contoh: ZR)...'),
          style: TextStyle(color: AppColors.textPrimary),
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final initial = initialsController.text.trim().toUpperCase();
              if (initial.isNotEmpty) {
                setState(() {
                  if (!_members.contains(initial)) {
                    _members.add(initial);
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _removeMember(String initial) {
    setState(() {
      _members.remove(initial);
    });
  }

  // === CHECKLIST ACTIONS ===
  void _openAddChecklistDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Tambah Daftar Checklist', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'Nama Checklist (contoh: Backend & Logic)...'),
          style: TextStyle(color: AppColors.textPrimary),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                setState(() {
                  _checklists.add(KanbanChecklist(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    items: [],
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  void _deleteChecklist(String id) {
    setState(() {
      _checklists.removeWhere((c) => c.id == id);
    });
  }

  // === SUBTASK ACTIONS ===
  void _addSubtaskItem(String checklistId) {
    final controller = _subtaskControllers[checklistId];
    final title = controller?.text.trim() ?? '';
    if (title.isEmpty) return;

    setState(() {
      _checklists = _checklists.map((c) {
        if (c.id == checklistId) {
          final updatedItems = List<ChecklistItem>.from(c.items)
            ..add(ChecklistItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: title,
              isDone: false,
            ));
          return c.copyWith(items: updatedItems);
        }
        return c;
      }).toList();
      controller?.clear();
      _isAddingSubtask[checklistId] = false;
    });
  }

  void _toggleSubtaskItem(String checklistId, String itemId, bool isDone) {
    setState(() {
      _checklists = _checklists.map((c) {
        if (c.id == checklistId) {
          final updatedItems = c.items.map((item) {
            if (item.id == itemId) {
              return item.copyWith(isDone: isDone);
            }
            return item;
          }).toList();
          return c.copyWith(items: updatedItems);
        }
        return c;
      }).toList();
    });
  }

  void _deleteSubtaskItem(String checklistId, String itemId) {
    setState(() {
      _checklists = _checklists.map((c) {
        if (c.id == checklistId) {
          final updatedItems = List<ChecklistItem>.from(c.items)
            ..removeWhere((item) => item.id == itemId);
          return c.copyWith(items: updatedItems);
        }
        return c;
      }).toList();
    });
  }

  // === DEADLINE ACTIONS ===
  Future<void> _pickDueDate() async {
    final initialDate = _dueDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.blueAccent,
            surface: AppColors.bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  // === SAVE CARD ===
  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul kartu tidak boleh kosong.'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updatedCard = widget.card.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        column: _column,
        dueDate: _connectToTask ? (_dueDate ?? DateTime.now()) : null,
        category: _connectToTask ? _category : null,
        priority: _connectToTask ? _priority : null,
        checklists: _checklists,
        labels: _labels,
        members: _members,
      );

      await context.read<KanbanBoardProvider>().updateCard(
            updatedCard,
            shouldLinkTask: _connectToTask,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kartu berhasil diperbarui ala Trello!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui kartu: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBoard = context.watch<KanbanBoardProvider>().activeBoard;
    final boardCols = activeBoard?.columns ?? kKanbanColumns;
    final isOverdue = _dueDate != null && _dueDate!.isBefore(DateTime.now()) && _column != boardCols.last;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 600;

    final pagePadding = isNarrow
        ? const EdgeInsets.fromLTRB(10, 10, 10, 30)
        : const EdgeInsets.fromLTRB(20, 16, 20, 60);

    final containerPadding = isNarrow
        ? const EdgeInsets.all(14)
        : const EdgeInsets.all(24);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GridBackground(
        child: Column(
          children: [
            // Custom AppBar for integrated design
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Detail Tugas',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.greenSuccess.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: AppColors.greenSuccess, size: 20),
                            ),
                      onPressed: _isSaving ? null : _saveChanges,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: pagePadding,
                child: GlassContainer(
                  padding: containerPadding,
                  borderRadius: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Section 1: Column pill, Title, and Action Buttons ──────────
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.blueAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.blueAccent.withValues(alpha: 0.2)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: boardCols.contains(_column) ? _column : boardCols.first,
                                dropdownColor: AppColors.bgCard,
                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.blueAccent, size: 16),
                                style: TextStyle(color: AppColors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                items: boardCols.map((col) {
                                  return DropdownMenuItem(
                                    value: col,
                                    child: Text(col),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _column = val);
                                },
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'STATUS TUGAS',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.blueAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.radio_button_unchecked_rounded, color: AppColors.blueAccent, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              style: TextStyle(
                                fontSize: 22,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Judul Tugas...',
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTrelloActionBtn(Icons.check_box_outlined, 'Tambah Checklist', _openAddChecklistDialog),
                          _buildTrelloActionBtn(Icons.attachment_outlined, 'Lampiran', () {}),
                        ],
                      ),

                      const Divider(height: 40),

                      // ── Section 2: Members & Labels ────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // MEMBERS
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ANGGOTA',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ..._members.map((initial) {
                                      return GestureDetector(
                                        onTap: () => _removeMember(initial),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [AppColors.blueAccent, AppColors.blueMuted],
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            initial,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                      );
                                    }),
                                    GestureDetector(
                                      onTap: _openAddMemberDialog,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.bgCardAlt,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.borderAccent, width: 1),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(Icons.add_rounded, color: AppColors.textPrimary, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // LABELS
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LABEL TUGAS',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ..._labels.map((lStr) {
                                      final parts = lStr.split(':');
                                      final colorKey = parts.first;
                                      final labelName = parts.length > 1 ? parts[1] : colorKey;
                                      final color = kTrelloLabelColors[colorKey] ?? Colors.grey;

                                      return GestureDetector(
                                        onTap: () => _removeLabel(lStr),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
                                          ),
                                          child: Text(
                                            labelName,
                                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                      );
                                    }),
                                    GestureDetector(
                                      onTap: _openAddLabelDialog,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: AppColors.bgCardAlt,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.borderAccent, width: 1),
                                        ),
                                        child: Icon(Icons.add_rounded, color: AppColors.textPrimary, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 40),

                      // ── Section 3: Due Date & Description ──────────────────────────
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.blueAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.calendar_today_rounded, color: AppColors.blueAccent, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Batas Tanggal (Due Date)',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _dueDate != null ? DateUtils2.formatDisplay(_dueDate!) : 'Belum diatur',
                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          if (isOverdue) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.expense.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.expense),
                              ),
                              child: const Text(
                                'Terlambat',
                                style: TextStyle(color: AppColors.expense, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          TextButton.icon(
                            onPressed: _pickDueDate,
                            icon: const Icon(Icons.edit_rounded, size: 14),
                            label: const Text('Atur', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.blueAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              backgroundColor: AppColors.blueAccent.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.blueAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.subject_rounded, color: AppColors.blueAccent, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Deskripsi Tugas',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                if (_isEditingDescription) {
                                  _descriptionController.text = _descriptionController.text.trim();
                                }
                                _isEditingDescription = !_isEditingDescription;
                              });
                            },
                            icon: Icon(_isEditingDescription ? Icons.check_circle_rounded : Icons.edit_rounded, size: 14),
                            label: Text(_isEditingDescription ? 'Selesai' : 'Ubah', style: const TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: _isEditingDescription ? AppColors.greenSuccess : AppColors.blueAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              backgroundColor: (_isEditingDescription ? AppColors.greenSuccess : AppColors.blueAccent).withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isEditingDescription)
                        TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Tambahkan catatan atau penjelasan mengenai tugas ini...',
                            filled: true,
                            fillColor: AppColors.bgCardAlt.withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.borderAccent),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.borderAccent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.blueAccent, width: 1.5),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bgCardAlt.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderAccent.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            _descriptionController.text.isEmpty
                                ? 'Belum ada penjelasan detail yang ditambahkan untuk tugas ini.'
                                : _descriptionController.text,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                          ),
                        ),

                      const Divider(height: 40),

                      // ── Section 4: Connection to Tasks ──────────────────────────────
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.greenSuccess.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.sync_rounded, color: AppColors.greenSuccess, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Hubungkan ke Task & Kalender',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(left: 38, top: 4),
                          child: Text(
                            'Sinkronisasikan aktivitas ini dengan modul tugas harian dan kalender utama.',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ),
                        value: _connectToTask,
                        activeThumbColor: AppColors.greenSuccess,
                        activeTrackColor: AppColors.greenSuccess.withValues(alpha: 0.3),
                        onChanged: (val) {
                          setState(() {
                            _connectToTask = val;
                            if (val && _dueDate == null) {
                              _dueDate = DateTime.now();
                            }
                          });
                        },
                      ),
                      if (_connectToTask) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Category
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                dropdownColor: AppColors.bgCard,
                                initialValue: _category,
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  labelText: 'Kategori',
                                  labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  filled: true,
                                  fillColor: AppColors.bgCardAlt.withValues(alpha: 0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: AppColors.borderAccent),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: AppColors.borderAccent),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: AppColors.blueAccent, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                items: kTaskCategories
                                    .map((cat) => DropdownMenuItem(
                                          value: cat,
                                          child: Text(cat, style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _category = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Priority
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                dropdownColor: AppColors.bgCard,
                                initialValue: _priority,
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  labelText: 'Prioritas',
                                  labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  filled: true,
                                  fillColor: AppColors.bgCardAlt.withValues(alpha: 0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: AppColors.borderAccent),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: AppColors.borderAccent),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: AppColors.blueAccent, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                items: kTaskPriorities
                                    .map((prio) => DropdownMenuItem(
                                          value: prio,
                                          child: Text(prio, style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _priority = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ── Section 5: Dynamic Checklists ──────────────────────────────
                      if (_checklists.isNotEmpty) ...[
                        const Divider(height: 40),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _checklists.length,
                          itemBuilder: (context, index) {
                            final checklist = _checklists[index];
                            return _buildTrelloChecklist(checklist);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Button Aksi Trello
  Widget _buildTrelloActionBtn(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.blueAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.blueAccent.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.blueAccent, size: 16),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Pembuat Checklist Trello (Bisa memiliki banyak checklist terpisah)
  Widget _buildTrelloChecklist(KanbanChecklist checklist) {
    final done = checklist.items.where((t) => t.isDone).length;
    final total = checklist.items.length;
    final progress = total > 0 ? done / total : 0.0;

    _subtaskControllers.putIfAbsent(checklist.id, () => TextEditingController());
    _isAddingSubtask.putIfAbsent(checklist.id, () => false);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.bgCardAlt.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderAccent.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Checklist
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.blueAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_box_rounded, color: AppColors.blueAccent, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  checklist.title,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 20),
                onPressed: () => _deleteChecklist(checklist.id),
                tooltip: 'Hapus Checklist',
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Row
          Row(
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.bgCardAlt,
                    valueColor: AlwaysStoppedAnimation(
                      progress == 1.0 ? AppColors.greenSuccess : AppColors.blueAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checklist items list
          if (checklist.items.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: checklist.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final subtask = checklist.items[idx];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: subtask.isDone ? Colors.transparent : AppColors.bgCardAlt.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: subtask.isDone ? Colors.transparent : AppColors.borderAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: subtask.isDone,
                        activeColor: AppColors.greenSuccess,
                        onChanged: (val) {
                          if (val != null) {
                            _toggleTrelloSubtask(checklist.id, subtask.id, val);
                          }
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subtask.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: subtask.isDone ? AppColors.textMuted : AppColors.textPrimary,
                            decoration: subtask.isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                        onPressed: () => _deleteSubtaskItem(checklist.id, subtask.id),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
          ],

          // Add item button / input
          if (_isAddingSubtask[checklist.id] == true)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskControllers[checklist.id],
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Tambah item baru...',
                      filled: true,
                      fillColor: AppColors.bgCardAlt.withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.borderAccent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.borderAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.blueAccent, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check_circle_rounded, color: AppColors.greenSuccess),
                  onPressed: () => _addSubtaskItem(checklist.id),
                ),
                IconButton(
                  icon: Icon(Icons.cancel_rounded, color: AppColors.textMuted),
                  onPressed: () {
                    setState(() {
                      _isAddingSubtask[checklist.id] = false;
                    });
                  },
                ),
              ],
            )
          else
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isAddingSubtask[checklist.id] = true;
                });
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text('Tambah Item Baru', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.blueAccent,
                backgroundColor: AppColors.blueAccent.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }

  // Toggles the subtask and saves it immediately to the local checklists state
  void _toggleTrelloSubtask(String checklistId, String itemId, bool isDone) {
    _toggleSubtaskItem(checklistId, itemId, isDone);
  }
}
