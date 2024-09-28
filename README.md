[![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)

# Dartstr

A monorepo of modular and compatible Dart packages of different Nostr NIPS and utilities.
Import just the packages of NIPS you need and keep your project lightweight.

# Supported NIPS

- [x] [NIP-01](/packages/nip01/README.md): Basic protocol flow description
- [x] [NIP-04](/packages/nip04/README.md): Encrypted Direct Message
- [x] [NIP-06](/packages/nip06/README.md): Basic key derivation from mnemonic seed phrase
- [-] [NIP-19](/packages/nip19/README.md): bech32-encoded entities
  > [!NOTE]
  > Bare keys and ids are implemented already, shareable identifiers with extra metadata not yet.
- [x] [NIP-24](/packages/nip24/README.md): Extra metadata fields and tags
- [-] [NIP-47](/packages/nip47/README.md): Wallet Connect
  > [!NOTE]
  > Wallet side is implemented already, App side not yet

# Utilities

In [dartstr_utils](/packages/dartstr_utils/README.md) you can find a set of common utilities used across the packages and that can be used in your own projects.

Currently, the following utilities are available:

- [x] Secret generator: generate secure random number bytes or hex strings
