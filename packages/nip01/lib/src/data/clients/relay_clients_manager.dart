import 'package:nip01/src/data/clients/relay_client.dart';

abstract class RelayClientsManager {
  List<String> get relayUrls;
  RelayClient getClient(String relayUrl);
  List<RelayClient> getClients({List<String>? onlyRelayUrls});
  Future<void> disposeClient(String relayUrl);
  Future<void> disposeAll();
}

class RelayClientsManagerImpl implements RelayClientsManager {
  final Map<String, RelayClient> _relayClients = {};

  RelayClientsManagerImpl(List<String> relayUrls) {
    for (var relayUrl in relayUrls) {
      _relayClients[relayUrl] = RelayClientImpl(relayUrl);
    }
  }

  @override
  List<String> get relayUrls => _relayClients.keys.toList();

  @override
  RelayClient getClient(String relayUrl) {
    if (_relayClients.containsKey(relayUrl)) {
      return _relayClients[relayUrl]!;
    }

    final client = RelayClientImpl(relayUrl);
    _relayClients[relayUrl] = client;
    return client;
  }

  @override
  List<RelayClient> getClients({List<String>? onlyRelayUrls}) {
    final clients = <RelayClient>[];
    if (onlyRelayUrls != null) {
      for (var relayUrl in onlyRelayUrls) {
        clients.add(getClient(relayUrl));
      }
    } else {
      clients.addAll(_relayClients.values);
    }
    return clients;
  }

  @override
  Future<void> disposeClient(String relayUrl) async {
    final client = _relayClients[relayUrl];
    if (client != null) {
      await client.dispose();
      _relayClients.remove(relayUrl);
    }
  }

  @override
  Future<void> disposeAll() async {
    for (final client in _relayClients.values) {
      await client.dispose();
    }
    _relayClients.clear();
  }
}
