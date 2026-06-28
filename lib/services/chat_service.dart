import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _fn = FirebaseFunctions.instanceFor(region: 'us-central1');

  static String get currentUid => _auth.currentUser!.uid;
  static String get _uid => _auth.currentUser!.uid;

  static String chatIdFor(String otherUserId) {
    final sorted = [_uid, otherUserId]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  static Stream<List<Map<String, dynamic>>> messagesStream({required String otherUserId}) {
    final chatId = chatIdFor(otherUserId);
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => {
                    'id': d.id,
                    ...d.data(),
                  })
              .toList(),
        );
  }

  static Stream<List<Map<String, dynamic>>> chatPreviewsStream() {
    return _db
        .collection('chats')
        .where('users', arrayContains: _uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => {
                    'id': d.id,
                    ...d.data(),
                  })
              .toList(),
        );
  }

  static Future<({bool ok, String? error})> sendMessage({
    required String otherUserId,
    required String text,
  }) async {
    final callable = _fn.httpsCallable('sendChatMessage');
    try {
      final res = await callable.call(<String, dynamic>{
        'otherUserId': otherUserId,
        'text': text.trim(),
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      return (
        ok: data['ok'] == true,
        error: data['error'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      return (ok: false, error: e.code);
    }
  }

  static Future<Map<String, dynamic>?> fetchChatPreview({required String otherUserId}) async {
    final chatId = chatIdFor(otherUserId);
    final snap = await _db.collection('chats').doc(chatId).get();
    return snap.data();
  }
}
