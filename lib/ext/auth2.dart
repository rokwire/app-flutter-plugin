
import 'package:rokwire_plugin/model/auth2.dart';

extension Auth2TokenMnemo on Auth2Token {
  String get refreshTokenMnemo =>
    refreshToken?.auth2TokenMnemo ?? '';
}

extension Auth2TokenStringMnemo on String {
  static const int significantTokenLen = 14;

  String get auth2TokenMnemo =>
    (significantTokenLen < length) ? '***$significantToken' : this;

  String get significantToken =>
    substring(length - significantTokenLen);
}
