import 'package:nip01/nip01.dart';
import 'package:nip26/nip26.dart';

void main() {
  final delegatorRootKeyPair = KeyPair.generate();
  final delegator = Delegator(delegatorRootKeyPair);

  final delegateeKeyPair = KeyPair.generate();

  final token = delegator.createDelegationToken(
    delegateePubkey: delegateeKeyPair.publicKey,
    conditionsQuery: ConditionsQuery(
      kinds: [EventKind.textNote.value],
      createdAfter: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    ),
  );

  final delegatee = Delegatee(
    delegateeKeyPair,
    delegatorPubkey: delegatorRootKeyPair.publicKey,
    conditions: ConditionsQuery(
      kinds: [EventKind.textNote.value],
      createdAfter: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    ),
    token: token,
  );

  final event = delegatee.constructSignedEvent(
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    kind: EventKind.textNote.value,
    content: 'Hello, World in name of delegator!',
  );

  print('Delegated event: $event');
}
