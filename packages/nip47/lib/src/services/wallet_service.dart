import 'dart:async';
import 'dart:developer';
import 'dart:math' show pow, min;

import 'package:dartstr_utils/dartstr_utils.dart';
import 'package:nip01/nip01.dart' as nip01;
import 'package:nip47/src/constants.dart';
import 'package:nip47/src/data/models/connection.dart';
import 'package:nip47/src/data/models/filters.dart';
import 'package:nip47/src/data/models/info_event.dart';
import 'package:nip47/src/data/models/request.dart';
import 'package:nip47/src/data/models/response.dart';
import 'package:nip47/src/enums/error_code.dart';
import 'package:nip47/src/enums/event_kind.dart';
import 'package:nip47/src/enums/method.dart';

abstract class WalletService {
  List<Connection> get connections;
  Stream<Request> get requests;
  Future<void> connect();
  Future<Connection> addConnection({
    required String relayUrl,
    required List<Method> permittedMethods,
  });
  void removeConnection(String pubkey);
  Future<void> handleResponse({
    required Response response,
    required Request request,
  });
  Future<void> disconnect();
  Future<void> dispose();
}

class WalletServiceImpl implements WalletService {
  final nip01.KeyPair _walletKeyPair;
  final nip01.RelayCommunication _relayCommunication;
  int? _lastRequestTimestamp;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int _retryCount = 0;
  final Map<String, Connection> _connections = {};
  final String _subscriptionId = SecretGenerator.secretHex(64);
  final StreamController<Request> _requestController =
      StreamController.broadcast();

  WalletServiceImpl(
    this._walletKeyPair,
    this._relayCommunication,
    List<Connection> connections,
    this._lastRequestTimestamp,
  ) {
    if (connections.isNotEmpty) {
      for (final connection in connections) {
        _connections[connection.pubkey] = connection;
      }
      connect();
    }
  }

  @override
  List<Connection> get connections => _connections.values.toList();

  @override
  Stream<Request> get requests => _requestController.stream;

  @override
  Future<void> connect({int retrySeconds = 1}) async {
    try {
      await _relayCommunication.init();
      print('...connected to relay.');
      // Start listening to NWC requests for the wallet
      await _subscribeToRequests();
      print('...subscribed to requests.');
      // Was able to subscribe to requests, so reset the retry count
      _retryCount = 0;
    } catch (e) {
      log('Error connecting: $e');
      await disconnect();
      await _scheduleReconnect();
    }
  }

  @override
  Future<Connection> addConnection({
    required String relayUrl,
    required List<Method> permittedMethods,
  }) async {
    final connectionKeyPair = nip01.KeyPair.generate();

    // Push permitted methods to relay with get info event
    final info = InfoEvent(permittedMethods: permittedMethods);
    final signedEvent = info.toSignedEvent(
      creatorKeyPair: _walletKeyPair,
      connectionPubkey: connectionKeyPair.publicKey,
      relayUrl: relayUrl,
    );

    final isPublished = await _relayCommunication.publishEvent(signedEvent);
    if (!isPublished) {
      throw Exception('Failed to publish event');
    }

    // Build the connection with URI so the user can share it with apps to connect
    //  its wallet.
    final connection = Connection(
      pubkey: connectionKeyPair.publicKey,
      permittedMethods: permittedMethods,
      uri: _buildConnectionUri(connectionKeyPair.privateKey, relayUrl),
    );
    // Save the connection in memory (user of the package should persist it)
    _connections[connectionKeyPair.publicKey] = connection;

    return connection;
  }

  @override
  void removeConnection(String pubkey) {
    _connections.remove(pubkey);
  }

  @override
  Future<void> handleResponse({
    required Response response,
    required Request request,
  }) async {
    await _sendResponseForRequest(response: response, request: request);
  }

  @override
  Future<void> disconnect() async {
    // Cancel the reconnect timer if it's running to avoid reconnecting
    _reconnectTimer?.cancel();
    // Close the subscription on the relay (Todo: check if relay didn't close it already through the error event)
    _relayCommunication.closeSubscription(_subscriptionId);
    // Stop listening to events
    await _subscription?.cancel();
    _subscription = null;
    // Disconnect from the relay
    await _relayCommunication.disconnect();
  }

  @override
  Future<void> dispose() async {
    await _requestController.close();
    await disconnect();
    await _relayCommunication.dispose();
  }

  Future<void> _subscribeToRequests() async {
    // Listen to events from the nostr relay
    _subscription = _relayCommunication.events.listen(
      _handleEvent,
      onError: (error) async {
        log('Error listening to requests: $error');
        await disconnect();
        await _scheduleReconnect();
      },
      onDone: () async {
        log('Request subscription done');
        await disconnect();
        await _scheduleReconnect();
      },
    );

    // Request nwc events for the wallet
    _relayCommunication.requestEvents(
      _subscriptionId,
      [
        Filters.requests(
          walletPublicKey: _walletKeyPair.publicKey,
          since: _lastRequestTimestamp,
        )
      ],
    );
  }

  Future<void> _scheduleReconnect() async {
    print('Scheduling reconnect in ${pow(2, _retryCount).toInt()} seconds');
    // Exponential backoff strategy with min 1 second and max 64 seconds
    final delay = Duration(seconds: pow(2, _retryCount).toInt());
    _retryCount = min(_retryCount + 1, 6);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      delay,
      () async {
        // Call the connect function again
        print('Reconnecting...');
        await connect();
      },
    );
  }

  String _buildConnectionUri(String secret, String relayUrl) {
    return '${Constants.uriProtocol}://'
        '${_walletKeyPair.publicKey}?'
        'secret=$secret&'
        'relay=$relayUrl';
  }

  void _handleEvent(nip01.Event event) async {
    try {
      if (event.kind != EventKind.request.value) {
        // The wallet should only process NIP-47 request event kinds
        return;
      }

      if (_isExpired(event)) return;

      Request request = Request.fromEvent(
        event,
        _walletKeyPair.privateKey,
      );

      final errorResponse = validateRequest(request);

      if (errorResponse != null) {
        await _sendResponseForRequest(
          response: errorResponse,
          request: request,
        );
        return;
      }

      _requestController.add(request);
    } catch (e) {
      log('Error handling event: $e');
      return;
    } finally {
      // Update the last request timestamp so at reconnect we can request events
      //  from this timestamp and not miss any events and not replay events from
      //  the timestamp the user passed when initializing Wallet either.
      _lastRequestTimestamp = event.createdAt;
    }
  }

  bool _isExpired(nip01.Event event) {
    for (var tag in event.tags) {
      if (tag[0] == 'expiration') {
        final expirationTimestamp = int.tryParse(tag[1]);
        if (expirationTimestamp != null &&
            DateTime.now().millisecondsSinceEpoch ~/ 1000 >
                expirationTimestamp) {
          return true;
        }
      }
    }
    return false;
  }

  ErrorResponse? validateRequest(Request request) {
    // 1. First make sure the request is a known request
    if (request is UnknownRequest) {
      // NotImplemented error response
      return Response.errorResponse(
        method: Method.unknown,
        error: ErrorCode.notImplemented,
        unknownMethod: request.unknownMethod,
      ) as ErrorResponse;
    }

    // 2. Check if the known request is coming from a trusted connection
    final connection = _connections[request.connectionPubkey];
    if (connection == null) {
      // Unauthorized error response
      return Response.errorResponse(
        method: request.method,
        error: ErrorCode.unauthorized,
      ) as ErrorResponse;
    }

    // 3. Check if the requested method is permitted for the known connection
    if (!connection.permittedMethods.contains(request.method)) {
      // Restricted error response
      return Response.errorResponse(
        method: request.method,
        error: ErrorCode.restricted,
      ) as ErrorResponse;
    }

    return null; // Request is valid
  }

  Future<void> _sendResponseForRequest({
    required Response response,
    required Request request,
  }) async {
    final signedResponseEvent = response.toSignedEvent(
      creatorKeyPair: _walletKeyPair,
      requestId: request.id,
      connectionPubkey: request.connectionPubkey,
    );
    final isPublished =
        await _relayCommunication.publishEvent(signedResponseEvent);

    if (!isPublished) {
      // Todo: use better logging and/or add a retry mechanism
      log(
        'Failed to publish response: $signedResponseEvent for request: $request',
      );
      throw Exception('Failed to publish response');
    }
  }
}
