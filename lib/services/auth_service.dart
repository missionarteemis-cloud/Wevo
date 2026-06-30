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
    required String username,
    required int age,
  }) async {
    try {
      final normalizedUsername = _normalizeUsername(username);
      final exists = await _usernameExists(normalizedUsername);
      if (exists) {
        return AppError.validation(WevoErrorCode.authUsernameAlreadyInUse);
      }

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid'          : cred.user!.uid,
        'name'         : name,
        'username'     : normalizedUsername,
        'age'          : age,
        'email'        : email,
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
      });
      // Mappa username pubblica: unicità + risoluzione login pre-auth.
      await _db.collection('usernames').doc(normalizedUsername).set({
        'uid'  : cred.user!.uid,
        'email': email,
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

      if (!email.contains('@')) {
        final normalizedUsername = _normalizeUsername(email);
        // Risoluzione username->email via mappa pubblica (funziona pre-auth).
        final unameDoc =
            await _db.collection('usernames').doc(normalizedUsername).get();
        final resolved = unameDoc.data()?['email'];
        if (resolved is String && resolved.isNotEmpty) {
          email = resolved;
        } else {
          return AppError.validation(WevoErrorCode.authUsernameNotFound);
        }
      }

      await _auth.setPersistence(Persistence.LOCAL);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return AppError.fromFirebaseAuth(e.code);
    } catch (e) {
      return AppError.unknown(e);
    }
  }

  static Future<AppError?> ensureDevAccount() async {
    const email = 'demo@wevo.app';
    const password = 'wevo1234';
    const username = 'wevo_demo';

    try {
      final loginError = await login(emailOrName: email, password: password);
      if (loginError == null) return null;

      if (loginError.code == WevoErrorCode.authUserNotFound ||
          loginError.code == WevoErrorCode.authInvalidCredential) {
        final registerError = await register(
          email: email,
          password: password,
          name: 'Wevo Demo',
          username: username,
          age: 24,
        );
        if (registerError != null &&
            registerError.code != WevoErrorCode.authEmailAlreadyInUse) {
          return registerError;
        }
        return await login(emailOrName: email, password: password);
      }

      return loginError;
    } catch (e) {
      return AppError.unknown(e);
    }
  }

  static Future<void> logout() => _auth.signOut();

  /// Invia l'email di reset password (Firebase built-in).
  static Future<AppError?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return AppError.fromFirebaseAuth(e.code);
    } catch (e) {
      return AppError.unknown(e);
    }
  }

  // Validazione locale prima di chiamare Firebase
  static AppError? validateRegistration({
    required String name,
    required String username,
    required String ageText,
    required String email,
    required String password,
  }) {
    if (name.trim().isEmpty) return AppError.validation(WevoErrorCode.validationNameEmpty);
    if (username.trim().isEmpty) return AppError.validation(WevoErrorCode.validationUsernameEmpty);
    if (_normalizeUsername(username).length < 3) {
      return AppError.validation(WevoErrorCode.validationUsernameTooShort);
    }
    final age = int.tryParse(ageText.trim());
    if (age == null) return AppError.validation(WevoErrorCode.validationAgeInvalid);
    if (age < 18)    return AppError.validation(WevoErrorCode.validationAgeTooYoung);
    if (email.trim().isEmpty) return AppError.validation(WevoErrorCode.validationEmailEmpty);
    if (password.length < 6)  return AppError.validation(WevoErrorCode.validationPasswordTooShort);
    return null;
  }

  /// Validazione per-campo: ritorna { campo: messaggio } per ogni errore.
  /// Vuoto = tutto valido. Campi: name, username, age, email, password.
  static Map<String, String> validateRegistrationFields({
    required String name,
    required String username,
    required String ageText,
    required String email,
    required String password,
  }) {
    final errors = <String, String>{};
    if (name.trim().isEmpty) errors['name'] = 'Inserisci il tuo nome';

    if (username.trim().isEmpty) {
      errors['username'] = 'Scegli uno username';
    } else if (_normalizeUsername(username).length < 3) {
      errors['username'] = 'Almeno 3 caratteri';
    }

    final age = int.tryParse(ageText.trim());
    if (age == null) {
      errors['age'] = 'Età non valida';
    } else if (age < 18) {
      errors['age'] = 'Devi avere almeno 18 anni';
    } else if (age > 120) {
      errors['age'] = 'Età non valida';
    }

    final em = email.trim();
    if (em.isEmpty) {
      errors['email'] = "Inserisci un'email";
    } else if (!RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w\-.]+$').hasMatch(em)) {
      errors['email'] = "Inserisci un'email valida";
    }

    if (password.length < 6) errors['password'] = 'Almeno 6 caratteri';
    return errors;
  }

  static String _normalizeUsername(String input) =>
      input.trim().toLowerCase().replaceAll(' ', '_');

  static Future<bool> _usernameExists(String username) async {
    // Lettura della mappa pubblica usernames/{username} (funziona pre-auth).
    final doc = await _db.collection('usernames').doc(username).get();
    return doc.exists;
  }
}
