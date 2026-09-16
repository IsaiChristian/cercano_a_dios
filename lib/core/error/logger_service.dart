import 'package:flutter/foundation.dart';

class LoggerService {
  static void logError(Object exception, {String tag = 'LocalOperation'}) {
    try {
      debugPrint('[$tag] Exception: ${exception.runtimeType}');
    } catch (_) {
      // Do not throw
    }
  }
}
