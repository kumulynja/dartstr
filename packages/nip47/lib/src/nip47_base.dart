import 'dart:async';
import 'dart:developer';

import 'package:dartstr_utils/dartstr_utils.dart';
import 'package:nip01/nip01.dart' as nip01;
import 'package:nip47/src/constants.dart';
import 'package:nip47/src/data/models/connection.dart';
import 'package:nip47/src/data/models/filters.dart';
import 'package:nip47/src/data/models/info_event.dart';
import 'package:nip47/src/data/models/request.dart';
import 'package:nip47/src/data/models/request_subscription.dart';
import 'package:nip47/src/data/models/response.dart';
import 'package:nip47/src/data/models/transaction.dart';
import 'package:nip47/src/enums/bitcoin_network.dart';
import 'package:nip47/src/enums/error_code.dart';
import 'package:nip47/src/enums/event_kind.dart';
import 'package:nip47/src/data/models/method.dart';

abstract class WalletService {
  List<Connection> get connections;
  Stream<Request> get requests;
  Future<Connection> addConnection({
    required String relayUrl,
    required List<Method> permittedMethods,
  });
  Future<void> restoreConnections(List<Connection> connections);
  Future<void> removeConnection(String pubkey);
  Future<List<Request>> getRequests({
    required String relayUrl,
    int? since,
  });
  Future<void> getInfoRequestHandled(
    GetInfoRequest request, {
    String alias,
    String color,
    String pubkey,
    BitcoinNetwork network,
    int blockHeight,
    String blockHash,
    required List<Method> methods,
  });
  Future<void> getBalanceRequestHandled(
    GetBalanceRequest request, {
    required int balanceSat,
  });
  Future<void> makeInvoiceRequestHandled(
    MakeInvoiceRequest request, {
    String? invoice,
    String? description,
    String? descriptionHash,
    String? preimage,
    required String paymentHash,
    required int amountSat,
    required int feesPaidSat,
    required int createdAt,
    required int expiresAt,
    required Map<dynamic, dynamic> metadata,
  });
  Future<void> payInvoiceRequestHandled(
    PayInvoiceRequest request, {
    required String preimage,
  });
  Future<void> multiPayInvoiceRequestHandled(
    MultiPayInvoiceRequest request, {
    required Map<String, String> preimageById,
  });
  Future<void> payKeysendRequestHandled(
    PayKeysendRequest request, {
    required String preimage,
  });
  Future<void> multiPayKeysendRequestHandled(
    MultiPayKeysendRequest request, {
    required Map<String, String> preimageById,
  });
  Future<void> lookupInvoiceRequestHandled(
    LookupInvoiceRequest request, {
    String? invoice,
    String? description,
    String? descriptionHash,
    String? preimage,
    required String paymentHash,
    required int amountSat,
    required int feesPaidSat,
    required int createdAt,
    int? expiresAt,
    int? settledAt,
    required Map<dynamic, dynamic> metadata,
  });
  Future<void> listTransactionsRequestHandled(
    ListTransactionsRequest request, {
    required List<Transaction> transactions,
  });
  Future<void> customRequestHandled(
    CustomRequest request, {
    required CustomResponse response,
  });
  Future<void> failedToHandleRequest(
    Request request, {
    required ErrorCode error,
  });
  Future<void> dispose();
}

class WalletServiceImpl implements WalletService {
  final nip01.KeyPair _walletKeyPair;
  final nip01.Nip01Repository _nip01Repository;
  final Map<String, RequestSubscription> _requestSubscriptionForRelay = {};
  final Map<String, Connection> _connections = {};
  final StreamController<Request> _requestController =
      StreamController.broadcast();

  WalletServiceImpl({
    required nip01.KeyPair walletKeyPair,
    required nip01.Nip01Repository nip01Repository,
  })  : _walletKeyPair = walletKeyPair,
        _nip01Repository = nip01Repository;

  @override
  List<Connection> get connections => _connections.values.toList();

  @override
  Stream<Request> get requests => _requestController.stream;

  @override
  Future<Connection> addConnection({
    required String relayUrl,
    required List<Method> permittedMethods,
  }) async {
    await _ensureRequestSubscription(relayUrl);

    // Generate a new random connection key pair
    final connectionKeyPair = nip01.KeyPair.generate();

    // Push permitted methods to relay with get info event
    final info = InfoEvent(permittedMethods: permittedMethods);

    final signedEvent = info.toSignedEvent(
      creatorKeyPair: _walletKeyPair,
      connectionPubkey: connectionKeyPair.publicKey,
      relayUrl: relayUrl,
    );

    final isPublished = await _nip01Repository.publishEvent(
      signedEvent,
      relayUrls: [relayUrl],
    );
    if (!isPublished) {
      throw Exception('Failed to publish event');
    }

    // Build the connection with URI so the user can share it with apps to connect
    //  its wallet.
    final connection = Connection(
      pubkey: connectionKeyPair.publicKey,
      permittedMethods: permittedMethods,
      relayUrl: relayUrl,
      uri: _buildConnectionUri(connectionKeyPair.privateKey, relayUrl),
    );
    // Save the connection in memory (user of the package should persist it securely)
    _connections[connectionKeyPair.publicKey] = connection;

    return connection;
  }

  @override
  Future<void> restoreConnections(List<Connection> connections) async {
    for (final connection in connections) {
      await _ensureRequestSubscription(connection.relayUrl);
      _connections[connection.pubkey] = connection;
    }
  }

  @override
  Future<void> removeConnection(String pubkey) async {
    final connectionRelay = _connections[pubkey]?.relayUrl;

    _connections.remove(pubkey);

    // If no more connections for the relay, cancel the request subscription
    if (connectionRelay != null &&
        _requestSubscriptionForRelay[connectionRelay] != null &&
        !_connections.values.any(
          (connection) => connection.relayUrl == connectionRelay,
        )) {
      // Unsubscribe for requests from the relay
      await _nip01Repository.unsubscribeFromEvents(
        _requestSubscriptionForRelay[connectionRelay]!.subscriptionId,
        relayUrls: [connectionRelay],
      );
      // Cancel the stream subscription
      _requestSubscriptionForRelay[connectionRelay]?.cancelStream();
      // Remove the subscription from the map
      _requestSubscriptionForRelay.remove(connectionRelay);
    }
  }

  @override
  Future<List<Request>> getRequests({
    required String relayUrl,
    int? since,
  }) async {
    final events = await _nip01Repository.getStoredEvents(
      [
        Filters.requests(
          walletPublicKey: _walletKeyPair.publicKey,
          since: since,
        )
      ],
      relayUrls: [relayUrl],
    );

    final requests = await Future.wait(
      events.map((event) async => await _tryToExtractValidRequest(event)),
    ).then(
      (requests) => requests.nonNulls.toList(),
    );

    return requests;
  }

  @override
  Future<void> getInfoRequestHandled(
    GetInfoRequest request, {
    String? alias,
    String? color,
    String? pubkey,
    BitcoinNetwork? network,
    int? blockHeight,
    String? blockHash,
    required List<Method> methods,
  }) async {
    // Todo: Add parameter validation
    final response = Response.getInfoResponse(
      alias: alias,
      color: color,
      pubkey: pubkey,
      network: network,
      blockHeight: blockHeight,
      blockHash: blockHash,
      methods: methods,
    );

    await _sendResponseForRequest(request: request, response: response);
  }

  @override
  Future<void> getBalanceRequestHandled(
    GetBalanceRequest request, {
    required int balanceSat,
  }) async {
    final response = Response.getBalanceResponse(balanceSat: balanceSat);

    await _sendResponseForRequest(request: request, response: response);
  }

  @override
  Future<void> makeInvoiceRequestHandled(
    MakeInvoiceRequest request, {
    String? invoice,
    String? description,
    String? descriptionHash,
    String? preimage,
    required String paymentHash,
    required int amountSat,
    required int feesPaidSat,
    required int createdAt,
    required int expiresAt,
    required Map<dynamic, dynamic> metadata,
  }) async {
    final response = Response.makeInvoiceResponse(
      invoice: invoice,
      description: description,
      descriptionHash: descriptionHash,
      preimage: preimage,
      paymentHash: paymentHash,
      amountSat: amountSat,
      feesPaidSat: feesPaidSat,
      createdAt: createdAt,
      expiresAt: expiresAt,
      metadata: metadata,
    );

    await _sendResponseForRequest(request: request, response: response);
  }

  @override
  Future<void> payInvoiceRequestHandled(
    PayInvoiceRequest request, {
    required String preimage,
  }) async {
    final response = Response.payInvoiceResponse(preimage: preimage);

    await _sendResponseForRequest(request: request, response: response);
  }

  @override
  Future<void> multiPayInvoiceRequestHandled(
    MultiPayInvoiceRequest request, {
    required Map<String, String> preimageById,
  }) async {
    for (var entry in preimageById.entries) {
      final response = Response.multiPayInvoiceResponse(
        preimage: entry.value,
        id: entry.key,
      );

      await _sendResponseForRequest(request: request, response: response);
    }
  }

  @override
  Future<void> payKeysendRequestHandled(
    PayKeysendRequest request, {
    required String preimage,
  }) async {
    final response = Response.payKeysendResponse(preimage: preimage);

    await _sendResponseForRequest(request: request, response: response);
  }

  @override
  Future<void> multiPayKeysendRequestHandled(
    MultiPayKeysendRequest request, {
    required Map<String, String> preimageById,
  }) async {
    for (var entry in preimageById.entries) {
      final response = Response.multiPayKeysendResponse(
        preimage: entry.value,
        id: entry.key,
      );

      await _sendResponseForRequest(request: request, response: response);
    }
  }

  @override
  Future<void> lookupInvoiceRequestHandled(
    LookupInvoiceRequest request, {
    String? invoice,
    String? description,
    String? descriptionHash,
    String? preimage,
    required String paymentHash,
    required int amountSat,
    required int feesPaidSat,
    required int createdAt,
    int? expiresAt,
    int? settledAt,
    required Map<dynamic, dynamic> metadata,
  }) async {
    final response = Response.lookupInvoiceResponse(
      invoice: invoice,
      description: description,
      descriptionHash: descriptionHash,
      preimage: preimage,
      paymentHash: paymentHash,
      amountSat: amountSat,
      feesPaidSat: feesPaidSat,
      createdAt: createdAt,
      expiresAt: expiresAt,
      settledAt: settledAt,
      metadata: metadata,
    );

    await _sendResponseForRequest(request: request, response: response);
  }

  @override
  Future<void> listTransactionsRequestHandled(
    ListTransactionsRequest request, {
    required List<Transaction> transactions,
  }) async {
    final response =
        Response.listTransactionsResponse(transactions: transactions);

    await _sendResponseForRequest(request: request, response: response);
  }

  @override
  Future<void> customRequestHandled(
    CustomRequest request, {
    required CustomResponse response,
  }) async {
    await _sendResponseForRequest(request: request, response: response);
  }

  @override
  Future<void> failedToHandleRequest(
    Request request, {
    required ErrorCode error,
  }) async {
    final response = Response.errorResponse(
      method: request.method,
      error: error,
    );

    await _sendResponseForRequest(request: request, response: response);
  }

  @override
  Future<void> dispose() async {
    await _requestController.close();
    for (final connection in _connections.values) {
      await removeConnection(connection.pubkey);
    }
  }

  String _buildConnectionUri(String secret, String relayUrl) {
    return '${Constants.uriProtocol}://'
        '${_walletKeyPair.publicKey}?'
        'secret=$secret&'
        'relay=$relayUrl';
  }

  Future<void> _ensureRequestSubscription(String relayUrl) async {
    if (_requestSubscriptionForRelay.containsKey(relayUrl)) return;

    final requestSubscription = await _subscribeToRequests(
      relayUrl,
    );

    _requestSubscriptionForRelay[relayUrl] = requestSubscription;
  }

  Future<RequestSubscription> _subscribeToRequests(
    String relayUrl,
  ) async {
    // Generate a new random subscription ID
    final subscriptionId = SecretGenerator.secretHex(64);

    // Listen to requests from the dedicated nwc relay
    final events = await _nip01Repository.subscribeToEvents(
      subscriptionId,
      [
        Filters.requests(
          walletPublicKey: _walletKeyPair.publicKey,
        )
      ],
      relayUrls: [relayUrl],
    );

    final streamSubscription = events.listen(
      _handleEvent,
    );

    return RequestSubscription(
      relayUrl: relayUrl,
      subscriptionId: subscriptionId,
      streamSubscription: streamSubscription,
    );
  }

  Future<Request?> _tryToExtractValidRequest(nip01.Event event) async {
    if (event.kind != EventKind.request.value) {
      // The wallet should only process NIP-47 request event kinds
      return null;
    }

    if (_isExpired(event)) return null;

    Request request = Request.fromEvent(
      event,
      _walletKeyPair.privateKey,
    );

    final errorResponse = _validateRequest(request);
    if (errorResponse != null) {
      await _sendResponseForRequest(
        response: errorResponse,
        request: request,
      );
      return null;
    }

    return request;
  }

  void _handleEvent(nip01.Event event) async {
    try {
      final request = await _tryToExtractValidRequest(event);

      if (request == null) return;

      _requestController.add(request);
    } catch (e) {
      log('Error handling event: $e');
      return;
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

  ErrorResponse? _validateRequest(Request request) {
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

    final relayUrl = _connections[request.connectionPubkey]?.relayUrl;
    if (relayUrl == null) {
      log('No relay found for request: $request');
      throw Exception('No relay found for request');
    }

    final isPublished = await _nip01Repository
        .publishEvent(signedResponseEvent, relayUrls: [relayUrl]);

    if (!isPublished) {
      // Todo: use better logging and/or add a retry mechanism
      log(
        'Failed to publish response: $signedResponseEvent for request: $request',
      );
      throw Exception('Failed to publish response');
    }
  }
}
