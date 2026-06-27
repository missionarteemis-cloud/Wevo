import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/furniture_catalog.dart';
import '../game/room_game.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';
import '../theme.dart';

/// Schermata stanza — game layer (vedi docs/game-layer.md).
///
/// Carica la stanza reale via [RoomService] e la passa al mondo Flame
/// [RoomGame]. Mostra il riquadro descrizione (stile Habbo) quando si tocca
/// un oggetto. Presence/visitatori/chat negli slice successivi.
class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final RoomGame _game = RoomGame();
  String _roomName = 'La tua stanza';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final room = await RoomService.loadOrCreateMyRoom();
      _game.applyRoom(room);
      if (mounted) setState(() => _roomName = room.name);
    } catch (e) {
      if (mounted) setState(() => _error = 'Impossibile caricare la stanza.');
    }
  }

  @override
  void dispose() {
    _game.selected.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WevoColors.ink,
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _Header(roomName: _roomName),
          ),

          // Riquadro descrizione oggetto (basso destra)
          Positioned(
            right: 16,
            bottom: 16,
            child: ValueListenableBuilder<RoomFurnitureItem?>(
              valueListenable: _game.selected,
              builder: (_, item, __) => item == null
                  ? const SizedBox.shrink()
                  : _FurniInfo(
                      item: item,
                      onClose: () => _game.selected.value = null,
                    ),
            ),
          ),

          // Barra azioni (placeholder)
          const Positioned(left: 0, right: 0, bottom: 24, child: _ActionBar()),

          if (_error != null)
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Center(
                child: Text(_error!, style: const TextStyle(color: WevoColors.coral)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Riquadro info oggetto, stile Habbo "furni info".
class _FurniInfo extends StatelessWidget {
  final RoomFurnitureItem item;
  final VoidCallback onClose;
  const _FurniInfo({required this.item, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final def = furnitureDef(item.itemId);
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: WevoColors.surface.withOpacity(0.96),
        border: Border.all(color: WevoColors.periwinkle.withOpacity(0.35)),
        boxShadow: [wevoGlow(WevoColors.periwinkle, blur: 22)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  def.name,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, size: 18, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            def.description,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: WevoColors.textMid),
          ),
          const SizedBox(height: 12),
          // Sposta / Ruota / Prendi — placeholder (wiring nello slice successivo)
          Row(
            children: const [
              _MiniAction(icon: Icons.open_with, label: 'Sposta'),
              SizedBox(width: 6),
              _MiniAction(icon: Icons.rotate_right, label: 'Ruota'),
              SizedBox(width: 6),
              _MiniAction(icon: Icons.inventory_2_outlined, label: 'Prendi'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: WevoColors.periwinkle),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
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
            // Inventario (placeholder)
            _CircleBtn(icon: Icons.inventory_2_outlined, onTap: () {}),
            const SizedBox(width: 8),
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
  const _ActionBar();

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
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
