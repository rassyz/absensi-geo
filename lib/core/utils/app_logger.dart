// lib/utils/app_logger.dart

import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(Object? message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;

    debugPrint('[DEBUG] $message');

    if (error != null) {
      debugPrint('[ERROR] $error');
    }

    if (stackTrace != null) {
      debugPrint('[STACKTRACE] $stackTrace');
    }
  }

  static void error(Object? message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;

    debugPrint('[ERROR] $message');

    if (error != null) {
      debugPrint('[DETAIL] $error');
    }

    if (stackTrace != null) {
      debugPrint('[STACKTRACE] $stackTrace');
    }
  }
}
