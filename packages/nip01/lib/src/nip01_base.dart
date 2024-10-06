import 'dart:developer';

import 'package:async/async.dart';
import 'package:nip01/src/data/clients/relay_clients_manager.dart';
import 'package:nip01/src/data/models/event.dart';
import 'package:nip01/src/data/models/filters.dart';
import 'package:nip01/src/data/models/key_pair.dart';
import 'package:nip01/src/data/models/kind_0_metadata.dart';

abstract class Nip01Repository {
  List<String> get relayUrls;
  Future<bool> publishEvent(
    Event event, {
    int successTreshold = 1,
    List<String>? relayUrls,
  });
  Future<List<Event>> getStoredEvents(
    List<Filters> filters, {
    List<String>? relayUrls,
  });
  Future<Stream<Event>> subscribeToEvents(
    String subscriptionId,
    List<Filters> filters, {
    List<String>? relayUrls,
    void Function(List<Event>)? onEose,
  });
  Future<void> unsubscribeFromEvents(
    String subscriptionId, {
    List<String>? relayUrls,
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  });
  Future<void> setUserMetadata({
    required KeyPair userKeyPair,
    required Kind0Metadata metadata,
    List<String>? relayUrls,
    int successTreshold = 1,
    int timeoutSec = 5,
  });
  Future<Kind0Metadata> getUserMetadata(
    String userPubkey, {
    List<String>? relayUrls,
  });
  Future<void> disposeRelayClient(
    String relayUrl, {
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  });
  Future<void> disposeAllRelayClients({
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  });
}

class Nip01RepositoryImpl implements Nip01Repository {
  Nip01RepositoryImpl({
    RelayClientsManager? relayClientsManager,
  }) : _relayClientsManager = relayClientsManager ??
            RelayClientsManagerImpl(
              [
                'wss://relay.paywithflash.com',
                'wss://relay.primal.net',
                'wss://relay.snort.social',
                'wss://relay.damus.io',
                'wss://relay.nostr.band',
              ],
            );

  final RelayClientsManager _relayClientsManager;

  @override
  List<String> get relayUrls => _relayClientsManager.relayUrls;

  @override
  Future<bool> publishEvent(
    Event event, {
    int successTreshold = 1,
    List<String>? relayUrls,
    int timeoutSec = 5,
  }) async {
    final relayApiClients = _relayClientsManager.getClients(
      onlyRelayUrls: relayUrls,
    );

    final results = await Future.wait(
      relayApiClients.map(
        (client) => client.publishEvent(
          event,
          timeoutSec: timeoutSec,
        ),
      ),
    );

    // Todo: Maybe change this to return the relays that succeeded.
    final successCount = results.where((result) => result == true).length;
    return successCount >= successTreshold;
  }

  @override
  Future<List<Event>> getStoredEvents(
    List<Filters> filters, {
    List<String>? relayUrls,
  }) async {
    final relayApiClients = _relayClientsManager.getClients(
      onlyRelayUrls: relayUrls,
    );

    final results = await Future.wait(
        relayApiClients.map((client) => client.requestStoredEvents(filters)));

    // Use a Set to automatically filter out duplicate events
    final Set<Event> events = {};
    for (final result in results) {
      events.addAll(result);
    }

    return events.toList();
  }

  @override
  Future<Stream<Event>> subscribeToEvents(
    String subscriptionId,
    List<Filters> filters, {
    List<String>? relayUrls,
    void Function(List<Event>)? onEose,
  }) async {
    final relayApiClients = _relayClientsManager.getClients(
      onlyRelayUrls: relayUrls,
    );

    final results = await Future.wait(
      relayApiClients.map(
        (client) => client.requestEvents(
          subscriptionId,
          filters,
          onEose: onEose,
        ),
      ),
    );

    // Group all streams into one
    return StreamGroup.merge<Event>(results);
  }

  @override
  Future<void> unsubscribeFromEvents(
    String subscriptionId, {
    List<String>? relayUrls,
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  }) async {
    final relayApiClients = _relayClientsManager.getClients(
      onlyRelayUrls: relayUrls,
    );

    await Future.wait(
      relayApiClients.map(
        (client) => client.closeSubscription(
          subscriptionId,
          waitForRelayClosedMessage: waitForRelayClosedMessage,
          timeoutSec: timeoutSec,
        ),
      ),
    );
  }

  @override
  Future<void> setUserMetadata({
    required KeyPair userKeyPair,
    required Kind0Metadata metadata,
    List<String>? relayUrls,
    int successTreshold = 1,
    int timeoutSec = 5,
  }) async {
    try {
      final event = Event(
        pubkey: userKeyPair.publicKey,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: 0,
        content: metadata.content,
      ).sign(userKeyPair);

      final success = await publishEvent(
        event,
        relayUrls: relayUrls,
        timeoutSec: timeoutSec,
      );
      if (!success) {
        throw Exception('Failed to publish user metadata');
      }
    } catch (e) {
      log('Error setting user metadata: $e');
      rethrow; // Todo: Add error handling
    }
  }

  @override
  Future<Kind0Metadata> getUserMetadata(
    String userPubkey, {
    List<String>? relayUrls,
  }) async {
    try {
      final filter = Filters(authors: [userPubkey], kinds: const [0]);

      final events = await getStoredEvents([filter], relayUrls: relayUrls);

      if (events.isEmpty) {
        throw Exception('No user metadata found');
      }

      final latestEvent = events.reduce(
          (a, b) => a.createdAt > b.createdAt ? a : b); // Get the latest event

      return Kind0Metadata.fromContent(latestEvent.content);
    } catch (e) {
      log('Error getting user metadata: $e');
      rethrow; // Todo: Add error handling
    }
  }

  @override
  Future<void> disposeRelayClient(
    String relayUrl, {
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  }) async {
    await _relayClientsManager.disposeClient(
      relayUrl,
      waitForRelayClosedMessage: waitForRelayClosedMessage,
      timeoutSec: timeoutSec,
    );
  }

  @override
  Future<void> disposeAllRelayClients({
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  }) async {
    await _relayClientsManager.disposeAll(
      waitForRelayClosedMessage: waitForRelayClosedMessage,
      timeoutSec: timeoutSec,
    );
  }
}
