import 'dart:convert';

import 'package:nip01/nip01.dart';

class Kind0ExtraMetadata extends Kind0Metadata {
  final String? displayName;
  final String? website;
  final String? banner;
  final bool bot;

  const Kind0ExtraMetadata({
    required super.name,
    super.about,
    super.picture,
    this.displayName,
    this.website,
    this.banner,
    this.bot = false,
  });

  factory Kind0ExtraMetadata.fromContent(String content) {
    final metadata = jsonDecode(content);

    return Kind0ExtraMetadata(
      name: metadata['name'],
      about: metadata['about'],
      picture: metadata['picture'],
      displayName: metadata['display_name'],
      website: metadata['website'],
      banner: metadata['banner'],
      bot: metadata['bot'] ?? false,
    );
  }

  @override
  String get content {
    final metadata = {
      'name': name,
      'about': about,
      'picture': picture,
      'display_name': displayName,
      'website': website,
      'banner': banner,
      'bot': bot,
    };

    return jsonEncode(metadata);
  }

  @override
  List<Object?> get props => [
        ...super.props,
        displayName,
        website,
        banner,
        bot,
      ];
}
