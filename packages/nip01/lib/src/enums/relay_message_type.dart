enum RelayMessageType {
  event('EVENT'), // used to send events requested by clients
  ok('OK'), // used to indicate acceptance or denial of an EVENT message
  eose(
      'EOSE'), // used to indicate the end of stored events and the beginning of events newly received in real-time
  closed(
      'CLOSED'), // used to indicate that a subscription was ended on the server side
  notice(
      'NOTICE'); // used to send human-readable error messages or other things to clients

  final String value;

  const RelayMessageType(this.value);

  factory RelayMessageType.fromValue(String value) {
    return RelayMessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () =>
          throw ArgumentError('Invalid relay message type value: $value'),
    );
  }
}
