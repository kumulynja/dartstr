enum EventKind {
  userMetadata(0),
  textNote(1);

  final int value;

  const EventKind(this.value);

  factory EventKind.fromValue(int value) {
    return EventKind.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => throw ArgumentError('Invalid event kind value: $value'),
    );
  }
}
