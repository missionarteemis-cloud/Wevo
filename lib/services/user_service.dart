import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../core/errors/app_error.dart';
import '../core/errors/error_codes.dart';

class UserService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;

  static Future<UserModel?> fetchCurrentUser() async {
    try {
      final authUser = _auth.currentUser;
      if (authUser == null) return null;

      debugPrint('[UserService] fetch user: ${authUser.uid}');
      final doc = await _db.collection('users').doc(authUser.uid).get()
          .timeout(const Duration(seconds: 15));

      if (!doc.exists || doc.data() == null) {
        debugPrint('[UserService] documento non trovato, lo creo');
        final data = <String, dynamic>{
          'uid'       : authUser.uid,
          'name'      : authUser.displayName ?? authUser.email?.split('@').first ?? 'Utente',
          'age'       : 0,
          'email'     : authUser.email ?? '',
          'bio'       : '',
          'interests' : [],
          'photoUrl'  : '',
          'coverUrl'  : '',
          'discordTag': null,
          'hasNetflix': false,
          'createdAt' : FieldValue.serverTimestamp(),
          'likedBy'   : [],
          'matches'   : [],
        };
        await _db.collection('users').doc(authUser.uid).set(data)
            .timeout(const Duration(seconds: 15));
        return UserModel.fromFirestore(data, authUser.uid);
      }

      debugPrint('[UserService] fetch ok: ${doc.data()!['name']}');
      return UserModel.fromFirestore(doc.data()!, doc.id);
    } on TimeoutException {
      debugPrint('[UserService] TIMEOUT su fetchCurrentUser');
      return null;
    } catch (e) {
      debugPrint('[UserService] errore fetchCurrentUser: $e');
      return null;
    }
  }

  static Future<UserModel?> fetchUserById(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get()
          .timeout(const Duration(seconds: 15));
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('[UserService] errore fetchUserById: $e');
      return null;
    }
  }

  static Future<AppError?> updateProfile({
    required String bio,
    required List<String> interests,
    required int age,
    String? photoUrl,
    String? coverUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'bio'      : bio.trim(),
        'interests': interests,
        'age'      : age,
      };
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (coverUrl  != null) updates['coverUrl']  = coverUrl;

      debugPrint('[UserService] updateProfile: $updates');
      await _db.collection('users').doc(_uid).update(updates)
          .timeout(const Duration(seconds: 15));
      debugPrint('[UserService] updateProfile ok');
      return null;
    } on TimeoutException {
      debugPrint('[UserService] TIMEOUT su updateProfile');
      return AppError(
        code: WevoErrorCode.dbWriteFailed,
        message: 'Connessione lenta. Controlla internet e riprova.',
      );
    } catch (e) {
      debugPrint('[UserService] errore updateProfile: $e');
      return AppError.fromFirestore(e);
    }
  }

  static Future<List<UserModel>> fetchDiscoverUsers() async {
    try {
      final snapshot = await _db.collection('users').limit(50).get()
          .timeout(const Duration(seconds: 15));
      return snapshot.docs
          .where((doc) => doc.id != _uid)
          .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[UserService] errore fetchDiscoverUsers: $e');
      return [];
    }
  }
}
