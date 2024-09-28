import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:nip01/nip01.dart' as nip01;
import 'package:nip04/nip04.dart';
import 'package:nip47/src/data/models/transaction.dart';
import 'package:nip47/src/enums/bitcoin_network.dart';
import 'package:nip47/src/enums/error_code.dart';
import 'package:nip47/src/enums/event_kind.dart';
import 'package:nip47/src/enums/method.dart';
import 'package:nip47/src/enums/transaction_type.dart';

@immutable
abstract class Response extends Equatable {
  final String resultType;
  final ErrorCode? error;
  final Map<String, dynamic>? result;

  const Response({
    required this.resultType,
    this.error,
    this.result,
  });

  factory Response.getInfoResponse({
    required String alias,
    required String color,
    required String pubkey,
    required BitcoinNetwork network,
    required int blockHeight,
    required String blockHash,
    required List<Method> methods,
  }) = GetInfoResponse;

  factory Response.getBalanceResponse({
    required int balanceSat,
  }) = GetBalanceResponse;

  factory Response.makeInvoiceResponse({
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
  }) = MakeInvoiceResponse;

  factory Response.payInvoiceResponse({
    required String preimage,
  }) = PayInvoiceResponse;

  factory Response.multiPayInvoiceResponse({
    required String id,
    required String preimage,
  }) = MultiPayInvoiceResponse;

  factory Response.payKeysendResponse({
    required String preimage,
  }) = PayKeysendResponse;

  factory Response.multiPayKeysendResponse({
    required String id,
    required String preimage,
  }) = MultiPayKeysendResponse;

  factory Response.lookupInvoiceResponse({
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
  }) = LookupInvoiceResponse;

  factory Response.listTransactionsResponse({
    required List<Transaction> transactions,
  }) = ListTransactionsResponse;

  factory Response.errorResponse({
    required Method method,
    required ErrorCode error,
    String unknownMethod,
  }) = ErrorResponse;

  nip01.Event toSignedEvent({
    required nip01.KeyPair creatorKeyPair,
    required String requestId,
    required String connectionPubkey,
  }) {
    final content = jsonEncode(
      {
        'resultType': resultType,
        if (error != null)
          'error': {
            'code': error!.value,
            'message': error!.message,
          },
        if (result != null) 'result': result,
      },
    );
    final encryptedContent = Nip04.encrypt(
      content,
      creatorKeyPair.privateKey,
      connectionPubkey,
    );

    final multiPayId = this is MultiPayInvoiceResponse
        ? (this as MultiPayInvoiceResponse).id
        : this is MultiPayKeysendResponse
            ? (this as MultiPayKeysendResponse).id
            : null;

    final partialEvent = nip01.Event(
      pubkey: creatorKeyPair.publicKey,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: EventKind.response.value,
      tags: [
        ['e', requestId],
        ['p', connectionPubkey],
        if (multiPayId != null) ['d', multiPayId],
      ],
      content: encryptedContent,
    );

    final eventId = partialEvent.id;
    final signedEvent = partialEvent.copyWith(
      id: eventId,
      sig: creatorKeyPair.sign(eventId),
    );

    return signedEvent;
  }

  @override
  List<Object?> get props => [resultType, error, result];
}

// Subclass for the get_info response
@immutable
class GetInfoResponse extends Response {
  final String alias;
  final String color;
  final String pubkey;
  final BitcoinNetwork network;
  final int blockHeight;
  final String blockHash;
  final List<Method> methods;

  GetInfoResponse({
    required this.alias,
    required this.color,
    required this.pubkey,
    required this.network,
    required this.blockHeight,
    required this.blockHash,
    required this.methods,
  }) : super(
          resultType: Method.getInfo.plaintext,
          result: {
            'alias': alias,
            'color': color,
            'pubkey': pubkey,
            'network': network.name,
            'blockHeight': blockHeight,
            'blockHash': blockHash,
            'methods': methods.map((method) => method.plaintext).toList(),
          },
        );

  @override
  List<Object?> get props => [
        ...super.props,
        alias,
        color,
        pubkey,
        network,
        blockHeight,
        blockHash,
        methods,
      ];
}

// Subclass for the get_balance response
@immutable
class GetBalanceResponse extends Response {
  final int balanceSat;

  GetBalanceResponse({
    required this.balanceSat,
  }) : super(resultType: Method.getBalance.plaintext, result: {
          'balance': balanceSat * 1000, // user's balance in msats
        });

  @override
  List<Object?> get props => [...super.props, balanceSat];
}

// Subclass for the make_invoice response
@immutable
class MakeInvoiceResponse extends Response {
  final String? invoice;
  final String? description;
  final String? descriptionHash;
  final String? preimage;
  final String paymentHash;
  final int amountSat;
  final int feesPaidSat;
  final int createdAt;
  final int? expiresAt;
  final Map<dynamic, dynamic> metadata;

  MakeInvoiceResponse({
    this.invoice,
    this.description,
    this.descriptionHash,
    this.preimage,
    required this.paymentHash,
    required this.amountSat,
    required this.feesPaidSat,
    required this.createdAt,
    this.expiresAt,
    required this.metadata,
  }) : super(
          resultType: Method.makeInvoice.plaintext,
          result: {
            'type': TransactionType.incoming.name,
            if (invoice != null) 'invoice': invoice,
            if (description != null) 'description': description,
            if (descriptionHash != null) 'descriptionHash': descriptionHash,
            if (preimage != null) 'preimage': preimage,
            'paymentHash': paymentHash,
            'amount': amountSat * 1000, // invoice amount in msats
            'feesPaid': feesPaidSat * 1000, // fees paid in msats
            'createdAt': createdAt,
            if (expiresAt != null) 'expiresAt': expiresAt,
            'metadata': metadata,
          },
        );

  @override
  List<Object?> get props => [
        ...super.props,
        invoice,
        description,
        descriptionHash,
        preimage,
        paymentHash,
        amountSat,
        feesPaidSat,
        createdAt,
        expiresAt,
        metadata,
      ];
}

@immutable
class PayInvoiceResponse extends Response {
  final String preimage;

  PayInvoiceResponse({
    required this.preimage,
  }) : super(
          resultType: Method.payInvoice.plaintext,
          result: {
            'preimage': preimage,
          },
        );

  @override
  List<Object?> get props => [...super.props, preimage];
}

@immutable
class MultiPayInvoiceResponse extends Response {
  final String id;
  final String preimage;

  MultiPayInvoiceResponse({
    required this.id,
    required this.preimage,
  }) : super(
          resultType: Method.multiPayInvoice.plaintext,
          result: {
            'preimage': preimage,
          },
        );

  @override
  List<Object?> get props => [...super.props, id, preimage];
}

@immutable
class PayKeysendResponse extends Response {
  final String preimage;

  PayKeysendResponse({
    required this.preimage,
  }) : super(
          resultType: Method.payKeysend.plaintext,
          result: {
            'preimage': preimage,
          },
        );

  @override
  List<Object?> get props => [...super.props, preimage];
}

@immutable
class MultiPayKeysendResponse extends Response {
  final String id;
  final String preimage;

  MultiPayKeysendResponse({
    required this.id,
    required this.preimage,
  }) : super(
          resultType: Method.multiPayKeysend.plaintext,
          result: {
            'preimage': preimage,
          },
        );

  @override
  List<Object?> get props => [...super.props, id, preimage];
}

@immutable
class LookupInvoiceResponse extends Response {
  final String? invoice;
  final String? description;
  final String? descriptionHash;
  final String? preimage;
  final String paymentHash;
  final int amountSat;
  final int feesPaidSat;
  final int createdAt;
  final int? expiresAt;
  final int? settledAt;
  final Map<dynamic, dynamic> metadata;

  LookupInvoiceResponse({
    this.invoice,
    this.description,
    this.descriptionHash,
    this.preimage,
    required this.paymentHash,
    required this.amountSat,
    required this.feesPaidSat,
    required this.createdAt,
    this.expiresAt,
    this.settledAt,
    required this.metadata,
  }) : super(
          resultType: Method.lookupInvoice.plaintext,
          result: {
            'type': TransactionType.incoming.name,
            if (invoice != null) 'invoice': invoice,
            if (description != null) 'description': description,
            if (descriptionHash != null) 'descriptionHash': descriptionHash,
            if (preimage != null) 'preimage': preimage,
            'paymentHash': paymentHash,
            'amount': amountSat * 1000, // invoice amount in msats
            'feesPaid': feesPaidSat * 1000, // fees paid in msats
            'createdAt': createdAt,
            if (expiresAt != null) 'expiresAt': expiresAt,
            if (settledAt != null) 'settledAt': settledAt,
            'metadata': metadata,
          },
        );

  @override
  List<Object?> get props => [
        ...super.props,
        invoice,
        description,
        descriptionHash,
        preimage,
        paymentHash,
        amountSat,
        feesPaidSat,
        createdAt,
        expiresAt,
        settledAt,
        metadata,
      ];
}

@immutable
class ListTransactionsResponse extends Response {
  final List<Transaction> transactions;

  ListTransactionsResponse({
    required this.transactions,
  }) : super(
          resultType: Method.listTransactions.plaintext,
          result: {
            'transactions': transactions
              ..sort((a, b) =>
                  a.createdAt -
                  b.createdAt) // Ensure transactions are in descending order
              ..map((transaction) => {
                    'type': transaction.type.name,
                    if (transaction.invoice != null)
                      'invoice': transaction.invoice,
                    if (transaction.description != null)
                      'description': transaction.description,
                    if (transaction.descriptionHash != null)
                      'descriptionHash': transaction.descriptionHash,
                    if (transaction.preimage != null)
                      'preimage': transaction.preimage,
                    'paymentHash': transaction.paymentHash,
                    'amount':
                        transaction.amountSat * 1000, // invoice amount in msats
                    'feesPaid':
                        transaction.feesPaidSat * 1000, // fees paid in msats
                    'createdAt': transaction.createdAt,
                    if (transaction.expiresAt != null)
                      'expiresAt': transaction.expiresAt,
                    if (transaction.settledAt != null)
                      'settledAt': transaction.settledAt,
                    'metadata': transaction.metadata,
                  }).toList(),
          },
        );

  @override
  List<Object?> get props => [...super.props, transactions];
}

@immutable
class ErrorResponse extends Response {
  final String unknownMethod;

  ErrorResponse({
    required Method method,
    required ErrorCode error,
    this.unknownMethod = '',
  }) : super(
          resultType:
              method == Method.unknown ? unknownMethod : method.plaintext,
          error: ErrorCode.notImplemented,
        );

  @override
  List<Object?> get props => [...super.props, unknownMethod];
}