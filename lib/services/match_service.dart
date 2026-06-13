import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class MatchService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;

  static Future<bool> swipeUser({
    required String targetUserId,
    required bool liked,
  }) async {
    final myRef = _db.collection('users').doc(_uid);
    final targetRef = _db.collection('users').doc(targetUserId);
    final swipeRef = _db.collection('swipes').doc('${_uid}_$targetUserId');
    final reverseSwipeRef = _db.collection('swipes').doc('${targetUserId}_$_uid');
    final matchId = _pairId(_uid, targetUserId);
    final matchRef = _db.collection('matches').doc(matchId);

    return _db.runTransaction((tx) async {
      tx.set(swipeRef, {
        'from': _uid,
        'to': targetUserId,
        'liked': liked,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!liked) return false;

      final reverseSnap = await tx.get(reverseSwipeRef);
      final reverseLiked = reverseSnap.data()?['liked'] == true;
      if (!reverseLiked) return false;

      await _materializeMatchInTransaction(
        tx: tx,
        myRef: myRef,
        targetRef: targetRef,
        matchRef: matchRef,
        targetUserId: targetUserId,
      );
      return true;
    });
  }

  static Future<bool> ensureMatchIfReciprocal({required String targetUserId}) async {
    final myRef = _db.collection('users').doc(_uid);
    final targetRef = _db.collection('users').doc(targetUserId);
    final reverseSwipeRef = _db.collection('swipes').doc('${targetUserId}_$_uid');
    final mySwipeRef = _db.collection('swipes').doc('${_uid}_$targetUserId');
    final matchId = _pairId(_uid, targetUserId);
    final matchRef = _db.collection('matches').doc(matchId);

    return _db.runTransaction((tx) async {
      final mySwipe = await tx.get(mySwipeRef);
      final reverseSwipe = await tx.get(reverseSwipeRef);
      final mineLiked = mySwipe.data()?['liked'] == true;
      final reverseLiked = reverseSwipe.data()?['liked'] == true;
      if (!mineLiked || !reverseLiked) return false;

      await _materializeMatchInTransaction(
        tx: tx,
        myRef: myRef,
        targetRef: targetRef,
        matchRef: matchRef,
        targetUserId: targetUserId,
      );
      return true;
    });
  }

  static Future<bool> alreadyMatchedWith(String targetUserId) async {
    try {
      final me = await _db.collection('users').doc(_uid).get().timeout(const Duration(seconds: 12));
      final matchIds = List<String>.from(me.data()?['matches'] ?? []);
      return matchIds.contains(targetUserId);
    } catch (_) {
      return false;
    }
  }

  static Future<List<UserModel>> fetchMatchUsers() async {
    try {
      final me = await _db.collection('users').doc(_uid).get().timeout(const Duration(seconds: 12));
      final matchIds = List<String>.from(me.data()?['matches'] ?? []);
      if (matchIds.isEmpty) return [];

      final futures = matchIds.map(
        (id) => _db.collection('users').doc(id).get().timeout(const Duration(seconds: 12)),
      );
      final docs = await Future.wait(futures);
      return docs
          .where((d) => d.exists && d.data() != null)
          .map((d) => UserModel.fromFirestore(d.data()!, d.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<UserModel>> fetchDiscoverFeed() async {
    try {
      final usersSnap = await _db.collection('users').limit(50).get().timeout(const Duration(seconds: 12));
      final swipesSnap = await _db
          .collection('swipes')
          .where('from', isEqualTo: _uid)
          .get()
          .timeout(const Duration(seconds: 12));

      final swipedIds = swipesSnap.docs.map((d) => d.data()['to'] as String).toSet();

      return usersSnap.docs
          .where((d) => d.id != _uid && !swipedIds.contains(d.id))
          .map((d) => UserModel.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _materializeMatchInTransaction({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> myRef,
    required DocumentReference<Map<String, dynamic>> targetRef,
    required DocumentReference<Map<String, dynamic>> matchRef,
    required String targetUserId,
  }) async {
    final matchSnap = await tx.get(matchRef);
    if (!matchSnap.exists) {
      tx.set(matchRef, {
        'users': [_uid, targetUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageAt': null,
        'lastSenderId': null,
      });
    }
    tx.set(myRef, {'matches': FieldValue.arrayUnion([targetUserId])}, SetOptions(merge: true));
    tx.set(targetRef, {'matches': FieldValue.arrayUnion([_uid])}, SetOptions(merge: true));
  }

  static String _pairId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
