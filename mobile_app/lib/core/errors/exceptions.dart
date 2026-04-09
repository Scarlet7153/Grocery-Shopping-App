/// Custom exception for API/Server errors
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ServerException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

/// Custom exception for network/connectivity errors
class NetworkException implements Exception {
  final String message;

  const NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

/// Custom exception for cache/local storage errors
class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;

  const ValidationException({required this.message, this.errors});

  @override
  String toString() => 'ValidationException: $message';
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  final String? errorCode;

  const AuthException({required this.message, this.errorCode});

  @override
  String toString() => 'AuthException: $message (Code: $errorCode)';
}
