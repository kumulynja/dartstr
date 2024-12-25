import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:nip01/src/data/models/event.dart';
import 'package:nip01/src/enums/relay_message_type.dart';

// Abstract base class for messages from relay to client
@immutable
abstract class RelayMessage extends Equatable {
  const RelayMessage();

  factory RelayMessage.fromSerialized(String serialized) {
    final message = jsonDecode(serialized);

    if (message is List && message.isNotEmpty) {
      final type = RelayMessageType.fromValue(message[0]);

      switch (type) {
        case RelayMessageType.event:
          return RelayEventMessage(
            subscriptionId: message[1],
            event: Event.fromMap(message[2]),
          );
        case RelayMessageType.ok:
          return RelayOkMessage(
            eventId: message[1],
            accepted: message[2],
            message: message[3],
          );
        case RelayMessageType.eose:
          return RelayEndOfStreamMessage(
            subscriptionId: message[1],
          );
        case RelayMessageType.closed:
          return RelayClosedMessage(
            subscriptionId: message[1],
            message: message[2],
          );
        case RelayMessageType.notice:
          return RelayNoticeMessage(
            message: message[1],
          );
      }
    } else {
      throw ArgumentError('Invalid message format');
    }
  }

  @override
  List<Object?> get props => [];
}

// Subclass for messages that contain an event
@immutable
class RelayEventMessage extends RelayMessage {
  final String subscriptionId;
  final Event event;

  const RelayEventMessage({required this.subscriptionId, required this.event});

  @override
  List<Object?> get props => [subscriptionId, event];
}

// Subclass for messages to indicate acceptance or denial of an EVENT message
@immutable
class RelayOkMessage extends RelayMessage {
  final String eventId;
  final bool accepted;
  final String message;

  const RelayOkMessage({
    required this.eventId,
    required this.accepted,
    required this.message,
  });

  @override
  List<Object?> get props => [eventId, accepted, message];
}

// Subclass for messages to indicate the end of stored events
@immutable
class RelayEndOfStreamMessage extends RelayMessage {
  final String subscriptionId;

  const RelayEndOfStreamMessage({required this.subscriptionId});

  @override
  List<Object?> get props => [subscriptionId];
}

// Subclass for messages to indicate that a subscription was ended on the server side
@immutable
class RelayClosedMessage extends RelayMessage {
  final String subscriptionId;
  final String message;

  const RelayClosedMessage({
    required this.subscriptionId,
    required this.message,
  });

  @override
  List<Object?> get props => [subscriptionId, message];
}

// Subclass for messages to send human-readable error messages or other notices
@immutable
class RelayNoticeMessage extends RelayMessage {
  final String message;

  const RelayNoticeMessage({required this.message});

  @override
  List<Object?> get props => [message];
}
