import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:productivity/presentation/screens/settings/edit_profile_screen.dart'
    show kLocalPhotoBase64Key;
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/presentation/screens/finance/finance_screen.dart';
import 'package:productivity/presentation/screens/home/home_screen.dart';
import 'package:productivity/presentation/screens/settings/settings_screen.dart';
import 'package:productivity/presentation/screens/tasks/tasks_screen.dart';
import 'package:productivity/presentation/screens/kanban/kanban_board_screen.dart';
import 'package:productivity/presentation/screens/pomodoro/pomodoro_timer_screen.dart';
import 'package:productivity/presentation/screens/habit_tracker/habit_tracker_screen.dart';
import 'package:productivity/presentation/widgets/transaction_form_sheet.dart';
import 'package:productivity/presentation/screens/lending/lending_screen.dart';
import 'package:productivity/presentation/screens/vehicle_service/vehicle_service_screen.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';
import 'package:productivity/providers/kanban_board_provider.dart';

/// Shell utama yang meng-host BottomNavigationBar + 5 tab
class MainShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MainShell({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainShell> createState() => _MainShellState();

  static void changeTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainShellState>();
    state?.changeTab(index);
  }
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  void _openAddForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TransactionFormSheet(),
    );
  }

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kanbanProvider = context.watch<KanbanBoardProvider>();
    final activeBoard = kanbanProvider.activeBoard;
    final isDark = widget.isDarkMode;

    final pages = [
      HomeScreen(
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      const FinanceScreen(),
      const TasksScreen(),
      const KanbanBoardScreen(),
      const PomodoroTimerScreen(),
      const HabitTrackerScreen(),
      const LendingScreen(),
      const VehicleServiceScreen(),
      SettingsScreen(
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        return Scaffold(
          extendBody: true,
          key: _scaffoldKey,
          drawer: Drawer(
            child: Container(
              color: AppColors.bgCard,
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.blueMid,
                            AppColors.blueAccent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              image: const DecorationImage(
                                image: AssetImage('assets/logo.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Productivity',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tasks, habits, focus, finance',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Menu Items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _DrawerItem(
                            icon: Icons.home_outlined,
                            title: 'Dashboard',
                            isActive: _currentIndex == 0,
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _currentIndex = 0);
                            },
                          ),
                          _DrawerItem(
                            icon: Icons.pie_chart_outline,
                            title: 'Keuangan',
                            isActive: _currentIndex == 1,
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _currentIndex = 1);
                            },
                          ),
                          _DrawerItem(
                            icon: Icons.event_note_outlined,
                            title: 'Task & Jadwal',
                            isActive: _currentIndex == 2,
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _currentIndex = 2);
                            },
                          ),
                          _DrawerItem(
                            icon: Icons.inventory_2_outlined,
                            title: 'Peminjaman',
                            isActive: _currentIndex == 6,
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _currentIndex = 6);
                            },
                          ),
                          _DrawerItem(
                            icon: Icons.two_wheeler_outlined,
                            title: 'Servis Motor',
                            isActive: _currentIndex == 7,
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _currentIndex = 7);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                                color: AppColors.isDark
                                    ? Colors.white10
                                    : AppColors.border),
                          ),
                          // Productivity Features Section
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'PRODUKTIVITAS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          _DrawerItem(
                            icon: Icons.dashboard_customize_outlined,
                            title: 'Kanban Board',
                            isActive: _currentIndex == 3,
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _currentIndex = 3);
                            },
                          ),
                          _DrawerItem(
                            icon: Icons.schedule_outlined,
                            title: 'Pomodoro Timer',
                            isActive: _currentIndex == 4,
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _currentIndex = 4);
                            },
                          ),
                          _DrawerItem(
                            icon: Icons.favorite_outline,
                            title: 'Habit Tracker',
                            isActive: _currentIndex == 5,
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _currentIndex = 5);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                                color: AppColors.isDark
                                    ? Colors.white10
                                    : AppColors.border),
                          ),
                          _DrawerItem(
                            icon: Icons.settings_outlined,
                            title: 'Pengaturan',
                            isActive: _currentIndex == 8,
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _currentIndex = 8);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Logout & Footer
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.expense,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text(
                                'Keluar',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Column(
                            children: [
                              Text(
                                'v2.4.1',
                                style: TextStyle(
                                  color: AppColors.textDim,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dibuat oleh Naufal Khalil Aldeza',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: isDesktop
              ? Row(
                  children: [
                    _SideNav(
                      currentIndex: _currentIndex,
                      onTap: (i) => setState(() => _currentIndex = i),
                      onToggleTheme: widget.onToggleTheme,
                      isDarkMode: widget.isDarkMode,
                      onOpenDrawer: () =>
                          _scaffoldKey.currentState?.openDrawer(),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? kBoardGradients[activeBoard?.colorIndex ?? 0]
                                : kBoardGradientsLight[activeBoard?.colorIndex ?? 0],
                          ),
                        ),
                        child: GridBackground(
                          child: IndexedStack(
                            index: _currentIndex,
                            children: pages,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? kBoardGradients[activeBoard?.colorIndex ?? 0]
                          : kBoardGradientsLight[activeBoard?.colorIndex ?? 0],
                    ),
                  ),
                  child: GridBackground(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: pages,
                    ),
                  ),
                ),
          floatingActionButton: _currentIndex == 0 && !isDesktop
              ? FloatingActionButton(
                  onPressed: _openAddForm,
                  backgroundColor: AppColors.blueAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const CircleBorder(
                      side: BorderSide(color: Colors.transparent)),
                  child: const Icon(Icons.add),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: isDesktop
              ? null
              : _BottomNav(
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
        );
      },
    );
  }
}

// ─── Custom Side Navigation Bar for Desktop ─────────────────────────────────
class _SideNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final VoidCallback onOpenDrawer;

  static const _items = [
    _NavItem(
        icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Beranda'),
    _NavItem(
        icon: Icons.pie_chart_outline,
        activeIcon: Icons.pie_chart,
        label: 'Keuangan'),
    _NavItem(
        icon: Icons.event_note_outlined,
        activeIcon: Icons.event_note,
        label: 'Task'),
  ];

  const _SideNav({
    required this.currentIndex,
    required this.onTap,
    required this.onToggleTheme,
    required this.isDarkMode,
    required this.onOpenDrawer,
  });

  @override
  State<_SideNav> createState() => _SideNavState();
}

class _SideNavState extends State<_SideNav> {
  Uint8List? _profilePhotoBytes;

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final base64Photo = prefs.getString(kLocalPhotoBase64Key);
    if (base64Photo != null && base64Photo.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Photo);
        if (mounted) setState(() => _profilePhotoBytes = bytes);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final currentIndex = widget.currentIndex;
    final onTap = widget.onTap;
    final onToggleTheme = widget.onToggleTheme;
    final onOpenDrawer = widget.onOpenDrawer;
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.bgCardAlt,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Hamburger Icon
          IconButton(
            icon: const Icon(Icons.menu),
            color: AppColors.textPrimary,
            onPressed: onOpenDrawer,
            tooltip: 'Menu',
          ),
          const SizedBox(height: 24),
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage('assets/logo.png'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blueAccent.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          ...List.generate(_SideNav._items.length, (i) {
            final item = _SideNav._items[i];
            final isActive = i == currentIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryWeb.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    color: isActive ? AppColors.primaryWeb : AppColors.textDim,
                    size: 24,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(color: AppColors.borderAccent),
          ),
          const SizedBox(height: 16),
          // Kanban
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Tooltip(
              message: 'Kanban Board',
              child: GestureDetector(
                onTap: () => onTap(3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: currentIndex == 3
                        ? AppColors.primaryWeb.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.dashboard_customize_outlined,
                    color: currentIndex == 3
                        ? AppColors.primaryWeb
                        : AppColors.textDim,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          // Pomodoro
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Tooltip(
              message: 'Pomodoro Timer',
              child: GestureDetector(
                onTap: () => onTap(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: currentIndex == 4
                        ? AppColors.primaryWeb.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.schedule_outlined,
                    color: currentIndex == 4
                        ? AppColors.primaryWeb
                        : AppColors.textDim,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          // Habit Tracker
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Tooltip(
              message: 'Habit Tracker',
              child: GestureDetector(
                onTap: () => onTap(5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: currentIndex == 5
                        ? AppColors.primaryWeb.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.favorite_outline,
                    color: currentIndex == 5
                        ? AppColors.primaryWeb
                        : AppColors.textDim,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          // Lending
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Tooltip(
              message: 'Peminjaman Barang',
              child: GestureDetector(
                onTap: () => onTap(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: currentIndex == 6
                        ? AppColors.primaryWeb.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: currentIndex == 6
                        ? AppColors.primaryWeb
                        : AppColors.textDim,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          // Vehicle Service
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Tooltip(
              message: 'Servis Motor',
              child: GestureDetector(
                onTap: () => onTap(7),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: currentIndex == 7
                        ? AppColors.primaryWeb.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.two_wheeler_outlined,
                    color: currentIndex == 7
                        ? AppColors.primaryWeb
                        : AppColors.textDim,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
            ),
            color: AppColors.textDim,
            onPressed: onToggleTheme,
            tooltip: isDarkMode ? 'Mode Terang' : 'Mode Gelap',
          ),
          const SizedBox(height: 8),
          // Avatar foto profil lokal pengguna
          GestureDetector(
            onTap: () => onTap(8), // Navigasi ke halaman Pengaturan
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.borderAccent,
              ),
              clipBehavior: Clip.antiAlias,
              child: _profilePhotoBytes != null
                  ? Image.memory(
                      _profilePhotoBytes!,
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom Bottom Navigation Bar ────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(
        icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Beranda'),
    _NavItem(
        icon: Icons.pie_chart_outline,
        activeIcon: Icons.pie_chart,
        label: 'Keuangan'),
    _NavItem(
        icon: Icons.event_note_outlined,
        activeIcon: Icons.event_note,
        label: 'Task'),
    _NavItem(
        icon: Icons.dashboard_customize_outlined,
        activeIcon: Icons.dashboard_customize,
        label: 'Kanban'),
    _NavItem(
        icon: Icons.schedule_outlined,
        activeIcon: Icons.schedule,
        label: 'Pomodoro'),
    _NavItem(
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
        label: 'Habit'),
    _NavItem(
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
        label: 'Dipinjam'),
    _NavItem(
        icon: Icons.two_wheeler_outlined,
        activeIcon: Icons.two_wheeler,
        label: 'Servis'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.isDark
                      ? const Color(0xFF1E1E1E).withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_items.length, (i) {
                      final item = _items[i];
                      final isActive = i == currentIndex;
                      return GestureDetector(
                        onTap: () => onTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.blueMid.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isActive ? item.activeIcon : item.icon,
                                color: isActive
                                    ? AppColors.blueAccent
                                    : AppColors.textDim,
                                size: 22,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: isActive
                                      ? AppColors.blueAccent
                                      : AppColors.textDim,
                                  fontSize: 10,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

// ─── Custom Drawer Item ──────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isActive;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.blueAccent : AppColors.textDim,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        tileColor: isActive ? AppColors.blueMid.withValues(alpha: 0.1) : null,
        onTap: onTap,
      ),
    );
  }
}
