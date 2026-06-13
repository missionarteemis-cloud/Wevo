import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/neon_stars_background.dart';
import 'dev_access_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailOrNameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final error = await AuthService.login(
      emailOrName: _emailOrNameCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() { _error = error.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [WevoColors.bg, WevoColors.dark, WevoColors.darkSoft],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const NeonStarsBackground(starCount: 70),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 768;
                  final logoSize = isDesktop ? 220.0 : 180.0;
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: isDesktop ? 380 : double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── LOGO GIGANTE ──
                            Image.asset(
                              'assets/images/wevo_scritta_nobg.png',
                              height: logoSize,
                            ),
                            const SizedBox(height: 16),
                            // ── Icona row: joystick + cuffie ──
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _neonIcon(Icons.sports_esports_outlined, WevoColors.pink),
                                const SizedBox(width: 24),
                                _neonIcon(Icons.headphones_outlined, WevoColors.cyan),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // ── Slogan ──
                            const Text(
                              '"Find people who share your world."',
                              style: TextStyle(
                                color: WevoColors.textMuted,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            // ── CAMPUS A CAPSULA (uguali all'immagine) ──
                            _capsuleField(
                              controller: _emailOrNameCtrl,
                              hint: 'Email o username',
                            ),
                            const SizedBox(height: 14),
                            _capsuleField(
                              controller: _passCtrl,
                              hint: 'Password',
                              obscure: _obscure,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: Colors.white38,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Text(_error!, style: const TextStyle(color: WevoColors.coral, fontSize: 13)),
                            ],
                            const SizedBox(height: 24),
                            // ── BOTTONE NEON SOLIDO (come nell'immagine) ──
                            _neonButton(label: 'Accedi', loading: _loading, onTap: _login),
                            const SizedBox(height: 16),
                            _ghostButton(
                              label: 'Accesso rapido demo',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const DevAccessScreen()),
                              ),
                            ),
                            const SizedBox(height: 28),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              ),
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Non hai un account? ',
                                  style: TextStyle(color: WevoColors.textMuted),
                                  children: [
                                    TextSpan(
                                      text: 'Registrati',
                                      style: TextStyle(color: WevoColors.pink, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Neon icon helper ─────────────────────────────────────────────────────────

Widget _neonIcon(IconData icon, Color color) {
  return Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withOpacity(0.18), Colors.transparent],
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Icon(icon, color: color, size: 28),
  );
}

// ── Capsula field (esattamente come nell'immagine) ──────────────────────────

Widget _capsuleField({
  required TextEditingController controller,
  required String hint,
  bool obscure = false,
  Widget? suffix,
}) {
  return TextField(
    controller: controller,
    obscureText: obscure,
    style: const TextStyle(color: Colors.white, fontSize: 15),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

// ── Bottone neon solido ─────────────────────────────────────────────────────

Widget _neonButton({
  required String label,
  required bool loading,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: WevoColors.pink,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: WevoColors.pink.withOpacity(0.40),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    ),
  );
}

// ── Ghost button ────────────────────────────────────────────────────────────

Widget _ghostButton({
  required String label,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withOpacity(0.12)),
        backgroundColor: Colors.white.withOpacity(0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      icon: const Icon(Icons.auto_awesome, color: WevoColors.lightBlue, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
    ),
  );
}
