/// Generic API response wrapper for consistent response handling.
/// Use when backend returns { "data": T } or similar structure.
class ApiResponse<T> {
  final T? data;
  final String? message;
  final int? code;

  const ApiResponse({
    this.data,
    this.message,
    this.code,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      message: json['message'] as String?,
      code: json['code'] as int?,
    );
  }

  bool get isSuccess => code != null && code! >= 200 && code! < 300;
}
