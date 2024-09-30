import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:nip01/src/data/models/key_pair.dart';

@immutable
class Event extends Equatable {
  final String? _id;
  final String pubkey;
  final int createdAt;
  final int kind;
  final List<List<String>> tags;
  final String content;
  final String? sig;

  const Event({
    String? id,
    required this.pubkey,
    required this.createdAt,
    required this.kind,
    this.tags = const [],
    required this.content,
    this.sig,
  }) : _id = id;

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      pubkey: map['pubkey'],
      createdAt: map['created_at'],
      kind: map['kind'],
      tags: List<List<String>>.from(
        (map['tags'] as List)
            .map(
              (tag) => (tag as List)
                  .map(
                    (tagElement) => tagElement.toString(),
                  )
                  .toList(),
            )
            .toList(),
      ),
      content: map['content'],
      sig: map['sig'],
    );
  }

  Event copyWith({
    String? id,
    String? pubkey,
    int? createdAt,
    int? kind,
    List<List<String>>? tags,
    String? content,
    String? sig,
  }) {
    return Event(
      id: id ?? _id,
      pubkey: pubkey ?? this.pubkey,
      createdAt: createdAt ?? this.createdAt,
      kind: kind ?? this.kind,
      tags: tags ?? this.tags,
      content: content ?? this.content,
      sig: sig ?? this.sig,
    );
  }

  String get id {
    if (_id != null) {
      return _id;
    }

    final data = [
      0,
      pubkey,
      createdAt,
      kind,
      tags,
      content,
    ];

    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return hex.encode(digest.bytes);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pubkey': pubkey,
      'created_at': createdAt,
      'kind': kind,
      'tags': tags,
      'content': content,
      'sig': sig,
    };
  }

  Event sign(KeyPair keyPair) {
    if (keyPair.publicKey != pubkey) {
      throw ArgumentError('Invalid keypair to sign event with pubkey: $pubkey');
    }

    final signature = keyPair.sign(id);

    return copyWith(sig: signature);
  }

  @override
  List<Object?> get props => [id, pubkey, createdAt, kind, tags, content, sig];
}
