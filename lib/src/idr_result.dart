class IdrResult {
  const IdrResult({
    required this.ok,
    required this.code,
    this.message,
    this.data = const {},
  });

  final bool ok;
  final int code;
  final String? message;
  final Map<String, dynamic> data;

  factory IdrResult.fromJson(Map<String, dynamic> json) {
    return IdrResult(
      ok: json['ok'] == true,
      code: (json['code'] as num?)?.toInt() ?? 0,
      message: json['message'] as String?,
      data: (json['data'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
