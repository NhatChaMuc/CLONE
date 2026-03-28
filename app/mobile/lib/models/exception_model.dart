/// Custom exception classes for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  AppException({required this.message, this.code, this.originalException});

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when authentication fails
class AuthException extends AppException {
  AuthException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
         message: message,
         code: code,
         originalException: originalException,
       );
}

/// Thrown when network request fails
class NetworkException extends AppException {
  final int? statusCode;

  NetworkException({
    required String message,
    this.statusCode,
    String? code,
    dynamic originalException,
  }) : super(
         message: message,
         code: code,
         originalException: originalException,
       );
}

/// Thrown when data is not found
class NotFoundException extends AppException {
  NotFoundException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
         message: message,
         code: code,
         originalException: originalException,
       );
}

/// Thrown when data parsing/validation fails
class DataException extends AppException {
  DataException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
         message: message,
         code: code,
         originalException: originalException,
       );
}

/// Thrown when recording/audio operation fails
class AudioException extends AppException {
  AudioException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
         message: message,
         code: code,
         originalException: originalException,
       );
}

/// Thrown for generic/unknown exceptions
class UnknownException extends AppException {
  UnknownException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
         message: message,
         code: code,
         originalException: originalException,
       );
}
