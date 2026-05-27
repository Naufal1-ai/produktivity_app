import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/utils/currency_utils.dart';
import 'package:productivity/data/models/board_model.dart';
import 'package:productivity/data/models/kanban_board_model.dart';
import 'package:productivity/providers/kanban_board_provider.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';
import 'package:productivity/presentation/widgets/kanban_card_form_sheet.dart';
import 'package:productivity/presentation/screens/kanban/kanban_card_detail_screen.dart';

const List<List<Color>> kBoardGradients = [
  [Color(0xFF1E293B), Color(0xFF0F172A)], // Slate Dark (default)
  [Color(0xFF312E81), Color(0xFF4F46E5)], // Indigo Deep
  [Color(0xFF064E3B), Color(0xFF10B981)], // Emerald Deep
  [Color(0xFF701A75), Color(0xFFEC4899)], // Pink/Purple
  [Color(0xFF7C2D12), Color(0xFFF97316)], // Orange/Rust
  [Color(0xFF0C4A6E), Color(0xFF0EA5E9)], // Sky Blue
];

const List<List<Color>> kBoardGradientsLight = [
  [Color(0xFFF1F5F9), Color(0xFFCBD5E1)], // Slate Light (default)
  [Color(0xFFEEF2FF), Color(0xFFC7D2FE)], // Indigo Light
  [Color(0xFFECFDF5), Color(0xFFA7F3D0)], // Emerald Light
  [Color(0xFFFDF2F8), Color(0xFFFBCFE8)], // Pink Light
  [Color(0xFFFFF7ED), Color(0xFFFED7AA)], // Orange Light
  [Color(0xFFF0F9FF), Color(0xFFBAE6FD)], // Sky Light
];

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
    final provider = context.watch<KanbanBoardProvider>();
    final activeBoard = provider.activeBoard;
    final columns = activeBoard?.columns ?? [];
    final isWideScreen = MediaQuery.of(context).size.width > 700;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
              children: [
                // Header Papan
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showBoardsSheet(context, provider),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.dashboard_customize_outlined,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showBoardsSheet(context, provider),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeBoard?.name ?? 'Papan Kanban',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (activeBoard != null && activeBoard.description.isNotEmpty)
                                Text(
                                  activeBoard.description,
                                  style: TextStyle(
                                    color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF334155),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              else
                                Text(
                                  'Ketuk untuk mengganti papan',
                                  style: TextStyle(
                                    color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF64748B),
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Tombol tambah kartu di kolom pertama
                      GestureDetector(
                        onTap: () {
                          if (columns.isNotEmpty) {
                            _openCardFormSheet(null, columns.first);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Builder(
                    builder: (context) {
                      final total = provider.getTotalCards();
                      final completed = provider.getCompletedCards();
                      final progress = total > 0 ? completed / total : 0.0;

                      return GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        borderRadius: 18,
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.4),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08)),
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 16,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Progress: $completed/$total',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
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
                                  backgroundColor: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08),
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

                // Kolom Kanban Viewport
                Expanded(
                  child: activeBoard == null
                      ? const Center(child: CircularProgressIndicator())
                      : isWideScreen
                          ? _buildColumnsHorizontalList(provider, columns, activeBoard)
                          : _buildColumnsVerticalList(provider, columns, activeBoard),
                ),
              ],
            ),
          ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: () {
            if (columns.isNotEmpty) {
              _openCardFormSheet(null, columns.first);
            }
          },
          backgroundColor: AppColors.blueAccent,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // === HORIZONTAL LIST UNTUK TABLET/WEB/DESKTOP ===
  Widget _buildColumnsHorizontalList(KanbanBoardProvider provider, List<String> columns, BoardModel board) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: columns.length + 1,
      itemBuilder: (context, index) {
        if (index == columns.length) {
          // Tombol tambah kolom di akhir horizontal row
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: () => _openAddColumnDialog(context, board, provider),
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: 24,
                color: Colors.white.withOpacity(0.08),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white.withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Text(
                      'Tambah Kolom',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final columnName = columns[index];
        final cards = _getCardsForColumn(columnName, provider);
        return SizedBox(
          width: 290,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildColumn(context, columnName, cards, provider, board, false),
          ),
        );
      },
    );
  }

  // === VERTICAL LIST UNTUK MOBILE ===
  Widget _buildColumnsVerticalList(KanbanBoardProvider provider, List<String> columns, BoardModel board) {
    return ListView.builder(
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: columns.length + 1,
      itemBuilder: (context, index) {
        if (index == columns.length) {
          // Tombol tambah kolom di akhir vertical list
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: GestureDetector(
              onTap: () => _openAddColumnDialog(context, board, provider),
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: 24,
                color: Colors.white.withOpacity(0.08),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white.withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Text(
                      'Tambah Kolom',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final columnName = columns[index];
        final cards = _getCardsForColumn(columnName, provider);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildColumn(context, columnName, cards, provider, board, true),
        );
      },
    );
  }

  List<KanbanCard> _getCardsForColumn(String column, KanbanBoardProvider provider) {
    return provider.getCardsForColumn(column);
  }

  Widget _buildColumn(BuildContext context, String columnName,
      List<KanbanCard> cards, KanbanBoardProvider provider, BoardModel board, bool isVerticalLayout) {
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
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: isHovered
                ? Border.all(color: isDark ? Colors.white : Colors.black87, width: 2)
                : null,
          ),
          child: GlassContainer(
            padding: const EdgeInsets.all(14),
            borderRadius: 24,
            color: isDark
                ? (isHovered ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.06))
                : (isHovered ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header kolom dengan Menu Popup
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        columnName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF172B4D),
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        cards.length.toString(),
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF172B4D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: isDark ? Colors.white70 : Colors.black54, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 100),
                      onSelected: (val) {
                        if (val == 'rename') {
                          _openRenameColumnDialog(context, columnName, board, provider);
                        } else if (val == 'delete') {
                          _confirmDeleteColumn(context, columnName, board, provider);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text('Ubah Nama', style: TextStyle(fontSize: 12)),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Hapus Kolom', style: TextStyle(fontSize: 12, color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (isHovered)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.3) : Colors.black26),
                    ),
                    child: Text(
                      'Lepas untuk memindahkan ke sini',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF172B4D),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                if (cards.isEmpty && !isHovered)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Tidak ada kartu',
                        style: TextStyle(color: isDark ? Colors.white.withOpacity(0.5) : Colors.black54, fontSize: 13),
                      ),
                    ),
                  )
                else
                  isVerticalLayout
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cards.length,
                          itemBuilder: (context, idx) {
                            return _buildDraggableCard(context, cards[idx]);
                          },
                        )
                      : Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: cards.length,
                            itemBuilder: (context, idx) {
                              return _buildDraggableCard(context, cards[idx]);
                            },
                          ),
                        ),
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
      delay: const Duration(milliseconds: 200),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.76,
            child: _buildCardContent(card, isDragging: true),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCardContent(card),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => KanbanCardDetailScreen(card: card),
            ),
          );
        },
        onDoubleTap: () {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) {
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 680,
                    height: MediaQuery.of(context).size.height * 0.85,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2127) : const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: KanbanCardDetailScreen(card: card),
                  ),
                ),
              );
            },
          );
        },
        child: _buildCardContent(card),
      ),
    );
  }

  Widget _buildCardContent(KanbanCard card, {bool isDragging = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        blur: 16,
        color: isDragging
            ? (isDark ? Colors.white.withOpacity(0.2) : Colors.white)
            : (isDark ? Colors.white.withOpacity(0.12) : Colors.white),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Label Tag
          if (card.labels.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: card.labels.map((lStr) {
                final parts = lStr.split(':');
                final colorKey = parts.first;
                final color = kTrelloLabelColors[colorKey] ?? Colors.grey;
                return Container(
                  width: 28,
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
          ],
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.drag_handle, size: 14, color: isDark ? Colors.white.withOpacity(0.5) : Colors.black45),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  card.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF172B4D),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isDragging)
                GestureDetector(
                  onTap: () => _deleteCard(card.id),
                  child: Icon(Icons.close, size: 16, color: isDark ? Colors.white.withOpacity(0.5) : Colors.black45),
                ),
            ],
          ),
          if (card.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              card.description,
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white.withOpacity(0.7) : Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (card.dueDate != null || card.category != null || card.priority != null || (card.checklists.isNotEmpty && card.checklists.any((c) => c.items.isNotEmpty)) || card.members.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // Checklist Status
                      if (card.checklists.isNotEmpty && card.checklists.any((c) => c.items.isNotEmpty))
                        Builder(
                          builder: (context) {
                            int done = 0;
                            int total = 0;
                            for (final checklist in card.checklists) {
                              done += checklist.items.where((t) => t.isDone).length;
                              total += checklist.items.length;
                            }
                            final isAllDone = done == total && total > 0;
                            if (total == 0) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isAllDone
                                    ? AppColors.greenSuccess.withOpacity(0.24)
                                    : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_box_outlined,
                                    size: 10,
                                    color: isAllDone ? AppColors.greenSuccess : (isDark ? Colors.white70 : Colors.black54),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$done/$total',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: isAllDone ? AppColors.greenSuccess : (isDark ? Colors.white70 : Colors.black54),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      if (card.dueDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? AppColors.blueAccent.withOpacity(0.24)
                                : AppColors.blueAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today, 
                                size: 10, 
                                color: isDark ? Colors.white : AppColors.blueAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateUtils2.formatDisplay(card.dueDate!),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: isDark ? Colors.white : AppColors.blueAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (card.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            card.category!,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (card.priority != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: card.priority == 'High'
                                ? AppColors.expense.withOpacity(0.24)
                                : card.priority == 'Low'
                                    ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))
                                    : AppColors.income.withOpacity(0.24),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            card.priority!,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: card.priority == 'High'
                                  ? AppColors.expense
                                  : card.priority == 'Low'
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : AppColors.income,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Members on the right
                if (card.members.isNotEmpty)
                  Wrap(
                    spacing: -8, // overlapping circles
                    children: card.members.take(3).map((initial) {
                      return Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052CC),
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF2D3139) : Colors.white, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),);
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

  // === BOARD DIALOGS & POPUPS ===

  void _showBoardsSheet(BuildContext context, KanbanBoardProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final boards = provider.boards;
            
            return GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: 28,
              color: AppColors.bgCardAlt,
              margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.15),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Papan Kanban (Board)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: AppColors.blueAccent),
                        onPressed: () => _openCreateBoardDialog(context, provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: boards.length,
                      itemBuilder: (context, index) {
                        final b = boards[index];
                        final isSelected = provider.activeBoard?.id == b.id;
                        
                        return GestureDetector(
                          onTap: () {
                            provider.selectBoard(b.id);
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: kBoardGradients[b.colorIndex],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          b.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (b.description.isNotEmpty)
                                          Text(
                                            b.description,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Actions for custom boards
                                  if (b.id.isNotEmpty && b.name != 'Papan Utama') ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                      onPressed: () {
                                        _openEditBoardDialog(context, b, provider);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                                      onPressed: () {
                                        _confirmDeleteBoard(context, b, provider);
                                      },
                                    ),
                                  ] else if (isSelected)
                                    const Icon(Icons.check_circle, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openCreateBoardDialog(BuildContext context, KanbanBoardProvider provider) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    int selectedColorIndex = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Buat Papan Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Papan'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pilih Tema Warna:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(kBoardGradients.length, (idx) {
                        final isSelected = selectedColorIndex == idx;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColorIndex = idx;
                            });
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: kBoardGradients[idx],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }),
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
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      await provider.addBoard(
                        name,
                        descController.text.trim(),
                        selectedColorIndex,
                        ['Todo', 'In Progress', 'Done'],
                      );
                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Close bottom sheet
                      }
                    }
                  },
                  child: const Text('Buat'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openEditBoardDialog(BuildContext context, BoardModel board, KanbanBoardProvider provider) {
    final nameController = TextEditingController(text: board.name);
    final descController = TextEditingController(text: board.description);
    int selectedColorIndex = board.colorIndex;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ubah Papan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Papan'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pilih Tema Warna:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(kBoardGradients.length, (idx) {
                        final isSelected = selectedColorIndex == idx;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColorIndex = idx;
                            });
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: kBoardGradients[idx],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }),
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
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      await provider.updateBoard(
                        board.copyWith(
                          name: name,
                          description: descController.text.trim(),
                          colorIndex: selectedColorIndex,
                        ),
                      );
                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Close bottom sheet
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteBoard(BuildContext context, BoardModel board, KanbanBoardProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Papan "${board.name}"?'),
        content: const Text('Apakah Anda yakin? Semua kartu di papan ini akan ikut terhapus selamanya.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteBoard(board.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close bottom sheet
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // === COLUMN DIALOGS ===

  void _openAddColumnDialog(BuildContext context, BoardModel board, KanbanBoardProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Kolom Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nama kolom (contoh: QA)...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final updatedCols = List<String>.from(board.columns)..add(name);
                await provider.updateBoard(board.copyWith(columns: updatedCols));
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _openRenameColumnDialog(BuildContext context, String currentName, BoardModel board, KanbanBoardProvider provider) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Kolom'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nama baru...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                final updatedCols = board.columns.map((c) => c == currentName ? newName : c).toList();
                final cardsInCol = provider.getCardsForColumn(currentName);
                
                await provider.updateBoard(board.copyWith(columns: updatedCols));
                
                for (final card in cardsInCol) {
                  await provider.updateCard(card.copyWith(column: newName));
                }

                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteColumn(BuildContext context, String columnName, BoardModel board, KanbanBoardProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Kolom "$columnName"?'),
        content: const Text('Apakah Anda yakin? Kartu di kolom ini akan dipindahkan ke kolom pertama.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (board.columns.length <= 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Papan harus memiliki minimal 1 kolom.')),
                );
                Navigator.pop(context);
                return;
              }

              final updatedCols = List<String>.from(board.columns)..remove(columnName);
              final fallbackCol = updatedCols.first;
              final cardsInCol = provider.getCardsForColumn(columnName);
              
              await provider.updateBoard(board.copyWith(columns: updatedCols));
              
              for (final card in cardsInCol) {
                await provider.updateCard(card.copyWith(column: fallbackCol));
              }

              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
