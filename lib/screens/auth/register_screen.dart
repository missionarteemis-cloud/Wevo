import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/neon_stars_background.dart';
import '../onboarding/complete_profile_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _register() async {
    final validation = AuthService.validateRegistration(
      name: _nameCtrl.text,
      username: _usernameCtrl.text,
      ageText: _ageCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );
    if (validation != null) {
      setState(() => _error = validation.message);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await AuthService.register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      age: int.parse(_ageCtrl.text.trim()),
    );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
        (_) => false,
      );
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
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Create your\nWevo identity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Setup veloce, poi entriamo nella parte bella.',
                      style: TextStyle(color: WevoColors.textMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 22),
                    _RegisterGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CardEyebrow('register'),
                          const SizedBox(height: 14),
                          _Field(controller: _nameCtrl, hint: 'Nome', icon: Icons.person_outline),
                          const SizedBox(height: 12),
                          _Field(controller: _usernameCtrl, hint: 'Username', icon: Icons.alternate_email),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _Field(
                                  controller: _ageCtrl,
                                  hint: 'Età',
                                  icon: Icons.cake_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _Field(
                                  controller: _emailCtrl,
                                  hint: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _passCtrl,
                            hint: 'Password (min 6 caratteri)',
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: Colors.white54,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: WevoColors.coral, fontSize: 13)),
                          ],
                          const SizedBox(height: 20),
                          _PrimaryAuthButton(
                            label: 'Crea account',
                            loading: _loading,
                            onTap: _register,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Hai già un account? ',
                            style: TextStyle(color: WevoColors.textMuted),
                            children: [
                              TextSpan(
                                text: 'Accedi',
                                style: TextStyle(color: WevoColors.pink, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class _RegisterBackgroundStars extends StatelessWidget {
  const _RegisterBackgroundStars();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: CustomPaint(
          painter: _NeonStarsPainter(
            baseColor: const Color(0x668EC5FF),
            starCount: 70,
          ),
        ),
      ),
    );
  }
}

class _NeonStarsPainter extends CustomPainter {
  final Color baseColor;
  final int starCount;

  const _NeonStarsPainter({
    required this.baseColor,
    required this.starCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    for (var i = 0; i < starCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = (0.6 + rng.nextDouble() * 1.4);
      final opacity = 0.15 + rng.nextDouble() * 0.30;
      final hueShift = rng.nextDouble() * 0.025;

      final starColor = Color.lerp(
        const Color(0x668EC5FF),
        i.isEven ? const Color(0x55FF5FA2) : const Color(0x448EC5FF),
        hueShift,
      )!.withOpacity(opacity);

      // outer glow
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [starColor.withOpacity(0.15), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius * 4));
      canvas.drawCircle(Offset(x, y), radius * 4, glowPaint);

      // sharp center
      final corePaint = Paint()..color = starColor.withOpacity(opacity + 0.2);
      canvas.drawCircle(Offset(x, y), radius, corePaint);

      // cross spike
      if (radius > 1.2) {
        final spikePaint = Paint()
          ..color = starColor.withOpacity(opacity * 0.5)
          ..strokeWidth = 0.4;
        canvas.drawLine(Offset(x - radius * 2.5, y), Offset(x + radius * 2.5, y), spikePaint);
        canvas.drawLine(Offset(x, y - radius * 2.5), Offset(x, y + radius * 2.5), spikePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_NeonStarsPainter old) => false;
}


class _RegisterGlassCard extends StatelessWidget {
  final Widget child;
  const _RegisterGlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [wevoGlow(WevoColors.cyan, blur: 22)],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CardEyebrow extends StatelessWidget {
  final String text;
  const _CardEyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF9FDBFF),
        fontSize: 11,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _Field({
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
        hintStyle: const TextStyle(color: WevoColors.textMuted),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: WevoColors.cyan, width: 1.4),
        ),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _PrimaryAuthButton({required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: WevoColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [wevoGlow(WevoColors.pink, blur: 22)],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
