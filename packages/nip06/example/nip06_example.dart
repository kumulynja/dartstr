import 'package:nip06/nip06.dart';

void main() {
  final keyPair = KeyPair.generate();
  print('Private key: ${keyPair.privateKey}');

  final keyPairFromMnemonic = KeyPair.fromMnemonic(
    'abandon '
    'abandon '
    'abandon '
    'abandon '
    'abandon '
    'abandon '
    'abandon '
    'abandon '
    'abandon '
    'abandon '
    'abandon '
    'about',
  );
  print('Private key: ${keyPairFromMnemonic.privateKey}');
}
