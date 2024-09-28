import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:nip47/src/enums/method.dart';

@immutable
class Connection extends Equatable {
  final String pubkey;
  final List<Method> permittedMethods;
  final String? uri;

  const Connection({
    required this.pubkey,
    required this.permittedMethods,
    this.uri,
  });

  factory Connection.fromMap(Map<String, dynamic> map) {
    return Connection(
      pubkey: map['pubkey'] as String,
      permittedMethods: (map['permittedMethods'] as List)
          .map((e) => Method.fromPlaintext(e as String))
          .toList(),
      uri: map['uri'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pubkey': pubkey,
      'permittedMethods': permittedMethods.map((e) => e.plaintext).toList(),
      'uri': uri,
    };
  }

  @override
  List<Object?> get props => [
        pubkey,
        permittedMethods,
        uri,
      ];
}
