import '../errors/failures.dart';

/// API layer exception with status code and optional server message.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? serverMessage;
  final dynamic originalError;

  const ApiException({
    this.statusCode,
    required this.message,
    this.serverMessage,
    this.originalError,
  });

  String get displayMessage => serverMessage ?? message;

  /// Convert to [ServerFailure] or [AuthFailure] for use in app layer.
  Failure toFailure() {
    if (statusCode == 401 || statusCode == 403) {
      return AuthFailure(message: displayMessage, code: statusCode);
    }
    return ServerFailure(message: displayMessage, code: statusCode);
  }

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message, serverMessage: $serverMessage)';
}
