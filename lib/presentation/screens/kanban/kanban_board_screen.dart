import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/data/models/kanban_board_model.dart';
import 'package:productivity/providers/kanban_board_provider.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';

class KanbanBoardScreen extends StatefulWidget {
  const KanbanBoardScreen({super.key});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedColumn = 'Todo';
  String? _draggingOverColumn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KanbanBoardProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _openAddCardDialog() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() => _selectedColumn = 'Todo');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text('Tambah Kartu Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Judul kartu',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: AppColors.isDark
                        ? const Color(0xFF1C1C1C)
                        : Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Deskripsi',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: AppColors.isDark
                        ? const Color(0xFF1C1C1C)
                        : Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedColumn,
                  items: kKanbanColumns
                      .map((col) =>
                          DropdownMenuItem(value: col, child: Text(col)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => _selectedColumn = val);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Kolom',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: AppColors.isDark
                        ? const Color(0xFF1C1C1C)
                        : Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _submitCard,
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitCard() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tidak boleh kosong')),
      );
      return;
    }

    final card = KanbanCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      column: _selectedColumn,
      order: DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now(),
    );

    context.read<KanbanBoardProvider>().addCard(card);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.isDark ? const Color(0xFF0F1117) : AppColors.bg,
      body: GridBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ✅ Header konsisten — sama dengan semua screen lain
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.blueAccent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.view_kanban_outlined,
                        color: AppColors.blueAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kanban Board',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // ✅ Tombol tambah di kanan header
                    GestureDetector(
                      onTap: _openAddCardDialog,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.blueAccent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppColors.blueAccent,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Progress bar dalam container pill — konsisten dengan stat area screen lain
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Consumer<KanbanBoardProvider>(
                  builder: (context, provider, _) {
                    final total = provider.getTotalCards();
                    final completed = provider.getCompletedCards();
                    final progress = total > 0 ? completed / total : 0.0;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.blueAccent.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Progress: $completed/$total',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 7,
                                backgroundColor: AppColors.borderAccent
                                    .withValues(alpha: 0.35),
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.greenSuccess,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: AppColors.greenSuccess,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ✅ Kolom kanban
              Expanded(
                child: Consumer<KanbanBoardProvider>(
                  builder: (context, provider, _) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      children: kKanbanColumns.map((column) {
                        final cards = _getCardsForColumn(column, provider);
                        return _buildColumn(context, column, cards, provider);
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: _openAddCardDialog,
          backgroundColor: AppColors.blueAccent,
          child:
              const Icon(Icons.add, color: Color.fromARGB(255, 255, 255, 255)),
        ),
      ),
    );
  }

  List<KanbanCard> _getCardsForColumn(
      String column, KanbanBoardProvider provider) {
    switch (column) {
      case 'Todo':
        return provider.todoCards;
      case 'In Progress':
        return provider.inProgressCards;
      case 'Review':
        return provider.reviewCards;
      case 'Done':
        return provider.doneCards;
      default:
        return [];
    }
  }

  Widget _buildColumn(BuildContext context, String columnName,
      List<KanbanCard> cards, KanbanBoardProvider provider) {
    final isHovered = _draggingOverColumn == columnName;

    return DragTarget<KanbanCard>(
      onWillAcceptWithDetails: (details) {
        if (details.data.column != columnName) {
          setState(() => _draggingOverColumn = columnName);
          return true;
        }
        return false;
      },
      onLeave: (_) => setState(() => _draggingOverColumn = null),
      onAcceptWithDetails: (details) {
        setState(() => _draggingOverColumn = null);
        final card = details.data;
        if (card.column != columnName) {
          provider.moveCard(
            card.id,
            columnName,
            DateTime.now().millisecondsSinceEpoch,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${card.title}" dipindah ke $columnName'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: isHovered
                ? Border.all(color: _getColumnColor(columnName), width: 2)
                : null,
          ),
          child: GlassContainer(
            padding: const EdgeInsets.all(14),
            borderRadius: 24,
            color: isHovered
                ? _getColumnColor(columnName).withValues(alpha: 0.08)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header kolom
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getColumnColor(columnName),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        columnName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          cards.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (isHovered)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color:
                          _getColumnColor(columnName).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _getColumnColor(columnName).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Lepas untuk memindahkan ke sini',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _getColumnColor(columnName),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                if (cards.isEmpty && !isHovered)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'Tidak ada kartu',
                        style:
                            TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ),
                  ),

                ...cards.map((card) => _buildDraggableCard(context, card)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableCard(BuildContext context, KanbanCard card) {
    return LongPressDraggable<KanbanCard>(
      data: card,
      delay: const Duration(milliseconds: 300),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 64,
            child: _buildCardContent(card, isDragging: true),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCardContent(card),
      ),
      child: _buildCardContent(card),
    );
  }

  Widget _buildCardContent(KanbanCard card, {bool isDragging = false}) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      blur: 16,
      color: isDragging
          ? AppColors.blueAccent.withValues(alpha: 0.15)
          : AppColors.isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.66),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.drag_handle, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  card.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isDragging)
                GestureDetector(
                  onTap: () => _deleteCard(card.id),
                  child:
                      Icon(Icons.close, size: 18, color: AppColors.textMuted),
                ),
            ],
          ),
          if (card.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              card.description,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Color _getColumnColor(String columnName) {
    switch (columnName) {
      case 'Todo':
        return Colors.grey[600]!;
      case 'In Progress':
        return Colors.blue[600]!;
      case 'Review':
        return Colors.orange[600]!;
      case 'Done':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  void _deleteCard(String cardId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kartu?'),
        content: const Text('Apakah Anda yakin ingin menghapus kartu ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<KanbanBoardProvider>().deleteCard(cardId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
