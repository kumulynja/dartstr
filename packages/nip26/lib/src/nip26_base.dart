import 'package:nip01/nip01.dart';
import 'package:nip26/src/data/models/conditions_query.dart';
import 'package:nip26/src/data/models/delegation_tag.dart';
import 'package:nip26/src/data/models/delegation_token.dart';

class Delegator {
  final KeyPair rootKeyPair;

  Delegator(this.rootKeyPair);

  String createDelegationToken(
    String delegateePubkey,
    ConditionsQuery conditionsQuery,
  ) {
    final delegationToken = DelegationToken(
      delegateePubkey: delegateePubkey,
      conditionsQuery: conditionsQuery,
    );

    return delegationToken.sign(rootKeyPair);
  }

  void deleteDelegatedEvent(Event event) => throw UnimplementedError();
}

class Delegatee {
  final KeyPair delegateeKeyPair;

  Delegatee(this.delegateeKeyPair);

  Event addDelegationTagToEvent(
    Event event,
    DelegationTag delegationTag,
  ) {
    final tags = event.tags;
    tags.add(delegationTag.tag);

    return event.copyWith(tags: tags);
  }
}

class Client {
  static bool isValidDelegationEvent(Event event) {
    final delegationTag = DelegationTag.fromEvent(event);

    // Verify the signature of the delegation token
    final isValidSignature = DelegationToken(
      delegateePubkey: event.pubkey,
      conditionsQuery: delegationTag.conditionsQuery,
    ).verify(delegationTag.delegationToken, delegationTag.delegatorPubkey);
    // Verify the conditions query
    final conditionKinds = delegationTag.conditionsQuery.kinds;
    final isValidKind =
        conditionKinds == null ? true : conditionKinds.contains(event.kind);
    final eventTimestamp = event.createdAt;
    final isValidTime = delegationTag.conditionsQuery.createdAfter == null ||
        eventTimestamp > delegationTag.conditionsQuery.createdAfter! &&
            delegationTag.conditionsQuery.createdBefore == null ||
        eventTimestamp < delegationTag.conditionsQuery.createdBefore!;

    if (!isValidSignature || !isValidKind || !isValidTime) {
      return false;
    }

    return true;
  }
}
