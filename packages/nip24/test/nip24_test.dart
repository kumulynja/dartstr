import 'dart:convert';
import 'package:nip24/nip24.dart';
import 'package:test/test.dart';

void main() {
  group('Kind0ExtraMetadata tests', () {
    const name = 'John Doe';
    const about = 'A developer';
    const picture = 'https://example.com/picture.png';
    const displayName = 'JD';
    const website = 'https://johndoe.dev';
    const banner = 'https://example.com/banner.png';
    const bot = true;

    late Kind0ExtraMetadata metadata;

    setUp(() {
      metadata = const Kind0ExtraMetadata(
        name: name,
        about: about,
        picture: picture,
        displayName: displayName,
        website: website,
        banner: banner,
        bot: bot,
      );
    });

    test('should return the correct content in JSON format', () {
      final expectedJson = jsonEncode({
        'name': name,
        'about': about,
        'picture': picture,
        'display_name': displayName,
        'website': website,
        'banner': banner,
        'bot': bot,
      });

      expect(metadata.content, expectedJson);
    });

    test('should parse content from JSON string correctly', () {
      final jsonString = '''
      {
        "name": "$name",
        "about": "$about",
        "picture": "$picture",
        "display_name": "$displayName",
        "website": "$website",
        "banner": "$banner",
        "bot": $bot
      }
      ''';

      final parsedMetadata = Kind0ExtraMetadata.fromContent(jsonString);

      expect(parsedMetadata.name, name);
      expect(parsedMetadata.about, about);
      expect(parsedMetadata.picture, picture);
      expect(parsedMetadata.displayName, displayName);
      expect(parsedMetadata.website, website);
      expect(parsedMetadata.banner, banner);
      expect(parsedMetadata.bot, bot);
    });

    test('should have correct props', () {
      expect(metadata.props, [
        name,
        about,
        picture,
        displayName,
        website,
        banner,
        bot,
      ]);
    });

    test('should set default bot to false if not provided', () {
      const jsonStringWithoutBot = '''
      {
        "name": "$name",
        "about": "$about",
        "picture": "$picture",
        "display_name": "$displayName",
        "website": "$website",
        "banner": "$banner"
      }
      ''';

      final parsedMetadata =
          Kind0ExtraMetadata.fromContent(jsonStringWithoutBot);

      expect(parsedMetadata.bot, isFalse);
    });
  });
}
