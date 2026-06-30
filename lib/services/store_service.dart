import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/catalog_item.dart';

/// Store: lettura catalogo + saldo coins (vedi docs/game-layer.md §18).
/// L'acquisto (`buyItem`) sarà una Cloud Function server-authoritative:
/// si aggancia qui appena è deployata.
class StoreService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Concede i coins iniziali (idempotente, non-bloccante). Chiamata all'ingresso.
  static Future<void> claimStarterCoins() async {
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('claimStarterCoins')
          .call();
    } catch (_) {
      // best-effort: non bloccare la UI
    }
  }

  static Future<List<CatalogItem>> loadCatalog() async {
    final snap = await _db.collection('catalog').get();
    return snap.docs
        .map((d) => CatalogItem.fromDoc(d.id, d.data()))
        .toList();
  }

  /// Saldo coins dell'utente, in tempo reale.
  static Stream<int> coinsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    return _db.collection('users').doc(uid).snapshots().map(
          (s) => (s.data()?['coins'] as num? ?? 0).toInt(),
        );
  }

  /// Acquisto server-authoritative via Cloud Function `buyItem` (us-central1).
  /// Ritorna `ok` e l'eventuale `error` ('insufficient', ...).
  static Future<({bool ok, String? error})> buyItem(String itemId) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('buyItem');
    final res = await callable.call(<String, dynamic>{'itemId': itemId});
    final data = Map<String, dynamic>.from(res.data as Map);
    return (ok: data['ok'] == true, error: data['error'] as String?);
  }
}
