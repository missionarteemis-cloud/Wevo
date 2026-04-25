import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_error.dart';
import '../core/errors/error_codes.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db   = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<AppError?> register({
    required String email,
    required String password,
    required String name,
    required int age,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid'       : cred.user!.uid,
        'name'      : name,
        'age'       : age,
        'email'     : email,
        'bio'       : '',
        'interests' : [],
        'photoUrl'  : '',
        'coverUrl'  : '',
        'discordTag': null,
        'hasNetflix': false,
        'createdAt' : FieldValue.serverTimestamp(),
        'likedBy'   : [],
        'matches'   : [],
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return AppError.fromFirebaseAuth(e.code);
    } catch (e) {
      return AppError.fromFirestore(e);
    }
  }

  static Future<AppError?> login({
    required String emailOrName,
    required String password,
  }) async {
    try {
      String email = emailOrName.trim();

      // Se non contiene @ lo trattiamo come nome utente
      if (!email.contains('@')) {
        final query = await _db
            .collection('users')
            .where('name', isEqualTo: email)
            .limit(1)
            .get();
        if (query.docs.isEmpty) {
          return AppError.validation(WevoErrorCode.authUsernameNotFound);
        }
        email = query.docs.first.data()['email'] as String;
      }

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return AppError.fromFirebaseAuth(e.code);
    } catch (e) {
      return AppError.unknown(e);
    }
  }

  static Future<void> logout() => _auth.signOut();

  // Validazione locale prima di chiamare Firebase
  static AppError? validateRegistration({
    required String name,
    required String ageText,
    required String email,
    required String password,
  }) {
    if (name.trim().isEmpty) return AppError.validation(WevoErrorCode.validationNameEmpty);
    final age = int.tryParse(ageText.trim());
    if (age == null) return AppError.validation(WevoErrorCode.validationAgeInvalid);
    if (age < 18)    return AppError.validation(WevoErrorCode.validationAgeTooYoung);
    if (email.trim().isEmpty) return AppError.validation(WevoErrorCode.validationEmailEmpty);
    if (password.length < 6)  return AppError.validation(WevoErrorCode.validationPasswordTooShort);
    return null;
  }
}
