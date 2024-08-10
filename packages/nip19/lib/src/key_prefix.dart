import 'package:nip19/src/constants.dart';

enum KeyPrefix {
  nsec(Constants.nsecPrefix),
  npub(Constants.npubPrefix);

  final String value;

  const KeyPrefix(this.value);

  factory KeyPrefix.fromValue(String value) {
    switch (value) {
      case Constants.nsecPrefix:
        return KeyPrefix.nsec;
      case Constants.npubPrefix:
        return KeyPrefix.npub;
      default:
        throw ArgumentError('Invalid key prefix value: $value');
    }
  }
}
