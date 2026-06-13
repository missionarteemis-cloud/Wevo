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
        final fallbackName = authUser.displayName ?? authUser.email?.split('@').first ?? 'Utente';
        final data = <String, dynamic>{
          'uid'          : authUser.uid,
          'name'         : fallbackName,
          'username'     : fallbackName.toLowerCase().replaceAll(' ', '_'),
          'age'          : 0,
          'email'        : authUser.email ?? '',
          'bio'          : '',
          'interests'    : [],
          'favoriteGames': [],
          'platforms'    : [],
          'lookingFor'   : [],
          'photoUrl'     : '',
          'coverUrl'     : '',
          'discordTag'   : null,
          'steamId'      : null,
          'spotifyArtist': null,
          'riotId'       : null,
          'timezone'     : 'CET',
          'country'      : 'Italia',
          'createdAt'    : FieldValue.serverTimestamp(),
          'likedBy'      : [],
          'matches'      : [],
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
    required List<String> favoriteGames,
    required List<String> platforms,
    required List<String> lookingFor,
    required int age,
    String? discordTag,
    String? steamId,
    String? spotifyArtist,
    String? riotId,
    String? timezone,
    String? country,
    String? photoUrl,
    String? coverUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'bio'          : bio.trim(),
        'interests'    : interests,
        'favoriteGames': favoriteGames,
        'platforms'    : platforms,
        'lookingFor'   : lookingFor,
        'age'          : age,
        'discordTag'   : _normalize(discordTag),
        'steamId'      : _normalize(steamId),
        'spotifyArtist': _normalize(spotifyArtist),
        'riotId'       : _normalize(riotId),
        'timezone'     : timezone?.trim().isNotEmpty == true ? timezone!.trim() : 'CET',
        'country'      : country?.trim().isNotEmpty == true ? country!.trim() : 'Italia',
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


String? _normalize(String? value) {
  if (value == null) return null;
  final v = value.trim();
  return v.isEmpty ? null : v;
}
