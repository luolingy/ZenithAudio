import 'package:logger/logger.dart';

final class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void v(String message) => _logger.t(message);

  static void d(String message) => _logger.d(message);

  static void i(String message) => _logger.i(message);

  static void w(String message) => _logger.w(message);

  static void e(String message, [dynamic error, StackTrace? stack]) {
    if (error != null && stack != null) {
      _logger.e(message, error: error, stackTrace: stack);
    } else if (error != null) {
      _logger.e(message, error: error);
    } else {
      _logger.e(message);
    }
  }
}
