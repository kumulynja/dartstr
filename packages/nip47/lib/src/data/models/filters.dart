import 'package:meta/meta.dart';
import 'package:nip01/nip01.dart' as nip01;
import 'package:nip47/src/enums/event_kind.dart';

@immutable
class Filters extends nip01.Filters {
  const Filters({
    super.ids,
    super.authors,
    super.kinds,
    super.tags,
    super.since,
    super.until,
    super.limit,
  });

  factory Filters.infoEvents({
    required String connectionPubkey,
    required String relayUrl,
    int? since,
  }) =>
      Filters(
        kinds: [EventKind.info.value],
        tags: {
          'a': [
            '${EventKind.info.value}:$connectionPubkey:',
            relayUrl,
          ]
        },
        since: since,
      );

  factory Filters.requests({
    required String walletPublicKey,
    int? since,
  }) =>
      Filters(
        kinds: [EventKind.request.value],
        tags: {
          'p': [walletPublicKey]
        },
        since: since,
      );
}
