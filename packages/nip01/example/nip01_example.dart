import 'package:nip01/nip01.dart';

void main() {
  final keyPair = KeyPair.generate();
  print('privateKey: ${keyPair.privateKey}');
}
