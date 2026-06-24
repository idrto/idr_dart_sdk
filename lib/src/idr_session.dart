class IdrSession {
  const IdrSession({
    required this.entityId,
    required this.host,
    required this.service,
    required this.signalSession,
    this.localPort = 0,
  });

  final String entityId;
  final String host;
  final String service;
  final String signalSession;
  final int localPort;

  factory IdrSession.fromJson(Map<String, dynamic> json) {
    return IdrSession(
      entityId: json['entity_id'] as String? ?? '',
      host: json['host'] as String? ?? '',
      service: json['service'] as String? ?? '',
      signalSession: json['signal_session'] as String? ?? '',
      localPort: (json['local_port'] as num?)?.toInt() ?? 0,
    );
  }
}
