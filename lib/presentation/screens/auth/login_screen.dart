import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:productivity/main.dart' show themeNotifier;
import 'package:productivity/presentation/screens/forgot/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  bool _rememberMe = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
            email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      } else {
        await _auth.createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'user-not-found' => 'Email tidak ditemukan',
          'wrong-password' => 'Password salah',
          'invalid-credential' => 'Email atau password salah',
          'email-already-in-use' => 'Email sudah terdaftar',
          'weak-password' => 'Password minimal 6 karakter',
          'invalid-email' => 'Format email tidak valid',
          _ => e.message ?? 'Terjadi kesalahan',
        };
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);
    } catch (_) {
      setState(() => _error = 'Gagal masuk dengan Google');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1117)
          : (isWide ? const Color(0xFFF0F4F8) : cs.surface),
      body: Center(
        child: isWide
            ? _WideLayout(formWidget: _buildForm(context))
            : _buildForm(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF1A1D2E) : cs.surface;
    final borderColor =
        isDark ? const Color(0xFF2A2D3E) : const Color(0xFFE5E7EB);
    final tabBg = isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF3F4F6);
    final inputFill =
        isDark ? const Color(0xFF131620) : const Color(0xFFF9FAFB);
    final primaryColor = cs.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo + toggle dark mode
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      image: const DecorationImage(
                        image: AssetImage('assets/logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('KeuanganApp',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                ]),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (_, mode, __) => IconButton(
                    icon: Icon(
                      mode == ThemeMode.dark
                          ? Icons.wb_sunny_outlined
                          : Icons.nights_stay_outlined,
                      color: textSecondary,
                    ),
                    onPressed: () {
                      themeNotifier.value =
                          themeNotifier.value == ThemeMode.dark
                              ? ThemeMode.light
                              : ThemeMode.dark;
                    },
                    tooltip:
                        mode == ThemeMode.dark ? 'Mode Terang' : 'Mode Gelap',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text('Masuk ke akun kamu',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textPrimary)),
            const SizedBox(height: 4),
            Text('Selamat datang! Pilih metode masuk:',
                style: TextStyle(fontSize: 14, color: textSecondary)),
            const SizedBox(height: 24),

            // Tab toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: tabBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(children: [
                _Tab(
                    'Masuk',
                    _isLogin,
                    isDark,
                    () => setState(() {
                          _isLogin = true;
                          _error = null;
                        })),
                _Tab(
                    'Daftar',
                    !_isLogin,
                    isDark,
                    () => setState(() {
                          _isLogin = false;
                          _error = null;
                        })),
              ]),
            ),
            const SizedBox(height: 20),

            // Google button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loading ? null : _signInGoogle,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: cardBg,
                ),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.g_mobiledata,
                      size: 22, color: Color(0xFF4285F4)),
                  const SizedBox(width: 8),
                  Text('Lanjutkan dengan Google',
                      style: TextStyle(
                          fontSize: 14,
                          color: textPrimary,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Divider
            Row(children: [
              Expanded(child: Divider(color: borderColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('atau dengan email',
                    style: TextStyle(fontSize: 12, color: textSecondary)),
              ),
              Expanded(child: Divider(color: borderColor)),
            ]),
            const SizedBox(height: 16),

            // Email
            _FieldLabel('Email', textSecondary),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: _inputDecor('nama@email.com', inputFill, borderColor),
            ),
            const SizedBox(height: 12),

            // Password
            _FieldLabel('Password', textSecondary),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              onSubmitted: (_) => _submitEmail(),
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration:
                  _inputDecor('••••••••', inputFill, borderColor).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: textSecondary,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Remember me + Lupa password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (val) {
                          if (val != null) setState(() => _rememberMe = val);
                        },
                        activeColor: primaryColor,
                        side: BorderSide(color: textSecondary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Ingat saya',
                        style: TextStyle(color: textSecondary, fontSize: 13)),
                  ],
                ),
                // ✅ Navigasi ke ForgotPasswordScreen
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text('Lupa password?',
                      style: TextStyle(color: primaryColor, fontSize: 13)),
                ),
              ],
            ),

            // Error
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: .3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13))),
                ]),
              ),
            ],
            const SizedBox(height: 16),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isLogin ? 'Masuk →' : 'Buat Akun →',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),

            // Switch mode
            Center(
              child: GestureDetector(
                onTap: () => setState(() {
                  _isLogin = !_isLogin;
                  _error = null;
                }),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: textSecondary),
                    children: [
                      TextSpan(
                          text: _isLogin
                              ? 'Belum punya akun? '
                              : 'Sudah punya akun? '),
                      TextSpan(
                        text: 'Klik di sini',
                        style: TextStyle(
                            color: primaryColor, fontWeight: FontWeight.w500),
                      ),
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

  InputDecoration _inputDecor(String hint, Color fill, Color border) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: border, fontSize: 14),
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5)),
      );
}

// ─── Wide layout ──────────────────────────────────────────────────────────────

class _WideLayout extends StatefulWidget {
  final Widget formWidget;
  const _WideLayout({required this.formWidget});
  @override
  State<_WideLayout> createState() => _WideLayoutState();
}

class _WideLayoutState extends State<_WideLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _float;
  late final PageController _pageCtrl;
  Timer? _timer;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Kelola keuanganmu\ndengan mudah',
      'desc': 'Catat pemasukan & pengeluaran,\npantau saldo real-time kapan saja.',
      'center': '💰',
      'orbs': ['📈', '💳', '🔔', '🏦']
    },
    {
      'title': 'Tingkatkan produktivitas\nsetiap hari',
      'desc': 'Gunakan Kanban Board & Pomodoro\nuntuk mengatur fokus dan jadwalmu.',
      'center': '⚡',
      'orbs': ['📅', '🎯', '⏱️', '📋']
    },
    {
      'title': 'Bangun kebiasaan baik\nsecara konsisten',
      'desc': 'Habit Tracker membantu memantau\nperkembangan target harianmu.',
      'center': '⭐',
      'orbs': ['🌱', '🔥', '💪', '🏆']
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _float = Tween(begin: 0.0, end: 8.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!mounted) return;
      if (_currentIndex < _slides.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      if (_pageCtrl.hasClients) {
        _pageCtrl.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1D2E) : Colors.white;

    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? .4 : .1),
              blurRadius: 40,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(children: [
        Expanded(child: widget.formWidget),
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: Container(
            width: 360,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(children: [
              Positioned(top: -80, left: -80, child: _buildRing(360)),
              Positioned(top: -20, left: -20, child: _buildRing(240)),
              Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageCtrl,
                      onPageChanged: (idx) {
                        setState(() {
                          _currentIndex = idx;
                        });
                      },
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _float,
                                builder: (_, __) => Transform.translate(
                                  offset: Offset(0, -_float.value),
                                  child: _buildIllustration(
                                    slide['center'],
                                    slide['orbs'],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(slide['title'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      height: 1.4)),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                    slide['desc'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        height: 1.6)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _buildDot(_currentIndex == index),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildRing(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: .1), width: 1.5),
        ),
      );

  Widget _buildIllustration(String centerEmoji, List<String> orbs) => SizedBox(
        width: 200,
        height: 200,
        child: Stack(alignment: Alignment.center, children: [
          _buildOrb(orbs[0], top: 0, left: 76),
          _buildOrb(orbs[1], top: 76, left: 0),
          _buildOrb(orbs[2], top: 76, right: 0),
          _buildOrb(orbs[3], bottom: 0, left: 76),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .25),
              borderRadius: BorderRadius.circular(18),
            ),
            child:
                Center(child: Text(centerEmoji, style: const TextStyle(fontSize: 28))),
          ),
        ]),
      );

  Widget _buildOrb(String emoji,
          {double? top, double? left, double? right, double? bottom}) =>
      Positioned(
        top: top,
        left: left,
        right: right,
        bottom: bottom,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .2),
            borderRadius: BorderRadius.circular(14),
          ),
          child:
              Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
        ),
      );

  Widget _buildDot(bool active) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: active ? 20 : 7,
        height: 7,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white38,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;
  const _Tab(this.label, this.active, this.isDark, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active
                  ? (isDark ? const Color(0xFF2D5A3D) : Colors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: active && !isDark
                  ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: .06),
                          blurRadius: 4)
                    ]
                  : [],
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? (isDark
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF1565C0))
                      : const Color(0xFF6B7280),
                )),
          ),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _FieldLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
                letterSpacing: .5)),
      );
}
