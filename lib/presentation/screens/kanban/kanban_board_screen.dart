import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/utils/currency_utils.dart';
import 'package:productivity/data/models/kanban_board_model.dart';
import 'package:productivity/providers/kanban_board_provider.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';
import 'package:productivity/presentation/widgets/kanban_card_form_sheet.dart';

class KanbanBoardScreen extends StatefulWidget {
  const KanbanBoardScreen({super.key});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
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
    super.dispose();
  }

  void _openCardFormSheet([KanbanCard? card, String preselectedColumn = 'Todo']) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KanbanCardFormSheet(
        existing: card,
        preselectedColumn: preselectedColumn,
      ),
    );
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
                      onTap: () => _openCardFormSheet(null, 'Todo'),
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
                            style: const TextStyle(
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
          onPressed: () => _openCardFormSheet(null, 'Todo'),
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
                          color: Colors.white.withValues(alpha: 0.3),
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
      child: GestureDetector(
        onTap: () => _openCardFormSheet(card, card.column),
        child: _buildCardContent(card),
      ),
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
          if (card.dueDate != null || card.category != null || card.priority != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (card.dueDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 10, color: AppColors.blueAccent),
                        const SizedBox(width: 4),
                        Text(
                          DateUtils2.formatDisplay(card.dueDate!),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.blueAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (card.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      card.category!,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (card.priority != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: card.priority == 'High'
                          ? AppColors.expense.withValues(alpha: 0.1)
                          : card.priority == 'Low'
                              ? AppColors.textMuted.withValues(alpha: 0.1)
                              : AppColors.income.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      card.priority!,
                      style: TextStyle(
                        fontSize: 10,
                        color: card.priority == 'High'
                            ? AppColors.expense
                            : card.priority == 'Low'
                                ? AppColors.textMuted
                                : AppColors.income,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
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
