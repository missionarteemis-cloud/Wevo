import 'error_codes.dart';

class AppError {
  final WevoErrorCode code;
  final String message;
  final String? technical; // messaggio tecnico per debug (non mostrato all'utente)

  const AppError({
    required this.code,
    required this.message,
    this.technical,
  });

  // ── Costruttori da sorgenti esterne ───────────

  factory AppError.fromFirebaseAuth(String firebaseCode) {
    final code = _firebaseAuthMap[firebaseCode] ?? WevoErrorCode.unknown;
    return AppError(code: code, message: _messages[code]!, technical: firebaseCode);
  }

  factory AppError.fromFirestore(Object e) {
    return AppError(
      code: WevoErrorCode.dbWriteFailed,
      message: _messages[WevoErrorCode.dbWriteFailed]!,
      technical: e.toString(),
    );
  }

  factory AppError.fromApiStatus(int statusCode) {
    final code = switch (statusCode) {
      401 => WevoErrorCode.apiUnauthorized,
      404 => WevoErrorCode.apiNotFound,
      >= 500 => WevoErrorCode.apiServerError,
      _ => WevoErrorCode.apiUnknown,
    };
    return AppError(code: code, message: _messages[code]!, technical: 'HTTP $statusCode');
  }

  factory AppError.validation(WevoErrorCode code) {
    return AppError(code: code, message: _messages[code] ?? _messages[WevoErrorCode.unknown]!);
  }

  factory AppError.unknown([Object? e]) {
    return AppError(
      code: WevoErrorCode.unknown,
      message: _messages[WevoErrorCode.unknown]!,
      technical: e?.toString(),
    );
  }

  @override
  String toString() => 'AppError(${code.name}): $message';
}

// ── Mappa Firebase Auth code → WevoErrorCode ──────────────────────────────────
const _firebaseAuthMap = <String, WevoErrorCode>{
  'email-already-in-use'  : WevoErrorCode.authEmailAlreadyInUse,
  'invalid-email'         : WevoErrorCode.authInvalidEmail,
  'weak-password'         : WevoErrorCode.authWeakPassword,
  'user-not-found'        : WevoErrorCode.authUserNotFound,
  'wrong-password'        : WevoErrorCode.authWrongPassword,
  'invalid-credential'    : WevoErrorCode.authInvalidCredential,
  'operation-not-allowed' : WevoErrorCode.authOperationNotAllowed,
  'too-many-requests'     : WevoErrorCode.authTooManyRequests,
  'network-request-failed': WevoErrorCode.authNetworkFailed,
};

// ── Messaggi utente per ogni codice ───────────────────────────────────────────
const _messages = <WevoErrorCode, String>{
  // Auth
  WevoErrorCode.authEmailAlreadyInUse  : 'Questa email è già registrata.',
  WevoErrorCode.authInvalidEmail       : 'Email non valida.',
  WevoErrorCode.authWeakPassword       : 'Password troppo corta (minimo 6 caratteri).',
  WevoErrorCode.authUserNotFound       : 'Nessun account trovato con questa email.',
  WevoErrorCode.authWrongPassword      : 'Password errata.',
  WevoErrorCode.authInvalidCredential  : 'Email o password non corretti.',
  WevoErrorCode.authOperationNotAllowed: 'Registrazione non abilitata. Contatta il supporto.',
  WevoErrorCode.authTooManyRequests    : 'Troppi tentativi. Riprova tra qualche minuto.',
  WevoErrorCode.authNetworkFailed      : 'Connessione assente. Controlla internet.',
  WevoErrorCode.authUsernameNotFound   : 'Nessun account trovato con questo nome.',

  // Validazione
  WevoErrorCode.validationNameEmpty      : 'Inserisci il tuo nome.',
  WevoErrorCode.validationAgeTooYoung    : 'Devi avere almeno 18 anni per usare Wevo.',
  WevoErrorCode.validationAgeInvalid     : 'Inserisci un\'età valida.',
  WevoErrorCode.validationEmailEmpty     : 'Inserisci un\'email.',
  WevoErrorCode.validationPasswordTooShort: 'La password deve essere di almeno 6 caratteri.',
  WevoErrorCode.validationBioTooLong     : 'La bio non può superare i 300 caratteri.',

  // Database
  WevoErrorCode.dbReadFailed      : 'Impossibile caricare i dati. Riprova.',
  WevoErrorCode.dbWriteFailed     : 'Impossibile salvare i dati. Riprova.',
  WevoErrorCode.dbUserNotFound    : 'Profilo non trovato.',
  WevoErrorCode.dbPermissionDenied: 'Accesso negato.',

  // API REST
  WevoErrorCode.apiTimeout    : 'Il server non risponde. Riprova tra poco.',
  WevoErrorCode.apiUnauthorized: 'Sessione scaduta. Accedi di nuovo.',
  WevoErrorCode.apiNotFound   : 'Risorsa non trovata.',
  WevoErrorCode.apiServerError: 'Errore del server. Riprova più tardi.',
  WevoErrorCode.apiUnknown    : 'Errore di comunicazione. Riprova.',

  // Generico
  WevoErrorCode.unknown: 'Qualcosa è andato storto. Riprova.',
};
