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

This package contains the extra metadata fields that can be added to a Nostr kind 0 event as described in the NIP-24. This includes the display name, website, banner, and bot fields.

## Getting started

### Installation

In your `pubspec.yaml` file add:

```yaml
dependencies:
  nip24: ^1.0.0
```

## Usage

```dart
import 'package:nip24/nip24.dart';

var metadata = Kind0ExtraMetadata(
    name: 'John Doe',
    about: 'A developer',
    picture: 'https://example.com/picture.png',
    displayName: 'JD',
    website: 'https://johndoe.dev',
    banner: 'https://example.com/banner.png',
    bot: true,
);

print(metadata.content);

metadata = Kind0ExtraMetadata.fromContent(metadata.content);

print(metadata.name);
```

## Additional information

This package is part of the Dartstr monorepo, which contains a set of modular and compatible Dart packages of different Nostr NIPS and utilities. Import just the packages of NIPS you need and keep your project lightweight. See the [Dartstr monorepo](https://github.com/kumulynja/dartstr) for all available packages.
