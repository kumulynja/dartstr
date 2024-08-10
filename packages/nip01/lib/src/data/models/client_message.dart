import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:nip01/nip01.dart';

// Abstract base class for messages from client to relay
@immutable
abstract class ClientMessage extends Equatable {
  const ClientMessage();

  const factory ClientMessage.clientEventMessage({
    required Event event,
  }) = ClientEventMessage;
  const factory ClientMessage.clientRequesMessage({
    required String subscriptionId,
    List<Filters>? filters,
  }) = ClientRequestMessage;
  const factory ClientMessage.clientCloseMessage({
    required String subscriptionId,
  }) = ClientCloseMessage;

  String get serialized;
}

// Subclass for messages to publish events
@immutable
class ClientEventMessage extends ClientMessage {
  final Event event;

  const ClientEventMessage({required this.event});

  @override
  String get serialized {
    final message = [ClientMessageType.event.value, event.toMap()];
    return jsonEncode(message);
  }

  @override
  List<Object?> get props => [event];
}

// Subclass for messages to request events and subscribe to new updates
class ClientRequestMessage extends ClientMessage {
  final String subscriptionId;
  final List<Filters>? filters;

  const ClientRequestMessage({
    required this.subscriptionId,
    this.filters,
  });

  @override
  String get serialized {
    final message = [
      ClientMessageType.req.value,
      subscriptionId,
      if (filters != null) ...filters!.map((f) => f.toMap()),
    ];
    return jsonEncode(message);
  }

  @override
  List<Object?> get props => [subscriptionId, filters];
}

// Subclass for messages to close a subscription
@immutable
class ClientCloseMessage extends ClientMessage {
  final String subscriptionId;

  const ClientCloseMessage({required this.subscriptionId});

  @override
  String get serialized {
    final message = [ClientMessageType.close.value, subscriptionId];
    return jsonEncode(message);
  }

  @override
  List<Object?> get props => [subscriptionId];
}
