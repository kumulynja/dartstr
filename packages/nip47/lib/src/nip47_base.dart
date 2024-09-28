import 'dart:developer';

import 'package:nip01/nip01.dart';
import 'package:nip47/src/data/models/connection.dart';
import 'package:nip47/src/data/models/request.dart';
import 'package:nip47/src/data/models/response.dart';
import 'package:nip47/src/data/models/transaction.dart';
import 'package:nip47/src/enums/bitcoin_network.dart';
import 'package:nip47/src/enums/error_code.dart';
import 'package:nip47/src/enums/method.dart';
import 'package:nip47/src/services/wallet_service.dart';

class Wallet {
  // Private fields
  final String _relayUrl;
  final KeyPair _walletKeyPair;
  late WalletService _walletService;

  // Public fields
  Stream<Request> get nwcRequests => _walletService.requests;

  // Private constructor
  Wallet._(
    this._walletKeyPair,
    this._relayUrl,
    List<Connection> connections,
    int? lastRequestTimestamp,
  ) {
    _walletService = WalletServiceImpl(
      _walletKeyPair,
      RelayCommunicationImpl(
        RelayConnectionProviderImpl(
          _relayUrl,
        ),
      ),
      connections,
      lastRequestTimestamp,
    );
  }

  // Singleton instance
  static Wallet? _instance;

  // Factory constructor
  factory Wallet({
    required KeyPair walletKeyPair,
    required String relayUrl,
    List<Connection> connections = const [],
    int? lastRequestTimestamp,
  }) {
    _instance ??= Wallet._(
      walletKeyPair,
      relayUrl,
      connections,
      lastRequestTimestamp,
    );
    return _instance!;
  }

  Future<Connection> addConnection({
    required List<Method> permittedMethods,
  }) async {
    // If first active connection, connect the _walletService
    if (_walletService.connections.isEmpty) {
      await _walletService.connect();
    }

    final connection = await _walletService.addConnection(
      relayUrl: _relayUrl,
      permittedMethods: permittedMethods,
    );

    log('Connection URI: ${connection.uri}');

    return connection;
  }

  Future<void> removeConnection(String pubkey) async {
    _walletService.removeConnection(pubkey);

    // Disconnect from the relay's websocket if no active connections left
    if (_walletService.connections.isEmpty) {
      await _walletService.disconnect();
    }
  }

  Future<void> getInfoRequestHandled(
    GetInfoRequest request, {
    required String alias,
    required String color,
    required String pubkey,
    required BitcoinNetwork network,
    required int blockHeight,
    required String blockHash,
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

    await _walletService.handleResponse(request: request, response: response);
  }

  Future<void> getBalanceRequestHandled(
    GetBalanceRequest request, {
    required int balanceSat,
  }) async {
    final response = Response.getBalanceResponse(balanceSat: balanceSat);

    await _walletService.handleResponse(request: request, response: response);
  }

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

    await _walletService.handleResponse(request: request, response: response);
  }

  Future<void> payInvoiceRequestHandled(
    PayInvoiceRequest request, {
    required String preimage,
  }) async {
    final response = Response.payInvoiceResponse(preimage: preimage);

    await _walletService.handleResponse(request: request, response: response);
  }

  Future<void> multiPayInvoiceRequestHandled(
    MultiPayInvoiceRequest request, {
    required Map<String, String> preimageById,
  }) async {
    for (var entry in preimageById.entries) {
      final response = Response.multiPayInvoiceResponse(
        preimage: entry.value,
        id: entry.key,
      );

      await _walletService.handleResponse(request: request, response: response);
    }
  }

  Future<void> payKeysendRequestHandled(
    PayKeysendRequest request, {
    required String preimage,
  }) async {
    final response = Response.payKeysendResponse(preimage: preimage);

    await _walletService.handleResponse(request: request, response: response);
  }

  Future<void> multiPayKeysendRequestHandled(
    MultiPayKeysendRequest request, {
    required Map<String, String> preimageById,
  }) async {
    for (var entry in preimageById.entries) {
      final response = Response.multiPayKeysendResponse(
        preimage: entry.value,
        id: entry.key,
      );

      await _walletService.handleResponse(request: request, response: response);
    }
  }

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

    await _walletService.handleResponse(request: request, response: response);
  }

  Future<void> listTransactionsRequestHandled(
    ListTransactionsRequest request, {
    required List<Transaction> transactions,
  }) async {
    final response =
        Response.listTransactionsResponse(transactions: transactions);

    await _walletService.handleResponse(request: request, response: response);
  }

  Future<void> failedToHandleRequest(
    Request request, {
    required ErrorCode error,
  }) async {
    final response = Response.errorResponse(
      method: request.method,
      error: error,
    );

    await _walletService.handleResponse(request: request, response: response);
  }

  // After disposing, the instance is no longer usable
  Future<void> dispose() async {
    await _walletService.dispose();
    _instance = null;
  }
}
