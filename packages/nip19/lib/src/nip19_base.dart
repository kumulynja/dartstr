import 'package:nip01/nip01.dart' as nip01;
import 'package:nip19/src/nip19_internal.dart';

/// Extends the nip01 [KeyPair] class to add key derivation from an nsec as described in NIP-19.
class KeyPair extends nip01.KeyPair {
  static String npubFromPublicKey(String publicKey) {
    return Nip19.npubFromHex(publicKey);
  }

  static String npubToPublicKey(String npub) {
    return Nip19.npubToHex(npub);
  }

  KeyPair({required super.privateKey});

  factory KeyPair.generate() {
    final keyPair = nip01.KeyPair.generate();
    return KeyPair(privateKey: keyPair.privateKey);
  }

  factory KeyPair.fromNsec(String nsec) {
    final privateKey = Nip19.nsecToHex(nsec);
    return KeyPair(privateKey: privateKey);
  }

  String get nsec => Nip19.nsecFromHex(privateKey);
  String get npub => Nip19.npubFromHex(publicKey);
}
