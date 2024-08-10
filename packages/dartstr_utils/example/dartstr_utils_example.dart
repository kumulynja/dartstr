import 'package:dartstr_utils/dartstr_utils.dart';

void main() {
  final secretBytes = SecretGenerator.secretBytes(32);
  print('secretBytes: $secretBytes');
  final secretHex = SecretGenerator.secretHex(64);
  print('secretHex: $secretHex');
}
