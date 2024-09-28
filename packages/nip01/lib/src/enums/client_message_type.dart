enum ClientMessageType {
  event('EVENT'), // used to publish events
  req('REQ'), // used to request events and subscribe to new updates
  close('CLOSE'); // used to stop a subscription

  final String value;

  const ClientMessageType(this.value);

  factory ClientMessageType.fromValue(String value) {
    return ClientMessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () =>
          throw ArgumentError('Invalid client message type value: $value'),
    );
  }
}
