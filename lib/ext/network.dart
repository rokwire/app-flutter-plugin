import 'package:http/http.dart';

extension ResponseExt on Response {
  bool get succeeded => (statusCode >= 200) && (statusCode <= 301);
}