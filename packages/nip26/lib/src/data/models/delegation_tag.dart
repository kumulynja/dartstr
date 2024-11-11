import 'package:equatable/equatable.dart';
import 'package:nip01/nip01.dart';
import 'package:nip26/src/data/models/conditions_query.dart';

class DelegationTag extends Equatable {
  final String delegatorPubkey;
  final ConditionsQuery conditionsQuery;
  final String delegationToken;

  const DelegationTag({
    required this.delegatorPubkey,
    required this.conditionsQuery,
    required this.delegationToken,
  });

  factory DelegationTag.fromEvent(Event event) {
    final tags = event.tags;
    final delegationTag = tags.firstWhere(
      (tag) => tag[0] == 'delegation',
      orElse: () => [],
    );

    if (delegationTag.isEmpty) {
      throw ArgumentError('No delegation tag found');
    }

    final delegatorPubkey = delegationTag[1];
    final conditionsQuery = ConditionsQuery.fromQueryString(delegationTag[2]);
    final delegationToken = delegationTag[3];

    return DelegationTag(
      delegatorPubkey: delegatorPubkey,
      conditionsQuery: conditionsQuery,
      delegationToken: delegationToken,
    );
  }

  List<String> get tag {
    return [
      'delegation',
      delegatorPubkey,
      conditionsQuery.queryString,
      delegationToken,
    ];
  }

  @override
  List<Object?> get props => [
        delegatorPubkey,
        conditionsQuery,
        delegationToken,
      ];
}
