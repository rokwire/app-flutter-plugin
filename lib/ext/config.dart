
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension ConfigUtils on Config {
  String deepLinkUrl(String deepLinkUrl) {
    String? redirectUrl = deepLinkRedirectUrl;
    return ((redirectUrl != null) && redirectUrl.isNotEmpty) ? UrlUtils.buildWithQueryParameters(redirectUrl, <String, String>{
      'target': deepLinkUrl
    }) : deepLinkUrl;
  }
}