<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

This package takes care of the [wallet service](https://docs.nwc.dev/bitcoin-lightning-wallets/getting-started) side of the [Nostr Wallet Connect (NWC)](https://docs.nwc.dev/) protocol as described by [NIP-47](https://github.com/nostr-protocol/nips/blob/master/47.md). It is a Flutter package that can be integrated into any Lightning wallet app to let its users connect their wallet to websites, platforms, apps or any NWC-enabled services.

[![NWC Infogram](https://github.com/kumulynja/nwc_wallet/assets/92805150/54bb7ec1-41fa-4bb5-b032-288bff9b77c1)](https://nwc.dev)

## Demo

https://github.com/kumulynja/nwc_wallet/assets/92805150/4bbbbb87-8734-4ffa-ac78-1b01ff8d2c46

## What does this package do for you?

- It lets you generate or restore a Nostr keypair for the wallet
- It takes care of (re)connecting to a Nostr relay and subscribing to events for the wallet
- It lets you create and remove NWC connections to manage connections to websites, platforms, apps or any NWC-enabled services
- It handles and parses Nostr events like relay messages and NIP47 requests
- It decrypts and validates NIP47 requests and puts them in a stream for you to listen to
- The validation of the requests includes checking that it is a valid NIP47 request, that the request is not expired if it contains an expiration tag, that it is coming from a known and active connection and that the requested method is a known method and permitted for that connection. If any of the checks fails, the package handles the response and will not put the request in the stream.
- It provides methods to respond to NIP47 requests after you have handled them with your wallet
- The response methods take care of encrypting and publishing the response to the relay following NIP47

## What does this package NOT do for you?

- It does not persist the wallet service's Nostr keypair or the created NWC connections between app restarts

Since you are building a wallet, you certainly already have your own secure storage mechanism in place to store the user's private keys or mnemonic. That's why we leave the storage of the Nostr keypair to you, and keep the library storage-agnostic. The same goes for the connections. You should persist the connections yourself so they stay alive between app restarts. As an id to store the connection by, you can use its pubkey, which is the public key related to its secret key and the way to identify the connection in the NWC protocol. To make it easier for the user to know which connection is which, you could also let the user set a readable name for the connection and store it as well. The permitted methods should also be persisted with the connection. When the app is restarted, you should pass the stored keypair and the connections to the `Wallet` constructor to continue using the same keypair and connections.

- It does not set or verify any budget limits, auto- or manual approvals or expiry date for the NWC connections

Together with the connection data like the name and permitted methods, you should also save spending limits (budgets) and an expiry date for every connection. You could also let the user configure auto- or manual approval for payment requests. It is your responsability as a wallet builder to validate those settings when handling a request from the stream. The expiry date should be checked when handling any NWC requests and the budget and other limits before making a payment. If the expiry date or any budget limits are reached, you should use the `failedToHandleRequest` function and pass the appropriate error code. In case a connection is expired, also remove the connection with `removeConnection` so no further requests will be put on the stream for this connection anymore.

- It does not store the requests, they are only available in real-time through the stream or by getting stored events from the relay

You should handle the requests in real-time and respond to them as soon as possible. If you can not handle a request, you should use the `failedToHandleRequest` method to inform the website or app that the request could not be handled. You could store the requests yourself if you want, but this is not required. If you want to process any missed events that were send while the app was not running, you can get events since a certain timestamp from the relay.

- This package is not a Lightning wallet itself, it should be used alongside a Lightning wallet

To use this package, your app should already have a Lightning Network node or wallet embedded or have access to a Lightning wallet API so you can handle the NWC requests. You can look at [ldk-node-flutter](https://github.com/LtbLightning/ldk-node-flutter) for a Flutter package that can be used to run a Lightning node on mobile.

## Getting started

### Installation

In your `pubspec.yaml` file add:

```yaml
dependencies:
  nip47: ^0.0.2
```

## Usage

Next, you can follow the steps below to integrate Nostr Wallet Connect into your app:

### 1. Generate or import a Nostr keypair for the wallet service\*

You should persist the private key in your app's secure storage to be able to use the same keypair between app restarts.

Since a Lightning Wallet normally has a mnemonic already that is stored securely, you could also derive a Nostr keypair from the mnemonic following [NIP06](https://github.com/nostr-protocol/nips/blob/master/06.md). This way you can use the same mnemonic for the Lightning wallet and NWC. This is a more secure way, as you don't have to store the private key separately and you can always restore the private key for NWC from the mnemonic. You can use the nip06 package for this.

```dart
import 'package:nip06/nip06.dart';

// Derive a Nostr keypair from a mnemonic
final nostrKeyPair = KeyPair.fromMnemonic('your_mnemonic_here');
```

To derive different keypairs from the same mnemonic, you can use the account index parameter.

```dart
// Derive a Nostr keypair from a mnemonic with an account index
final nostrKeyPair = KeyPair.fromMnemonic(
    'your_mnemonic_here',
    accountIndex: 1,
);
```

\* If your wallet also offers any other Nostr functionality, like a user profile and already has a keypair for that, do NOT use that same keypair for the wallet service for Nostr Wallet Connect, since the apps you connect to will be able to link your payments with your Nostr identity. Every wallet should have its own identity, and thus keypair, independent of the user's Nostr profile. What you can do though, is use the same mnemonic to derive both keypairs from, each with a different account index as shown above. For example the Nostr profile keypair could be derived from the mnemonic with account index 0 and the wallet service keypair with account index 1.

### 2. Initialize a `WalletService` instance

`WalletService` is the main class of this package. It takes care of the NWC protocol for the wallet service side. To initialize a `WalletService` instance, you should provide it the Nostr keypair from the previous step and a nip01 repository which will handle all relay connections.

```dart
import 'package:nip47/nip47.dart';


// Generate a key pair for the wallet
final nostrKeyPair = KeyPair.generate();
// Create a Nip01Repository instance to manage the relay connections
//  it can be empty if you don't want to set any relay until an nwc
//  connection is added. At that point the relay client will be created
//  and managed by the clients manager.
final nip01Repository = Nip01RepositoryImpl(
    relayClientsManager: RelayClientsManagerImpl([]),
);

final nwcWalletService = WalletServiceImpl(
    walletKeyPair: nostrKeyPair,
    nip01repository: nip01Repository,
);
```

### 3. Listen for NWC requests and handle them based on the method type and with the wallet in your app

For every request that comes in through the stream, you should handle it based on the method type and call the appropriate method after the request has been handled through the user's Lightning wallet. This can be done by a simple switch statement based on the method type of the request.

```dart
import 'package:nip47/nip47.dart';

nwcWalletService.requests.listen((request) {
    switch (request.method) {
        case Method.getInfo:
            /* Todo yourself: Get the alias, color, network, blockHeight and blockHash of the Lightning wallet/node */
            nwcWalletService.getInfoRequestHandled(
                request as GetInfoRequest,
                alias: <alias>,
                color: <color>,
                pubkey: nostrKeyPair.publicKey,
                network: <network>,
                blockHeight: <blockHeight>,
                blockHash: <blockHash>,
                // Only keep the methods that the wallet supports and wants to permit for this connection
                methods: [
                    Method.getInfo,
                    Method.getBalance,
                    Method.makeInvoice,
                    Method.lookupInvoice,
                    Method.payInvoice,
                    Method.multiPayInvoice,
                    Method.payKeysend,
                    Method.multiPayKeysend,
                    Method.listTransactions,
                ],
            );
        case Method.getBalance:
            // Todo yourself: get the balance from the wallet/node
            nwcWalletService.getBalanceRequestHandled(
                request as GetBalanceRequest,
                balanceSat: <balance>,
            );
        case Method.makeInvoice:
            // Todo yourself: generate a new invoice with the wallet/node in your app
            nwcWalletService.makeInvoiceRequestHandled(
                request as MakeInvoiceRequest,
                invoice: <invoice>,
                description: <description>,
                descriptionHash: <descriptionHash>,
                preimage: <preimage>,
                paymentHash: <paymentHash>,
                amountSat: <amountSat>,
                feesPaidSat: <feesPaidSat>,
                createdAt: <createdAt>,
                expiresAt: <expiresAt>,
                metadata: <metadata>,
            );
        case Method.lookupInvoice:
            // Todo yourself: lookup the invoice with the wallet/node in your app
            nwcWalletService.lookupInvoiceRequestHandled(
                request as LookupInvoiceRequest,
                invoice: <invoice>,
                description: <description>,
                descriptionHash: <descriptionHash>,
                preimage: <preimage>,
                paymentHash: <paymentHash>,
                amountSat: <amountSat>,
                feesPaidSat: <feesPaidSat>,
                createdAt: <createdAt>,
                expiresAt: <expiresAt>,
                settledAt: <settledAt>,
                metadata: <metadata>,
            );
        case Method.payInvoice:
            // Todo yourself: Check the budget limits and expiry date of the connection before making the payment!!!
            // Todo yourself: Pay the invoice with the wallet/node in your app and get the preimage
            nwcWalletService.payInvoiceRequestHandled(
                request as PayInvoiceRequest,
                preimage: <preimage>
            );
        case Method.multiPayInvoice:
            // Todo yourself: Check the budget limits and expiry date of the connection before making the payments!!!
            // Todo yourself: Pay the invoices with the wallet/node in your app and get the preimages, pass them as a map with the invoice id as key
            nwcWalletService.multiPayInvoiceRequestHandled(
                request as MultiPayInvoiceRequest,
                preimageById: <{preimagesById}>,
            );
        case Method.payKeysend:
            // Todo yourself: Check the budget limits and expiry date of the connection before making the payment!!!
            // Todo yourself: Pay the keysend with the wallet/node in your app and get the preimage
            nwcWalletService.payKeysendRequestHandled(
                request as PayKeysendRequest,
                preimage: <preimage>
            );
        case Method.multiPayKeysend:
            // Todo yourself: Check the budget limits and expiry date of the connection before making the payments!!!
            // Todo yourself: Pay the keysends with the wallet/node in your app and get the preimages, pass them as a map with the keysend id as key
            nwcWalletService.multiPayKeysendRequestHandled(
                request as MultiPayKeysendRequest,
                preimageById: <{preimagesById}>,
            );
        case Method.listTransactions:
            // Todo yourself: Fetch the transactions from the wallet/node in your app
            final transactions = <Transaction>[];
            nwcWalletService.listTransactionsRequestHandled(
                request as ListTransactionsRequest,
                transactions: transactions,
            );
        default:
            // This should never happen as the package only puts known methods on the stream,
            //  but it is better to handle it anyway to prevent any unexpected behavior
            print('Unpermitted method: ${request.method}');
    }

    // (Optionally) Todo yourself: store the timestamp to get missed events since this moment after an app restart
});
```

If a request can not be handled, you should use the `failedToHandleRequest` method to inform the website or app, instead of using the specific request handled method. You could add a try catch block around the request handling to catch any exceptions that are thrown by the wallet/node in your app.

```dart
try {
    // Try paying the invoice with the wallet/node in your app
    final preimage = <preimage>;

    // If no exception is thrown, respond to the payInvoice request with the preimage
    nwcWalletService.payInvoiceRequestHandled(request, preimage: preimage);
} catch(e) {
    // If an exception is thrown, inform the website or app that the request could not be handled
    // instead of the specific request handled method and provide the nwc error code that fits best.
    nwcWalletService.failedToHandleRequest(request, error: Error.paymentFailed);
}
```

### 4. Create and store a new NWC connection

To create a new NWC connection, you can use the `addConnection` method, specifying the relay to use for the connection as well as the methods permitted for this connection:

```dart
import 'package:nip47/nip47.dart';

final connection = await nwcWalletService.addConnection(
    relayUrl: relayUrl,
    permittedMethods: [
        Method.getInfo,
        Method.getBalance,
        Method.makeInvoice,
        Method.lookupInvoice,
    ],
);

println('Connection added with id: ${connection.pubkey} and URI: ${connection.uri}');
```

The `addConnection` method returns the created connection with the pubkey, relayUrl, URI and permitted methods. You should store this connection in your app's secure storage mechanism to use it in the future when the app is restarted.
Also let the user enter a readable name, spending limit(s), approval logic and the expiry date for the connection and store this data as well, so you can validate it when handling requests.
The URI should be shown and copied by the user to enter it in the website, platform, app or any NWC-enabled service they want to connect its wallet to. The URI itself should not necessarily be persisted by your app after the user has copied it.

## Why this package may be what you are looking for

- **Easy to use**: This package is built with simplicity in mind. It provides a small and simple API to support Nostr Wallet Connect in your app, so you can focus on building your wallet and not on Nostr protocol details.
- **Well scoped & flexible**: Only NIP's needed for the wallet side of Nostr Wallet Connect are implemented in this package. Nostr Wallet Connect having a separate keypair for the wallet and a dedicated relay for NWC connections is a good reason to keep it separate from other Nostr functionalities. This makes it lightweight and also easier to maintain and for you to review. You can still add profile, contacts, social media and other Nostr functionalities with other Nostr packages though, they can run independently from this package and vice versa.
- **Lightning node agnostic**: This package does not depend on any specific Lightning node implementation. You can use any Lightning wallet or node that you want to handle the NWC requests. This makes it possible to integrate into any existing wallet app built with Flutter.

## WIP

All basic functionality of the NWC protocol is implemented and working in this package, so you should already be able to use it in your app to make it compatible with NWC apps. But software is never finished, so be aware that following things should still be added or improved upon in future versions:

- [ ] Updating permitted methods of a connection
- [ ] Connection status checks
- [ ] lud16 in connection URI
- [ ] Custom exceptions
- [ ] More tests
- [ ] More documentation
- [ ] Logging

Feel free to open an issue for any suggestions to improve or if you encounter any other problems or limitations that should be addressed.
And if you feel like contributing, pull requests are very welcome as well.

## Additional information

This package is part of the Dartstr monorepo, which contains a set of modular and compatible Dart packages of different Nostr NIPS and utilities. Import just the packages of NIPS you need and keep your project lightweight. See the [Dartstr monorepo](https://github.com/kumulynja/dartstr) for all available packages.
