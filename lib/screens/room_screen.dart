import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/furniture_catalog.dart';
import '../game/room_game.dart';
import '../models/avatar_figure.dart';
import '../models/room_model.dart';
import '../services/inventory_service.dart';
import '../services/presence_service.dart';
import '../services/room_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import 'inventory_window.dart';
import 'store_window.dart';

/// Schermata stanza — game layer (vedi docs/game-layer.md).
///
/// `ownerUid` null = la tua stanza (editabile). `ownerUid` valorizzato = visiti
/// la stanza di un altro (sola lettura) + presence multiplayer.
class RoomScreen extends StatefulWidget {
  final String? ownerUid;
  final String? ownerName;
  const RoomScreen({super.key, this.ownerUid, this.ownerName});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final RoomGame _game = RoomGame();
  String _roomName = 'La tua stanza';
  AvatarFigure _figure = AvatarFigure.standard;
  String? _error;
  bool _storeOpen = false;
  Offset _storePos = const Offset(20, 96);
  bool _inventoryOpen = false;
  Offset _invPos = const Offset(40, 110);
  StreamSubscription<List<RoomVisitor>>? _visitorsSub;
  StreamSubscription<RoomModel?>? _roomSub;

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;
  bool get _isVisiting => widget.ownerUid != null && widget.ownerUid != _myUid;
  String get _targetOwner => widget.ownerUid ?? _myUid;

  @override
  void initState() {
    super.initState();
    if (!_isVisiting) {
      _game.onPersist = _persist;
      _game.onPlace = _place;
    }
    _game.onMyMove = (x, y) =>
        PresenceService.instance.updatePosition(_targetOwner, x, y);
    _loadFigure();
    _enterAndSubscribe();
    _load();
  }

  /// Carica l'aspetto del mio avatar e lo applica (gioco + presence).
  Future<void> _loadFigure() async {
    final fig = await UserService.fetchMyFigure();
    if (!mounted) return;
    setState(() => _figure = fig);
    _game.setMyFigure(fig);
    PresenceService.instance
        .setMyAppearance(_targetOwner, hoodie: fig.hoodie, skin: fig.skin);
  }

  /// Applica un aspetto aggiornato: gioco, persistenza, propagazione visitatori.
  void _applyFigure(AvatarFigure fig) {
    setState(() => _figure = fig);
    _game.setMyFigure(fig);
    UserService.saveFigure(fig);
    PresenceService.instance
        .setMyAppearance(_targetOwner, hoodie: fig.hoodie, skin: fig.skin);
  }

  void _setHoodie(int? hoodie) => _applyFigure(
      _figure.copyWith(hoodie: hoodie, resetHoodie: hoodie == null));

  void _setSkin(int? skin) =>
      _applyFigure(_figure.copyWith(skin: skin, resetSkin: skin == null));

  Future<void> _enterAndSubscribe() async {
    final myName = FirebaseAuth.instance.currentUser?.displayName ?? 'Ospite';
    await PresenceService.instance.enterRoom(_targetOwner,
        name: myName, hoodie: _figure.hoodie, skin: _figure.skin);
    _visitorsSub = PresenceService.instance
        .roomVisitors(_targetOwner)
        .listen((visitors) => _game.setVisitors(visitors));
  }

  Future<void> _reloadRoom() async {
    try {
      final room = await RoomService.loadOrCreateMyRoom();
      _game.applyRoom(room);
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _place(RoomFurnitureItem item) async {
    final r = await InventoryService.placeItem(item.instanceId, item.x, item.y, item.rot);
    if (!mounted) return;
    if (r.ok) {
      await _reloadRoom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Piazzamento non riuscito')),
      );
    }
  }

  Future<void> _take(RoomFurnitureItem item) async {
    final r = await InventoryService.takeItem(item.instanceId);
    if (!mounted) return;
    if (r.ok) {
      _game.selected.value = null;
      await _reloadRoom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operazione non riuscita')),
      );
    }
  }

  Future<void> _load() async {
    try {
      if (_isVisiting) {
        _roomSub = RoomService.roomStream(_targetOwner).listen((room) {
          if (room != null) _game.applyRoom(room);
        });
        if (mounted) {
          setState(() => _roomName = widget.ownerName != null
              ? 'Stanza di ${widget.ownerName}'
              : 'Stanza');
        }
      } else {
        final room = await RoomService.loadOrCreateMyRoom();
        _game.applyRoom(room);
        if (mounted) setState(() => _roomName = room.name);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Impossibile caricare la stanza.');
    }
  }

  void _showFriends() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Amici — pannello in arrivo')),
    );
  }

  void _showEmotes() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: WevoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Emote', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _EmotePick(icon: Icons.waving_hand, label: 'Saluta', color: WevoColors.gold),
                _EmotePick(icon: Icons.music_note, label: 'Balla', color: WevoColors.pink),
                _EmotePick(icon: Icons.celebration, label: 'Festa', color: WevoColors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAppearance() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: WevoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aspetto',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 16),
              const Text('Felpa',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final c in kHoodiePresets)
                    _ColorSwatch(
                      color: c,
                      fallback: WevoColors.teal,
                      selected: _figure.hoodie == c,
                      onTap: () {
                        _setHoodie(c);
                        setSheet(() {});
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Pelle',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final c in kSkinPresets)
                    _ColorSwatch(
                      color: c,
                      fallback: const Color(0xFFDF8D5D),
                      selected: _figure.skin == c,
                      onTap: () {
                        _setSkin(c);
                        setSheet(() {});
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _persist(List<RoomFurnitureItem> furniture) async {
    try {
      await RoomService.saveFurniture(furniture);
    } catch (_) {
      // best-effort: non bloccare la UI sull'errore di salvataggio
    }
  }

  @override
  void dispose() {
    _visitorsSub?.cancel();
    _roomSub?.cancel();
    PresenceService.instance.leaveRoom(_targetOwner);
    _game.selected.dispose();
    _game.moving.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WevoColors.ink,
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _Header(roomName: _roomName),
          ),

          // Finestra store draggabile
          if (_storeOpen && !_isVisiting)
            Positioned(
              left: _storePos.dx,
              top: _storePos.dy,
              child: StoreWindow(
                onDrag: (delta) => setState(() => _storePos += delta),
                onClose: () => setState(() => _storeOpen = false),
              ),
            ),

          // Finestra inventario draggabile
          if (_inventoryOpen && !_isVisiting)
            Positioned(
              left: _invPos.dx,
              top: _invPos.dy,
              child: InventoryWindow(
                onDrag: (delta) => setState(() => _invPos += delta),
                onClose: () => setState(() => _inventoryOpen = false),
                onPlaceItem: (inv) {
                  setState(() => _inventoryOpen = false);
                  _game.startPlace(RoomFurnitureItem(
                    instanceId: inv.instanceId,
                    itemId: inv.itemId,
                    x: 3,
                    y: 3,
                    rot: 0,
                  ));
                },
              ),
            ),

          // Riquadro descrizione / pannello spostamento (basso destra)
          Positioned(
            right: 16,
            bottom: 120, // sopra il dock (evita sovrapposizione su schermi stretti)
            child: AnimatedBuilder(
              animation: Listenable.merge([_game.selected, _game.moving]),
              builder: (_, __) {
                final item = _game.selected.value;
                if (item == null) return const SizedBox.shrink();
                if (_game.moving.value) {
                  return _MovePanel(
                    item: item,
                    onRotate: _game.rotateSelected,
                    onCancel: _game.cancelMove,
                  );
                }
                return _FurniInfo(
                  item: item,
                  canEdit: !_isVisiting,
                  onMove: _game.startMove,
                  onRotate: _game.rotateSelected,
                  onTake: () => _take(item),
                  onClose: () => _game.selected.value = null,
                );
              },
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: _RoomDock(
              canEdit: !_isVisiting,
              onFriends: _showFriends,
              onStore: () => setState(() => _storeOpen = !_storeOpen),
              onInventory: () => setState(() => _inventoryOpen = !_inventoryOpen),
              onAppearance: _showAppearance,
              onEmote: _showEmotes,
            ),
          ),

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

/// Riquadro info oggetto (stile Habbo) con azioni Sposta/Ruota/Prendi.
class _FurniInfo extends StatelessWidget {
  final RoomFurnitureItem item;
  final bool canEdit;
  final VoidCallback onMove;
  final VoidCallback onRotate;
  final VoidCallback onTake;
  final VoidCallback onClose;
  const _FurniInfo({
    required this.item,
    required this.canEdit,
    required this.onMove,
    required this.onRotate,
    required this.onTake,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final def = furnitureDef(item.itemId);
    return _Panel(
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
          if (canEdit) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniAction(icon: Icons.open_with, label: 'Sposta', onTap: onMove),
                const SizedBox(width: 6),
                _MiniAction(icon: Icons.rotate_right, label: 'Ruota', onTap: onRotate),
                const SizedBox(width: 6),
                _MiniAction(icon: Icons.inventory_2_outlined, label: 'Prendi', onTap: onTake),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Pannello modalità spostamento (anteprima fantasma attiva).
class _MovePanel extends StatelessWidget {
  final RoomFurnitureItem item;
  final VoidCallback onRotate;
  final VoidCallback onCancel;
  const _MovePanel({
    required this.item,
    required this.onRotate,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.open_with, size: 16, color: WevoColors.teal),
              const SizedBox(width: 6),
              Text(
                'Sposta ${furnitureDef(item.itemId).name}',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tocca una cella per posizionare. Ri-tocca la stessa cella per confermare.',
            style: TextStyle(fontSize: 12, height: 1.4, color: WevoColors.textMid),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniAction(icon: Icons.rotate_right, label: 'Ruota', onTap: onRotate),
              const SizedBox(width: 6),
              _MiniAction(icon: Icons.close, label: 'Annulla', onTap: onCancel),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: WevoColors.surface.withOpacity(0.96),
        border: Border.all(color: WevoColors.periwinkle.withOpacity(0.35)),
        boxShadow: [wevoGlow(WevoColors.periwinkle, blur: 22)],
      ),
      child: child,
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _MiniAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? WevoColors.periwinkle : Colors.white24;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white.withOpacity(enabled ? 0.06 : 0.02),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: enabled ? Colors.white70 : Colors.white24),
              ),
            ],
          ),
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

/// Dock stile Habbo: barra strumenti in basso (Amici / Store / Zaino / Emote).
class _RoomDock extends StatelessWidget {
  final bool canEdit;
  final VoidCallback onFriends;
  final VoidCallback onStore;
  final VoidCallback onInventory;
  final VoidCallback onAppearance;
  final VoidCallback onEmote;
  const _RoomDock({
    required this.canEdit,
    required this.onFriends,
    required this.onStore,
    required this.onInventory,
    required this.onAppearance,
    required this.onEmote,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.13), Colors.white.withValues(alpha: 0.04)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.24), blurRadius: 22, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DockButton(icon: Icons.people_alt_rounded, label: 'Amici', color: WevoColors.lightBlue, onTap: onFriends),
                if (canEdit) ...[
                  _DockButton(icon: Icons.storefront_rounded, label: 'Store', color: WevoColors.pink, onTap: onStore),
                  _DockButton(icon: Icons.backpack_rounded, label: 'Zaino', color: WevoColors.gold, onTap: onInventory),
                ],
                _DockButton(icon: Icons.checkroom_rounded, label: 'Aspetto', color: WevoColors.periwinkle, onTap: onAppearance),
                _DockButton(icon: Icons.emoji_emotions_rounded, label: 'Emote', color: WevoColors.teal, onTap: onEmote),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmotePick extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _EmotePick({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(), // wiring emote → prossimo step
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Pastiglia colore nel pannello Aspetto. `color` null = originale ([fallback]).
class _ColorSwatch extends StatelessWidget {
  final int? color;
  final Color fallback;
  final bool selected;
  final VoidCallback onTap;
  const _ColorSwatch(
      {required this.color,
      required this.fallback,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color == null ? fallback : Color(color!);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c,
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: selected ? 3 : 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 10)]
              : null,
        ),
        child: color == null
            ? const Icon(Icons.star_rounded, color: Colors.white70, size: 18)
            : (selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                : null),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _DockButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: color.withValues(alpha: 0.16),
                border: Border.all(color: color.withValues(alpha: 0.32)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 10, fontWeight: FontWeight.w700),
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
