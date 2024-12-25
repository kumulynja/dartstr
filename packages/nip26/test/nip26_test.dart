import 'package:nip01/nip01.dart';
import 'package:nip26/nip26.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final delegatorRootKeyPair = KeyPair.generate();
    final delegator = Delegator(delegatorRootKeyPair);

    final delegateeKeyPair = KeyPair.generate();

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final conditions = ConditionsQuery(
      kinds: [EventKind.textNote.value],
      createdAfter: now,
      createdBefore: now + 600,
    );

    final token = delegator.createDelegationToken(
      delegateePubkey: delegateeKeyPair.publicKey,
      conditionsQuery: conditions,
    );

    final delegatee = Delegatee(
      delegateeKeyPair,
      delegatorPubkey: delegatorRootKeyPair.publicKey,
      conditions: conditions,
      token: token,
    );

    final event = delegatee.constructSignedEvent(
      createdAt: now + 1,
      kind: EventKind.textNote.value,
      content: 'Hello, World in name of delegator!',
    );

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(
        Client.tryGetDelegatorOfEvent(event),
        delegatorRootKeyPair.publicKey,
      );
    });
  });
}
