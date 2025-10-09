import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Centralized logging service for the Hindu Connect app
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  Logger? _logger;

  /// Initialize the logger with appropriate configuration
  void initialize() {
    _logger = Logger(
      filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.none,
      ),
      output: kDebugMode ? ConsoleOutput() : null,
    );
  }

  /// Check if logger is initialized
  bool get isInitialized => _logger != null;

  /// Log debug information (only in debug mode)
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.d(message, error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
    }
  }

  /// Log general information
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.i(message, error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
    }
  }

  /// Log warnings
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.w(message, error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
    }
  }

  /// Log errors
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.e(message, error: error, stackTrace: stackTrace);
    } else {
    }
  }

  /// Log fatal errors
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.f(message, error: error, stackTrace: stackTrace);
    } else {
    }
  }

  /// Log authentication events specifically
  void auth(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.i('🔐 AUTH: $message', error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
    }
  }

  /// Log navigation events
  void navigation(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.i('📍 NAV: $message', error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
    }
  }

  /// Log API calls
  void api(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.i('🌐 API: $message', error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
    }
  }

  /// Log Firebase events
  void firebase(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.i('🔥 FIREBASE: $message', error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
    }
  }

  /// Log user actions
  void userAction(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.i('👤 USER: $message', error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
    }
  }
}

/// Global logger instance for easy access
final logger = LoggerService();
