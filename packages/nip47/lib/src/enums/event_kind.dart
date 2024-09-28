enum EventKind {
  info(13194),
  request(23194),
  response(23195);

  final int value;

  const EventKind(this.value);

  factory EventKind.fromValue(int value) {
    return EventKind.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => throw ArgumentError('Invalid event kind value: $value'),
    );
  }
}
