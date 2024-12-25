import 'package:nip01/nip01.dart';
import 'package:nip26/src/data/models/conditions_query.dart';
import 'package:nip26/src/data/models/delegation_tag.dart';
import 'package:nip26/src/data/models/delegation_token.dart';

class Delegator {
  final KeyPair _rootKeyPair;

  Delegator(KeyPair rootKeyPair) : _rootKeyPair = rootKeyPair;

  String createDelegationToken({
    required String delegateePubkey,
    required ConditionsQuery conditionsQuery,
  }) {
    final delegationToken = DelegationToken(
      delegateePubkey: delegateePubkey,
      conditionsQuery: conditionsQuery,
    );

    return delegationToken.sign(_rootKeyPair);
  }
}

class Delegatee {
  final KeyPair _keyPair;
  final DelegationTag _delegationTag;

  Delegatee(
    KeyPair keyPair, {
    required String delegatorPubkey,
    required ConditionsQuery conditions,
    required String token,
  })  : _keyPair = keyPair,
        _delegationTag = DelegationTag(
          delegatorPubkey: delegatorPubkey,
          conditionsQuery: conditions,
          delegationToken: token,
        );

  Event constructSignedEvent({
    required int createdAt,
    required int kind,
    List<List<String>> tags = const [],
    required String content,
  }) {
    List<List<String>> tagsWithDelegationTag = [...tags, _delegationTag.tag];
    final event = Event(
      pubkey: _keyPair.publicKey,
      createdAt: createdAt,
      kind: kind,
      tags: tagsWithDelegationTag,
      content: content,
    );

    return event.sign(_keyPair);
  }
}

class Client {
  static String? tryGetDelegatorOfEvent(Event event) {
    try {
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
      final isValidTime = (delegationTag.conditionsQuery.createdAfter == null ||
              eventTimestamp > delegationTag.conditionsQuery.createdAfter!) &&
          (delegationTag.conditionsQuery.createdBefore == null ||
              eventTimestamp < delegationTag.conditionsQuery.createdBefore!);

      if (!isValidSignature || !isValidKind || !isValidTime) {
        throw ArgumentError('Invalid delegation');
      }

      return delegationTag.delegatorPubkey;
    } catch (e) {
      return null;
    }
  }
}
