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

- [x] Secret Generator: generate secure random number bytes or hex strings for use as secrets in Nostr.

## Getting started

### Installation

In your `pubspec.yaml` file add:

```yaml
dependencies:
  dartstr_utils: ^0.0.1
```

## Usage

```dart
import 'package:dartstr_utils/dartstr_utils.dart';

final secretBytes = SecretGenerator.secretBytes(32);
print('secretBytes: $secretBytes');

final secretHex = SecretGenerator.secretHex(64);
print('secretHex: $secretHex');
```

## Additional information

This package is part of the Dartstr monorepo, which contains a set of modular and compatible Dart packages of different Nostr NIPS and utilities. Import just the packages of NIPS you need and keep your project lightweight. See the [Dartstr monorepo](https://github.com/kumulynja/dartstr) for all available packages.
