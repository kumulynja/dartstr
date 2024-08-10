class Constants {
  // Nostr client message type constants
  static const String clientMessageEventType = 'EVENT';
  static const String clientMessageRequestType = 'REQ';
  static const String clientMessageCloseType = 'CLOSE';

  // Nostr event kind constants
  static const int userMetadataEventKind = 0;
  static const int textNoteEventKind = 1;

  // Nostr relay message type constants
  static const String relayMessageEventType = 'EVENT';
  static const String relayMessageOkType = 'OK';
  static const String relayMessageEoseType = 'EOSE';
  static const String relayMessageClosedType = 'CLOSED';
  static const String relayMessageNoticeType = 'NOTICE';
}
