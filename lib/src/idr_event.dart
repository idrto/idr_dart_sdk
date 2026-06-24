sealed class IdrEvent {
  const IdrEvent();
}

class IdrJoinPendingEvent extends IdrEvent {
  const IdrJoinPendingEvent({required this.requestId, required this.host});

  final String requestId;
  final String host;
}

class IdrConnectionStateEvent extends IdrEvent {
  const IdrConnectionStateEvent({required this.state});

  final String state;
}
