import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:nip01/nip01.dart' as nip01;
import 'package:nip47/src/enums/event_kind.dart';
import 'package:nip47/src/enums/method.dart';

@immutable
class InfoEvent extends Equatable {
  final List<Method> permittedMethods;

  const InfoEvent({
    required this.permittedMethods,
  });

  nip01.Event toSignedEvent({
    required nip01.KeyPair creatorKeyPair,
    required String connectionPubkey,
    required String relayUrl,
  }) {
    final partialNostrEvent = nip01.Event(
      pubkey: creatorKeyPair.publicKey,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: EventKind.info.value,
      // The info event should be a replaceable event, so add 'a' tag.
      tags: [
        [
          'a',
          '${EventKind.info.value}:$connectionPubkey:',
          relayUrl,
        ]
      ],
      content: permittedMethods
          .map(
            (method) => method.plaintext,
          )
          .join(
            ' ',
          ), // NIP-47 spec: The content should be a plaintext string with the supported commands, space-separated.
    );

    final id = partialNostrEvent.id;
    final signedNostrEvent = partialNostrEvent.copyWith(
      id: id,
      sig: creatorKeyPair.sign(id),
    );

    return signedNostrEvent;
  }

  @override
  List<Object?> get props => [permittedMethods];
}