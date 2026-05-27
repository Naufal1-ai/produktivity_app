import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:productivity/firebase_options.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/presentation/screens/auth/login_screen.dart';
import 'package:productivity/presentation/screens/shell/main_shell.dart';
import 'package:productivity/l10n/app_localizations.dart';
import 'package:productivity/services/settings_service.dart';
import 'package:productivity/providers/localization_provider.dart';
import 'package:productivity/providers/kanban_board_provider.dart';
import 'package:productivity/providers/pomodoro_provider.dart';
import 'package:productivity/providers/habit_tracker_provider.dart';
import 'package:productivity/providers/vehicle_service_provider.dart';
import 'package:productivity/services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Satu sumber kebenaran untuk dark mode
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);
final themeColorNotifier = ValueNotifier<Color>(const Color(0xFF4F46E5));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi service notifikasi secara aman (terutama untuk Windows desktop)
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint("Gagal menginisialisasi layanan notifikasi: $e");
  }

  // Initialize settings service
  final settingsService = SettingsService();
  await settingsService.init();
  themeColorNotifier.value = settingsService.themeColor;

  final prefs = await SharedPreferences.getInstance();
  final rememberMe = prefs.getBool('remember_me') ?? true;

  // If user didn't check 'Remember Me' in their last session, sign them out on fresh app start
  if (!rememberMe && FirebaseAuth.instance.currentUser != null) {
    await FirebaseAuth.instance.signOut();
  }

  runApp(MyApp(settingsService: settingsService));
}

class MyApp extends StatelessWidget {
  final SettingsService settingsService;

  const MyApp({super.key, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LocalizationProvider(settingsService),
        ),
        ChangeNotifierProvider(
          create: (_) => KanbanBoardProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PomodoroProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => HabitTrackerProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => VehicleServiceProvider(),
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, mode, __) => ValueListenableBuilder<Color>(
          valueListenable: themeColorNotifier,
          builder: (_, color, __) => Consumer<LocalizationProvider>(
            builder: (context, localizationProvider, child) => MaterialApp(
              title: 'Productivity',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              locale: localizationProvider.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'), // English
                Locale('id'), // Indonesian
              ],
              home: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold();
                  }
                  if (snapshot.hasData) {
                    return MainShell(
                      onToggleTheme: () {
                        themeNotifier.value =
                            themeNotifier.value == ThemeMode.dark
                                ? ThemeMode.light
                                : ThemeMode.dark;
                      },
                      isDarkMode: mode == ThemeMode.dark,
                    );
                  }
                  return const LoginScreen();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

