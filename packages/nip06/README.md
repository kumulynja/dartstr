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

This package contains the basic key derivation from mnemonic seed phrases for Nostr as described in the NIP-06.

## Usage

```dart
import 'package:nip06/nip06.dart';

final keyPairFromMnemonic = KeyPair.fromMnemonic(
'abandon '
'abandon '
'abandon '
'abandon '
'abandon '
'abandon '
'abandon '
'abandon '
'abandon '
'abandon '
'abandon '
'about',
);
print('Private key: ${keyPairFromMnemonic.privateKey}');
```

## Additional information

This package is part of the Dartstr monorepo, which contains a set of modular and compatible Dart packages of different Nostr NIPS and utilities. Import just the packages of NIPS you need and keep your project lightweight. See the [Dartstr monorepo](https://github.com/kumulynja/dartstr) for all available packages.
