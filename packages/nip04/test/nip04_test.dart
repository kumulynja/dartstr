import 'package:nip01/nip01.dart';
import 'package:nip04/nip04.dart';
import 'package:test/test.dart';

void main() {
  group('nip04', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Decryption', () {
      final keyPair = KeyPair(
        privateKey:
            '9bdc0737ecc9b7871b21537cc707c972389c829028f9fa8e6c95b331768ee4ac',
      );
      const encryptedContent =
          'zdiUBdrfA+HNM4qF67oKN2HcUv4kxnlRkpjHP5mqd9UrFuoSbwGAXQeTBUUrYO1svYBvhnpBK4s5XNVvXmvQ4yuji+v7KOwrDYjQzFveXLXXlyoFPakp5CD2BUdGkNn3pVzodWD84dgmfuuUDNYNfmm8EyjVyGBE1TmiBHawOI0MkhZ+uHf4VGhO6EIvhunLYQITe4YQvTRHiNlO4hoHh9kOjQLxYEY9AEkZ2EEPcfYpSkuYqUnvwUii7qzPJWU8o7PI86k4R3IryEf7hnN1DvZgZxRiWrwJwXP7P9PTiaorzjsEZWrKsus+65vU2e1F6L0jOPX0f5+/lZkSwF7Qgq4YZc/OlyJSqMDrz0SoMw0NbugGYOU/DxO4pP75o0NPIeG6lyr4jA4VsXMyA2NiNfFQRlGbRuk/qF8nmG4we70=?iv=yIIcMRiYu41Qlztn0asP3g==';
      const connectionPublicKey =
          '7a29579ddcb698db1b93f7078c5020dc932de36cba53fedd6a0746005db7fd7f';

      expect(
        Nip04.decrypt(
          encryptedContent,
          keyPair.privateKey,
          connectionPublicKey,
        ),
        '{"method":"pay_invoice","params":{"invoice":"lntbs210n1pn83jurpp5lgvkz8w6y6vws7urs97ewkz5j9dmlfcsqksrw0egjt34ml6yezgsdqqcqzzsxqyz5vqsp5yke8eagt7uynk30adlq707rtq496lvrn3nxxs80levkfyfczd7uq9qyyssqmhx239fvsulum8nekent00v6x7nfgv9peuy6q4r0pakmc63cqkm8vjjrx4nk2e0z0nekzzqkhxsdt5jv2vfnwu0sn9cl09hgfedzmyspzje739"}}',
      );
    });
  });
}
