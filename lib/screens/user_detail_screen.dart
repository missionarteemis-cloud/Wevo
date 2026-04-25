import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme.dart';

class UserDetailScreen extends StatelessWidget {
  final UserModel user;

  /// Callback chiamato quando l'utente preme ♥ (like) o ✕ (passa).
  /// true = like, false = passa. Null se si vuole solo vedere il profilo.
  final void Function(bool liked)? onDecision;

  const UserDetailScreen({
    super.key,
    required this.user,
    this.onDecision,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WevoColors.dark,
      body: Stack(
        children: [
          // ── Cover full-screen ─────────────────────────────────────────────
          Positioned.fill(
            child: Image.network(
              user.coverUrl.isNotEmpty ? user.coverUrl : user.photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: WevoColors.dark),
            ),
          ),

          // ── Gradiente dal basso ───────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.35, 1.0],
                ),
              ),
            ),
          ),

          // ── Pulsante indietro ─────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // ── Contenuto in basso ────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nome ed età
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${user.name}, ${user.age}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (user.discordTag != null)
                            const Icon(Icons.games, color: WevoColors.lightBlue, size: 22),
                          if (user.hasNetflix)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(Icons.tv, color: WevoColors.coral, size: 22),
                            ),
                        ],
                      ),

                      // Bio
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          user.bio,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],

                      // Interessi
                      if (user.interests.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: user.interests.map((i) => _Chip(label: i)).toList(),
                        ),
                      ],

                      // Bottoni like / passa
                      if (onDecision != null) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _DecisionButton(
                              icon: Icons.close,
                              color: WevoColors.coral,
                              size: 56,
                              onTap: () {
                                onDecision!(false);
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(width: 40),
                            _DecisionButton(
                              icon: Icons.favorite,
                              color: WevoColors.pink,
                              size: 68,
                              onTap: () {
                                onDecision!(true);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Avatar circolare sovrapposto al pannello ───────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LayoutBuilder(builder: (context, constraints) {
              // Trova altezza pannello (approssimata) per posizionare avatar
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const SizedBox(height: 56), // placeholder per il padding sopra
                  Positioned(
                    top: -44,
                    left: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: WevoColors.dark,
                        backgroundImage: NetworkImage(user.photoUrl),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: WevoColors.pink.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WevoColors.pink.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _DecisionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.46),
      ),
    );
  }
}
