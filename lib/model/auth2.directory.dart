
import 'package:collection/collection.dart';

import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/utils/utils.dart';

//////////////////////////////////////////
// Auth2PublicAccountsResult

class Auth2PublicAccountsResult {
  final List<Auth2PublicAccount>? accounts;
  final Map<String, int>? indexCounts;
  final int? totalCount;

  Auth2PublicAccountsResult({this.accounts, this.indexCounts, this.totalCount});

  static Auth2PublicAccountsResult? fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      Map<String, int> indexCounts = {};
      Map<String, dynamic>? indexCountsJson = JsonUtils.mapValue(json['counts']);
      for (MapEntry<String, dynamic> count in indexCountsJson?.entries ?? []) {
        indexCounts[count.key] = (count.value is int) ? count.value : 0;
      }

      return Auth2PublicAccountsResult(
        accounts: Auth2PublicAccount.listFromJson(JsonUtils.listValue(json['accounts'])),
        indexCounts: indexCounts,
        totalCount: JsonUtils.intValue(json['total']),
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'accounts': Auth2PublicAccount.listToJson(accounts),
    'counts': indexCounts,
    'total': totalCount,
  };
}

//////////////////////////////////////////
// Auth2PublicAccount

class Auth2PublicAccount {
  final String? id;

  final bool? isVerified;
  final bool? isFollowing;
  final bool? isConnection;

  final Auth2UserProfile? profile;
  final List<Auth2PublicAccountIdentifier>? identifiers;

  Auth2PublicAccount({this.id,
    this.isVerified, this.isFollowing, this.isConnection,
    this.profile, this.identifiers,
  });

  static Auth2PublicAccount? fromJson(Map<String, dynamic>? json) => (json != null) ?
    Auth2PublicAccount(
      id: JsonUtils.stringValue(json['id']),

      isVerified: JsonUtils.boolValue(json['verified']),
      isFollowing: JsonUtils.boolValue(json['is_following']),
      isConnection: JsonUtils.boolValue(json['is_connection']),
      
      profile: Auth2UserProfile.fromJson(JsonUtils.mapValue(json['profile'])),
      identifiers: Auth2PublicAccountIdentifier.listFromJson(JsonUtils.listValue(json['identifiers'])),
    ) : null;

  Map<String, dynamic> toJson() => {
    'id' : id,

    'verified' : isVerified,
    'is_following' : isFollowing,
    'is_connection' : isConnection,

    'profile' : profile?.toJson(),
    'identifiers' : Auth2PublicAccountIdentifier.listToJson(identifiers),
  };

  // Equality

  @override
  bool operator==(Object other) =>
    (other is Auth2PublicAccount) &&
    (id == other.id) &&

    (isVerified == other.isVerified) &&
    (isFollowing == other.isFollowing) &&
    (isConnection == other.isConnection) &&

    (profile == other.profile) &&
    (DeepCollectionEquality().equals(identifiers, other.identifiers));

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^

    (isVerified?.hashCode ?? 0) ^
    (isFollowing?.hashCode ?? 0) ^
    (isConnection?.hashCode ?? 0) ^

    (profile?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(identifiers));

  // JSON List Serialization

  static List<Auth2PublicAccount>? listFromJson(List<dynamic>? json) {
    List<Auth2PublicAccount>? values;
    if (json != null) {
      values = <Auth2PublicAccount>[];
      for (dynamic entry in json) {
        ListUtils.add(values, Auth2PublicAccount.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<Auth2PublicAccount>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = [];
      for (Auth2PublicAccount value in values) {
        json.add(value.toJson());
      }
    }
    return json;
  }
}

//////////////////////////////////////////
// Auth2PublicAccountIdentifier

class Auth2PublicAccountIdentifier {
  final String? code;
  final String? identifier;

  Auth2PublicAccountIdentifier({this.code, this.identifier});

  static Auth2PublicAccountIdentifier? fromJson(Map<String, dynamic>? json) => (json != null) ?
    Auth2PublicAccountIdentifier(
      code: JsonUtils.stringValue(json['code']),
      identifier: JsonUtils.stringValue(json['identifier']),
    ) : null;

  Map<String, dynamic> toJson() => {
    'code' : code,
    'identifier' : identifier,
  };

  // Equality

  @override
  bool operator==(Object other) =>
    (other is Auth2PublicAccountIdentifier) &&
    (code == other.code) &&
    (identifier == other.identifier);

  @override
  int get hashCode =>
    (code?.hashCode ?? 0) ^
    (identifier?.hashCode ?? 0);

  // JSON List Serialization

  static List<Auth2PublicAccountIdentifier>? listFromJson(List<dynamic>? json) {
    List<Auth2PublicAccountIdentifier>? values;
    if (json != null) {
      values = <Auth2PublicAccountIdentifier>[];
      for (dynamic entry in json) {
        ListUtils.add(values, Auth2PublicAccountIdentifier.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<Auth2PublicAccountIdentifier>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = [];
      for (Auth2PublicAccountIdentifier value in values) {
        json.add(value.toJson());
      }
    }
    return json;
  }
}