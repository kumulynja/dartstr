import 'dart:async';
import 'dart:developer';

import 'package:nip01/src/data/models/client_message.dart';
import 'package:nip01/src/data/models/relay_message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

abstract class RelayConnectionProvider {
  Stream<RelayMessage> get messages;
  Future<void> connect();
  void sendMessage(ClientMessage message);
  Future<void> disconnect();
  Future<void> dispose();
}

class RelayConnectionProviderImpl implements RelayConnectionProvider {
  final String _relayUrl;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<RelayMessage> _messageController =
      StreamController.broadcast();

  RelayConnectionProviderImpl(
    this._relayUrl,
  );

  @override
  Stream<RelayMessage> get messages => _messageController.stream;

  @override
  Future<void> connect() async {
    final wsUrl = Uri.parse(_relayUrl);
    _channel = WebSocketChannel.connect(wsUrl);
    await _channel?.ready;

    _subscription = _channel?.stream.listen((data) {
      final message = RelayMessage.fromSerialized(data);
      log('Received message: $message');
      _messageController.add(message);
    }, onError: (error) {
      log('Error listening to relay messages: $error');
      _messageController.addError(error);
    }, onDone: () {
      log('Relay messages subscription done');
      // Todo: Make custom error for this
      _messageController.addError('Connection lost');
    });
  }

  @override
  void sendMessage(ClientMessage message) {
    final serializedMessage = message.serialized;
    log('Sending message: $serializedMessage');
    _channel?.sink.add(serializedMessage);
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close(status.goingAway);
    _channel = null;
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
  }
}
