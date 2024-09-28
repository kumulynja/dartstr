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

This package contains the encrypted direct message protocol flow for Nostr as described in the NIP-04. This includes the encryption and decryption of messages between two parties using their key pairs.

## Getting started

### Installation

In your `pubspec.yaml` file add:

```yaml
dependencies:
  nip04: ^0.0.1
```

## Usage

```dart
import 'package:nip01/nip01.dart';
import 'package:nip04/nip04.dart';

final receiverKeyPair = KeyPair.generate();
final senderKeyPair = KeyPair.generate();

const encryptedContent =
    'zdiUBdrfA+HNM4qF67oKN2HcUv4kxnlRkpjHP5mqd9UrFuoSbwGAXQeTBUUrYO1svYBvhnpBK4s5XNVvXmvQ4yuji+v7KOwrDYjQzFveXLXXlyoFPakp5CD2BUdGkNn3pVzodWD84dgmfuuUDNYNfmm8EyjVyGBE1TmiBHawOI0MkhZ+uHf4VGhO6EIvhunLYQITe4YQvTRHiNlO4hoHh9kOjQLxYEY9AEkZ2EEPcfYpSkuYqUnvwUii7qzPJWU8o7PI86k4R3IryEf7hnN1DvZgZxRiWrwJwXP7P9PTiaorzjsEZWrKsus+65vU2e1F6L0jOPX0f5+/lZkSwF7Qgq4YZc/OlyJSqMDrz0SoMw0NbugGYOU/DxO4pP75o0NPIeG6lyr4jA4VsXMyA2NiNfFQRlGbRuk/qF8nmG4we70=?iv=yIIcMRiYu41Qlztn0asP3g==';

final decryptedMessage = Nip04.decrypt(
    encryptedContent,
    receiverKeyPair.privateKey,
    senderKeyPair.publicKey,
);
print(decryptedMessage);

const senderPublicKey =
    '7a29579ddcb698db1b93f7078c5020dc932de36cba53fedd6a0746005db7fd7f';

final encryptedMessage = Nip04.encrypt(
    'This is a secret message.',
    senderKeyPair.privateKey,
    receiverKeyPair.publicKey,
);
```

## Additional information

This package is part of the Dartstr monorepo, which contains a set of modular and compatible Dart packages of different Nostr NIPS and utilities. Import just the packages of NIPS you need and keep your project lightweight. See the [Dartstr monorepo](https://github.com/kumulynja/dartstr) for all available packages.
