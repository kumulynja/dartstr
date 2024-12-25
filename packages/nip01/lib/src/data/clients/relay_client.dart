import 'dart:async';
import 'dart:developer';

import 'package:synchronized/synchronized.dart';
import 'package:dartstr_utils/dartstr_utils.dart';
import 'package:nip01/src/data/models/client_message.dart';
import 'package:nip01/src/data/models/event.dart';
import 'package:nip01/src/data/models/filters.dart';
import 'package:nip01/src/data/models/relay_client_event_subscription.dart';
import 'package:nip01/src/data/models/relay_message.dart';
import 'package:nip01/src/data/providers/relay_stream_provider.dart';

abstract class RelayClient {
  String get relayUrl;
  bool get isConnected;
  Future<bool> publishEvent(
    Event event, {
    int timeoutSec = 10,
  });
  Future<Stream<Event>> requestEvents(
    String subscriptionId,
    List<Filters> filters, {
    void Function(List<Event>)? onEose,
  });
  Future<List<Event>> requestStoredEvents(
    List<Filters> filters,
  );
  Future<RelayClientEventSubscription?> closeSubscription(
    String subscriptionId, {
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  });
  Future<void> disconnect();
  Future<void> dispose({
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  });
}

class RelayClientImpl implements RelayClient {
  final String _relayUrl;
  final RelayStreamProvider _relayStreamProvider;
  StreamSubscription? _relayStreamSubscription;
  bool _isConnected = false;
  final Lock _connectionLock = Lock();
  int _retryAttempts = 0;
  final int _maxRetryAttempts;
  final Map<String, RelayClientEventSubscription> _eventSubscriptionsCache = {};
  final Map<String, Completer<bool>> _publishingEvents = {};

  RelayClientImpl(
    relayUrl, {
    RelayStreamProvider? relayStreamProvider,
    int maxRetryAttempts = 5,
  })  : _relayStreamProvider = relayStreamProvider ??
            RelayStreamProviderImpl(
              relayUrl,
            ),
        _relayUrl = relayStreamProvider != null
            ? relayStreamProvider.relayUrl
            : relayUrl,
        _maxRetryAttempts = maxRetryAttempts;

  @override
  String get relayUrl => _relayUrl;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> publishEvent(
    Event event, {
    int timeoutSec = 10,
  }) async {
    log('Publishing event: $event in relay $_relayUrl');
    try {
      final completer = Completer<bool>();
      final message = ClientEventMessage(event: event);

      _publishingEvents[event.id] = completer; // Store completer with event ID

      // Before sending the message, ensure the connection is established
      await _ensureConnected();
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
  Future<Stream<Event>> requestEvents(
    String subscriptionId,
    List<Filters> filters, {
    void Function(List<Event>)? onEose,
  }) async {
    log(
      'Requesting events for subscription: $subscriptionId, with filters: $filters in relay $_relayUrl',
    );
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

      // Before sending the message, ensure the connection is established
      await _ensureConnected();
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
    List<Filters> filters,
  ) async {
    log('Requesting stored events with filters: $filters in relay $_relayUrl');
    String subscriptionId = SecretGenerator.secretHex(64);
    try {
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

      // Before sending the message, ensure the connection is established
      await _ensureConnected();
      _relayStreamProvider.sendMessage(message);

      // Wait for the end of stored events
      await _eventSubscriptionsCache[subscriptionId]!.waitForEose();

      // Unsubscribe from the relay
      final closedSubscription = await closeSubscription(subscriptionId);

      return closedSubscription!.storedEvents;
    } catch (e) {
      log('Error requesting stored events: $e');
      rethrow;
    } finally {
      // Be sure to remove the subscription from the cache if it's not already removed
      if (_eventSubscriptionsCache.containsKey(subscriptionId)) {
        await closeSubscription(subscriptionId);
      }
    }
  }

  @override
  Future<RelayClientEventSubscription?> closeSubscription(
    String subscriptionId, {
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  }) async {
    log('Closing subscription: $subscriptionId in relay $_relayUrl');
    try {
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
    } catch (e) {
      log('Error closing subscription: $e');
      // Even if there's an error, remove the subscription from the cache
      _eventSubscriptionsCache.remove(subscriptionId);
      rethrow;
    } finally {
      // Disconnect if no more subscriptions left in the cache
      if (_eventSubscriptionsCache.isEmpty && _publishingEvents.isEmpty) {
        log('No more subscriptions or messages to publish left for relay $_relayUrl.');
        await disconnect();
      }
    }
  }

  @override
  Future<void> disconnect() async {
    await _connectionLock.synchronized(() async {
      // Check if already disconnected
      if (_isConnected) {
        try {
          log('Disconnecting from relay $_relayUrl');
          await _relayStreamSubscription?.cancel();
          _relayStreamSubscription = null;
          await _relayStreamProvider.disconnect();
          _isConnected = false;
        } catch (e) {
          log('Error during disconnect: $e');
          rethrow;
        }
      }
    });
  }

  @override
  Future<void> dispose({
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  }) async {
    await Future.wait(
      _eventSubscriptionsCache.keys.map((subscriptionId) {
        return closeSubscription(
          subscriptionId,
          waitForRelayClosedMessage: waitForRelayClosedMessage,
          timeoutSec: timeoutSec,
        );
      }),
    );
    await disconnect();
    await _relayStreamProvider.dispose();
  }

  Future<void> _ensureConnected() async {
    log('Ensuring connection to relay $_relayUrl');
    await _connectionLock.synchronized(() async {
      if (!_isConnected) {
        await _connect();
      }
    });
  }

  Future<void> _connect() async {
    try {
      log('Initializing relay client for relay $_relayUrl');

      await _relayStreamProvider.connect();
      _relayStreamSubscription = _relayStreamProvider.messages.listen(
        (message) {
          log('Received message from relay $_relayUrl: $message');
          _handleRelayMessage(message);
        },
        onError: (error) async {
          log('Stream error on relay $_relayUrl: $error');
          await disconnect();
          await _reconnect();
        },
        onDone: () async {
          log('Stream done on relay $_relayUrl');
          await disconnect();
          await _reconnect();
        },
        cancelOnError: true,
      );

      // Re-subscribe to subscriptions if any
      _resubscribe();

      log('Relay client successfully initialized for relay $_relayUrl');
      _isConnected = true;
      _retryAttempts = 0;
    } catch (e) {
      log('Error initializing relay client for relay $_relayUrl: $e');
      rethrow;
    }
  }

  Future<void> _reconnect() async {
    await _connectionLock.synchronized(
      () async {
        if (!_isConnected) {
          while (_retryAttempts < _maxRetryAttempts) {
            _retryAttempts++;
            final timeout = Duration(seconds: 2 * _retryAttempts);
            log('Reconnecting to relay $_relayUrl in $timeout seconds for attempt $_retryAttempts');
            await Future.delayed(timeout);

            try {
              // Reconnect
              await _connect();
              log('Reconnected successfully to relay $_relayUrl after $_retryAttempts attempts');
              break;
            } catch (e) {
              log('Error reconnecting to relay $_relayUrl: $e');
            }
          }
          if (_retryAttempts >= _maxRetryAttempts) {
            log('Max retry attempts reached for relay $_relayUrl');
            _retryAttempts = 0;
          }
        }
      },
    );
  }

  void _resubscribe() {
    log('Resubscribing to subscriptions in relay $_relayUrl');
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
