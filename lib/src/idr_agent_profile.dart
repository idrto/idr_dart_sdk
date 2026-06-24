/// Agent role and identity written to `idr-agent.toml` via [IdrClient.configureAgent].
class IdrAgentProfile {
  const IdrAgentProfile({
    required this.mode,
    required this.entityId,
    required this.host,
    this.sourceHost,
  });

  final IdrAgentMode mode;
  final String entityId;
  final String host;
  final String? sourceHost;
}

enum IdrAgentMode {
  source('source'),
  target('target'),
  hybrid('hybrid');

  const IdrAgentMode(this.value);
  final String value;
}
