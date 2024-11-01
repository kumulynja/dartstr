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

This package contains the bech32-encoding for Nostr entities as described in the NIP-19 so they can be used informatively in Nostr clients, preventing confusion between different types of entities like private keys, public keys, and other Nostr entities.

## Usage

```dart
import 'package:nip19/nip19.dart';

final keyPair = KeyPair.generate();
print('nsec: ${keyPair.nsec}');

final keyPairFromNsec = KeyPair.fromNsec(keyPair.nsec);
print('privateKey: ${keyPairFromNsec.privateKey}');

final npubFromPublicKey = KeyPair.npubFromPublicKey(keyPair.publicKey);
print('npub: $npubFromPublicKey');

final npubToPublicKey = KeyPair.npubToPublicKey(npubFromPublicKey);
print('publicKey: $npubToPublicKey');
```

## Additional information

This package is part of the Dartstr monorepo, which contains a set of modular and compatible Dart packages of different Nostr NIPS and utilities. Import just the packages of NIPS you need and keep your project lightweight. See the [Dartstr monorepo](https://github.com/kumulynja/dartstr) for all available packages.
