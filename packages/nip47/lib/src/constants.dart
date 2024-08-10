class Constants {
  static const String uriProtocol = 'nostr+walletconnect';

  // Event kind constants
  static const int infoEventKind = 13194;
  static const int requestEventKind = 23194;
  static const int responseEventKind = 23195;

  // Nwc method constants
  static const String payInvoiceMethod = 'pay_invoice';
  static const String multiPayInvoiceMethod = 'multi_pay_invoice';
  static const String payKeysendMethod = 'pay_keysend';
  static const String multiPayKeysendMethod = 'multi_pay_keysend';
  static const String makeInvoiceMethod = 'make_invoice';
  static const String lookupInvoiceMethod = 'lookup_invoice';
  static const String listTransactionsMethod = 'list_transactions';
  static const String getBalanceMethod = 'get_balance';
  static const String getInfoMethod = 'get_info';
  static const String unknownMethod = 'unknown';

  // NWC error code constants
  static const String rateLimitedErrorCode = 'RATE_LIMITED';
  static const String notImplementedErrorCode = 'NOT_IMPLEMENTED';
  static const String insufficientBalanceErrorCode = 'INSUFFICIENT_BALANCE';
  static const String paymentFailedErrorCode = 'PAYMENT_FAILED';
  static const String notFoundErrorCode = 'NOT_FOUND';
  static const String quotaExceededErrorCode = 'QUOTA_EXCEEDED';
  static const String restrictedErrorCode = 'RESTRICTED';
  static const String unauthorizedErrorCode = 'UNAUTHORIZED';
  static const String internalErrorCode = 'INTERNAL';
  static const String otherErrorCode = 'OTHER';
}
