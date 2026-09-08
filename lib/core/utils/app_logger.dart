import 'package:flutter/foundation.dart';

/// 🎨 Colored logger (ANSI). Works in most Flutter consoles.
/// If your IDE console doesn't show colors, you'll still see the tags.
class AppLogger {
  AppLogger._();

  static bool enabled = kDebugMode;

  static const _reset = '\x1B[0m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _blue = '\x1B[34m';
  static const _purple = '\x1B[35m';
  static const _cyan = '\x1B[36m';
  static const _gray = '\x1B[90m';

  static void _p(String tag, String msg, String color) {
    if (!enabled) return;
    debugPrint('$color[$tag] $msg$_reset');
  }

  static void info(String msg) => _p('INFO', msg, _gray);
  static void read(String msg) => _p('READ', msg, _blue);
  static void write(String msg) => _p('WRITE', msg, _green);
  static void delete(String msg) => _p('DELETE', msg, _yellow);
  static void audit(String msg) => _p('AUDIT', msg, _purple);
  static void debug(String msg) => _p('DEBUG', msg, _cyan);

  /// Errors always log, including release builds — otherwise a field failure
  /// leaves nothing behind in logcat to diagnose it with.
  static void error(String msg) => debugPrint('$_red[ERROR] $msg$_reset');
}
