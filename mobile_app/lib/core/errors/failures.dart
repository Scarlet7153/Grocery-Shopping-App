import 'package:equatable/equatable.dart';

/// Base class for all app failures
abstract class Failure extends Equatable {
  final String message;
  final int? code;
  
  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Server failure - when API returns an error
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

/// Network failure - when there's no internet or connection issues
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
  });
}

/// Cache failure - when local storage operations fail
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
  });
}

/// Validation failure - when input validation fails
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
  });
}

/// Authentication failure - when auth operations fail
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });
}

/// Permission failure - when permissions are denied
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code,
  });
}

/// Unknown failure - for unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
  });
}

/// Extension to convert exceptions to failures
extension ExceptionToFailure on Exception {
  Failure toFailure() {
    if (toString().contains('SocketException')) {
      return const NetworkFailure(
        message: 'Không có kết nối mạng',
        code: 1001,
      );
    } else if (toString().contains('TimeoutException')) {
      return const NetworkFailure(
        message: 'Hết thời gian chờ kết nối',
        code: 1002,
      );
    } else if (toString().contains('FormatException')) {
      return const ValidationFailure(
        message: 'Dữ liệu không hợp lệ',
        code: 2001,
      );
    } else {
      return UnknownFailure(
        message: 'Đã xảy ra lỗi không xác định: ${toString()}',
        code: 9999,
      );
    }
  }
}
