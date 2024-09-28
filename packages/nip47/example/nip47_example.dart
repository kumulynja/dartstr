import 'package:nip01/nip01.dart';
import 'package:nip47/nip47.dart';
import 'package:nip47/src/enums/bitcoin_network.dart';
import 'package:nip47/src/enums/method.dart';

Future<void> main() async {
  final nostrKeyPair = KeyPair.generate();
  final nwcWallet = Wallet(
    relayUrl: 'wss://nostr2.daedaluslabs.io',
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

  print('Connection URI: ${connection.uri}');

  // Listen for nwc requests
  final sub = nwcWallet.nwcRequests.listen((request) {
    print('Request: $request');
    switch (request.method) {
      case Method.getInfo:
        nwcWallet.getInfoRequestHandled(
          request as GetInfoRequest,
          alias: 'kumulynja',
          color: '#FF9900',
          pubkey: nostrKeyPair.publicKey,
          network: BitcoinNetwork.signet,
          blockHeight: 1220149,
          blockHash:
              '00000237e2ad85bbbe9db8d20ce44054f25b05a56318e30d8f4e1791b228157c',
          methods: [
            Method.getInfo,
            Method.getBalance,
            Method.payInvoice,
            Method.makeInvoice,
            Method.multiPayInvoice,
            Method.payKeysend,
            Method.lookupInvoice,
            Method.listTransactions,
          ],
        );

      case Method.getBalance:
        nwcWallet.getBalanceRequestHandled(request as GetBalanceRequest,
            balanceSat: 987123);
      case Method.makeInvoice:
        const invoice =
            'lntbs750u1pngrch7dq8w3jhxaqpp56sm3029nrfdjg67rr7tcdcpvtnngq5dz90xxf7h5zq6cp0y6vhyssp529ge5rfqtfryp4dn2gr4qg84rejfus653j3cf975fj9wyyhz2a7q9qyysgqcqp6xqrgegrzjqdcadltawh0z6qmj6ql2qr5t4ndvk5xz0582ag98dgrz9ml37hhjkzyuuqqqdugqqvqqqqqqqqqqqqqqfqef3lceuteux4sv0xarvmtw2sck964s4xwn2wx8d4q4k772v8jn3jtfhf9tjhqge5nhesgt6rvxlkkwvn4f8kwmtx0ghjal72nkv8gsqpc4uyvg';
        nwcWallet.makeInvoiceRequestHandled(
          request as MakeInvoiceRequest,
          invoice: invoice,
          paymentHash:
              'd43717a8b31a5b246bc31f9786e02c5ce68051a22bcc64faf4103580bc9a65c9',
          amountSat: 75000,
          feesPaidSat: 0,
          createdAt: 1719788286,
          expiresAt: 1719797286,
          metadata: {},
        );
      case Method.listTransactions:
        nwcWallet.listTransactionsRequestHandled(
            request as ListTransactionsRequest,
            transactions: []);
      case Method.lookupInvoice:
        nwcWallet.lookupInvoiceRequestHandled(
          request as LookupInvoiceRequest,
          invoice:
              'lntbs750u1pngrch7dq8w3jhxaqpp56sm3029nrfdjg67rr7tcdcpvtnngq5dz90xxf7h5zq6cp0y6vhyssp529ge5rfqtfryp4dn2gr4qg84rejfus653j3cf975fj9wyyhz2a7q9qyysgqcqp6xqrgegrzjqdcadltawh0z6qmj6ql2qr5t4ndvk5xz0582ag98dgrz9ml37hhjkzyuuqqqdugqqvqqqqqqqqqqqqqqfqef3lceuteux4sv0xarvmtw2sck964s4xwn2wx8d4q4k772v8jn3jtfhf9tjhqge5nhesgt6rvxlkkwvn4f8kwmtx0ghjal72nkv8gsqpc4uyvg',
          paymentHash:
              'd43717a8b31a5b246bc31f9786e02c5ce68051a22bcc64faf4103580bc9a65c9',
          preimage:
              '5ad05d1f46124f1a191d634e9a16a60224ce118949d72f8b366fef37de01c662',
          amountSat: 75000,
          feesPaidSat: 0,
          createdAt: 1719788286,
          expiresAt: 1719797286,
          settledAt: 1719788757,
          metadata: {},
        );
      default:
        print('Unpermitted method: ${request.method}');
    }
  });

  sub.cancel();
}
