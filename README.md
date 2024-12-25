[![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)

# Dartstr

A monorepo of modular and compatible Dart packages of different Nostr NIPS and utilities.
Import just the packages of NIPS you need and keep your project lightweight.

# Supported NIPS

- [x] [NIP-01](/packages/nip01): Basic protocol flow description
- [x] [NIP-04](/packages/nip04): Encrypted Direct Message
- [x] [NIP-06](/packages/nip06): Basic key derivation from mnemonic seed phrase
- [x] [NIP-19](/packages/nip19): bech32-encoded entities

> [!NOTE]
> Bare keys and ids are implemented already, shareable identifiers with extra metadata not yet.

- [x] [NIP-24](/packages/nip24): Extra metadata fields and tags
- [x] [NIP-26](/packages/nip26): Delegated Event Signing
- [x] [NIP-47](/packages/nip47): Wallet Connect

> [!NOTE]
> Wallet service side is implemented already, App/client side not yet

# Utilities

In [dartstr_utils](/packages/dartstr_utils) you can find a set of common utilities used across the packages and that can be used in your own projects.

Currently, the following utilities are available:

- [x] Secret generator: generate secure random number bytes or hex strings
