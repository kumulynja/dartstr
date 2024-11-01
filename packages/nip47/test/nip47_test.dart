import 'package:meta/meta.dart';
import 'package:nip01/nip01.dart' as nip01;
import 'package:nip47/nip47.dart';
import 'package:test/test.dart';

// Define specific custom methods
class MakeLiquidAddressMethod extends CustomMethod {
  static const instance = MakeLiquidAddressMethod();
  const MakeLiquidAddressMethod() : super('make_liquid_address');
}

class PayLiquidMethod extends CustomMethod {
  static const instance = PayLiquidMethod();
  const PayLiquidMethod() : super('pay_liquid');
}

@immutable
class MakeLiquidAddressRequest extends CustomRequest {
  const MakeLiquidAddressRequest({
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
  }) : super(method: MakeLiquidAddressMethod.instance);
}

@immutable
class PayLiquidRequest extends CustomRequest {
  final String address;

  const PayLiquidRequest({
    required super.id,
    required super.connectionPubkey,
    required super.createdAt,
    required this.address,
  }) : super(method: PayLiquidMethod.instance);
}

class MakeLiquidAddressResponse extends CustomResponse {
  final String liquidAddress;

  MakeLiquidAddressResponse({
    required this.liquidAddress,
  }) : super(resultType: MakeLiquidAddressMethod.instance.plaintext);

  @override
  List<Object?> get props => [...super.props, liquidAddress];
}

void main() {
  setUp(() {
    // Define custom methods
    final makeLiquidAddress = MakeLiquidAddressMethod.instance;
    final payLiquid = PayLiquidMethod.instance;

    // Register custom methods
    Method.registerCustomMethods([makeLiquidAddress, payLiquid]);

    // Define and register custom requests
    Request.registerCustomRequests({
      makeLiquidAddress: (Map<String, dynamic> map) => MakeLiquidAddressRequest(
            id: map['id'] as String,
            connectionPubkey: map['connectionPubkey'] as String,
            createdAt: map['createdAt'] as int,
          ),
      payLiquid: (Map<String, dynamic> map) => PayLiquidRequest(
            id: map['id'] as String,
            connectionPubkey: map['connectionPubkey'] as String,
            createdAt: map['createdAt'] as int,
            address: map['address'] as String,
          ),
    });
  });

  test(
    'adds a connection',
    () async {
      const relayUrl = 'wss://nostr2.daedaluslabs.io';
      final nip01Repository = nip01.Nip01RepositoryImpl(
        relayClientsManager: nip01.RelayClientsManagerImpl([relayUrl]),
      );
      final nostrKeyPair = nip01.KeyPair.generate();
      final nwcWallet = WalletServiceImpl(
        walletKeyPair: nostrKeyPair,
        nip01repository: nip01Repository,
      );

      final connection = await nwcWallet.addConnection(
        relayUrl: relayUrl,
        permittedMethods: [
          Method.getInfo,
          Method.getBalance,
          Method.makeInvoice,
          Method.lookupInvoice,
          MakeLiquidAddressMethod.instance,
          PayLiquidMethod.instance,
        ],
      );

      expect(
        connection.uri,
        startsWith('nostr+walletconnect://${nostrKeyPair.publicKey}?secret='),
      );
      expect(connection.uri, endsWith('&relay=$relayUrl'));

      final infoEvents = await nip01Repository.getStoredEvents(
        [
          Filters.infoEvents(
            connectionPubkey: connection.pubkey,
            relayUrl: connection.relayUrl,
          ),
        ],
        relayUrls: [relayUrl],
      );

      expect(infoEvents.length, 1);
      final infoEvent = InfoEvent.fromEvent(infoEvents.first);

      print(
        'Petmitted methods in info event: ${infoEvent.permittedMethods.map((m) => m.plaintext).toList()}',
      );

      expect(infoEvent.permittedMethods, [
        Method.getInfo,
        Method.getBalance,
        Method.makeInvoice,
        Method.lookupInvoice,
        MakeLiquidAddressMethod.instance,
        PayLiquidMethod.instance,
      ]);
    },
  );
}
