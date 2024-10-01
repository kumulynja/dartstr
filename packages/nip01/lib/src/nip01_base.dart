import 'dart:async';
import 'dart:developer';

import 'package:nip01/src/data/models/client_message.dart';
import 'package:nip01/src/data/models/event.dart';
import 'package:nip01/src/data/models/filters.dart';
import 'package:nip01/src/data/models/relay_client_event_subscription.dart';
import 'package:nip01/src/data/models/relay_message.dart';
import 'package:nip01/src/data/providers/relay_stream_provider.dart';

abstract class RelayClient {
  String get relayUrl;
  bool get isConnected;
  Future<void> connect();
  Stream<Event> requestEvents(String subscriptionId, List<Filters> filters);
  Future<List<Event>> requestStoredEvents(
    String subscriptionId,
    List<Filters> filters,
  );
  Future<bool> publishEvent(Event event);
  Future<RelayClientEventSubscription?> closeSubscription(
    String subscriptionId, {
    bool waitForRelayClosedMessage,
  });
  Future<void> disconnect();
  Future<void> dispose();
}

class RelayClientImpl implements RelayClient {
  final String _relayUrl;
  final RelayStreamProvider _relayStreamProvider;
  StreamSubscription? _relayStreamSubscription;
  bool _isConnected = false;
  int _retryAttempts = 0;
  final int _maxRetryAttempts;
  final Map<String, RelayClientEventSubscription> _eventSubscriptionsCache = {};
  final Map<String, Completer<bool>> _publishingEvents = {};

  RelayClientImpl(
    this._relayUrl, {
    RelayStreamProvider? relayStreamProvider,
    int maxRetryAttempts = 5,
  })  : _relayStreamProvider = relayStreamProvider ??
            RelayStreamProviderImpl(
              _relayUrl,
            ),
        _maxRetryAttempts = maxRetryAttempts;

  @override
  String get relayUrl => _relayUrl;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect() async {
    try {
      log('Initializing relay client for relay $_relayUrl');

      await _relayStreamProvider.connect();
      _relayStreamSubscription = _relayStreamProvider.messages.listen(
        (message) {
          log('Received message from relay $_relayUrl: $message');
          _handleRelayMessage(message);
        },
        onError: (error) {
          log('Stream error on relay $_relayUrl: $error');
          _reconnect();
        },
        onDone: () {
          log('Stream done on relay $_relayUrl');
          _reconnect();
        },
        cancelOnError: true,
      );

      log('Relay client successfully initialized for relay $_relayUrl');
    } catch (e) {
      log('Error initializing relay client for relay $_relayUrl: $e');
      rethrow;
    }
  }

  @override
  Future<bool> publishEvent(
    Event event, {
    int timeoutSec = 5,
  }) async {
    try {
      final completer = Completer<bool>();
      final message = ClientEventMessage(event: event);

      _publishingEvents[event.id] = completer; // Store completer with event ID

      _relayStreamProvider.sendMessage(message);

      final isPublishedSuccessfully = await completer.future.timeout(
        Duration(seconds: timeoutSec),
        onTimeout: () {
          log('Publish event timeout: ${event.id}');
          return false; // Return false on timeout
        },
      );

      return isPublishedSuccessfully;
    } catch (e) {
      log('Error publishing event: $e');
      return false;
    } finally {
      // Remove the completer from the map
      _publishingEvents.remove(event.id);
    }
  }

  @override
  Stream<Event> requestEvents(
    String subscriptionId,
    List<Filters> filters, {
    void Function(List<Event>)? onEose,
  }) {
    try {
      // Keep track of the subscription
      _eventSubscriptionsCache[subscriptionId] = RelayClientEventSubscription(
        subscriptionId: subscriptionId,
        filters: filters,
        onEose: onEose,
      );

      // Send the subscription request to the relay
      final message = ClientRequestMessage(
        subscriptionId: subscriptionId,
        filters: filters,
      );
      _relayStreamProvider.sendMessage(message);

      // Return the stream of events
      return _eventSubscriptionsCache[subscriptionId]!.events;
    } catch (e) {
      log('Error requesting events: $e');
      _eventSubscriptionsCache.remove(subscriptionId);
      rethrow;
    }
  }

  @override
  Future<List<Event>> requestStoredEvents(
    String subscriptionId,
    List<Filters> filters,
  ) async {
    // Keep track of the subscription
    _eventSubscriptionsCache[subscriptionId] = RelayClientEventSubscription(
      subscriptionId: subscriptionId,
      filters: filters,
    );

    // Send the subscription request to the relay
    final message = ClientRequestMessage(
      subscriptionId: subscriptionId,
      filters: filters,
    );
    _relayStreamProvider.sendMessage(message);

    // Wait for the end of stored events
    await _eventSubscriptionsCache[subscriptionId]!.waitForEose();

    // Unsubscribe from the relay
    final closedSubscription = await closeSubscription(subscriptionId);

    return closedSubscription!.storedEvents;
  }

  @override
  Future<RelayClientEventSubscription?> closeSubscription(
    String subscriptionId, {
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  }) async {
    if (!_eventSubscriptionsCache.containsKey(subscriptionId)) {
      log('No subscription found for ID: $subscriptionId');
      return null;
    }

    final message = ClientCloseMessage(subscriptionId: subscriptionId);

    _relayStreamProvider.sendMessage(message);

    if (waitForRelayClosedMessage) {
      await _eventSubscriptionsCache[subscriptionId]!
          .waitForClose()
          .timeout(Duration(seconds: 10), onTimeout: () {
        log('Timeout waiting for close message from relay.');
      });
    }

    // Dispose and remove the subscription from the cache
    _eventSubscriptionsCache[subscriptionId]!.dispose();
    final subscription =
        _eventSubscriptionsCache.remove(message.subscriptionId);

    return subscription;
  }

  @override
  Future<void> disconnect() async {
    await _relayStreamSubscription?.cancel();
    _relayStreamSubscription = null;
    await _relayStreamProvider.disconnect();
  }

  @override
  Future<void> dispose() async {
    await Future.wait(
      _eventSubscriptionsCache.keys.map((subscriptionId) {
        return closeSubscription(subscriptionId);
      }),
    );
    await disconnect();
    await _relayStreamProvider.dispose();
  }

  void _reconnect() async {
    try {
      // Clean up before reconnecting
      disconnect();
      _isConnected = false;

      if (_retryAttempts < _maxRetryAttempts) {
        final timeout = Duration(seconds: 2 * _retryAttempts);
        log('Reconnecting to relay $_relayUrl in $timeout seconds');
        await Future.delayed(timeout);

        // Reconnect
        _retryAttempts++;
        await connect();
        _isConnected = true;
        _retryAttempts = 0;

        // Re-subscribe to all subscriptions
        _resubscribe();
      } else {
        log('Max retry attempts reached for relay $_relayUrl');
      }
    } catch (e) {
      log('Error reconnecting to relay $_relayUrl: $e');
      _reconnect();
    }
  }

  void _resubscribe() {
    _eventSubscriptionsCache.forEach((subscriptionId, subscription) {
      final message = ClientRequestMessage(
        subscriptionId: subscriptionId,
        filters: subscription.filters,
      );
      _relayStreamProvider.sendMessage(message);
    });
  }

  void _handleRelayMessage(RelayMessage message) {
    if (message is RelayEventMessage) {
      // Handle event message
      log('Received event: ${message.event.content}');

      // Get the subscription for the event
      final subscription = _eventSubscriptionsCache[message.subscriptionId];
      if (subscription != null) {
        // Add the event to the subscription stream
        subscription.addEvent(message.event);
      }
    } else if (message is RelayNoticeMessage) {
      // Handle notice message
      log('Received notice: ${message.message}');
    } else if (message is RelayEndOfStreamMessage) {
      // Handle end of stream message
      log(
        'End of stored events for subscription: ${message.subscriptionId}',
      );

      // Get the subscription for the event
      final subscription = _eventSubscriptionsCache[message.subscriptionId];
      if (subscription != null) {
        subscription.endOfStoredEvents();
      }
    } else if (message is RelayClosedMessage) {
      log(
        'Subscription closed by relay: ${message.subscriptionId} with message: ${message.message}',
      );

      final subscription = _eventSubscriptionsCache[message.subscriptionId];
      if (subscription != null) {
        subscription.markClosed();
      }
    } else if (message is RelayOkMessage) {
      log(
        'OK message: Event ${message.eventId} accepted: ${message.accepted}, message: ${message.message}',
      );

      // Handle OK message by completing the completer
      final completer = _publishingEvents[message.eventId];
      if (completer != null) {
        completer.complete(message.accepted);
      }
    }
  }
}
