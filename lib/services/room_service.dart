import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/room_model.dart';

class RoomService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;

  static DocumentReference<Map<String, dynamic>> _roomRef(String ownerUid) =>
      _db.collection('rooms').doc(ownerUid);

  static Future<RoomModel> loadOrCreateMyRoom() async {
    final ref = _roomRef(_uid);
    final snap = await ref.get();

    if (snap.exists && snap.data() != null) {
      return RoomModel.fromMap(snap.data()!, snap.id);
    }

    final room = _defaultRoom(_uid);
    await ref.set({
      ...room.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return room;
  }

  /// Carica la stanza di un altro utente (visita, sola lettura).
  static Future<RoomModel?> loadRoom(String ownerUid) async {
    final snap = await _roomRef(ownerUid).get();
    if (snap.exists && snap.data() != null) {
      return RoomModel.fromMap(snap.data()!, snap.id);
    }
    return null;
  }

  static Future<void> saveFurniture(List<RoomFurnitureItem> furniture) async {
    await _roomRef(_uid).set({
      'ownerUid': _uid,
      'furniture': furniture.map((item) => item.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static RoomModel _defaultRoom(String ownerUid) {
    return RoomModel(
      ownerUid: ownerUid,
      name: 'My Room',
      theme: const RoomTheme(
        floor: 'neon-grid',
        wallpaper: 'violet-lounge',
      ),
      furniture: const [
        RoomFurnitureItem(
          instanceId: 'starter-sofa',
          itemId: 'sofa_neon_2x1',
          x: 2,
          y: 4,
          rot: 0,
        ),
        RoomFurnitureItem(
          instanceId: 'starter-table',
          itemId: 'table_low_2x2',
          x: 4,
          y: 3,
          rot: 0,
        ),
        RoomFurnitureItem(
          instanceId: 'starter-lamp',
          itemId: 'lamp_pillar_1x1',
          x: 1,
          y: 2,
          rot: 0,
        ),
        RoomFurnitureItem(
          instanceId: 'starter-bed',
          itemId: 'bed_loft_3x1',
          x: 0,
          y: 5,
          rot: 0,
        ),
      ],
    );
  }
}
