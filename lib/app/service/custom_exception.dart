import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

// Logger configuration class for initializing and managing loggers
class LoggerConfig {
  static bool _isInitialized = false;
  static final Map<String, Logger> _loggers = {};

  // Initializes the logging system with default settings
  static void initialize({
    Level level = Level.INFO,
    bool consoleOutput = true,
    String? logFilePath,
    bool enableRemoteLogging = false,
  }) {
    if (_isInitialized) return;
    Logger.root.level = level;

    Logger.root.onRecord.listen((record) {
      // Console output
      if (consoleOutput) {
        print(
          '[${record.time}] ${record.level.name} [${record.loggerName}] ${record.message}'
              '${record.error != null ? '\nError: ${record.error}' : ''}'
              '${record.stackTrace != null ? '\nStackTrace: ${record.stackTrace}' : ''}',
        );
      }

      // File output (optional, requires `path_provider` or similar for file paths)
      if (logFilePath != null) {
        // Placeholder for file logging (implement with `dart:io` or a package)
        // Example: File(logFilePath).writeAsStringSync(formattedLog, mode: FileMode.append);
      }

      // Remote logging (e.g., Sentry, Firebase Crashlytics)
      if (enableRemoteLogging) {
        // Placeholder for remote logging integration
        // Example: Sentry.captureException(record.error, stackTrace: record.stackTrace);
      }
    });

    _isInitialized = true;
  }

  // Retrieves or creates a logger for a given name
  static Logger getLogger(String name) {
    return _loggers.putIfAbsent(name, () => Logger(name));
  }
}

// Base custom exception class with enhanced features for production
abstract class CustomException implements Exception {
  final String message; // User-facing error message
  final String code; // Unique error code for identification
  final DateTime timestamp; // When the error occurred
  final StackTrace? stackTrace; // Optional stack trace for debugging
  final Map<String, dynamic>? metadata; // Additional context (e.g., HTTP status, request details)
  final bool isRetryable; // Indicates if the error is transient and retryable
  final String? localizedMessageKey; // Key for localized message (if applicable)
  final Logger _logger; // Logger instance for this exception

  CustomException({
    required this.message,
    required this.code,
    StackTrace? stackTrace,
    this.metadata,
    this.isRetryable = false,
    this.localizedMessageKey,
    String loggerName = 'AppException',
  })  : timestamp = DateTime.now(),
        stackTrace = stackTrace ?? StackTrace.current,
        _logger = LoggerConfig.getLogger(loggerName);

  // Returns a localized message based on the provided locale
  String getLocalizedMessage(String locale) {
    if (localizedMessageKey == null) return message;
    return _localizeMessage(localizedMessageKey!, locale, metadata);
  }

  // Converts the exception to a JSON-serializable map
  Map<String, dynamic> toJson() {
    return {
      'error_type': runtimeType.toString(),
      'code': code,
      'message': message,
      'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp),
      'is_retryable': isRetryable,
      'metadata': metadata,
      'stack_trace': stackTrace?.toString(),
    };
  }

  // Logs the exception using the logging package
  void log({String loggerName = 'AppException', Level level = Level.SEVERE}) {
    final logger = LoggerConfig.getLogger(loggerName);
    logger.log(
      level,
      '[$code] $message${metadata != null ? ' (Metadata: $metadata)' : ''}',
      this,
      stackTrace,
    );
  }

  @override
  String toString() => '[$code] $message${metadata != null ? ' (Metadata: $metadata)' : ''}';

  // Placeholder for localization logic (integrated with intl)
  String _localizeMessage(String key, String locale, Map<String, dynamic>? params) {
    final translations = {
      'en': {
        'generic_error': 'An error occurred: {message}',
        'network_unavailable': 'Network is unavailable. Please check your connection.',
        'server_timeout': 'Server timed out. Please try again later.',
        'auth_failed': 'Authentication failed: {reason}',
        'client_error': 'Invalid request: {details}',
        'server_error': 'Server error: {details}',
        'database_error': 'Database operation failed: {details}',
        'validation_error': 'Validation failed: {details}',
      },
      'es': {
        'generic_error': 'Ocurrió un error: {message}',
        'network_unavailable': 'La red no está disponible. Verifique su conexión.',
        'server_timeout': 'El servidor agotó el tiempo de espera. Intente de nuevo más tarde.',
        'auth_failed': 'Fallo de autenticación: {reason}',
        'client_error': 'Solicitud inválida: {details}',
        'server_error': 'Error del servidor: {details}',
        'database_error': 'Fallo en la operación de la base de datos: {details}',
        'validation_error': 'Fallo de validación: {details}',
      },
    };
    String template = translations[locale]?[key] ?? message;
    if (params != null) {
      params.forEach((k, v) => template = template.replaceAll('{$k}', v.toString()));
    }
    return template;
  }
}

// Generic exception for unhandled cases
class GenericException extends CustomException {
  GenericException({
    String message = 'An unexpected error occurred',
    String code = 'GENERIC_ERROR',
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
    bool isRetryable = false,
    String? localizedMessageKey = 'generic_error',
    String loggerName = 'AppException',
  }) : super(
    message: message,
    code: code,
    stackTrace: stackTrace,
    metadata: metadata,
    isRetryable: isRetryable,
    localizedMessageKey: localizedMessageKey,
    loggerName: loggerName,
  );
}

// Network-related exceptions
class NetworkException extends CustomException {
  final int? httpStatusCode;

  NetworkException({
    String message = 'Network error occurred',
    String code = 'NETWORK_ERROR',
    this.httpStatusCode,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
    bool isRetryable = true,
    String? localizedMessageKey = 'network_unavailable',
    String loggerName = 'NetworkException',
  }) : super(
    message: message,
    code: code,
    stackTrace: stackTrace,
    metadata: metadata ?? (httpStatusCode != null ? {'http_status': httpStatusCode} : null),
    isRetryable: isRetryable,
    localizedMessageKey: localizedMessageKey,
    loggerName: loggerName,
  );
}

// Network timeout exception
class TimeoutException extends NetworkException {
  TimeoutException({
    String message = 'Request timed out',
    String code = 'TIMEOUT_ERROR',
    int? httpStatusCode,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
    bool isRetryable = true,
    String? localizedMessageKey = 'server_timeout',
    String loggerName = 'TimeoutException',
  }) : super(
    message: message,
    code: code,
    httpStatusCode: httpStatusCode,
    stackTrace: stackTrace,
    metadata: metadata,
    isRetryable: isRetryable,
    localizedMessageKey: localizedMessageKey,
    loggerName: loggerName,
  );
}

// Authentication-related exception
class AuthenticationException extends CustomException {
  AuthenticationException({
    String message = 'Authentication failed',
    String code = 'AUTH_ERROR',
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
    bool isRetryable = false,
    String? localizedMessageKey = 'auth_failed',
    String loggerName = 'AuthenticationException',
  }) : super(
    message: message,
    code: code,
    stackTrace: stackTrace,
    metadata: metadata,
    isRetryable: isRetryable,
    localizedMessageKey: localizedMessageKey,
    loggerName: loggerName,
  );
}

// Client-side request error (e.g., 4xx HTTP errors)
class ClientException extends CustomException {
  final int? httpStatusCode;

  ClientException({
    String message = 'Invalid request',
    String code = 'CLIENT_ERROR',
    this.httpStatusCode,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
    bool isRetryable = false,
    String? localizedMessageKey = 'client_error',
    String loggerName = 'ClientException',
  }) : super(
    message: message,
    code: code,
    stackTrace: stackTrace,
    metadata: metadata ?? (httpStatusCode != null ? {'http_status': httpStatusCode} : null),
    isRetryable: isRetryable,
    localizedMessageKey: localizedMessageKey,
    loggerName: loggerName,
  );
}

// Server-side error (e.g., 5xx HTTP errors)
class ServerException extends CustomException {
  final int? httpStatusCode;

  ServerException({
    String message = 'Server error occurred',
    String code = 'SERVER_ERROR',
    this.httpStatusCode,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
    bool isRetryable = true,
    String? localizedMessageKey = 'server_error',
    String loggerName = 'ServerException',
  }) : super(
    message: message,
    code: code,
    stackTrace: stackTrace,
    metadata: metadata ?? (httpStatusCode != null ? {'http_status': httpStatusCode} : null),
    isRetryable: isRetryable,
    localizedMessageKey: localizedMessageKey,
    loggerName: loggerName,
  );
}

// Database-related exception
class DatabaseException extends CustomException {
  DatabaseException({
    String message = 'Database error occurred',
    String code = 'DATABASE_ERROR',
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
    bool isRetryable = false,
    String? localizedMessageKey = 'database_error',
    String loggerName = 'DatabaseException',
  }) : super(
    message: message,
    code: code,
    stackTrace: stackTrace,
    metadata: metadata,
    isRetryable: isRetryable,
    localizedMessageKey: localizedMessageKey,
    loggerName: loggerName,
  );
}

// Validation-related exception
class ValidationException extends CustomException {
  final List<String>? validationErrors;

  ValidationException({
    String message = 'Validation failed',
    String code = 'VALIDATION_ERROR',
    this.validationErrors,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
    bool isRetryable = false,
    String? localizedMessageKey = 'validation_error',
    String loggerName = 'ValidationException',
  }) : super(
    message: message,
    code: code,
    stackTrace: stackTrace,
    metadata: metadata ?? (validationErrors != null ? {'errors': validationErrors} : null),
    isRetryable: isRetryable,
    localizedMessageKey: localizedMessageKey,
    loggerName: loggerName,
  );
}

// Utility class for handling exceptions
class ExceptionHandler {
  // Maps HTTP status codes to appropriate exceptions
  static CustomException fromHttpStatus(int statusCode, String message, {Map<String, dynamic>? metadata, String loggerName = 'HttpException'}) {
    switch (statusCode) {
      case 400:
        return ClientException(
          message: message,
          code: 'BAD_REQUEST',
          httpStatusCode: statusCode,
          metadata: metadata,
          localizedMessageKey: 'client_error',
          loggerName: loggerName,
        );
      case 401:
        return AuthenticationException(
          message: message,
          code: 'UNAUTHORIZED',
          metadata: metadata,
          localizedMessageKey: 'auth_failed',
          loggerName: loggerName,
        );
      case 403:
        return AuthenticationException(
          message: message,
          code: 'FORBIDDEN',
          metadata: metadata,
          localizedMessageKey: 'auth_failed',
          loggerName: loggerName,
        );
      case 404:
        return ClientException(
          message: message,
          code: 'NOT_FOUND',
          httpStatusCode: statusCode,
          metadata: metadata,
          localizedMessageKey: 'client_error',
          loggerName: loggerName,
        );
      case 408:
        return TimeoutException(
          message: message,
          code: 'REQUEST_TIMEOUT',
          httpStatusCode: statusCode,
          metadata: metadata,
          localizedMessageKey: 'server_timeout',
          loggerName: loggerName,
        );
      case 429:
        return NetworkException(
          message: message,
          code: 'TOO_MANY_REQUESTS',
          httpStatusCode: statusCode,
          metadata: metadata,
          isRetryable: true,
          localizedMessageKey: 'network_unavailable',
          loggerName: loggerName,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          message: message,
          code: 'SERVER_ERROR_$statusCode',
          httpStatusCode: statusCode,
          metadata: metadata,
          isRetryable: true,
          localizedMessageKey: 'server_error',
          loggerName: loggerName,
        );
      default:
        return NetworkException(
          message: message,
          code: 'NETWORK_ERROR_$statusCode',
          httpStatusCode: statusCode,
          metadata: metadata,
          isRetryable: statusCode >= 500,
          localizedMessageKey: 'network_unavailable',
          loggerName: loggerName,
        );
    }
  }

  // Wraps an async operation and handles exceptions
  static Future<T> handleAsync<T>(
      Future<T> Function() operation, {
        String operationName = 'AsyncOperation',
        Map<String, dynamic>? metadata,
        String loggerName = 'AsyncException',
        Level logLevel = Level.SEVERE,
      }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      CustomException exception;
      if (e is CustomException) {
        exception = e;
      } else {
        exception = GenericException(
          message: 'Unexpected error during $operationName: $e',
          code: 'UNEXPECTED_ERROR',
          stackTrace: stackTrace,
          metadata: metadata,
          loggerName: loggerName,
        );
      }
      exception.log(loggerName: loggerName, level: logLevel);
      throw exception;
    }
  }

  // Determines if an exception suggests retrying
  static bool shouldRetry(CustomException exception) {
    return exception.isRetryable;
  }

  // Serializes an exception to JSON string
  static String toJsonString(CustomException exception) {
    return jsonEncode(exception.toJson());
  }
}