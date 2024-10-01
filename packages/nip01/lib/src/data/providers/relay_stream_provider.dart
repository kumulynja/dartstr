import 'dart:async';
import 'dart:developer';

import 'package:nip01/src/data/models/client_message.dart';
import 'package:nip01/src/data/models/relay_message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

abstract class RelayStreamProvider {
  Stream<RelayMessage> get messages;
  Future<void> connect();
  void sendMessage(ClientMessage message);
  Future<void> disconnect();
  Future<void> dispose();
}

class RelayStreamProviderImpl implements RelayStreamProvider {
  final String _relayUrl;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  final StreamController<RelayMessage> _messageController =
      StreamController.broadcast();

  RelayStreamProviderImpl(
    this._relayUrl,
  );

  @override
  Stream<RelayMessage> get messages => _messageController.stream;

  @override
  Future<void> connect() async {
    try {
      if (_channel != null) {
        disconnect();
      }

      log('Attempting to connect to relay: $_relayUrl');

      _channel = WebSocketChannel.connect(Uri.parse(_relayUrl));
      await _channel!.ready;

      _subscription = _channel?.stream.listen(
        (data) {
          final message = RelayMessage.fromSerialized(data);
          log('Received message from relay $_relayUrl: $message');
          _messageController.add(message);
        },
        onError: (error) {
          log('Websocket error on relay $_relayUrl: $error');
          _messageController.addError(error);
          _isConnected = false;
        },
        onDone: () {
          log('Websocket done on relay $_relayUrl');
          _messageController.addError('Connection lost');
          _isConnected = false;
        },
        cancelOnError: true,
      );

      _isConnected = true;
      log('Successfully connected to relay: $_relayUrl');
    } catch (e) {
      log('Error connecting to relay: $e');
      _isConnected = false;
      rethrow;
    }
  }

  @override
  void sendMessage(ClientMessage message) {
    if (!_isConnected || _channel == null) {
      throw Exception('Not connected to relay');
    }

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
