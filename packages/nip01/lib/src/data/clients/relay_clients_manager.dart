import 'dart:developer';

import 'package:nip01/src/data/clients/relay_client.dart';

abstract class RelayClientsManager {
  List<String> get relayUrls;
  RelayClient getClient(String relayUrl);
  List<RelayClient> getClients({List<String>? onlyRelayUrls});
  Future<void> disposeClient(
    String relayUrl, {
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  });
  Future<void> disposeAll({
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  });
}

class RelayClientsManagerImpl implements RelayClientsManager {
  final Map<String, RelayClient> _relayClients = {};
  final int _maxRetryAttempts;

  RelayClientsManagerImpl(
    List<String> relayUrls, {
    int maxRetryAttempts = 5,
  }) : _maxRetryAttempts = maxRetryAttempts {
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

    final client = RelayClientImpl(
      relayUrl,
      maxRetryAttempts: _maxRetryAttempts,
    );
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
    log('RelayClientsManagerImpl.getClients: ${clients.length} clients: $clients');
    return clients;
  }

  @override
  Future<void> disposeClient(
    String relayUrl, {
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  }) async {
    final client = _relayClients[relayUrl];
    if (client != null) {
      await client.dispose(
        waitForRelayClosedMessage: waitForRelayClosedMessage,
        timeoutSec: timeoutSec,
      );
      _relayClients.remove(relayUrl);
    }
  }

  @override
  Future<void> disposeAll({
    bool waitForRelayClosedMessage = false,
    int timeoutSec = 10,
  }) async {
    for (final client in _relayClients.values) {
      await client.dispose(
        waitForRelayClosedMessage: waitForRelayClosedMessage,
        timeoutSec: timeoutSec,
      );
    }
    _relayClients.clear();
  }
}
