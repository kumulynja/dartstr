import 'package:nip01/src/constants.dart';

enum EventKind {
  userMetadata(Constants.userMetadataEventKind),
  textNote(Constants.textNoteEventKind);

  final int value;

  const EventKind(this.value);

  factory EventKind.fromValue(int value) {
    switch (value) {
      case Constants.userMetadataEventKind:
        return EventKind.userMetadata;
      case Constants.textNoteEventKind:
        return EventKind.textNote;
      default:
        throw ArgumentError('Invalid event kind value: $value');
    }
  }
}
