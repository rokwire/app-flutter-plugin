
import 'package:collection/collection.dart';

import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/utils/utils.dart';

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
  final String? id;
  final String? code;
  final String? identifier;

  Auth2PublicAccountIdentifier({this.id, this.code, this.identifier});

  static Auth2PublicAccountIdentifier? fromJson(Map<String, dynamic>? json) => (json != null) ?
    Auth2PublicAccountIdentifier(
      id: JsonUtils.stringValue(json['id']),
      code: JsonUtils.stringValue(json['code']),
      identifier: JsonUtils.stringValue(json['identifier']),
    ) : null;

  Map<String, dynamic> toJson() => {
    'id' : id,
    'code' : code,
    'identifier' : identifier,
  };

  factory Auth2PublicAccountIdentifier.fromUserIdentifier(Auth2Identifier other, {
    String? id,
    String? code,
    String? identifier,
  }) => Auth2PublicAccountIdentifier(
    id: id ?? other.id,
    code: code ?? other.code,
    identifier: identifier ?? other.identifier,
  );

  // Equality

  @override
  bool operator==(Object other) =>
    (other is Auth2PublicAccountIdentifier) &&
      (id == other.id) &&
      (code == other.code) &&
      (identifier == other.identifier);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
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

  static List<Auth2PublicAccountIdentifier> listForType(List<Auth2PublicAccountIdentifier>? identifiers, String type) {
    List<Auth2PublicAccountIdentifier> typeIdentifiers = [];
    for (Auth2PublicAccountIdentifier publicIdentifier in identifiers ?? []) {
      if (publicIdentifier.code == type) {
        typeIdentifiers.add(publicIdentifier);
      }
    }
    return typeIdentifiers;
  }
}