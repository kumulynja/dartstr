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

## Features

This package contains the basic protocol flows for Nostr as described in the NIP-01. This includes the creation of key pairs, event creation, event publishing, event requests, and event listening among others.

## Usage

```dart
import 'package:nip01/nip01.dart';
import 'package:dartstr_utils/dartstr_utils.dart';

final keyPair = KeyPair.generate();
print('privateKey: ${keyPair.privateKey}');

final nip01Repository = Nip01RepositoryImpl(
    relayClientsManager: RelayClientsManagerImpl(['wss://example.relay.org']),
);

final partialEvent = Event(
    pubkey: '981cc2078af05b62ee1f98cff325aac755bf5c5836a265c254447b5933c6223b',
    createdAt: 1672175320,
    kind: EventKind.textNote.value,
    tags: [],
    content: "This is an event.",
);

final signedEvent = partialEvent.sign(keyPair);

final isPublished = await nip01Repository.publishEvent(signedEvent);
if (!isPublished) {
    throw Exception('Failed to publish event');
}

// Subscribe to events on the relay
final String subscriptionId = SecretGenerator.secretHex(
    64,
); // SecretGenerator is part of the dartstr_utils package

final eventsStream = await nip01Repository.subscribeToEvents(
    subscriptionId,
    [
      Filters(
        authors: [keyPair.publicKey],
        since: 1672175320,
      ),
    ],
);

eventsStream.listen((event) {
    print('Received event: $event');
});
```

## Additional information

This package is part of the Dartstr monorepo, which contains a set of modular and compatible Dart packages of different Nostr NIPS and utilities. Import just the packages of NIPS you need and keep your project lightweight. See the [Dartstr monorepo](https://github.com/kumulynja/dartstr) for all available packages.
