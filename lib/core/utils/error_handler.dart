import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Base exception class for app errors
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic original;

  AppException(this.message, {this.code, this.original});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Authentication exceptions
class AuthException extends AppException {
  AuthException(String message, {String? code, dynamic original})
      : super(message, code: code, original: original);

  // Factory constructor to convert Firebase Auth exceptions
  factory AuthException.fromFirebaseAuth(dynamic exception) {
    String message = 'An authentication error occurred.';
    String? code;

    if (exception is FirebaseAuthException) {
      code = exception.code;
      switch (exception.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please use a stronger password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        case 'operation-not-allowed':
          message = 'This operation is not allowed.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        default:
          message = exception.message ?? message;
      }
    }

    return AuthException(message, code: code, original: exception);
  }
}

/// Network exceptions
class NetworkException extends AppException {
  NetworkException(String message, {String? code, dynamic original})
      : super(message, code: code, original: original);

  // Factory constructor for common network exceptions
  factory NetworkException.fromException(dynamic exception) {
    String message = 'A network error occurred.';
    String? code;

    if (exception is SocketException) {
      message = 'No internet connection.';
      code = 'no_internet';
    } else if (exception is HttpException) {
      message = 'Couldn\'t reach the server.';
      code = 'http_error';
    } else if (exception is FormatException) {
      message = 'Bad response format.';
      code = 'format_error';
    } else if (exception is TimeoutException) {
      message = 'Connection timeout. Please try again.';
      code = 'timeout';
    }

    return NetworkException(message, code: code, original: exception);
  }
}

/// API exceptions
class ApiException extends AppException {
  final int? statusCode;

  ApiException(String message, {this.statusCode, String? code, dynamic original})
      : super(message, code: code, original: original);

  // Factory constructor for HTTP status codes
  factory ApiException.fromStatusCode(int statusCode, {dynamic original}) {
    String message;
    String code = statusCode.toString();

    switch (statusCode) {
      case 400:
        message = 'Bad request.';
        break;
      case 401:
        message = 'Unauthorized. Please login again.';
        break;
      case 403:
        message = 'Access denied.';
        break;
      case 404:
        message = 'Resource not found.';
        break;
      case 409:
        message = 'Conflict with current state.';
        break;
      case 422:
        message = 'Invalid data provided.';
        break;
      case 429:
        message = 'Too many requests. Please try again later.';
        break;
      case 500:
        message = 'Server error. Please try again later.';
        break;
      case 503:
        message = 'Service unavailable. Please try again later.';
        break;
      default:
        if (statusCode >= 500) {
          message = 'Server error. Please try again later.';
        } else if (statusCode >= 400) {
          message = 'Request error. Please try again.';
        } else {
          message = 'An API error occurred.';
        }
    }

    return ApiException(message, statusCode: statusCode, code: code, original: original);
  }
}

/// Storage exceptions
class StorageException extends AppException {
  StorageException(String message, {String? code, dynamic original})
      : super(message, code: code, original: original);
}

/// Database exceptions
class DatabaseException extends AppException {
  DatabaseException(String message, {String? code, dynamic original})
      : super(message, code: code, original: original);
}

/// Helper for displaying errors in UI
class ErrorDisplay {
  // Show a snackbar with error message
  static void showErrorSnackBar(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Show an error dialog
  static Future<void> showErrorDialog(
      BuildContext context,
      String title,
      String message, {
        String? buttonText,
        VoidCallback? onPressed,
      }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: onPressed ?? () => Navigator.of(context).pop(),
              child: Text(buttonText ?? 'OK'),
            ),
          ],
        );
      },
    );
  }

  // Log error to analytics or crash reporting
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    // Implement logging to your preferred service
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);
    debugPrint('ERROR: $error');
    if (stackTrace != null) {
      debugPrint('STACKTRACE: $stackTrace');
    }
  }

  // Get user-friendly message from an exception
  static String getUserFriendlyMessage(dynamic exception) {
    if (exception is AppException) {
      return exception.message;
    } else if (exception is FirebaseAuthException) {
      return AuthException.fromFirebaseAuth(exception).message;
    } else if (exception is SocketException ||
        exception is HttpException ||
        exception is TimeoutException) {
      return NetworkException.fromException(exception).message;
    }

    return 'An unexpected error occurred. Please try again.';
  }
}