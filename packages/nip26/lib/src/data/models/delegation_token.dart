import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:nip01/nip01.dart';
import 'package:nip26/src/data/models/conditions_query.dart';
import 'package:bip340/bip340.dart' as bip340;

class DelegationToken extends Equatable {
  final String delegateePubkey;
  final ConditionsQuery conditionsQuery;

  const DelegationToken({
    required this.delegateePubkey,
    required this.conditionsQuery,
  });

  String get _digest {
    final plaintext =
        'nostr:delegation:$delegateePubkey:${conditionsQuery.queryString}';
    final digest = sha256.convert(utf8.encode(plaintext));
    return hex.encode(digest.bytes);
  }

  String sign(KeyPair delegatorKeyPair) {
    return delegatorKeyPair.sign(_digest);
  }

  bool verify(String delegationToken, String delegatorPubkey) {
    if (delegationToken.length != 128) {
      throw ArgumentError('Signature must be 64 hex characters');
    }
    return bip340.verify(delegatorPubkey, _digest, delegationToken);
  }

  @override
  List<Object?> get props => [delegateePubkey, conditionsQuery];
}
