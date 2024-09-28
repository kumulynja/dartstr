import 'dart:async';
import 'dart:developer';

import 'package:nip01/src/data/models/client_message.dart';
import 'package:nip01/src/data/models/event.dart';
import 'package:nip01/src/data/models/filters.dart';
import 'package:nip01/src/data/models/relay_message.dart';
import 'package:nip01/src/data/providers/relay_connection_provider.dart';

abstract class RelayCommunication {
  Stream<Event> get events;
  Future<void> init();
  void requestEvents(String subscriptionId, List<Filters> filters);
  Future<bool> publishEvent(Event event);
  void closeSubscription(String subscriptionId);
  Future<void> disconnect();
  Future<void> dispose();
}

class RelayCommunicationImpl implements RelayCommunication {
  final RelayConnectionProviderImpl _relayConnectionProvider;
  StreamSubscription? _subscription;
  final StreamController<Event> _eventController = StreamController.broadcast();
  final Map<String, Completer<bool>> _publishingEvents = {};

  RelayCommunicationImpl(this._relayConnectionProvider);

  @override
  Stream<Event> get events => _eventController.stream;

  @override
  Future<void> init() async {
    await _relayConnectionProvider.connect();
    _subscription = _relayConnectionProvider.messages.listen(
      _handleRelayMessage,
      onError: (error) {
        log('Error listening to events: $error');
        _eventController.addError(error);
      },
      onDone: () {
        log('Event subscription done');
        _eventController.addError('Connection lost');
      },
    );
  }

  @override
  Future<bool> publishEvent(
    Event event, {
    int timeoutSec = 5,
  }) async {
    final completer = Completer<bool>();
    final message = ClientEventMessage(event: event);

    _publishingEvents[event.id] = completer; // Store completer with event ID

    _relayConnectionProvider.sendMessage(message);

    final isPublishedSuccessfully = await completer.future.timeout(
      Duration(seconds: timeoutSec),
      onTimeout: () {
        log('Publish event timeout: ${event.id}');
        return false; // Return false on timeout
      },
    );

    _publishingEvents.remove(event.id);

    return isPublishedSuccessfully;
  }

  @override
  void requestEvents(String subscriptionId, List<Filters> filters) {
    final message =
        ClientRequestMessage(subscriptionId: subscriptionId, filters: filters);
    _relayConnectionProvider.sendMessage(message);
  }

  @override
  void closeSubscription(String subscriptionId) async {
    final message = ClientCloseMessage(subscriptionId: subscriptionId);

    _relayConnectionProvider.sendMessage(message);
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _relayConnectionProvider.disconnect();
  }

  @override
  Future<void> dispose() async {
    await _eventController.close();
    await disconnect();
    await _relayConnectionProvider.dispose();
  }

  void _handleRelayMessage(RelayMessage message) {
    if (message is RelayEventMessage) {
      // Handle event message
      log('Received event: ${message.event.content}');

      // Publish the event to the stream
      _eventController.add(message.event);
    } else if (message is RelayNoticeMessage) {
      // Handle notice message
      log('Received notice: ${message.message}');
    } else if (message is RelayEndOfStreamMessage) {
      // Handle end of stream message
      log(
        'End of stored events for subscription: ${message.subscriptionId}',
      );
    } else if (message is RelayClosedMessage) {
      log(
        'Subscription closed by relay: ${message.subscriptionId} with message: ${message.message}',
      );

      _eventController
          .addError('Subscription closed by relay: ${message.message}');
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
