import 'dart:developer';

import 'package:async/async.dart';
import 'package:nip01/nip01.dart';
import 'package:nip01/src/data/clients/relay_clients_manager.dart';

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
  });
  Future<void> unsubscribeFromEvents(
    String subscriptionId, {
    List<String>? relayUrls,
  });
  Future<void> setUserMetadata({
    required KeyPair userKeyPair,
    required Kind0Metadata metadata,
  });
  Future<Kind0Metadata> getUserMetadata(
    String userPubkey, {
    List<String>? relayUrls,
  });
  Future<void> disposeRelayClient(String relayUrl);
  Future<void> disposeAllRelayClients();
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
  }) async {
    final relayApiClients = _relayClientsManager.getClients(
      onlyRelayUrls: relayUrls,
    );

    final results = await Future.wait(
        relayApiClients.map((client) => client.publishEvent(event)));

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
  }) async {
    final relayApiClients = _relayClientsManager.getClients(
      onlyRelayUrls: relayUrls,
    );

    final results = await Future.wait(relayApiClients
        .map((client) => client.requestEvents(subscriptionId, filters)));

    // Group all streams into one
    return StreamGroup.merge<Event>(results);
  }

  @override
  Future<void> unsubscribeFromEvents(
    String subscriptionId, {
    List<String>? relayUrls,
  }) async {
    final relayApiClients = _relayClientsManager.getClients(
      onlyRelayUrls: relayUrls,
    );

    await Future.wait(relayApiClients
        .map((client) => client.closeSubscription(subscriptionId)));
  }

  @override
  Future<void> setUserMetadata({
    required KeyPair userKeyPair,
    required Kind0Metadata metadata,
  }) async {
    try {
      final event = Event(
        pubkey: userKeyPair.publicKey,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: 0,
        content: metadata.content,
      ).sign(userKeyPair);

      final success = await publishEvent(event);
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
  Future<void> disposeRelayClient(String relayUrl) async {
    await _relayClientsManager.disposeClient(relayUrl);
  }

  @override
  Future<void> disposeAllRelayClients() async {
    await _relayClientsManager.disposeAll();
  }
}
