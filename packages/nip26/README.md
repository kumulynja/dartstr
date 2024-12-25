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

Dart implementation of Delegated Event Signing in Nostr as described in [NIP-26](https://github.com/nostr-protocol/nips/blob/master/26.md).

## Features

This package lets you create delegation tokens as a delegator, construct delegated events as a delegatee and check and get the delegator from an event as a client.

## Usage

```dart
import 'package:nip26/nip26.dart';
import 'package:nip01/nip01.dart';

final delegatorRootKeyPair = KeyPair.generate();
final delegator = Delegator(delegatorRootKeyPair);

final delegateeKeyPair = KeyPair.generate();

final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
final conditions = ConditionsQuery(
    kinds: [EventKind.textNote.value],
    createdAfter: now,
    createdBefore: now + 600,
);

final token = delegator.createDelegationToken(
    delegateePubkey: delegateeKeyPair.publicKey,
    conditionsQuery: conditions,
);

final delegatee = Delegatee(
    delegateeKeyPair,
    delegatorPubkey: delegatorRootKeyPair.publicKey,
    conditions: conditions,
    token: token,
);

final event = delegatee.constructSignedEvent(
    createdAt: now + 1,
    kind: EventKind.textNote.value,
    content: 'Hello, World in name of delegator!',
);

final delegator = Client.tryGetDelegatorOfEvent(event);
```

## Additional information

This package is part of the Dartstr monorepo, which contains a set of modular and compatible Dart packages of different Nostr NIPS and utilities. Import just the packages of NIPS you need and keep your project lightweight. See the [Dartstr monorepo](https://github.com/kumulynja/dartstr) for all available packages.
