import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/errors/error_codes.dart';
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
  Map<String, String> _fieldErrors = {};

  Future<void> _register() async {
    final fieldErrors = AuthService.validateRegistrationFields(
      name: _nameCtrl.text,
      username: _usernameCtrl.text,
      ageText: _ageCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );
    if (fieldErrors.isNotEmpty) {
      setState(() { _fieldErrors = fieldErrors; _error = null; });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _fieldErrors = {};
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
        _loading = false;
        // Mappa gli errori backend noti sul campo giusto.
        if (error.code == WevoErrorCode.authEmailAlreadyInUse) {
          _fieldErrors = {'email': 'Email già in uso'};
        } else if (error.code == WevoErrorCode.authUsernameAlreadyInUse) {
          _fieldErrors = {'username': 'Username già in uso'};
        } else {
          _error = error.message;
        }
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
                          _Field(controller: _nameCtrl, hint: 'Nome', icon: Icons.person_outline, error: _fieldErrors['name']),
                          const SizedBox(height: 12),
                          _Field(controller: _usernameCtrl, hint: 'Username', icon: Icons.alternate_email, error: _fieldErrors['username']),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _Field(
                                  controller: _ageCtrl,
                                  hint: 'Età',
                                  icon: Icons.cake_outlined,
                                  keyboardType: TextInputType.number,
                                  error: _fieldErrors['age'],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _Field(
                                  controller: _emailCtrl,
                                  hint: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  error: _fieldErrors['email'],
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
                            error: _fieldErrors['password'],
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
  final String? error;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Campo in vetro liquido (glassmorphism) ──
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: hasError
                      ? WevoColors.coral.withOpacity(0.75)
                      : Colors.white.withOpacity(0.20),
                  width: 1.2,
                ),
                boxShadow: [
                  // specular highlight (riflesso "liquid")
                  BoxShadow(color: Colors.white.withOpacity(0.10), spreadRadius: -1, offset: const Offset(0, 1)),
                  BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: TextField(
                controller: controller,
                obscureText: obscure,
                keyboardType: keyboardType,
                cursorColor: WevoColors.cyan,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: WevoColors.textMuted),
                  prefixIcon: Icon(icon, color: Colors.white70, size: 20),
                  suffixIcon: suffixIcon,
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 17),
                ),
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: WevoColors.coral, size: 13),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(color: WevoColors.coral, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
      ],
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
