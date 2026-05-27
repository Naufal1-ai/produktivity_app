import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/utils/currency_utils.dart';
import 'package:productivity/data/models/kanban_board_model.dart';
import 'package:productivity/data/models/task_model.dart';
import 'package:productivity/providers/kanban_board_provider.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF1E2127) : const Color(0xFFF4F5F7);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF5E6C84);
    final cardBg = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02);
    final cardBorder = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: secondaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check, color: AppColors.greenSuccess, size: 28),
            onPressed: _isSaving ? null : _saveChanges,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Column pill selector
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                    ),
                    child: DropdownButton<String>(
                      underline: const SizedBox.shrink(),
                      value: boardCols.contains(_column) ? _column : boardCols.first,
                      dropdownColor: isDark ? const Color(0xFF2D3139) : Colors.white,
                      icon: Icon(Icons.keyboard_arrow_down, color: secondaryTextColor, size: 16),
                      style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold, fontSize: 13),
                      items: boardCols.map((col) {
                        return DropdownMenuItem(
                          value: col,
                          child: Text(
                            col,
                            style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _column = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Card Title & Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Icon(Icons.radio_button_unchecked, color: secondaryTextColor.withOpacity(0.8), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 22,
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
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

              // 3. Action Buttons (Add, Checklist, Attachment)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTrelloActionBtn(Icons.add, 'Add', () {}),
                  _buildTrelloActionBtn(Icons.check_box_outlined, 'Checklist', _openAddChecklistDialog),
                  _buildTrelloActionBtn(Icons.attachment_outlined, 'Attachment', () {}),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Members & Labels Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MEMBERS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Members',
                          style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ..._members.map((initial) {
                              return GestureDetector(
                                onTap: () => _removeMember(initial),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0052CC), // Blue avatar
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initial,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.add, color: secondaryTextColor, size: 18),
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
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Labels',
                          style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    labelName,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              );
                            }),
                            GestureDetector(
                              onTap: _openAddLabelDialog,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(Icons.add, color: secondaryTextColor, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Due Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due date',
                    style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDueDate,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, color: secondaryTextColor, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _dueDate != null ? DateUtils2.formatDisplay(_dueDate!) : 'Pilih Batas Tanggal',
                                style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w500),
                              ),
                              if (isOverdue) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Overdue',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, color: secondaryTextColor, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 6. Description Section
              Row(
                children: [
                  Icon(Icons.subject, color: secondaryTextColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Description',
                    style: TextStyle(color: primaryTextColor, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_isEditingDescription) {
                          _descriptionController.text = _descriptionController.text.trim();
                        }
                        _isEditingDescription = !_isEditingDescription;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isEditingDescription ? 'Done' : 'Edit',
                        style: TextStyle(color: primaryTextColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isEditingDescription)
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  style: TextStyle(color: primaryTextColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tambahkan deskripsi detail...',
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? AppColors.greenSuccess : Colors.black.withOpacity(0.2)),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _descriptionController.text.isEmpty
                        ? 'Tidak ada deskripsi.'
                        : _descriptionController.text,
                    style: TextStyle(color: secondaryTextColor, fontSize: 14, height: 1.4),
                  ),
                ),
              const SizedBox(height: 28),

              // 7. Dynamic Checklists (Multiple Checklists like Trello image)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _checklists.length,
                itemBuilder: (context, index) {
                  final checklist = _checklists[index];
                  return _buildTrelloChecklist(checklist);
                },
              ),

              const SizedBox(height: 24),
              
              // 8. Connect to Task switch
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      const Icon(Icons.sync, color: AppColors.greenSuccess, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Hubungkan ke Task & Jadwal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Menyelaraskan aktivitas ini dengan kalender dan tugas harian.',
                    style: TextStyle(fontSize: 11, color: secondaryTextColor),
                  ),
                  value: _connectToTask,
                  activeThumbColor: AppColors.greenSuccess,
                  onChanged: (val) {
                    setState(() {
                      _connectToTask = val;
                      if (val && _dueDate == null) {
                        _dueDate = DateTime.now();
                      }
                    });
                  },
                ),
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _connectToTask
                    ? Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              children: [
                                // Category
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    dropdownColor: isDark ? const Color(0xFF2D3139) : Colors.white,
                                    initialValue: _category,
                                    style: TextStyle(color: primaryTextColor, fontSize: 12),
                                    decoration: InputDecoration(
                                      labelText: 'Kategori',
                                      labelStyle: TextStyle(color: secondaryTextColor, fontSize: 12),
                                      filled: true,
                                      fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: AppColors.greenSuccess, width: 1.5),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: kTaskCategories
                                        .map((cat) => DropdownMenuItem(
                                              value: cat,
                                              child: Text(cat, style: TextStyle(fontSize: 12, color: primaryTextColor)),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _category = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Priority
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    dropdownColor: isDark ? const Color(0xFF2D3139) : Colors.white,
                                    initialValue: _priority,
                                    style: TextStyle(color: primaryTextColor, fontSize: 12),
                                    decoration: InputDecoration(
                                      labelText: 'Prioritas',
                                      labelStyle: TextStyle(color: secondaryTextColor, fontSize: 12),
                                      filled: true,
                                      fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: AppColors.greenSuccess, width: 1.5),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: kTaskPriorities
                                        .map((prio) => DropdownMenuItem(
                                              value: prio,
                                              child: Text(prio, style: TextStyle(fontSize: 12, color: primaryTextColor)),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _priority = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Button Aksi Trello
  Widget _buildTrelloActionBtn(IconData icon, String text, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF172B4D);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF172B4D).withOpacity(0.8), size: 16),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(color: isDark ? Colors.white.withOpacity(0.85) : primaryTextColor, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Pembuat Checklist Trello (Bisa memiliki banyak checklist terpisah)
  Widget _buildTrelloChecklist(KanbanChecklist checklist) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF5E6C84);
    
    final done = checklist.items.where((t) => t.isDone).length;
    final total = checklist.items.length;
    final progress = total > 0 ? done / total : 0.0;

    _subtaskControllers.putIfAbsent(checklist.id, () => TextEditingController());
    _isAddingSubtask.putIfAbsent(checklist.id, () => false);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Checklist
          Row(
            children: [
              Icon(Icons.check_box_outlined, color: secondaryTextColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  checklist.title,
                  style: TextStyle(color: primaryTextColor, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: () => _deleteChecklist(checklist.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Row
          Row(
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: secondaryTextColor, fontSize: 11),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation(
                      progress == 1.0 ? AppColors.greenSuccess : const Color(0xFF5AAC44),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Checklist items list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: checklist.items.length,
            itemBuilder: (context, idx) {
              final subtask = checklist.items[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Theme(
                      data: ThemeData(
                        unselectedWidgetColor: isDark ? Colors.white38 : Colors.black38,
                      ),
                      child: Checkbox(
                        value: subtask.isDone,
                        activeColor: const Color(0xFF5AAC44),
                        onChanged: (val) {
                          if (val != null) {
                            _toggleTrelloSubtask(checklist.id, subtask.id, val);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: Text(
                        subtask.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: subtask.isDone 
                              ? (isDark ? Colors.white38 : Colors.black38) 
                              : (isDark ? const Color(0xFFE8E8E8) : const Color(0xFF172B4D)),
                          decoration: subtask.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close, 
                        size: 16, 
                        color: isDark ? Colors.white.withOpacity(0.3) : const Color(0xFF172B4D).withOpacity(0.3),
                      ),
                      onPressed: () => _deleteSubtaskItem(checklist.id, subtask.id),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Add item button / input
          if (_isAddingSubtask[checklist.id] == true)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskControllers[checklist.id],
                    style: TextStyle(fontSize: 13, color: primaryTextColor),
                    decoration: InputDecoration(
                      hintText: 'Tambah item baru...',
                      hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.6)),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: isDark ? AppColors.greenSuccess : Colors.black.withOpacity(0.2)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check, color: AppColors.greenSuccess),
                  onPressed: () => _addSubtaskItem(checklist.id),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: secondaryTextColor),
                  onPressed: () {
                    setState(() {
                      _isAddingSubtask[checklist.id] = false;
                    });
                  },
                ),
              ],
            )
          else
            GestureDetector(
              onTap: () {
                setState(() {
                  _isAddingSubtask[checklist.id] = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: secondaryTextColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Add an item',
                      style: TextStyle(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
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
