import 'package:nip01/nip01.dart';
import 'package:nip47/nip47.dart';
import 'package:test/test.dart';

void main() {
  test(
    'adds a connection',
    () async {
      const relayUrl = 'wss://nostr2.daedaluslabs.io';
      final nip01Repository = Nip01RepositoryImpl(
        relayClientsManager: RelayClientsManagerImpl([relayUrl]),
      );
      final nostrKeyPair = KeyPair.generate();
      final nwcWallet = WalletServiceImpl(
        walletKeyPair: nostrKeyPair,
        nip01repository: nip01Repository,
      );

      final connection = await nwcWallet.addConnection(
        relayUrl: relayUrl,
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
