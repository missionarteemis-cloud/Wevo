import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get currentUid => _auth.currentUser!.uid;
  static String get _uid => _auth.currentUser!.uid;

  static String chatIdFor(String otherUserId) {
    final sorted = [_uid, otherUserId]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  static Future<void> ensureChat({required String otherUserId}) async {
    final chatId = chatIdFor(otherUserId);
    final chatRef = _db.collection('chats').doc(chatId);
    final snap = await chatRef.get();
    if (snap.exists) return;

    await chatRef.set({
      'users': [_uid, otherUserId],
      'matchId': chatId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageAt': null,
      'lastSenderId': null,
    });
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

  static Future<void> sendMessage({
    required String otherUserId,
    required String text,
  }) async {
    final chatId = chatIdFor(otherUserId);
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    await ensureChat(otherUserId: otherUserId);

    await _db.runTransaction((tx) async {
      tx.set(msgRef, {
        'senderId': _uid,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        chatRef,
        {
          'users': [_uid, otherUserId],
          'matchId': chatId,
          'lastMessage': text.trim(),
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastSenderId': _uid,
        },
        SetOptions(merge: true),
      );
    });
  }

  static Future<Map<String, dynamic>?> fetchChatPreview({required String otherUserId}) async {
    final chatId = chatIdFor(otherUserId);
    final snap = await _db.collection('chats').doc(chatId).get();
    return snap.data();
  }
}
