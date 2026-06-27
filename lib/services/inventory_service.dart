import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/inventory_item.dart';

/// Inventario: oggetti posseduti + piazzamento/raccolta via Cloud Functions
/// (placeItem/takeItem, us-central1) — vedi docs/game-layer.md §18.
class InventoryService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static FirebaseFunctions get _fn =>
      FirebaseFunctions.instanceFor(region: 'us-central1');

  static Stream<List<InventoryItem>> stream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _db
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .snapshots()
        .map((s) =>
            s.docs.map((d) => InventoryItem.fromDoc(d.id, d.data())).toList());
  }

  /// Piazza un oggetto posseduto in stanza (inventario → rooms.furniture).
  static Future<({bool ok, String? error})> placeItem(
      String instanceId, int x, int y, int rot) async {
    final res = await _fn.httpsCallable('placeItem').call(<String, dynamic>{
      'instanceId': instanceId,
      'x': x,
      'y': y,
      'rot': rot,
    });
    final d = Map<String, dynamic>.from(res.data as Map);
    return (ok: d['ok'] == true, error: d['error'] as String?);
  }

  /// Rimette un oggetto in inventario (rooms.furniture → inventario).
  static Future<({bool ok, String? error})> takeItem(String instanceId) async {
    final res = await _fn.httpsCallable('takeItem').call(<String, dynamic>{
      'instanceId': instanceId,
    });
    final d = Map<String, dynamic>.from(res.data as Map);
    return (ok: d['ok'] == true, error: d['error'] as String?);
  }
}
