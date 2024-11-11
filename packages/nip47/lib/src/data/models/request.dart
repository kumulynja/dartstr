import 'dart:convert';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:nip01/nip01.dart';
import 'package:nip04/nip04.dart';
import 'package:nip47/src/data/models/tlv_record.dart';
import 'package:nip47/src/data/models/method.dart';
import 'package:nip47/src/enums/transaction_type.dart';

@immutable
sealed class Request extends Equatable {
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

  // Registry to hold custom request constructors
  static final Map<String, Function(Map<String, dynamic>)>
      _customRequestRegistry = {};

  static void registerCustomRequests(
    Map<CustomMethod, Function(Map<String, dynamic>)> requests,
  ) {
    for (var entry in requests.entries) {
      if (!_customRequestRegistry.containsKey(entry.key.plaintext)) {
        _customRequestRegistry[entry.key.plaintext] = entry.value;
      } else {
        log("Warning: Request for method '${entry.key.plaintext}' is already registered.");
      }
    }
  }

  factory Request.fromEvent(Event event, String contentDecryptionPrivateKey) {
    final connectionPubkey = event.pubkey;
    final decryptedContent = Nip04.decrypt(
      event.content,
      contentDecryptionPrivateKey,
      connectionPubkey,
    );

    final content = jsonDecode(decryptedContent);
    final method = content['method'] as String;
    final params = content['params'] as Map<String, dynamic>? ?? {};

    return Request.fromMap({
      'id': event.id,
      'connection_pubkey': connectionPubkey,
      'method': method,
      'created_at': event.createdAt,
      ...params,
    });
  }

  factory Request.fromMap(Map<String, dynamic> map) {
    final method = Method.fromPlaintext(map['method'] as String);

    // Check if there is a custom request registered for this method
    if (_customRequestRegistry.containsKey(method.plaintext)) {
      return _customRequestRegistry[method.plaintext]!(map);
    }

    // Handling for standard methods
    switch (method) {
      case Method.getInfo:
        return GetInfoRequest(
          id: map['id'] as String,
          connectionPubkey: map['connection_pubkey'] as String,
          createdAt: map['created_at'] as int,
        );
      case Method.getBalance:
        return GetBalanceRequest(
          id: map['id'] as String,
          connectionPubkey: map['connection_pubkey'] as String,
          createdAt: map['created_at'] as int,
        );
      case Method.makeInvoice:
        return MakeInvoiceRequest(
          id: map['id'] as String,
          connectionPubkey: map['connection_pubkey'] as String,
          amountMsat: map['amount'] as int,
          description: map['description'] as String?,
          descriptionHash: map['description_hash'] as String?,
          expiry: map['expiry'] as int?,
          createdAt: map['created_at'] as int,
        );
      case Method.payInvoice:
        return PayInvoiceRequest(
          id: map['id'] as String,
          connectionPubkey: map['connection_pubkey'] as String,
          invoice: map['invoice'] as String,
          createdAt: map['created_at'] as int,
        );
      case Method.multiPayInvoice:
        final invoices = (map['invoices'] as List)
            .map((e) => MultiPayInvoiceRequestInvoicesElement(
                  id: e['id'] as String?,
                  invoice: e['invoice'] as String,
                  amountMsat: e['amount'] as int,
                ))
            .toList();
        return MultiPayInvoiceRequest(
          id: map['id'] as String,
          connectionPubkey: map['connection_pubkey'] as String,
          invoices: invoices,
          createdAt: map['created_at'] as int,
        );
      case Method.payKeysend:
        return PayKeysendRequest(
          id: map['id'] as String,
          connectionPubkey: map['connection_pubkey'] as String,
          amountMsat: map['amount'] as int,
          pubkey: map['pubkey'] as String,
          preimage: map['preimage'] as String?,
          tlvRecords: (map['tlv_records'] as List)
              .map((e) => TlvRecord.fromMap(e as Map<String, dynamic>))
              .toList(),
          createdAt: map['created_at'] as int,
        );
      case Method.multiPayKeysend:
        final keysends = (map['keysends'] as List)
            .map((e) => MultiPayKeysendRequestInvoicesElement(
                  id: e['id'] as String?,
                  pubkey: e['pubkey'] as String,
                  amountMsat: e['amount'] as int,
                  preimage: e['preimage'] as String?,
                  tlvRecords: (e['tlv_records'] as List)
                      .map((e) => TlvRecord.fromMap(e as Map<String, dynamic>))
                      .toList(),
                ))
            .toList();
        return MultiPayKeysendRequest(
          id: map['id'] as String,
          connectionPubkey: map['connection_pubkey'] as String,
          keysends: keysends,
          createdAt: map['created_at'] as int,
        );
      case Method.lookupInvoice:
        return LookupInvoiceRequest(
          id: map['id'] as String,
          connectionPubkey: map['connection_pubkey'] as String,
          paymentHash: map['payment_hash'] as String?,
          invoice: map['invoice'] as String?,
          createdAt: map['created_at'] as int,
        );
      case Method.listTransactions:
        return ListTransactionsRequest(
          id: map['id'] as String,
          connectionPubkey: map['connection_pubkey'] as String,
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
          createdAt: map['created_at'] as int,
        );
      default:
        return UnknownRequest(
          id: map['id'] as String,
          connectionPubkey: map['connection_pubkey'] as String,
          unknownMethod: map['method'] as String,
          params: map['params'] as Map<String, dynamic>,
          createdAt: map['created_at'] as int,
        );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'connection_pubkey': connectionPubkey,
      'method': method.plaintext,
      'created_at': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, connectionPubkey, method, createdAt];
}

// Standard request classes

// Subclass for requests to get info like supported methods
@immutable
class GetInfoRequest extends Request {
  const GetInfoRequest({
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
  }) : super(method: Method.getInfo);
}

// Subclass for requests to get balance
@immutable
class GetBalanceRequest extends Request {
  const GetBalanceRequest({
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
  }) : super(method: Method.getBalance);
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
      'amount': amountSat * 1000,
      'description': description,
      'description_hash': descriptionHash,
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
  final int amountSat;

  const MultiPayInvoiceRequestInvoicesElement({
    this.id,
    required this.invoice,
    required amountMsat,
  }) : amountSat = amountMsat ~/ 1000;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice': invoice,
      'amount': amountSat * 1000,
    };
  }

  List<Object?> get props => [id, invoice, amountSat];
}

// Subclass for requests for a keysend payment
@immutable
class PayKeysendRequest extends Request {
  final int amountSat;
  final String pubkey;
  final String? preimage;
  final List<TlvRecord>? tlvRecords;

  const PayKeysendRequest({
    required amountMsat,
    required this.pubkey,
    this.preimage,
    this.tlvRecords,
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
  })  : amountSat = amountMsat ~/ 1000,
        super(method: Method.payKeysend);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'amount': amountSat * 1000,
      'pubkey': pubkey,
      'preimage': preimage,
      'tlv_records': tlvRecords?.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props =>
      [...super.props, amountSat, pubkey, preimage, tlvRecords];
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
  final int amountSat;
  final String? preimage;
  final List<TlvRecord>? tlvRecords;

  const MultiPayKeysendRequestInvoicesElement({
    this.id,
    required this.pubkey,
    required amountMsat,
    this.preimage,
    this.tlvRecords,
  }) : amountSat = amountMsat ~/ 1000;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pubkey': pubkey,
      'amount': amountSat * 1000,
      'preimage': preimage,
      'tlv_records': tlvRecords?.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, pubkey, amountSat, preimage, tlvRecords];
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
      'payment_hash': paymentHash,
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
      'unknown_method': unknownMethod,
      'params': params,
    };
  }

  @override
  List<Object?> get props => [...super.props, unknownMethod, params];
}

// CustomRequest open for subclassing by users of the library
@immutable
abstract class CustomRequest extends Request {
  const CustomRequest({
    required super.id,
    required super.connectionPubkey,
    required super.method,
    required super.createdAt,
  });
}
