import 'package:equatable/equatable.dart';

class ConditionsQuery extends Equatable {
  final List<int>? kinds;
  final int? createdBefore;
  final int? createdAfter;

  const ConditionsQuery({
    this.kinds,
    this.createdBefore,
    this.createdAfter,
  });

  factory ConditionsQuery.fromQueryString(String queryString) {
    final parts = queryString.split('&');
    final kinds = parts
        .where((part) => part.startsWith('kind='))
        .map((part) {
          final splitPart = part.split('=');
          return splitPart.length > 1 ? int.tryParse(splitPart[1]) : null;
        })
        .whereType<
            int>() // Filters out any nulls resulting from empty 'kind=' parts
        .toList();

    final createdBeforePart = parts
        .firstWhere((part) => part.startsWith('created_at<'), orElse: () => '');
    final createdBefore = createdBeforePart.contains('<') &&
            createdBeforePart.split('<').length > 1
        ? int.tryParse(createdBeforePart.split('<')[1])
        : null;

    final createdAfterPart = parts
        .firstWhere((part) => part.startsWith('created_at>'), orElse: () => '');
    final createdAfter =
        createdAfterPart.contains('>') && createdAfterPart.split('>').length > 1
            ? int.tryParse(createdAfterPart.split('>')[1])
            : null;

    return ConditionsQuery(
      kinds: kinds,
      createdBefore: createdBefore,
      createdAfter: createdAfter,
    );
  }

  String get queryString {
    final kind = kinds?.map((k) => 'kind=$k').join('&');
    final createdBeforeString = createdBefore != null
        ? 'created_at<$createdBefore'
        : null; // If createdBefore is null, don't include it in the query
    final createdAfterString = createdAfter != null
        ? 'created_at>$createdAfter'
        : null; // If createdAfter is null, don't include it in the query
    final query = [kind, createdBeforeString, createdAfterString]
        .where((element) => element != null)
        .join('&');
    return query;
  }

  @override
  List<Object?> get props => [createdBefore, kinds, createdAfter];
}
