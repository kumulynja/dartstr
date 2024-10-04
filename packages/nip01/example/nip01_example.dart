import 'package:dartstr_utils/dartstr_utils.dart';
import 'package:nip01/nip01.dart';

void main() async {
  final keyPair = KeyPair.generate();
  print('privateKey: ${keyPair.privateKey}');

  final nip01Repository = Nip01RepositoryImpl(
    relayClientsManager: RelayClientsManagerImpl(['wss://example.relay.org']),
  );

  final partialEvent = Event(
    pubkey: '981cc2078af05b62ee1f98cff325aac755bf5c5836a265c254447b5933c6223b',
    createdAt: 1672175320,
    kind: EventKind.textNote.value,
    tags: [],
    content: "This is an event.",
  );

  final signedEvent = partialEvent.sign(keyPair);

  final isPublished = await nip01Repository.publishEvent(signedEvent);
  if (!isPublished) {
    throw Exception('Failed to publish event');
  }

  // Subscribe to events on the relay
  final String subscriptionId = SecretGenerator.secretHex(
    64,
  ); // SecretGenerator is part of the dartstr_utils package
  final eventsStream = await nip01Repository.subscribeToEvents(
    subscriptionId,
    [
      Filters(
        authors: [keyPair.publicKey],
        since: 1672175320,
      ),
    ],
  );

  eventsStream.listen((event) {
    print('Received event: $event');
  });
}
