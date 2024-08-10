import 'package:nip01/src/constants.dart';

enum RelayMessageType {
  event(
    Constants.relayMessageEventType,
  ), // used to send events requested by clients
  ok(
    Constants.relayMessageOkType,
  ), // used to indicate acceptance or denial of an EVENT message
  eose(
    Constants.relayMessageEoseType,
  ), // used to indicate the end of stored events and the beginning of events newly received in real-time
  closed(
    Constants.relayMessageClosedType,
  ), // used to indicate that a subscription was ended on the server side
  notice(
    Constants.relayMessageNoticeType,
  ); // used to send human-readable error messages or other things to clients

  final String value;

  const RelayMessageType(this.value);

  factory RelayMessageType.fromValue(String value) {
    switch (value) {
      case Constants.relayMessageEventType:
        return RelayMessageType.event;
      case Constants.relayMessageOkType:
        return RelayMessageType.ok;
      case Constants.relayMessageEoseType:
        return RelayMessageType.eose;
      case Constants.relayMessageClosedType:
        return RelayMessageType.closed;
      case Constants.relayMessageNoticeType:
        return RelayMessageType.notice;
      default:
        throw ArgumentError('Invalid relay message type value: $value');
    }
  }
}
