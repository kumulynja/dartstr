import 'package:nip19/nip19.dart';

void main() {
  final keyPair = KeyPair.generate();
  print('nsec: ${keyPair.nsec}');

  final keyPairFromNsec = KeyPair.fromNsec(keyPair.nsec);
  print('privateKey: ${keyPairFromNsec.privateKey}');

  final npubFromPublicKey = KeyPair.npubFromPublicKey(keyPair.publicKey);
  print('npub: $npubFromPublicKey');

  final npubToPublicKey = KeyPair.npubToPublicKey(npubFromPublicKey);
  print('publicKey: $npubToPublicKey');
}
