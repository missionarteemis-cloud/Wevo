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
      int? skin}) async {
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
        'ts': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  /// Aggiorna l'aspetto (felpa/pelle) nel nodo roomPresence corrente.
  Future<void> setMyAppearance(String ownerUid,
      {int? hoodie, int? skin}) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _database
          .ref('roomPresence/$ownerUid/$uid')
          .update({'hoodie': hoodie, 'skin': skin});
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

  const RoomVisitor({
    required this.uid,
    required this.name,
    required this.x,
    required this.y,
    this.emote,
    this.hoodie,
    this.skin,
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
      );
}
