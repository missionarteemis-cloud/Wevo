import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/room_game.dart';
import '../theme.dart';

/// Schermata stanza — slice 1-2 del game layer (vedi docs/game-layer.md).
///
/// Per ora locale: ospita il mondo Flame [RoomGame] + header e barra azioni
/// in stile Wevo. Presence/visitatori/chat arrivano negli slice successivi.
class RoomScreen extends StatefulWidget {
  /// Nome mostrato in header (placeholder finché non c'è il modello `rooms`).
  final String roomName;
  const RoomScreen({super.key, this.roomName = 'La tua stanza'});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final RoomGame _game = RoomGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WevoColors.ink,
      body: Stack(
        children: [
          // ── Mondo di gioco ──
          Positioned.fill(child: GameWidget(game: _game)),

          // ── Header ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _Header(roomName: widget.roomName),
          ),

          // ── Barra azioni (placeholder, no-op per ora) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: _ActionBar(),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String roomName;
  const _Header({required this.roomName});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _CircleBtn(
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: WevoColors.surface,
                border: Border.all(color: WevoColors.teal.withOpacity(0.4)),
              ),
              child: const Icon(Icons.home_rounded, color: WevoColors.teal, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    roomName,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'La tua vibe diventa un posto',
                    style: TextStyle(fontSize: 12, color: WevoColors.textMuted),
                  ),
                ],
              ),
            ),
            _CircleBtn(
              icon: Icons.close,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: WevoColors.surface.withOpacity(0.85),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _ActionChip(icon: Icons.waving_hand, label: 'Saluta', color: WevoColors.gold),
            _ActionChip(icon: Icons.music_note, label: 'Balla', color: WevoColors.pink),
            _ActionChip(icon: Icons.emoji_emotions_outlined, label: 'Emote', color: WevoColors.teal),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withOpacity(0.12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: WevoColors.surface,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}
