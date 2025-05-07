import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get fileName => '.env';

  static String get apiKey {
    return dotenv.env['API_KEY'] ?? "API_KEY not specified";
  }

  static String get apiBaseUrl {
    return dotenv.env['BASE_URL'] ?? "URl not specified";
  }
}
