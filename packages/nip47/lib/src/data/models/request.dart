import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:nip01/nip01.dart';
import 'package:nip04/nip04.dart';
import 'package:nip47/src/data/models/tlv_record.dart';
import 'package:nip47/src/enums/method.dart';
import 'package:nip47/src/enums/transaction_type.dart';

// Abstract base class for messages from relay to client
@immutable
abstract class Request extends Equatable {
  final String id;
  final String connectionPubkey;
  final Method method;
  final int createdAt;

  const Request({
    required this.id,
    required this.connectionPubkey,
    required this.method,
    required this.createdAt,
  });

  factory Request.fromEvent(
    Event event,
    String contentDecryptionPrivateKey,
  ) {
    String connectionPubkey = event.pubkey;

    // Try to decrypt the content with the nip04 standard
    String decryptedContent = Nip04.decrypt(
      event.content,
      contentDecryptionPrivateKey,
      connectionPubkey,
    );

    final content = jsonDecode(decryptedContent);
    final method = content['method'] as String;
    final params = content['params'] as Map<String, dynamic>? ?? {};

    switch (Method.fromPlaintext(method)) {
      case Method.getInfo:
        return GetInfoRequest(
          id: event.id,
          connectionPubkey: connectionPubkey,
          createdAt: event.createdAt,
        );
      case Method.getBalance:
        return GetBalanceRequest(
          id: event.id,
          connectionPubkey: connectionPubkey,
          createdAt: event.createdAt,
        );
      case Method.makeInvoice:
        return MakeInvoiceRequest(
          id: event.id,
          connectionPubkey: connectionPubkey,
          amountMsat: params['amount'] as int,
          description: params['description'] as String?,
          descriptionHash: params['descriptionHash'] as String?,
          expiry: params['expiry'] as int?,
          createdAt: event.createdAt,
        );
      case Method.payInvoice:
        return PayInvoiceRequest(
          id: event.id,
          connectionPubkey: connectionPubkey,
          invoice: params['invoice'] as String,
          createdAt: event.createdAt,
        );
      case Method.multiPayInvoice:
        final invoices = (params['invoices'] as List)
            .map((e) => MultiPayInvoiceRequestInvoicesElement(
                  id: e['id'] as String?,
                  invoice: e['invoice'] as String,
                  amount: e['amount'] as int,
                ))
            .toList();
        return MultiPayInvoiceRequest(
          id: event.id,
          connectionPubkey: connectionPubkey,
          invoices: invoices,
          createdAt: event.createdAt,
        );
      case Method.payKeysend:
        return PayKeysendRequest(
          id: event.id,
          connectionPubkey: connectionPubkey,
          amount: params['amount'] as int,
          pubkey: params['pubkey'] as String,
          preimage: params['preimage'] as String?,
          tlvRecords: (params['tlvRecords'] as List)
              .map((e) => TlvRecord.fromMap(e as Map<String, dynamic>))
              .toList(),
          createdAt: event.createdAt,
        );
      case Method.multiPayKeysend:
        final keysends = (params['keysends'] as List)
            .map((e) => MultiPayKeysendRequestInvoicesElement(
                  id: e['id'] as String?,
                  pubkey: e['pubkey'] as String,
                  amount: e['amount'] as int,
                  preimage: e['preimage'] as String?,
                  tlvRecords: (e['tlvRecords'] as List)
                      .map((e) => TlvRecord.fromMap(e as Map<String, dynamic>))
                      .toList(),
                ))
            .toList();
        return MultiPayKeysendRequest(
          id: event.id,
          connectionPubkey: connectionPubkey,
          keysends: keysends,
          createdAt: event.createdAt,
        );
      case Method.lookupInvoice:
        return LookupInvoiceRequest(
          id: event.id,
          connectionPubkey: connectionPubkey,
          paymentHash: params['paymentHash'] as String?,
          invoice: params['invoice'] as String?,
          createdAt: event.createdAt,
        );
      case Method.listTransactions:
        return ListTransactionsRequest(
          id: event.id,
          connectionPubkey: connectionPubkey,
          from: params['from'] as int?,
          until: params['until'] as int?,
          limit: params['limit'] as int?,
          offset: params['offset'] as int?,
          unpaid: params['unpaid'] as bool,
          type: params['type'] == null
              ? null
              : TransactionType.fromValue(
                  params['type'] as String,
                ),
          createdAt: event.createdAt,
        );
      default:
        return UnknownRequest(
          id: event.id,
          connectionPubkey: connectionPubkey,
          unknownMethod: method,
          params: params,
          createdAt: event.createdAt,
        );
    }
  }

  factory Request.fromMap(Map<String, dynamic> map) {
    final method = Method.fromPlaintext(map['method'] as String);
    switch (method) {
      case Method.getInfo:
        return GetInfoRequest(
          id: map['id'] as String,
          connectionPubkey: map['connectionPubkey'] as String,
          createdAt: map['createdAt'] as int,
        );
      case Method.getBalance:
        return GetBalanceRequest(
          id: map['id'] as String,
          connectionPubkey: map['connectionPubkey'] as String,
          createdAt: map['createdAt'] as int,
        );
      case Method.makeInvoice:
        return MakeInvoiceRequest(
          id: map['id'] as String,
          connectionPubkey: map['connectionPubkey'] as String,
          amountMsat: map['amount'] as int,
          description: map['description'] as String?,
          descriptionHash: map['descriptionHash'] as String?,
          expiry: map['expiry'] as int?,
          createdAt: map['createdAt'] as int,
        );
      case Method.payInvoice:
        return PayInvoiceRequest(
          id: map['id'] as String,
          connectionPubkey: map['connectionPubkey'] as String,
          invoice: map['invoice'] as String,
          createdAt: map['createdAt'] as int,
        );
      case Method.multiPayInvoice:
        final invoices = (map['invoices'] as List)
            .map((e) => MultiPayInvoiceRequestInvoicesElement(
                  id: e['id'] as String?,
                  invoice: e['invoice'] as String,
                  amount: e['amount'] as int,
                ))
            .toList();
        return MultiPayInvoiceRequest(
          id: map['id'] as String,
          connectionPubkey: map['connectionPubkey'] as String,
          invoices: invoices,
          createdAt: map['createdAt'] as int,
        );
      case Method.payKeysend:
        return PayKeysendRequest(
          id: map['id'] as String,
          connectionPubkey: map['connectionPubkey'] as String,
          amount: map['amount'] as int,
          pubkey: map['pubkey'] as String,
          preimage: map['preimage'] as String?,
          tlvRecords: (map['tlvRecords'] as List)
              .map((e) => TlvRecord.fromMap(e as Map<String, dynamic>))
              .toList(),
          createdAt: map['createdAt'] as int,
        );
      case Method.multiPayKeysend:
        final keysends = (map['keysends'] as List)
            .map((e) => MultiPayKeysendRequestInvoicesElement(
                  id: e['id'] as String?,
                  pubkey: e['pubkey'] as String,
                  amount: e['amount'] as int,
                  preimage: e['preimage'] as String?,
                  tlvRecords: (e['tlvRecords'] as List)
                      .map((e) => TlvRecord.fromMap(e as Map<String, dynamic>))
                      .toList(),
                ))
            .toList();
        return MultiPayKeysendRequest(
          id: map['id'] as String,
          connectionPubkey: map['connectionPubkey'] as String,
          keysends: keysends,
          createdAt: map['createdAt'] as int,
        );
      case Method.lookupInvoice:
        return LookupInvoiceRequest(
          id: map['id'] as String,
          connectionPubkey: map['connectionPubkey'] as String,
          paymentHash: map['paymentHash'] as String?,
          invoice: map['invoice'] as String?,
          createdAt: map['createdAt'] as int,
        );
      case Method.listTransactions:
        return ListTransactionsRequest(
          id: map['id'] as String,
          connectionPubkey: map['connectionPubkey'] as String,
          from: map['from'] as int?,
          until: map['until'] as int?,
          limit: map['limit'] as int?,
          offset: map['offset'] as int?,
          unpaid: map['unpaid'] as bool,
          type: map['type'] == null
              ? null
              : TransactionType.fromValue(
                  map['type'] as String,
                ),
          createdAt: map['createdAt'] as int,
        );
      default:
        return UnknownRequest(
          id: map['id'] as String,
          connectionPubkey: map['connectionPubkey'] as String,
          unknownMethod: map['unknownMethod'] as String,
          params: map['params'] as Map<String, dynamic>,
          createdAt: map['createdAt'] as int,
        );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'connectionPubkey': connectionPubkey,
      'method': method.plaintext,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, connectionPubkey, method, createdAt];
}

// Subclass for requests to get info like supported methods
@immutable
class GetInfoRequest extends Request {
  const GetInfoRequest({
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
  }) : super(method: Method.getInfo);

  @override
  List<Object?> get props => [...super.props];
}

// Subclass for requests to get balance
@immutable
class GetBalanceRequest extends Request {
  const GetBalanceRequest({
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
  }) : super(method: Method.getBalance);

  @override
  List<Object?> get props => [...super.props];
}

// Subclass for requests to make a bolt11 invoice
@immutable
class MakeInvoiceRequest extends Request {
  final int amountSat;
  final String? description;
  final String? descriptionHash;
  final int? expiry;

  const MakeInvoiceRequest({
    required amountMsat,
    this.description,
    this.descriptionHash,
    this.expiry,
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
  })  : amountSat = amountMsat ~/ 1000,
        super(method: Method.makeInvoice);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'amount': amountSat,
      'description': description,
      'descriptionHash': descriptionHash,
      'expiry': expiry,
    };
  }

  @override
  List<Object?> get props => [
        ...super.props,
        amountSat,
        description,
        descriptionHash,
        expiry,
      ];
}

// Subclass for requests to pay a bolt11 invoice
@immutable
class PayInvoiceRequest extends Request {
  final String invoice;

  const PayInvoiceRequest({
    required this.invoice,
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
  }) : super(method: Method.payInvoice);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'invoice': invoice,
    };
  }

  @override
  List<Object?> get props => [...super.props, invoice];
}

// Subclass for requests to pay multiple bolt11 invoices
@immutable
class MultiPayInvoiceRequest extends Request {
  final List<MultiPayInvoiceRequestInvoicesElement> invoices;

  const MultiPayInvoiceRequest({
    required this.invoices,
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
  }) : super(method: Method.multiPayInvoice);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'invoices': invoices.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [...super.props, invoices];
}

@immutable
class MultiPayInvoiceRequestInvoicesElement {
  final String? id;
  final String invoice;
  final int amount;

  const MultiPayInvoiceRequestInvoicesElement({
    this.id,
    required this.invoice,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice': invoice,
      'amount': amount,
    };
  }

  List<Object?> get props => [id, invoice, amount];
}

// Subclass for requests for a keysend payment
@immutable
class PayKeysendRequest extends Request {
  final int amount;
  final String pubkey;
  final String? preimage;
  final List<TlvRecord>? tlvRecords;

  const PayKeysendRequest({
    required this.amount,
    required this.pubkey,
    this.preimage,
    this.tlvRecords,
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
  }) : super(method: Method.payKeysend);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'amount': amount,
      'pubkey': pubkey,
      'preimage': preimage,
      'tlvRecords': tlvRecords?.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props =>
      [...super.props, amount, pubkey, preimage, tlvRecords];
}

// Subclass for requests to pay multiple keysend payments
@immutable
class MultiPayKeysendRequest extends Request {
  final List<MultiPayKeysendRequestInvoicesElement> keysends;

  const MultiPayKeysendRequest({
    required this.keysends,
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
  }) : super(method: Method.multiPayKeysend);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'keysends': keysends.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [...super.props, keysends];
}

@immutable
class MultiPayKeysendRequestInvoicesElement extends Equatable {
  final String? id;
  final String pubkey;
  final int amount;
  final String? preimage;
  final List<TlvRecord>? tlvRecords;

  const MultiPayKeysendRequestInvoicesElement({
    this.id,
    required this.pubkey,
    required this.amount,
    this.preimage,
    this.tlvRecords,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pubkey': pubkey,
      'amount': amount,
      'preimage': preimage,
      'tlvRecords': tlvRecords?.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, pubkey, amount, preimage, tlvRecords];
}

// Subclass for requests to look up an invoice
@immutable
class LookupInvoiceRequest extends Request {
  final String? paymentHash;
  final String? invoice;

  const LookupInvoiceRequest({
    this.paymentHash,
    this.invoice,
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
  }) : super(method: Method.lookupInvoice);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'paymentHash': paymentHash,
      'invoice': invoice,
    };
  }

  @override
  List<Object?> get props => [...super.props, paymentHash, invoice];
}

// Subclass for requests to get a list of transactions
@immutable
class ListTransactionsRequest extends Request {
  final int? from;
  final int? until;
  final int? limit;
  final int? offset;
  final bool unpaid;
  final TransactionType? type;

  const ListTransactionsRequest({
    this.from,
    this.until,
    this.limit,
    this.offset,
    this.unpaid = false,
    this.type,
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
  }) : super(method: Method.listTransactions);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'from': from,
      'until': until,
      'limit': limit,
      'offset': offset,
      'unpaid': unpaid,
      'type': type?.name,
    };
  }

  @override
  List<Object?> get props =>
      [...super.props, from, until, limit, offset, unpaid, type];
}

// Subclass for requests with an unkown method
@immutable
class UnknownRequest extends Request {
  final String unknownMethod;
  final Map<String, dynamic> params;

  const UnknownRequest({
    required this.unknownMethod,
    required this.params,
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
  }) : super(method: Method.unknown);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'unknownMethod': unknownMethod,
      'params': params,
    };
  }

  @override
  List<Object?> get props => [...super.props, unknownMethod, params];
}
