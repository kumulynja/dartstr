import 'package:nip01/src/constants.dart';

enum ClientMessageType {
  event(Constants.clientMessageEventType), // used to publish events
  req(Constants
      .clientMessageRequestType), // used to request events and subscribe to new updates
  close(Constants.clientMessageCloseType); // used to stop a subscription

  final String value;

  const ClientMessageType(this.value);

  factory ClientMessageType.fromValue(String value) {
    switch (value) {
      case Constants.clientMessageEventType:
        return ClientMessageType.event;
      case Constants.clientMessageRequestType:
        return ClientMessageType.req;
      case Constants.clientMessageCloseType:
        return ClientMessageType.close;
      default:
        throw ArgumentError('Invalid client message type value: $value');
    }
  }
}
