import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get baseUrl {
    final value = dotenv.env['BASE_URL'];

    if (value == null || value.isEmpty) {
      throw Exception('BASE_URL is not defined in .env file. ');
    }

    return value;
  }
}
