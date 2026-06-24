/// Options for [IdrClient.connect].
class IdrConnectOptions {
  const IdrConnectOptions({
    this.holdSeconds = 0,
    this.localPort = 0,
    this.tunnelTimeoutSeconds = 60,
  });

  /// Seconds to keep the tunnel open after connect (0 = until disconnect).
  final int holdSeconds;

  /// Local TCP port for the outbound proxy (0 = do not start a listener).
  final int localPort;

  /// Max seconds to wait for the data channel before returning.
  final int tunnelTimeoutSeconds;
}
