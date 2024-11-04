import 'dart:async';

import 'package:nip01/src/data/models/event.dart';
import 'package:nip01/src/data/models/filters.dart';

class RelayClientEventSubscription {
  final String subscriptionId;
  final List<Filters> filters;
  final Function(List<Event>)? onEose;
  final List<Event> _storedEvents = [];
  // Completer for end of stored events message from relay
  final Completer _eose = Completer();
  // Completer for close message from relay
  final Completer<void> _closed = Completer<void>();
  final StreamController<Event> _eventController = StreamController.broadcast();

  RelayClientEventSubscription({
    required this.subscriptionId,
    required this.filters,
    this.onEose,
  });

  Stream<Event> get events => _eventController.stream.asBroadcastStream();
  List<Event> get storedEvents => _storedEvents;

  void addEvent(Event event) {
    if (!_eose.isCompleted) {
      _storedEvents.add(event);
    }
    _eventController.add(event);
  }

  void endOfStoredEvents() {
    if (_eose.isCompleted) {
      return;
    }
    _eose.complete();
    onEose?.call(_storedEvents);
  }

  Future<void> waitForEose() async {
    return _eose.future;
  }

  // Wait for the close message from the relay
  Future<void> waitForClose() async {
    return _closed.future;
  }

  // Mark the subscription as closed by the relay
  void markClosed() {
    _closed.complete();
  }

  void dispose() {
    _eventController.close();
  }
}
