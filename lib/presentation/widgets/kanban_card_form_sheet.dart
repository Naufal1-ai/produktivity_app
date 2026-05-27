import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/utils/currency_utils.dart';
import 'package:productivity/data/models/kanban_board_model.dart';
import 'package:productivity/data/models/task_model.dart';
import 'package:productivity/providers/kanban_board_provider.dart';

class KanbanCardFormSheet extends StatefulWidget {
  final KanbanCard? existing;
  final String preselectedColumn;

  const KanbanCardFormSheet({
    super.key,
    this.existing,
    this.preselectedColumn = 'Todo',
  });

  @override
  State<KanbanCardFormSheet> createState() => _KanbanCardFormSheetState();
}

class _KanbanCardFormSheetState extends State<KanbanCardFormSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedColumn = 'Todo';
  bool _connectToTask = true;
  DateTime _dueDate = DateTime.now();
  String _category = kTaskCategories.first;
  String _priority = kTaskPriorities[1];
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final activeBoard = context.read<KanbanBoardProvider>().activeBoard;
    final boardCols = activeBoard?.columns ?? kKanbanColumns;
    
    _selectedColumn = boardCols.contains(widget.preselectedColumn)
        ? widget.preselectedColumn
        : (boardCols.isNotEmpty ? boardCols.first : 'Todo');

    if (_isEditing) {
      final card = widget.existing!;
      _titleController.text = card.title;
      _descriptionController.text = card.description;
      _selectedColumn = boardCols.contains(card.column)
          ? card.column
          : (boardCols.isNotEmpty ? boardCols.first : 'Todo');
      _connectToTask = card.taskId != null;
      if (card.dueDate != null) {
        _dueDate = card.dueDate!;
      }
      if (card.category != null) {
        _category = card.category!;
      }
      if (card.priority != null) {
        _priority = card.priority!;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
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

  Future<void> _saveCard() async {
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
      final provider = context.read<KanbanBoardProvider>();
      final boardId = provider.activeBoard?.id ?? 'default';

      final card = KanbanCard(
        id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        column: _selectedColumn,
        order: widget.existing?.order ?? DateTime.now().millisecondsSinceEpoch,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        taskId: widget.existing?.taskId,
        dueDate: _connectToTask ? _dueDate : null,
        category: _connectToTask ? _category : null,
        priority: _connectToTask ? _priority : null,
        boardId: boardId,
        checklists: widget.existing?.checklists ?? const [],
        labels: widget.existing?.labels ?? const [],
      );

      if (_isEditing) {
        await provider.updateCard(card, shouldLinkTask: _connectToTask);
      } else {
        await provider.addCard(card, createLinkedTask: _connectToTask);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan kartu: $e'),
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
    final displayColumn = boardCols.contains(_selectedColumn)
        ? _selectedColumn
        : (boardCols.isNotEmpty ? boardCols.first : 'Todo');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCardAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                _isEditing ? Icons.edit_note : Icons.add_task,
                color: AppColors.blueAccent,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                _isEditing ? 'Ubah Kartu Kanban' : 'Tambah Kartu Kanban',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          
          // Title Field
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Judul Kartu',
              hintText: 'Masukkan judul aktivitas...',
            ),
          ),
          const SizedBox(height: 12),

          // Description Field
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Deskripsi (opsional)',
              hintText: 'Detail aktivitas...',
            ),
          ),
          const SizedBox(height: 12),

          // Column Selector Dropdown
          DropdownButtonFormField<String>(
            value: displayColumn,
            decoration: const InputDecoration(labelText: 'Kolom Papan'),
            items: boardCols
                .map((col) => DropdownMenuItem<String>(value: col, child: Text(col)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedColumn = val);
            },
          ),
          const SizedBox(height: 16),

          // Divider and Connect Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderAccent.withValues(alpha: 0.4),
              ),
            ),
            child: SwitchListTile.adaptive(
              title: Row(
                children: [
                  Icon(
                    Icons.sync,
                    color: _connectToTask ? AppColors.blueAccent : AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Hubungkan ke Task & Jadwal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _connectToTask ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'Akan membuat task sinkron pada kalender/daftar tugas harian.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              value: _connectToTask,
              activeThumbColor: AppColors.blueAccent,
              onChanged: (val) {
                setState(() => _connectToTask = val);
              },
            ),
          ),

          // Dynamic Task Fields (Animated size transition)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _connectToTask
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Kebutuhan Task Terhubung',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blueAccent,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Deadline picker card
                      GestureDetector(
                        onTap: _pickDueDate,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderAccent),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppColors.blueAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tanggal Deadline',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateUtils2.formatDisplay(_dueDate),
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.edit, size: 18, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          // Category Dropdown
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: const InputDecoration(labelText: 'Kategori'),
                              items: kTaskCategories
                                  .map((cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat, style: const TextStyle(fontSize: 13)),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _category = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Priority Dropdown
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _priority,
                              decoration: const InputDecoration(labelText: 'Prioritas'),
                              items: kTaskPriorities
                                  .map((prio) => DropdownMenuItem(
                                        value: prio,
                                        child: Text(prio, style: const TextStyle(fontSize: 13)),
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
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveCard,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isEditing ? 'Simpan Perubahan' : 'Tambah Kartu',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
