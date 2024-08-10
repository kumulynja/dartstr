import 'package:nip01/nip01.dart' as nip01;
import 'package:nip19/nip19.dart';
import 'package:test/test.dart';

void main() {
  group('nip19', () {
    const testCases = [
      {
        'privateKey':
            '7f7ff03d123792d6ac594bfa67bf6d0c0ab55b6b1fdb6249303fe861f1ccba9a',
        'publicKey':
            '17162c921dc4d2518f9a101db33695df1afb56ab82f5ff3e5da6eec3ca5cd917',
        'nsec':
            'nsec10allq0gjx7fddtzef0ax00mdps9t2kmtrldkyjfs8l5xruwvh2dq0lhhkp',
        'npub':
            'npub1zutzeysacnf9rru6zqwmxd54mud0k44tst6l70ja5mhv8jjumytsd2x7nu'
      },
      {
        'privateKey':
            'c15d739894c81a2fcfd3a2df85a0d2c0dbc47a280d092799f144d73d7ae78add',
        'publicKey':
            'd41b22899549e1f3d335a31002cfd382174006e166d3e658e3a5eecdb6463573',
        'nsec':
            'nsec1c9wh8xy5eqdzln7n5t0ctgxjcrdug73gp5yj0x03gntn67h83twssdfhel',
        'npub':
            'npub16sdj9zv4f8sl85e45vgq9n7nsgt5qphpvmf7vk8r5hhvmdjxx4es8rq74h',
      }
    ];

    setUp(() {
      // Additional setup goes here.
    });

    test('Nsec to Key Pair derivation', () {
      for (final testCase in testCases) {
        final keyPair = KeyPair.fromNsec(testCase['nsec'] as String);

        expect(keyPair.privateKey, testCase['privateKey']);
        expect(keyPair.publicKey, testCase['publicKey']);
        expect(keyPair.npub, testCase['npub']);
        // negative test
        expect(keyPair.privateKey, isNot(nip01.KeyPair.generate().privateKey));
      }
    });

    test('Nsec getter', () {
      for (final testCase in testCases) {
        final keyPair = KeyPair(privateKey: testCase['privateKey'] as String);

        expect(keyPair.nsec, testCase['nsec']);
        // negative test
        expect(keyPair.nsec, isNot(KeyPair.generate().nsec));
      }
    });

    test('Npub getter', () {
      for (final testCase in testCases) {
        final keyPair = KeyPair(privateKey: testCase['privateKey'] as String);

        expect(keyPair.npub, testCase['npub']);
        // negative test
        expect(keyPair.npub, isNot(KeyPair.generate().npub));
      }
    });

    test('Npub to Public Key', () {
      for (final testCase in testCases) {
        final pubkey = KeyPair.npubToPublicKey(testCase['npub'] as String);

        expect(pubkey, testCase['publicKey']);
        // negative test
        expect(pubkey, isNot(KeyPair.generate().publicKey));
      }
    });

    test('Npub from Public Key', () {
      for (final testCase in testCases) {
        final npub = KeyPair.npubFromPublicKey(testCase['publicKey'] as String);

        expect(npub, testCase['npub']);
        // negative test
        expect(npub, isNot(KeyPair.generate().npub));
      }
    });
  });
}
