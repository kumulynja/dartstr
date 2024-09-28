import 'package:nip01/nip01.dart';
import 'package:nip47/nip47.dart';
import 'package:nip47/src/enums/method.dart';
import 'package:test/test.dart';

void main() {
  test(
    'adds a connection',
    () async {
      const relayUrl = 'wss://nostr2.daedaluslabs.io';
      final nostrKeyPair = KeyPair.generate();
      final nwcWallet = Wallet(
        relayUrl: relayUrl,
        walletKeyPair: nostrKeyPair,
      );

      final connection = await nwcWallet.addConnection(
        permittedMethods: [
          Method.getInfo,
          Method.getBalance,
          Method.makeInvoice,
          Method.lookupInvoice,
        ],
      );

      expect(
        connection.uri,
        startsWith('nostr+walletconnect://${nostrKeyPair.publicKey}?secret='),
      );
      expect(connection.uri, endsWith('&relay=$relayUrl'));
    },
  );
}
