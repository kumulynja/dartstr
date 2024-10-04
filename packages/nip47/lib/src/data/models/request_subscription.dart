import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:nip01/nip01.dart';

class RequestSubscription extends Equatable {
  final String relayUrl;
  final String subscriptionId;
  final StreamSubscription<Event> _streamSubscription;

  RequestSubscription({
    required this.relayUrl,
    required this.subscriptionId,
    required StreamSubscription<Event> streamSubscription,
  }) : _streamSubscription = streamSubscription;

  void cancelStream() {
    _streamSubscription.cancel();
  }

  @override
  List<Object?> get props => [relayUrl, subscriptionId, _streamSubscription];
}
