import 'package:logger/logger.dart';
import '../config/environment.dart';

class AppLogger {
  static late Logger _logger;

  /// Initialize logger với configuration phù hợp
  static void initialize() {
    _logger = Logger(
      filter: _CustomLogFilter(),
      printer: Environment.isDevelopment 
          ? PrettyPrinter(
              methodCount: 2,
              errorMethodCount: 8,
              lineLength: 120,
              colors: true,
              printEmojis: true,
              dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
            )
          : SimplePrinter(),
      output: _CustomLogOutput(),
    );
  }

  /// Debug level logging
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info level logging
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning level logging
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error level logging
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Fatal level logging
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// API specific logging
  static void apiRequest(String method, String url, {dynamic data}) {
    if (Environment.enableLogging) {
      info('🔵 API Request: $method $url${data != null ? '\nData: $data' : ''}');
    }
  }

  static void apiResponse(String method, String url, int statusCode, {dynamic data}) {
    if (Environment.enableLogging) {
      final emoji = statusCode >= 200 && statusCode < 300 ? '🟢' : '🔴';
      info('$emoji API Response: $method $url [$statusCode]${data != null ? '\nData: $data' : ''}');
    }
  }

  static void apiError(String method, String url, dynamic error) {
    if (Environment.enableLogging) {
      AppLogger.error('🔴 API Error: $method $url', error);
    }
  }
}

/// Custom log filter để control log levels theo environment
class _CustomLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // Production: chỉ log warning trở lên
    if (!Environment.isDevelopment) {
      return event.level.index >= Level.warning.index;
    }
    // Development: log tất cả
    return true;
  }
}

/// Custom log output để có thể extend với remote logging
class _CustomLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // Console output
    for (var line in event.lines) {
      // ignore: avoid_print
      print(line);
    }
    
    // Có thể thêm remote logging ở đây
    // _sendToRemoteLogging(event);
  }

  // Future<void> _sendToRemoteLogging(OutputEvent event) async {
  //   // Gửi logs lên remote service như Firebase Crashlytics, Sentry, etc.
  // }
}