import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/firebase_crashlytics.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:logger/logger.dart' as logger;

class Logger with Service {

  // Singleton Factory

  static Logger? _instance;

  static Logger? get instance => _instance;

  final logger.Logger _logger = logger.Logger();

  @protected
  static set instance(Logger? value) => _instance = value;

  factory Logger() => _instance ?? (_instance = Logger.internal());

  @protected
  Logger.internal();

  void error(dynamic message) {
    FirebaseCrashlytics().recordError(message, null);
    _logger.e(message);
  }

  void warning(dynamic message) {
    FirebaseCrashlytics().log("warn: $message");
    _logger.w(message);
  }

  void info(dynamic message) {
    FirebaseCrashlytics().log(message);
    _logger.i(message);
  }

  void debug(dynamic message) {
    _logger.d(message);
  }

  void handleZoneError(dynamic exception, StackTrace stack) {
    if (isInitialized) {
      exception = exception?.toString();
      debugPrint(exception);
      FirebaseCrashlytics().recordError(exception, stack);
    }
  }
}
