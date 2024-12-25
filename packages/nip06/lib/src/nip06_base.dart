import 'package:nip01/nip01.dart' as nip01;
import 'package:nip06/src/nip06_internal.dart';

// Put public facing types in this file.

/// Extends the nip01 [KeyPair] class to add key derivation from a mnemonic seed phrase as described in NIP-06.
class KeyPair extends nip01.KeyPair {
  KeyPair({required super.privateKey});

  factory KeyPair.generate() {
    final keyPair = nip01.KeyPair.generate();
    return KeyPair(privateKey: keyPair.privateKey);
  }

  factory KeyPair.fromMnemonic(
    String mnemonic, {
    int accountIndex = 0,
    String passphrase = '',
  }) {
    final privateKey = Nip06.mnemonicToPrivateKey(
      mnemonic,
      accountIndex: accountIndex,
      passphrase: passphrase,
    );
    return KeyPair(privateKey: privateKey);
  }
}
