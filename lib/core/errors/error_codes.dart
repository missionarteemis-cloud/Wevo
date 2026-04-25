enum WevoErrorCode {
  // ── Auth ──────────────────────────────────────
  authEmailAlreadyInUse,
  authInvalidEmail,
  authWeakPassword,
  authUserNotFound,
  authWrongPassword,
  authInvalidCredential,
  authOperationNotAllowed,
  authTooManyRequests,
  authNetworkFailed,

  // ── Auth aggiuntivi ───────────────────────────
  authUsernameNotFound,

  // ── Validazione form ─────────────────────────
  validationNameEmpty,
  validationAgeTooYoung,
  validationAgeInvalid,
  validationEmailEmpty,
  validationPasswordTooShort,
  validationBioTooLong,

  // ── Firestore / Database ──────────────────────
  dbReadFailed,
  dbWriteFailed,
  dbUserNotFound,
  dbPermissionDenied,

  // ── Chiamate REST / API esterne ───────────────
  apiTimeout,
  apiUnauthorized,
  apiNotFound,
  apiServerError,
  apiUnknown,

  // ── Generico ─────────────────────────────────
  unknown,
}
