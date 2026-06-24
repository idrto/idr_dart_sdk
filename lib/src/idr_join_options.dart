class IdrJoinOptions {
  const IdrJoinOptions({
    required this.hostName,
    this.joinKey,
  });

  final String hostName;
  final String? joinKey;
}
