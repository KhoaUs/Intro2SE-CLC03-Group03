import 'package:logger/logger.dart';

class MyLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter( // You can customize the printer
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  static void d(dynamic message) => _logger.d(message);
  static void i(dynamic message) => _logger.i(message);
  static void w(dynamic message) => _logger.w(message);
  static void e(dynamic message) => _logger.e(message);
}
