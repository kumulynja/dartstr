import 'package:dartstr_utils/dartstr_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Secret generator', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Secret bytes', () {
      final secret = SecretGenerator.secretBytes(32);
      expect(secret.length, 32);
    });

    test('Secret hex', () {
      final secret = SecretGenerator.secretHex(64);
      expect(secret.length, 64);
    });
  });
}
