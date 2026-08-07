
import 'package:http/http.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension Auh2Directory on Auth2 {

  static const String attributesScope = 'app-directory';

  ContentAttributes? get directoryAttributes =>
    Content().contentAttributes(attributesScope);

  Future<List<Auth2PublicAccountSection>?> loadDirectoryAccountSections({String? search,
    String? userName, String? firstName, String? lastName,
    Iterable<String>? ids, String? followingId, String? followerId,
    Map<String, dynamic>? attriutes,
  }) async {

    if (Config().coreUrl != null) {
      String url = UrlUtils.addQueryParameters("${Config().coreUrl}/services/accounts/public/index", <String, String>{
        if (search != null)
          'search': search,

        if (userName != null)
          'username': userName,
        if (firstName != null)
          'firstname': firstName,
        if (lastName != null)
          'lastname': lastName,

        if ((ids != null) && ids.isNotEmpty)
          'ids': ids.join(','),

        if (followingId != null)
          'following-id': followingId,
        if (followerId != null)
          'follower-id': followerId,

        if (attriutes != null)
          ...attriutes.map((k, v) => MapEntry(k, (v is List) ? v.join(',') : v.toString()))
      });

      Response? response = await Network().get(url, auth: Auth2());
      Map<String, dynamic>? responseData = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
      return (responseData != null) ? Auth2PublicAccountSection.listFromJson(JsonUtils.listValue(responseData['letters'])) : null;
    }
    return null;
  }

  Future<List<Auth2PublicAccount>?> loadDirectoryAccounts({String? search,
    String? userName, String? firstName, String? lastName, String? section,
    Iterable<String>? ids, String? followingId, String? followerId,
    Map<String, dynamic>? attriutes,
    int? offset, int? limit}) async {

    //TMP:
    //return _sampleAccounts;

    //TMP:
    //return _loadSampleDirectoryAccounts(offset: offset, limit: limit);

    // ignore: dead_code
    if (Config().coreUrl != null) {
      String url = UrlUtils.addQueryParameters("${Config().coreUrl}/services/accounts/public", <String, String>{
        if (search != null)
          'search': search,

        if (userName != null)
          'username': userName,
        if (firstName != null)
          'firstname': firstName,
        if (lastName != null)
          'lastname': lastName,

        if (section != null)
          'letter': section,

        if ((ids != null) && ids.isNotEmpty)
          'ids': ids.join(','),

        if (followingId != null)
          'following-id': followingId,
        if (followerId != null)
          'follower-id': followerId,

        if (offset != null)
          'offset': offset.toString(),
        if (limit != null)
          'limit': limit.toString(),
        
        if (attriutes != null)
          ...attriutes.map((k, v) => MapEntry(k, (v is List) ? v.join(',') : v.toString()))
      });

      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? Auth2PublicAccount.listFromJson(JsonUtils.decodeList(response?.body)) : null;
    }
    return null;
  }

}

