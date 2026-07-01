import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Presence + visitatori via Realtime Database (vedi docs/game-layer.md §19).
///
/// - Presence **per-connessione** (`presence/{uid}/connections/{connId}`) →
///   multi-tab safe; online = esiste almeno una connection.
/// - **Heartbeat** su `lastSeen` → mitiga l'`onDisconnect` lento su web (tab
///   chiusa "sporca"): si considera offline se `lastSeen` è troppo vecchio.
/// - Tutto **best-effort** (try/catch): se RTDB non è ancora attivo, non rompe
///   l'app. Diventa funzionante appena l'istanza RTDB esiste.
class PresenceService {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  /// URL istanza RTDB (europe-west1). Da creare in console: vedi §19.
  static const String dbUrl =
      'https://wevo-22275-default-rtdb.europe-west1.firebasedatabase.app';
  static const int _staleMs = 60000; // online solo se lastSeen < 60s fa

  FirebaseDatabase? _db;
  FirebaseDatabase get _database => _db ??= FirebaseDatabase.instanceFor(
        app: FirebaseAuth.instance.app,
        databaseURL: dbUrl,
      );

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  StreamSubscription<DatabaseEvent>? _connectedSub;
  Timer? _heartbeat;
  bool _started = false;

  /// Avvia la presence per l'utente corrente. Idempotente.
  Future<void> start() async {
    final uid = _uid;
    if (uid == null || _started) return;
    _started = true;
    try {
      final presenceRef = _database.ref('presence/$uid');
      final connectedRef = _database.ref('.info/connected');

      _connectedSub = connectedRef.onValue.listen((event) async {
        if (event.snapshot.value != true) return;
        final conn = presenceRef.child('connections').push();
        await conn.onDisconnect().remove();
        await presenceRef
            .child('lastSeen')
            .onDisconnect()
            .set(ServerValue.timestamp);
        await conn.set(true);
        await presenceRef.child('lastSeen').set(ServerValue.timestamp);
      });

      _heartbeat = Timer.periodic(const Duration(seconds: 20), (_) {
        presenceRef.child('lastSeen').set(ServerValue.timestamp);
      });
    } catch (_) {
      _started = false; // riprova al prossimo start()
    }
  }

  /// True se l'utente è online (connection viva + lastSeen recente).
  Stream<bool> onlineStream(String uid) {
    try {
      return _database.ref('presence/$uid').onValue.map((event) {
        final data = event.snapshot.value;
        if (data is! Map) return false;
        final hasConn = (data['connections'] as Map?)?.isNotEmpty ?? false;
        final lastSeen = data['lastSeen'];
        final fresh = lastSeen is int &&
            DateTime.now().millisecondsSinceEpoch - lastSeen < _staleMs;
        return hasConn && fresh;
      });
    } catch (_) {
      return Stream.value(false);
    }
  }

  /// True se l'utente è online E si trova nella propria stanza.
  Stream<bool> inOwnRoomStream(String uid) {
    try {
      return _database.ref('presence/$uid').onValue.map((event) {
        final data = event.snapshot.value;
        if (data is! Map) return false;
        return data['inRoom'] == uid;
      });
    } catch (_) {
      return Stream.value(false);
    }
  }

  /// Entra in una stanza: segna `inRoom` + scrive il proprio nodo roomPresence.
  Future<void> enterRoom(String ownerUid,
      {required String name,
      int x = 3,
      int y = 3,
      int? hoodie,
      int? skin,
      int? hair,
      String base = 'avatar_base'}) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final inRoomRef = _database.ref('presence/$uid/inRoom');
      await inRoomRef.onDisconnect().set(null);
      await inRoomRef.set(ownerUid);

      final node = _database.ref('roomPresence/$ownerUid/$uid');
      await node.onDisconnect().remove();
      await node.set({
        'name': name,
        'x': x,
        'y': y,
        if (hoodie != null) 'hoodie': hoodie,
        if (skin != null) 'skin': skin,
        if (hair != null) 'hair': hair,
        'base': base,
        'ts': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  /// Aggiorna l'aspetto (base/felpa/pelle/capelli) nel nodo roomPresence.
  Future<void> setMyAppearance(String ownerUid,
      {int? hoodie, int? skin, int? hair, String base = 'avatar_base'}) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _database.ref('roomPresence/$ownerUid/$uid').update(
          {'hoodie': hoodie, 'skin': skin, 'hair': hair, 'base': base});
    } catch (_) {}
  }

  Future<void> updatePosition(String ownerUid, int x, int y,
      {String? emote}) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _database.ref('roomPresence/$ownerUid/$uid').update({
        'x': x,
        'y': y,
        if (emote != null) 'emote': emote,
        'ts': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  Future<void> leaveRoom(String ownerUid) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _database.ref('roomPresence/$ownerUid/$uid').remove();
      await _database.ref('presence/$uid/inRoom').set(null);
    } catch (_) {}
  }

  /// Visitatori live nella stanza (escluso l'utente corrente).
  Stream<List<RoomVisitor>> roomVisitors(String ownerUid) {
    try {
      return _database.ref('roomPresence/$ownerUid').onValue.map((event) {
        final data = event.snapshot.value;
        if (data is! Map) return <RoomVisitor>[];
        return data.entries
            .where((e) => e.key != _uid)
            .map((e) => RoomVisitor.fromMap(
                  e.key as String,
                  Map<String, dynamic>.from(e.value as Map),
                ))
            .toList();
      });
    } catch (_) {
      return Stream.value(const []);
    }
  }

  // ── Chat stanza (effimera, RTDB roomChat) ──

  /// Invia un messaggio nella chat della stanza [ownerUid].
  Future<void> sendRoomMessage(String ownerUid,
      {required String name, required String text}) async {
    final uid = _uid;
    final t = text.trim();
    if (uid == null || t.isEmpty) return;
    try {
      await _database.ref('roomChat/$ownerUid').push().set({
        'senderId': uid,
        'name': name,
        'text': t.length > 200 ? t.substring(0, 200) : t,
        'ts': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  /// Cronologia live (ultimi ~40 messaggi, ordinati per tempo).
  Stream<List<RoomMessage>> roomChatStream(String ownerUid) {
    try {
      return _database
          .ref('roomChat/$ownerUid')
          .orderByChild('ts')
          .limitToLast(40)
          .onValue
          .map((event) {
        final data = event.snapshot.value;
        if (data is! Map) return <RoomMessage>[];
        final list = data.entries
            .map((e) => RoomMessage.fromMap(
                  e.key as String,
                  Map<String, dynamic>.from(e.value as Map),
                ))
            .toList()
          ..sort((a, b) => a.ts.compareTo(b.ts));
        return list;
      });
    } catch (_) {
      return Stream.value(const []);
    }
  }

  /// Segna se sto scrivendo (nuvoletta "..." per gli altri).
  Future<void> setTyping(String ownerUid, bool typing) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _database
          .ref('roomPresence/$ownerUid/$uid')
          .update({'typing': typing});
    } catch (_) {}
  }

  void dispose() {
    _connectedSub?.cancel();
    _heartbeat?.cancel();
    _started = false;
  }
}

/// Un visitatore presente in una stanza (da `roomPresence/{owner}/{visitor}`).
class RoomVisitor {
  final String uid;
  final String name;
  final int x;
  final int y;
  final String? emote;
  final int? hoodie; // colore felpa (recolor), null = originale
  final int? skin; // tono pelle (recolor), null = originale
  final int? hair; // colore capelli (recolor), null = originale
  final String base; // sprite set (es. 'avatar_base', 'avatar_female')
  final bool typing; // sta scrivendo in chat

  const RoomVisitor({
    required this.uid,
    required this.name,
    required this.x,
    required this.y,
    this.emote,
    this.hoodie,
    this.skin,
    this.hair,
    this.base = 'avatar_base',
    this.typing = false,
  });

  factory RoomVisitor.fromMap(String uid, Map<String, dynamic> d) =>
      RoomVisitor(
        uid: uid,
        name: (d['name'] ?? '') as String,
        x: (d['x'] as num? ?? 0).toInt(),
        y: (d['y'] as num? ?? 0).toInt(),
        emote: d['emote'] as String?,
        hoodie: (d['hoodie'] as num?)?.toInt(),
        skin: (d['skin'] as num?)?.toInt(),
        hair: (d['hair'] as num?)?.toInt(),
        base: (d['base'] as String?) ?? 'avatar_base',
        typing: d['typing'] == true,
      );
}

/// Un messaggio della chat-stanza (RTDB `roomChat/{owner}/{id}`), effimero.
class RoomMessage {
  final String id;
  final String senderId;
  final String name;
  final String text;
  final int ts;

  const RoomMessage({
    required this.id,
    required this.senderId,
    required this.name,
    required this.text,
    required this.ts,
  });

  factory RoomMessage.fromMap(String id, Map<String, dynamic> d) => RoomMessage(
        id: id,
        senderId: (d['senderId'] ?? '') as String,
        name: (d['name'] ?? '') as String,
        text: (d['text'] ?? '') as String,
        ts: (d['ts'] as num? ?? 0).toInt(),
      );
}
