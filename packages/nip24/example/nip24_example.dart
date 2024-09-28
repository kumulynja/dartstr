import 'package:nip24/nip24.dart';

void main() {
  var metadata = Kind0ExtraMetadata(
    name: 'John Doe',
    about: 'A developer',
    picture: 'https://example.com/picture.png',
    displayName: 'JD',
    website: 'https://johndoe.dev',
    banner: 'https://example.com/banner.png',
    bot: true,
  );

  print(metadata.content);

  metadata = Kind0ExtraMetadata.fromContent(metadata.content);

  print(metadata.name);
}
