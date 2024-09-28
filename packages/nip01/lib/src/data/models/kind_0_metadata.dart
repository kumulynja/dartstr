import 'dart:convert';

import 'package:equatable/equatable.dart';

class Kind0Metadata extends Equatable {
  final String name;
  final String? about;
  final String? picture;

  const Kind0Metadata({
    required this.name,
    this.about,
    this.picture,
  });

  factory Kind0Metadata.fromContent(String content) {
    final metadata = jsonDecode(content);

    return Kind0Metadata(
      name: metadata['name'],
      about: metadata['about'],
      picture: metadata['picture'],
    );
  }

  String get content {
    final metadata = {
      'name': name,
      'about': about,
      'picture': picture,
    };

    return jsonEncode(metadata);
  }

  @override
  List<Object?> get props => [name, about, picture];
}
