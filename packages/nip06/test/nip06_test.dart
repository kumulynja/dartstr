import 'package:nip06/nip06.dart';
import 'package:test/test.dart';

void main() {
  group('nip06', () {
    const testCases = [
      {
        'mnemonic':
            'leader monkey parrot ring guide accident before fence cannon height naive bean',
        'privateKey':
            '7f7ff03d123792d6ac594bfa67bf6d0c0ab55b6b1fdb6249303fe861f1ccba9a',
        'publicKey':
            '17162c921dc4d2518f9a101db33695df1afb56ab82f5ff3e5da6eec3ca5cd917',
      },
      {
        'mnemonic':
            'what bleak badge arrange retreat wolf trade produce cricket blur garlic valid proud rude strong choose busy staff weather area salt hollow arm fade',
        'privateKey':
            'c15d739894c81a2fcfd3a2df85a0d2c0dbc47a280d092799f144d73d7ae78add',
        'publicKey':
            'd41b22899549e1f3d335a31002cfd382174006e166d3e658e3a5eecdb6463573',
      }
    ];

    setUp(() {
      // Additional setup goes here.
    });

    test('Mnemonic to Key Pair derivation', () {
      for (final testCase in testCases) {
        final keyPair = KeyPair.fromMnemonic(testCase['mnemonic'] as String);

        expect(keyPair.privateKey, testCase['privateKey']);
        expect(keyPair.publicKey, testCase['publicKey']);
        // negative test
        expect(keyPair.privateKey, isNot(KeyPair.generate().privateKey));
      }
    });
  });
}
