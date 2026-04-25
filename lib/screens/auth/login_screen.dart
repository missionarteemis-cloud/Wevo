import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import 'register_screen.dart';

// Colore che matcha il background del PNG del logo
const _logoBg = Color(0xFF0D0812);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailOrNameCtrl = TextEditingController();
  final _passCtrl        = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final error = await AuthService.login(
      emailOrName: _emailOrNameCtrl.text.trim(),
      password   : _passCtrl.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() { _error = error.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WevoColors.dark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header con logo + onda ──────────────────────────────────
              ClipPath(
                clipper: _WaveClipper(),
                child: Container(
                  width: double.infinity,
                  color: _logoBg,
                  padding: const EdgeInsets.fromLTRB(28, 56, 28, 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/wevo scritta.PNG', height: 70),
                      const SizedBox(height: 10),
                      Text(
                        'Connettiti con persone vere.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Form di login ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WevoField(
                      controller: _emailOrNameCtrl,
                      hint: 'Email o nome utente',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _WevoField(
                      controller: _passCtrl,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white38,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(
                              color: WevoColors.coral, fontSize: 13)),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WevoColors.pink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Accedi',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: RichText(
                          text: TextSpan(
                            text: 'Non hai un account? ',
                            style:
                                TextStyle(color: Colors.white.withOpacity(0.5)),
                            children: const [
                              TextSpan(
                                text: 'Registrati',
                                style: TextStyle(
                                    color: WevoColors.pink,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Wave clipper ──────────────────────────────────────────────────────────────

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 55);
    // prima curva: sale
    path.quadraticBezierTo(
      size.width * 0.25, size.height,
      size.width * 0.5,  size.height - 30,
    );
    // seconda curva: scende
    path.quadraticBezierTo(
      size.width * 0.75, size.height - 60,
      size.width,        size.height - 25,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => false;
}

// ── Campo testo ───────────────────────────────────────────────────────────────

class _WevoField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _WevoField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: WevoColors.pink, width: 1.5),
        ),
      ),
    );
  }
}
