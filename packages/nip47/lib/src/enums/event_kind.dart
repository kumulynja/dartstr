import 'package:nip47/src/constants.dart';

enum EventKind {
  info(Constants.infoEventKind),
  request(Constants.requestEventKind),
  response(Constants.responseEventKind);

  final int value;

  const EventKind(this.value);

  factory EventKind.fromValue(int value) {
    switch (value) {
      case Constants.infoEventKind:
        return EventKind.info;
      case Constants.requestEventKind:
        return EventKind.request;
      case Constants.responseEventKind:
        return EventKind.response;
      default:
        throw ArgumentError('Invalid event kind value: $value');
    }
  }
}
