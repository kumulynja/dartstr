enum KeyPrefix {
  nsec('nsec'),
  npub('npub');

  final String value;

  const KeyPrefix(this.value);

  factory KeyPrefix.fromValue(String value) {
    return KeyPrefix.values.firstWhere(
      (prefix) => prefix.value == value,
      orElse: () => throw ArgumentError('Invalid key prefix value: $value'),
    );
  }
}
