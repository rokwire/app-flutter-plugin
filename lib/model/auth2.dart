
import 'dart:collection';
import 'dart:core';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

////////////////////////////////
// Auth2Token

class Auth2Token {
  final String? idToken;
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;
  
  Auth2Token({this.accessToken, this.refreshToken, this.idToken, this.tokenType});

  factory Auth2Token.fromOther(Auth2Token? value, {String? idToken, String? accessToken, String? refreshToken, String? tokenType }) {
    return Auth2Token(
      idToken: idToken ?? value?.idToken,
      accessToken: accessToken ?? value?.accessToken,
      refreshToken: refreshToken ?? value?.refreshToken,
      tokenType: tokenType ?? value?.tokenType,
    );
  }

  static Auth2Token? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2Token(
      idToken: JsonUtils.stringValue(json['id_token']),
      accessToken: JsonUtils.stringValue(json['access_token']),
      refreshToken: JsonUtils.stringValue(json['refresh_token']),
      tokenType: JsonUtils.stringValue(json['token_type']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id_token' : idToken,
      'access_token' : accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType
    };
  }

  @override
  bool operator ==(other) =>
    (other is Auth2Token) &&
      (other.idToken == idToken) &&
      (other.accessToken == accessToken) &&
      (other.refreshToken == refreshToken) &&
      (other.tokenType == tokenType);

  @override
  int get hashCode =>
    (idToken?.hashCode ?? 0) ^
    (accessToken?.hashCode ?? 0) ^
    (refreshToken?.hashCode ?? 0) ^
    (tokenType?.hashCode ?? 0);

  bool get isValid {
    return StringUtils.isNotEmpty(accessToken) && (kIsWeb || StringUtils.isNotEmpty(refreshToken)) && StringUtils.isNotEmpty(tokenType);
  }

  bool get isValidUiuc {
    return StringUtils.isNotEmpty(accessToken) && StringUtils.isNotEmpty(idToken) && StringUtils.isNotEmpty(tokenType);
  }
}

////////////////////////////////
// Auth2Account

class Auth2Account {
  static const String notifySecretsChanged       = "edu.illinois.rokwire.account.secrets.changed";

  final String? id;
  final Auth2UserProfile? profile;
  final Auth2UserPrefs? prefs;
  final Auth2UserPrivacy? privacy;
  final Map<String, dynamic> secrets;
  final List<Auth2Permission>? permissions;
  final List<Auth2Role>? roles;
  final List<Auth2Group>? groups;
  final List<Auth2Identifier>? identifiers;
  final List<Auth2Type>? authTypes;
  final Map<String, dynamic>? systemConfigs;

  final DateTime? lastLoginDate;
  final DateTime? lastAccessTokenDate;

  Auth2Account({this.id, this.profile, this.prefs, this.privacy, this.secrets = const {}, this.permissions,
    this.roles, this.groups, this.identifiers, this.authTypes, this.systemConfigs, this.lastLoginDate, this.lastAccessTokenDate});

  factory Auth2Account.fromOther(Auth2Account? other, {String? id, String? username,
    Auth2UserProfile? profile, Auth2UserPrefs? prefs, Auth2UserPrivacy? privacy, Map<String, dynamic>? secrets,
    List<Auth2Permission>? permissions, List<Auth2Role>? roles, List<Auth2Group>? groups,
    List<Auth2Identifier>? identifiers, List<Auth2Type>? authTypes, Map<String, dynamic>? systemConfigs,
    DateTime? lastLoginDate, DateTime? lastAccessTokenDate}) {
    return Auth2Account(
      id: id ?? other?.id,
      profile: profile ?? other?.profile,
      prefs: prefs ?? other?.prefs,
      privacy: privacy ?? other?.privacy,
      secrets: secrets ?? other?.secrets ?? {},
      permissions: permissions ?? other?.permissions,
      roles: roles ?? other?.roles,
      groups: groups ?? other?.groups,
      identifiers: identifiers ?? other?.identifiers,
      authTypes: authTypes ?? other?.authTypes,
      systemConfigs: systemConfigs ?? other?.systemConfigs,
      lastLoginDate: lastLoginDate ?? other?.lastLoginDate,
      lastAccessTokenDate: lastAccessTokenDate ?? other?.lastAccessTokenDate,
    );
  }

  static Auth2Account? fromJson(Map<String, dynamic>? json, { Auth2UserPrefs? prefs, Auth2UserProfile? profile, Auth2UserPrivacy? privacy }) {
    return (json != null) ? Auth2Account(
      id: JsonUtils.stringValue(json['id']),
      profile: Auth2UserProfile.fromJson(JsonUtils.mapValue(json['profile'])) ?? profile,
      prefs: Auth2UserPrefs.fromJson(JsonUtils.mapValue(json['preferences'])) ?? prefs, //TBD Auth2
      privacy: Auth2UserPrivacy.fromJson(JsonUtils.mapValue(json['privacy'])) ?? privacy,
      secrets: JsonUtils.mapValue(json['secrets']) ?? {}, //TBD Auth2
      permissions: Auth2Permission.listFromJson(JsonUtils.listValue(json['permissions'])),
      roles: Auth2Role.listFromJson(JsonUtils.listValue(json['roles'])),
      groups: Auth2Group.listFromJson(JsonUtils.listValue(json['groups'])),
      identifiers: Auth2Identifier.listFromJson(JsonUtils.listValue(json['identifiers'])),
      authTypes: Auth2Type.listFromJson(JsonUtils.listValue(json['auth_types'])),
      systemConfigs: JsonUtils.mapValue(json['system_configs']),
      lastLoginDate: AppDateTime().dateTimeLocalFromJson(json['last_login_date']),
      lastAccessTokenDate: AppDateTime().dateTimeLocalFromJson(json['last_access_token_date']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'profile': profile?.toJson(),
      'preferences': prefs?.toJson(),
      'privacy': privacy?.toJson(),
      'secrets': secrets,
      'permissions': Auth2StringEntry.listToJson(permissions),
      'roles': Auth2StringEntry.listToJson(roles),
      'groups': Auth2StringEntry.listToJson(groups),
      'identifiers': Auth2Identifier.listToJson(identifiers),
      'auth_types': Auth2Type.listToJson(authTypes),
      'system_configs': systemConfigs,
      'last_login_date': AppDateTime().dateTimeLocalToJson(lastLoginDate),
      'last_access_token_date': AppDateTime().dateTimeLocalToJson(lastAccessTokenDate),
    };
  }

  @override
  bool operator ==(other) =>
    (other is Auth2Account) &&
      (other.id == id) &&
      (other.profile == profile) &&
      (other.privacy == privacy) &&
      const DeepCollectionEquality().equals(other.permissions, permissions) &&
      const DeepCollectionEquality().equals(other.roles, roles) &&
      const DeepCollectionEquality().equals(other.groups, groups) &&
      const DeepCollectionEquality().equals(other.identifiers, identifiers) &&
      const DeepCollectionEquality().equals(other.authTypes, authTypes) &&
      const DeepCollectionEquality().equals(other.systemConfigs, systemConfigs) &&
      ((lastLoginDate != null && other.lastLoginDate != null && lastLoginDate!.isAtSameMomentAs(other.lastLoginDate!)) || (lastLoginDate == null && other.lastLoginDate == null)) &&
      ((lastAccessTokenDate != null && other.lastAccessTokenDate != null && lastAccessTokenDate!.isAtSameMomentAs(other.lastAccessTokenDate!)) || (lastAccessTokenDate == null && other.lastAccessTokenDate == null));

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (profile?.hashCode ?? 0) ^
    (privacy?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(permissions)) ^
    (const DeepCollectionEquality().hash(roles)) ^
    (const DeepCollectionEquality().hash(groups)) ^
    (const DeepCollectionEquality().hash(identifiers)) ^
    (const DeepCollectionEquality().hash(authTypes)) ^
    (const DeepCollectionEquality().hash(systemConfigs)) ^
    (lastLoginDate?.hashCode ?? 0) ^
    (lastAccessTokenDate?.hashCode ?? 0);

  bool get isValid {
    return (id != null) && id!.isNotEmpty /* && (profile != null) && profile.isValid*/;
  }

  Auth2Identifier? get identifier {
    return ((identifiers != null) && identifiers!.isNotEmpty) ? identifiers?.first : null;
  }

  String? get username {
    List<Auth2Identifier> usernameIdentifiers = getLinkedForIdentifierType(Auth2Identifier.typeUsername);
    if (usernameIdentifiers.isNotEmpty) {
      return usernameIdentifiers.first.identifier;
    }
    return null;
  }

  bool get isAuthenticated {
    return lastLoginDate != null && lastAccessTokenDate != null && lastLoginDate!.isAtSameMomentAs(lastAccessTokenDate!);
  }

  bool isIdentifierLinked(String code) {
    if (identifiers != null) {
      for (Auth2Identifier identifier in identifiers!) {
        if (identifier.code == code) {
          return true;
        }
      }
    }
    return false;
  }

  Auth2Identifier? getIdentifier(String? identifier, String code) {
    if (identifier != null) {
      for (Auth2Identifier id in identifiers ?? []) {
        if (id.code == code && id.identifier == identifier) {
          return id;
        }
      }
    }
    return null;
  }

  List<Auth2Identifier> getLinkedForIdentifierType(String code) {
    List<Auth2Identifier> linkedTypes = <Auth2Identifier>[];
    if (identifiers != null) {
      for (Auth2Identifier identifier in identifiers!) {
        if (identifier.code == code) {
          linkedTypes.add(identifier);
        }
      }
    }
    return linkedTypes;
  }

  List<Auth2Identifier> getLinkedForAuthTypeId(String id) {
    List<Auth2Identifier> linkedTypes = <Auth2Identifier>[];
    if (identifiers != null) {
      for (Auth2Identifier identifier in identifiers!) {
        if (identifier.accountAuthTypeId == id) {
          linkedTypes.add(identifier);
        }
      }
    }
    return linkedTypes;
  }

  Auth2Type? get authType {
    return ((authTypes != null) && authTypes!.isNotEmpty) ? authTypes?.first : null;
  }

  bool isAuthTypeLinked(String code) {
    if (authTypes != null) {
      for (Auth2Type authType in authTypes!) {
        if (authType.code == code && authType.hasValidCredential) {
          return true;
        }
      }
    }
    return false;
  }

  List<Auth2Type> getLinkedForAuthType(String code) {
    List<Auth2Type> linkedTypes = <Auth2Type>[];
    if (authTypes != null) {
      for (Auth2Type authType in authTypes!) {
        if (authType.code == code) {
          linkedTypes.add(authType);
        }
      }
    }
    return linkedTypes;
  }

  // Permissions

  bool hasPermission(String? permission) => (permission != null) && (
    (Auth2Permission.findInList(permissions, permission: permission) != null) ||
    (Auth2Role.findInList(roles, permission: permission) != null) ||
    (Auth2Group.findInList(groups, permission: permission) != null)
  );

  Set<Auth2Permission> get allPermissions {
    Set<Auth2Permission> result = (permissions != null) ? Set<Auth2Permission>.of(permissions!) : <Auth2Permission>{};
    result.union(Auth2Role.permissionsInList(roles));
    result.union(Auth2Group.permissionsInList(groups));
    return result;
  }

  Set<String> get allPermissionNames => Set<String>.of(allPermissions.map<String>((Auth2Permission permission) => permission.name ?? ''));

  // Roles

  bool hasRole(String? role) => (role != null) && (Auth2StringEntry.findInList(roles, name: role) != null);

  Set<Auth2Role> get allRoles {
    Set<Auth2Role> result = (roles != null) ? Set<Auth2Role>.of(roles!) : <Auth2Role>{};
    result.union(Auth2Group.rolesInList(groups));
    return result;
  }

  Set<String> get allRoleNames => Set<String>.of(allRoles.map<String>((Auth2Role role) => role.name ?? ''));

  // Groups

  bool belongsToGroup(String? group) => (group != null) && (Auth2StringEntry.findInList(groups, name: group) != null);
  Set<Auth2Group> get allGroups => (groups != null) ? Set<Auth2Group>.of(groups!) : <Auth2Group>{};
  Set<String> get allGroupNames => Set<String>.of(allGroups.map<String>((Auth2Group group) => group.name ?? ''));

  // System config

  bool get isAnalyticsProcessed => (MapUtils.get(systemConfigs, 'analytics_processed_date') != null);

  // Secrets

  String? getSecretString(String? name, { String? defaultValue }) =>
      JsonUtils.stringValue(getSecret(name)) ?? defaultValue;

  dynamic getSecret(String? name) => secrets[name];

  void applySecret(String name, dynamic value) {
    if (value != null) {
      secrets[name] = value;
    } else {
      secrets.remove(name);
    }
    NotificationService().notify(notifySecretsChanged, secrets);
  }

  static List<Auth2Account>? listFromJson(List<dynamic>? jsonList) {
    List<Auth2Account>? result;
    if (jsonList != null) {
      result = <Auth2Account>[];
      for (dynamic jsonEntry in jsonList) {
        Map<String, dynamic>? accountJson = JsonUtils.mapValue(jsonEntry);
        Auth2UserProfile profile = Auth2UserProfile(
            firstName: JsonUtils.stringValue(accountJson?['first_name']), lastName: JsonUtils.stringValue(accountJson?['last_name']));
        ListUtils.add(result, Auth2Account.fromJson(accountJson, profile: profile));
      }
    }
    return result;
  }
}

////////////////////////////////
// Auth2AccountPrivacy

class Auth2UserPrivacy {
  final bool? public;
  final Auth2AccountFieldsVisibility? fieldsVisibility;

  Auth2UserPrivacy({this.public, this.fieldsVisibility});

  factory Auth2UserPrivacy.fromOther(Auth2UserPrivacy? other, {
    bool? public,
    Auth2AccountFieldsVisibility? fieldsVisibility,
  }) => Auth2UserPrivacy(
    public: public ?? other?.public,
    fieldsVisibility: fieldsVisibility ?? other?.fieldsVisibility,
  );

  static Auth2UserPrivacy? fromJson(Map<String, dynamic>? json) => (json != null) ? Auth2UserPrivacy(
    public: JsonUtils.boolValue(json['public']),
    fieldsVisibility: Auth2AccountFieldsVisibility.fromJson(JsonUtils.mapValue(json['field_visibility'])),
  ) : null;

  Map<String, dynamic> toJson() => {
    'public': public,
    'field_visibility': fieldsVisibility?.toJson(),
  };

  @override
  bool operator ==(other) =>
    (other is Auth2UserPrivacy) &&
      (other.public == public) &&
      DeepCollectionEquality().equals(other.fieldsVisibility, fieldsVisibility);

  @override
  int get hashCode =>
    (public?.hashCode ?? 0) ^
    (fieldsVisibility?.hashCode ?? 0);
}

////////////////////////////////
// Auth2AccountFieldsVisibility

class Auth2AccountFieldsVisibility {
  final Auth2UserProfileFieldsVisibility? profile;
  final Map<String, Auth2FieldVisibility>? identifiers;

  Auth2AccountFieldsVisibility({this.profile, this.identifiers});

  factory Auth2AccountFieldsVisibility.fromOther(Auth2AccountFieldsVisibility? other, {
    Auth2UserProfileFieldsVisibility? profile, Map<String, Auth2FieldVisibility>? identifiers,
  }) => Auth2AccountFieldsVisibility(
    profile: profile ?? other?.profile,
    identifiers: identifiers ?? other?.identifiers,
  );

  static Auth2AccountFieldsVisibility? fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      Map<String, Auth2FieldVisibility>? identifiers;
      Map<String, dynamic>? identifiersJson = JsonUtils.mapValue(json['identifiers']);
      for (MapEntry<String, dynamic> item in identifiersJson?.entries ?? []) {
        if (item.value is String) {
          identifiers ??= {};
          identifiers[item.key] = Auth2FieldVisibilityImpl.fromJson(item.value) ?? Auth2FieldVisibility.private;
        }
      }

      return Auth2AccountFieldsVisibility(
        profile: Auth2UserProfileFieldsVisibility.fromJson(JsonUtils.mapValue(json['profile'])),
        identifiers: identifiers,
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    Map<String, String>? identifiersJson;
    for (MapEntry<String, Auth2FieldVisibility> item in identifiers?.entries ?? []) {
      identifiersJson ??= {};
      identifiersJson[item.key] = item.value.toJson();
    }
    return {
      'profile': profile?.toJson(),
      'identifiers': identifiersJson,
    };
  }

  @override
  bool operator ==(other) =>
    (other is Auth2AccountFieldsVisibility) &&
    (other.profile == profile) &&
    DeepCollectionEquality().equals(other.identifiers, identifiers);

  @override
  int get hashCode =>
    (profile?.hashCode ?? 0) ^
    (identifiers?.hashCode ?? 0);
}

////////////////////////////////
// Auth2AccountScope

class Auth2AccountScope {
  final Set<Auth2UserPrefsScope>? prefs;
  final Set<Auth2UserProfileScope>? profile;

  const Auth2AccountScope({this.prefs, this.profile});
}

////////////////////////////////
// Auth2UserProfile

class Auth2UserProfile {

  static const String notifyDataChanged          = "edu.illinois.rokwire.user.profile.data.changed";
  static const String notifyChanged              = "edu.illinois.rokwire.user.profile.changed";

  // Known unstructured_properties entries
  static const String researchQuestionnaireAnswersDataKey = 'research_questionnaire_answers';

  static const String universityRoleDataKey = 'university_role';
  static const String collegeDataKey = 'college';
  static const String departmentDataKey = 'department';
  static const String majorDataKey = 'major';
  static const String department2DataKey = 'department2';
  static const String major2DataKey = 'major2';
  static const String titleDataKey = 'title';
  static const String email2DataKey = 'email2';

  static const String universityRoleFacultyStaff = 'Faculty/Staff'; //TODO: verify this string is correct

  static const Set<Auth2UserProfileScope> defaultProfileScope = const {
    Auth2UserProfileScope.firstName, Auth2UserProfileScope.middleName, Auth2UserProfileScope.lastName,
  };

  String? _id;

  String? _firstName;
  String? _middleName;
  String? _lastName;
  String? _pronouns;

  int?    _birthYear;
  String? _photoUrl;
  String? _pronunciationUrl;

  String? _website;

  String? _address;
  String? _address2;
  String? _poBox;
  String? _city;
  String? _zip;
  String? _state;
  String? _country;

  Map<String, dynamic>? _data;
  
  Auth2UserProfile({String? id,
    String? firstName, String? middleName, String? lastName, String? pronouns,
    int? birthYear, String? photoUrl, String? pronunciationUrl,
    String? email, String? phone, String? website,
    String? address, String? address2, String? poBox, String? city, String? zip, String? state, String? country,
    Map<String, dynamic>? data
  }):
    _id = id,

    _firstName = firstName,
    _middleName = middleName,
    _lastName = lastName,
    _pronouns = pronouns,

    _birthYear = birthYear,
    _photoUrl = photoUrl,
    _pronunciationUrl = pronunciationUrl,

    _website = website,

    _address = address,
    _address2 = address2,
    _poBox = poBox,
    _city = city,
    _zip  = zip,
    _state  = state,
    _country = country,

    _data = data;

  factory Auth2UserProfile.fromOther(Auth2UserProfile? other, {
    Auth2UserProfile? override,
    Set<Auth2UserProfileScope>? scope
  }) {
    return Auth2UserProfile(
      id: override?.id ?? other?._id,

      firstName: (override != null) ? Auth2UserProfileScope.firstName.pickString(override.firstName, other?._firstName, scope: scope) : other?._firstName,
      middleName: (override != null) ? Auth2UserProfileScope.middleName.pickString(override.middleName, other?._middleName, scope: scope) : other?._middleName,
      lastName: (override != null) ? Auth2UserProfileScope.lastName.pickString(override.lastName, other?._lastName, scope: scope) : other?._lastName,
      pronouns: (override != null) ? Auth2UserProfileScope.pronouns.pickString(override.pronouns, other?._pronouns, scope: scope) : other?._pronouns,

      birthYear: (override != null) ? Auth2UserProfileScope.birthYear.pickInt(override.birthYear, other?._birthYear, scope: scope) : other?._birthYear,
      photoUrl: (override != null) ? Auth2UserProfileScope.photoUrl.pickString(override.photoUrl, other?._photoUrl, scope: scope) : other?._photoUrl,
      pronunciationUrl: (override != null) ? Auth2UserProfileScope.pronunciationUrl.pickString(override.pronunciationUrl, other?._pronunciationUrl, scope: scope) : other?._pronunciationUrl,

      website: (override != null) ? Auth2UserProfileScope.website.pickString(override.website, other?._website, scope: scope) : other?._website,

      address: (override != null) ? Auth2UserProfileScope.address.pickString(override.address, other?._address, scope: scope) : other?._address,
      address2: (override != null) ? Auth2UserProfileScope.address2.pickString(override.address2, other?._address2, scope: scope) : other?._address2,
      poBox: (override != null) ? Auth2UserProfileScope.poBox.pickString(override.poBox, other?._poBox, scope: scope) : other?._poBox,
      city: (override != null) ? Auth2UserProfileScope.city.pickString(override.city, other?._city, scope: scope) : other?._city,
      zip: (override != null) ? Auth2UserProfileScope.zip.pickString(override.zip, other?._zip, scope: scope) : other?._zip,
      state: (override != null) ? Auth2UserProfileScope.state.pickString(override.state, other?._state, scope: scope) : other?._state,
      country: (override != null) ? Auth2UserProfileScope.country.pickString(override.country, other?._country, scope: scope) : other?._country,

      data: (override != null) ? MapUtils.combine(other?._data, override.data) : other?._data,
    );
  }

  factory Auth2UserProfile.fromFieldsVisibility(Auth2UserProfile source, Auth2UserProfileFieldsVisibility? visibility, {
    Set<Auth2FieldVisibility> permitted = const <Auth2FieldVisibility>{Auth2FieldVisibility.public}
  }) {
    return Auth2UserProfile(
      id: source._id,

      firstName: permitted.contains(visibility?.firstName) ? source._firstName : null,
      middleName: permitted.contains(visibility?.middleName) ? source._middleName : null,
      lastName: permitted.contains(visibility?.lastName) ? source._lastName : null,
      pronouns: permitted.contains(visibility?.pronouns) ? source._pronouns : null,

      birthYear: permitted.contains(visibility?.birthYear) ? source._birthYear : null,
      photoUrl: permitted.contains(visibility?.photoUrl) ? source._photoUrl : null,
      pronunciationUrl: permitted.contains(visibility?.pronunciationUrl) ? source._pronunciationUrl : null,

      website: permitted.contains(visibility?.website) ? source._website : null,

      address: permitted.contains(visibility?.address) ? source._address : null,
      address2: permitted.contains(visibility?.address2) ? source._address2 : null,
      poBox: permitted.contains(visibility?.poBox) ? source._poBox : null,
      city: permitted.contains(visibility?.city) ? source._city : null,
      zip: permitted.contains(visibility?.zip) ? source._zip : null,
      state: permitted.contains(visibility?.state) ? source._state : null,
      country: permitted.contains(visibility?.country) ? source._country : null,

      data: Auth2UserProfileFieldsVisibility.buildPermitted(source._data, visibility?.data , permitted: permitted),
    );
  }

  factory Auth2UserProfile.empty() {
    return Auth2UserProfile();
  }

  static Auth2UserProfile? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2UserProfile(
      id: JsonUtils.stringValue(json['id']),

      firstName: JsonUtils.stringValue(json['first_name']),
      middleName: JsonUtils.stringValue(json['middle_name']),
      lastName: JsonUtils.stringValue(json['last_name']),
      pronouns: JsonUtils.stringValue(json['pronouns']),

      birthYear: JsonUtils.intValue(json['birth_year']),
      photoUrl: JsonUtils.stringValue(json['photo_url']),
      pronunciationUrl: JsonUtils.stringValue(json['pronunciation_url']),

      website: JsonUtils.stringValue(json['website']),

      address: JsonUtils.stringValue(json['address']),
      address2: JsonUtils.stringValue(json['address2']),
      poBox: JsonUtils.stringValue(json['po_box']),
      city: JsonUtils.stringValue(json['city']),
      zip: JsonUtils.stringValue(json['zip_code']),
      state: JsonUtils.stringValue(json['state']),
      country: JsonUtils.stringValue(json['country']),

      data: JsonUtils.mapValue(json['unstructured_properties']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : _id,

      'first_name': _firstName,
      'middle_name': _middleName,
      'last_name': _lastName,
      'pronouns': _pronouns,

      'birth_year': _birthYear,
      'photo_url': _photoUrl,
      'pronunciation_url': _pronunciationUrl,

      'website': _website,

      'address': _address,
      'address2': _address2,
      'po_box': _poBox,
      'city': _city,
      'zip_code': _zip,
      'state': _state,
      'country': _country,

      'unstructured_properties': _data,
    };
  }

  @override
  bool operator ==(other) =>
    (other is Auth2UserProfile) &&
      (other._id == _id) &&

      (other._firstName == _firstName) &&
      (other._middleName == _middleName) &&
      (other._lastName == _lastName) &&
      (other._pronouns == _pronouns) &&

      (other._birthYear == _birthYear) &&
      (other._photoUrl == _photoUrl) &&
      (other._pronunciationUrl == _pronunciationUrl) &&

      (other._website == _website) &&

      (other._address == _address) &&
      (other._address2 == _address2) &&
      (other._poBox == _poBox) &&
      (other._city == _city) &&
      (other._zip == _zip) &&
      (other._state == _state) &&
      (other._country == _country) &&

      const DeepCollectionEquality().equals(other._data, _data);

  @override
  int get hashCode =>
    (_id?.hashCode ?? 0) ^

    (_firstName?.hashCode ?? 0) ^
    (_middleName?.hashCode ?? 0) ^
    (_lastName?.hashCode ?? 0) ^
    (_pronouns?.hashCode ?? 0) ^

    (_birthYear?.hashCode ?? 0) ^
    (_photoUrl?.hashCode ?? 0) ^
    (_pronunciationUrl?.hashCode ?? 0) ^

    (_website?.hashCode ?? 0) ^

    (_address?.hashCode ?? 0) ^
    (_address2?.hashCode ?? 0) ^
    (_poBox?.hashCode ?? 0) ^
    (_city?.hashCode ?? 0) ^
    (_zip?.hashCode ?? 0) ^
    (_state?.hashCode ?? 0) ^
    (_country?.hashCode ?? 0) ^

    (const DeepCollectionEquality().hash(_data));

  bool apply(Auth2UserProfile? profile, { Set<Auth2UserProfileScope>? scope = defaultProfileScope}) {
    bool modified = false;
    if (profile != null) {
      /*if ((profile._id != _id) && (profile._id?.isNotEmpty ?? false)) {
        _id = profile._id;
        modified = true;
      }*/
      if ((profile._firstName != _firstName) && (
          (scope?.contains(Auth2UserProfileScope.firstName) == true) ||
          ((profile._firstName?.isNotEmpty ?? false) && (_firstName?.isEmpty ?? true))
      )) {
        _firstName = profile._firstName;
        modified = true;
      }
      if ((profile._middleName != _middleName) && (
          (scope?.contains(Auth2UserProfileScope.middleName) == true) ||
          ((profile._middleName?.isNotEmpty ?? false) && (_middleName?.isEmpty ?? true))
      )) {
        _middleName = profile._middleName;
        modified = true;
      }
      if ((profile._lastName != _lastName) && (
          (scope?.contains(Auth2UserProfileScope.lastName) == true) ||
          ((profile._lastName?.isNotEmpty ?? false) && (_lastName?.isEmpty ?? true))
      )) {
        _lastName = profile._lastName;
        modified = true;
      }
      if ((profile._pronouns != _pronouns) && (
          (scope?.contains(Auth2UserProfileScope.pronouns) == true) ||
          ((profile._pronouns?.isNotEmpty ?? false) && (_pronouns?.isEmpty ?? true))
      )) {
        _pronouns = profile._pronouns;
        modified = true;
      }

      if ((profile._birthYear != _birthYear) && (
          (scope?.contains(Auth2UserProfileScope.birthYear) == true) ||
          (((profile._birthYear ?? 0) != 0) && ((_birthYear ?? 0) == 0))
      )) {
        _birthYear = profile._birthYear;
        modified = true;
      }
      if ((profile._photoUrl != _photoUrl) && (
          (scope?.contains(Auth2UserProfileScope.phone) == true) ||
          ((profile._photoUrl?.isNotEmpty ?? false) && (_photoUrl?.isEmpty ?? true))
      )) {
        _photoUrl = profile._photoUrl;
        modified = true;
      }
      if ((profile._pronunciationUrl != _pronunciationUrl) && (
          (scope?.contains(Auth2UserProfileScope.pronunciationUrl) == true) ||
          ((profile._pronunciationUrl?.isNotEmpty ?? false) && (_pronunciationUrl?.isEmpty ?? true))
      )) {
        _pronunciationUrl = profile._pronunciationUrl;
        modified = true;
      }

      if ((profile._website != _website) && (
          (scope?.contains(Auth2UserProfileScope.website) == true) ||
          ((profile._website?.isNotEmpty ?? false) && (_website?.isEmpty ?? true))
      )) {
        _website = profile._website;
        modified = true;
      }

      if ((profile._address != _address) && (
          (scope?.contains(Auth2UserProfileScope.address) == true) ||
          ((profile._address?.isNotEmpty ?? false) && (_address?.isEmpty ?? true))
      )) {
        _address = profile._address;
        modified = true;
      }
      if ((profile._address2 != _address2) && (
          (scope?.contains(Auth2UserProfileScope.address2) == true) ||
              ((profile._address2?.isNotEmpty ?? false) && (_address2?.isEmpty ?? true))
      )) {
        _address2 = profile._address2;
        modified = true;
      }
      if ((profile._poBox != _poBox) && (
          (scope?.contains(Auth2UserProfileScope.poBox) == true) ||
              ((profile._poBox?.isNotEmpty ?? false) && (_poBox?.isEmpty ?? true))
      )) {
        _poBox = profile._poBox;
        modified = true;
      }
      if ((profile._city != _city) && (
          (scope?.contains(Auth2UserProfileScope.city) == true) ||
              ((profile._city?.isNotEmpty ?? false) && (_city?.isEmpty ?? true))
      )) {
        _city = profile._city;
        modified = true;
      }
      if ((profile._zip != _zip) && (
          (scope?.contains(Auth2UserProfileScope.zip) == true) ||
          ((profile._zip?.isNotEmpty ?? false) && (_zip?.isEmpty ?? true))
      )) {
        _zip = profile._zip;
        modified = true;
      }
      if ((profile._state != _state) && (
          (scope?.contains(Auth2UserProfileScope.state) == true) ||
          ((profile._state?.isNotEmpty ?? false) && (_state?.isEmpty ?? true))
      )) {
        _state = profile._state;
        modified = true;
      }
      if ((profile._country != _country) && (
          (scope?.contains(Auth2UserProfileScope.country) == true) ||
          ((profile._country?.isNotEmpty ?? false) && (_country?.isEmpty ?? true))
      )) {
        _country = profile._country;
        modified = true;
      }

      if (!const DeepCollectionEquality().equals(profile._data, _data)) {
        Map<String, dynamic>? data = MapUtils.apply(_data, profile._data);
        if (!const DeepCollectionEquality().equals(_data, data)) {
          _data = data;
          modified = true;
        }
      }
    }
    return modified;
  }
  
  String? get id => _id;
  String? get firstName => _firstName;
  String? get middleName => _middleName;
  String? get lastName => _lastName;
  String? get pronouns => _pronouns;

  int?    get birthYear => _birthYear;
  String? get photoUrl => _photoUrl;
  String? get pronunciationUrl => _pronunciationUrl;

  String? get website => _website;

  String? get address => _address;
  String? get address2 => _address2;
  String? get poBox => _poBox;
  String? get city => _city;
  String? get zip => _zip;
  String? get state => _state;
  String? get country => _country;

  Map<String, dynamic>? get data => _data;

  bool   get isValid => StringUtils.isNotEmpty(id);
  String? get fullName => StringUtils.fullName([firstName, middleName, lastName]);
  bool get isFacultyStaff => universityRole == universityRoleFacultyStaff;

  // Other Data Fields


  String? get universityRole => JsonUtils.stringValue(_data?[universityRoleDataKey]);
  String? get college => JsonUtils.stringValue(_data?[collegeDataKey]);
  String? get department => JsonUtils.stringValue(_data?[departmentDataKey]);
  String? get major => JsonUtils.stringValue(_data?[majorDataKey]);
  String? get department2 => JsonUtils.stringValue(_data?[department2DataKey]);
  String? get major2 => JsonUtils.stringValue(_data?[major2DataKey]);
  String? get title => JsonUtils.stringValue(_data?[titleDataKey]);

  String? get email2 => JsonUtils.stringValue(_data?[email2DataKey]);

  // Research Questionnaire Answers

  Map<String, dynamic>? get researchQuestionnaireAnswers => JsonUtils.mapValue(MapUtils.get(_data, researchQuestionnaireAnswersDataKey));

  set researchQuestionnaireAnswers(Map<String, dynamic>? value) {
    if (value != null) {
      _data ??= <String, dynamic>{};
      _data![researchQuestionnaireAnswersDataKey] = value;
    }
    else if (_data != null) {
      _data?.remove(researchQuestionnaireAnswersDataKey);
    }
  }

  Map<String, LinkedHashSet<String>>? getResearchQuestionnaireAnswers(String? questionnaireId) {
    return JsonUtils.mapOfStringToLinkedHashSetOfStringsValue(MapUtils.get(researchQuestionnaireAnswers, questionnaireId));
  }

  void setResearchQuestionnaireAnswers(String? questionnaireId, Map<String, LinkedHashSet<String>>? questionnaireAnswers) {
    Map<String, dynamic>? answersJson = JsonUtils.mapOfStringToLinkedHashSetOfStringsJsonValue(questionnaireAnswers);
    Map<String, dynamic>? lastAnswersJson = JsonUtils.mapValue(MapUtils.get(researchQuestionnaireAnswers, questionnaireId));
    if (!const DeepCollectionEquality().equals(answersJson, lastAnswersJson)) {
      researchQuestionnaireAnswers ??= <String, dynamic>{};
      MapUtils.set(researchQuestionnaireAnswers, questionnaireId, answersJson);
      NotificationService().notify(notifyDataChanged, researchQuestionnaireAnswersDataKey);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void clearAllResearchQuestionnaireAnswers() {
    if (researchQuestionnaireAnswers?.isNotEmpty ?? false) {
      researchQuestionnaireAnswers?.clear();
      NotificationService().notify(notifyDataChanged, researchQuestionnaireAnswersDataKey);
      NotificationService().notify(notifyChanged, this);
    }
  }

  // JSON List Serialization

  static List<Auth2UserProfile>? listFromJson(List<dynamic>? json) {
    List<Auth2UserProfile>? values;
    if (json != null) {
      values = <Auth2UserProfile>[];
      for (dynamic entry in json) {
        ListUtils.add(values, Auth2UserProfile.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<Auth2UserProfile>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = [];
      for (Auth2UserProfile value in values) {
        json.add(value.toJson());
      }
    }
    return json;
  }
}

////////////////////////////////
// Auth2UserProfilePrivacy

class Auth2UserProfileFieldsVisibility {

  final Auth2FieldVisibility? firstName;
  final Auth2FieldVisibility? middleName;
  final Auth2FieldVisibility? lastName;
  final Auth2FieldVisibility? pronouns;

  final Auth2FieldVisibility? birthYear;
  final Auth2FieldVisibility? photoUrl;
  final Auth2FieldVisibility? pronunciationUrl;

  final Auth2FieldVisibility? website;

  final Auth2FieldVisibility? address;
  final Auth2FieldVisibility? address2;
  final Auth2FieldVisibility? poBox;
  final Auth2FieldVisibility? city;
  final Auth2FieldVisibility? zip;
  final Auth2FieldVisibility? state;
  final Auth2FieldVisibility? country;

  final Map<String, Auth2FieldVisibility?>? data;

  Auth2UserProfileFieldsVisibility({
    this.firstName, this.middleName, this.lastName, this.pronouns,
    this.birthYear, this.photoUrl, this.pronunciationUrl,
    this.email, this.phone, this.website,
    this.address, this.address2, this.poBox, this.city, this.zip, this.state, this.country,
    this.data
  });

  factory Auth2UserProfileFieldsVisibility.fromOther(Auth2UserProfileFieldsVisibility? other, {
    Auth2FieldVisibility? firstName,
    Auth2FieldVisibility? middleName,
    Auth2FieldVisibility? lastName,
    Auth2FieldVisibility? pronouns,

    Auth2FieldVisibility? birthYear,
    Auth2FieldVisibility? photoUrl,
    Auth2FieldVisibility? pronunciationUrl,

    Auth2FieldVisibility? website,

    Auth2FieldVisibility? address,
    Auth2FieldVisibility? address2,
    Auth2FieldVisibility? poBox,
    Auth2FieldVisibility? city,
    Auth2FieldVisibility? zip,
    Auth2FieldVisibility? state,
    Auth2FieldVisibility? country,

    Map<String, Auth2FieldVisibility?>? data
  }) => Auth2UserProfileFieldsVisibility(
    firstName: firstName ?? other?.firstName,
    middleName: middleName ?? other?.middleName,
    lastName: lastName ?? other?.lastName,
    pronouns: pronouns ?? other?.pronouns,

    birthYear: birthYear ?? other?.birthYear,
    photoUrl: photoUrl ?? other?.photoUrl,
    pronunciationUrl: photoUrl ?? other?.pronunciationUrl,

    website: website ?? other?.website,

    address: address ?? other?.address,
    address2: address2 ?? other?.address2,
    poBox: poBox ?? other?.poBox,
    city: city ?? other?.city,
    zip: zip ?? other?.zip,
    state: state ?? other?.state,
    country: country ?? other?.country,

    data: MapUtils.combine(other?.data, data),
  );

  static Auth2UserProfileFieldsVisibility? fromJson(Map<String, dynamic>? json) => (json != null) ? Auth2UserProfileFieldsVisibility(
    firstName: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['first_name'])),
    middleName: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['middle_name'])),
    lastName: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['last_name'])),
    pronouns: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['pronouns'])),

    birthYear: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['birth_year'])),
    photoUrl: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['photo_url'])),
    pronunciationUrl: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['pronunciation_url'])),

    website: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['website'])),

    address: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['address'])),
    address2: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['address2'])),
    poBox: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['poBox'])),
    city: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['city'])),
    zip: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['zip_code'])),
    state: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['state'])),
    country: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['country'])),

    data: Auth2FieldVisibilityImpl.mapFromJson(JsonUtils.mapValue(json['unstructured_properties'])),
  ) : null;

  // PUT services/account/privacy does not accept null field values but accepts their omission.
  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName?.toJson(),
      'middle_name': middleName?.toJson(),
      'last_name': lastName?.toJson(),
      'pronouns': pronouns?.toJson(),

      'birth_year': birthYear?.toJson(),
      'photo_url': photoUrl?.toJson(),
      'pronunciation_url': pronunciationUrl?.toJson(),

      'website': website?.toJson(),

      'address': address?.toJson(),
      'address2': address2?.toJson(),
      'poBox': poBox?.toJson(),
      'city': city?.toJson(),
      'zip_code': zip?.toJson(),
      'state': state?.toJson(),
      'country': country?.toJson(),

      'unstructured_properties': Auth2FieldVisibilityImpl.mapToJson(data),
    };
  }

  @override
  bool operator ==(other) =>
    (other is Auth2UserProfileFieldsVisibility) &&
      (other.firstName == firstName) &&
      (other.middleName == middleName) &&
      (other.lastName == lastName) &&
      (other.pronouns == pronouns) &&

      (other.birthYear == birthYear) &&
      (other.photoUrl == photoUrl) &&
      (other.pronunciationUrl == pronunciationUrl) &&

      (other.website == website) &&

      (other.address == address) &&
      (other.address2 == address2) &&
      (other.poBox == poBox) &&
      (other.city == city) &&
      (other.zip == zip) &&
      (other.state == state) &&
      (other.country == country) &&

      const DeepCollectionEquality().equals(other.data, data);

  @override
  int get hashCode =>
    (firstName?.hashCode ?? 0) ^
    (middleName?.hashCode ?? 0) ^
    (lastName?.hashCode ?? 0) ^
    (pronouns?.hashCode ?? 0) ^

    (birthYear?.hashCode ?? 0) ^
    (photoUrl?.hashCode ?? 0) ^
    (pronunciationUrl?.hashCode ?? 0) ^

    (website?.hashCode ?? 0) ^

    (address?.hashCode ?? 0) ^
    (address2?.hashCode ?? 0) ^
    (poBox?.hashCode ?? 0) ^
    (city?.hashCode ?? 0) ^
    (zip?.hashCode ?? 0) ^
    (state?.hashCode ?? 0) ^
    (country?.hashCode ?? 0) ^

    (const DeepCollectionEquality().hash(data));

  // Other Data dields

  Auth2FieldVisibility? get universityRole => data?[Auth2UserProfile.universityRoleDataKey];
  Auth2FieldVisibility? get college => data?[Auth2UserProfile.collegeDataKey];
  Auth2FieldVisibility? get department => data?[Auth2UserProfile.departmentDataKey];
  Auth2FieldVisibility? get major => data?[Auth2UserProfile.majorDataKey];
  Auth2FieldVisibility? get department2 => data?[Auth2UserProfile.department2DataKey];
  Auth2FieldVisibility? get major2 => data?[Auth2UserProfile.major2DataKey];
  Auth2FieldVisibility? get title => data?[Auth2UserProfile.titleDataKey];

  Auth2FieldVisibility? get email2 => data?[Auth2UserProfile.email2DataKey];

  static Map<String, dynamic>? buildPermitted(Map<String, dynamic>? source, Map<String, Auth2FieldVisibility?>? visibility, {
    required Set<Auth2FieldVisibility> permitted
  }) => (source != null) ? source.map((String key, dynamic value) => MapEntry(key, permitted.contains(visibility?[key]) ? value : null)) : null;
}


////////////////////////////////
// Auth2StringEntry

class Auth2StringEntry {
  final String? id;
  final String? name;
  
  Auth2StringEntry({this.id, this.name});

  factory Auth2StringEntry.fromJson(Map<String, dynamic> json) => Auth2StringEntry(
    id: JsonUtils.stringValue(json['id']),
    name: JsonUtils.stringValue(json['name']),
  );

  Map<String, dynamic> toJson() => {
    'id' : id,
    'name': name,
  };

  @override
  bool operator ==(other) => (other is Auth2StringEntry) &&
    (other.id == id) &&
    (other.name == name);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (name?.hashCode ?? 0);

  static List<Auth2StringEntry>? listFromJson(List<dynamic>? jsonList) {
    List<Auth2StringEntry>? result;
    if (jsonList != null) {
      result = <Auth2StringEntry>[];
      for (dynamic jsonEntry in jsonList) {
        Map<String, dynamic>? jsonMap = JsonUtils.mapValue(jsonEntry);
        if (jsonMap != null) {
          result.add(Auth2StringEntry.fromJson(jsonMap));
        }
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Auth2StringEntry>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (Auth2StringEntry contentEntry in contentList) {
        jsonList.add(contentEntry.toJson());
      }
    }
    return jsonList;
  }

  static Auth2StringEntry? findInList(List<Auth2StringEntry>? contentList, { String? name }) {
    if (contentList != null) {
      for (Auth2StringEntry contentEntry in contentList) {
        if (contentEntry.name == name) {
          return contentEntry;
        }
      }
    }
    return null;
  }
}

////////////////////////////////
// Auth2Permission

class Auth2Permission extends Auth2StringEntry {
  Auth2Permission({super.id, super.name});

  factory Auth2Permission.fromBase(Auth2StringEntry other) => Auth2Permission(
    id: other.id, name: other.name,
  );

  factory Auth2Permission.fromJson(Map<String, dynamic> json) =>
    Auth2Permission.fromBase(Auth2StringEntry.fromJson(json));

  bool hasPermission(String? permission) => (name == permission);

  static List<Auth2Permission>? listFromJson(List<dynamic>? jsonList) {
    List<Auth2Permission>? result;
    if (jsonList != null) {
      result = <Auth2Permission>[];
      for (dynamic jsonEntry in jsonList) {
        Map<String, dynamic>? jsonMap = JsonUtils.mapValue(jsonEntry);
        if (jsonMap != null) {
          result.add(Auth2Permission.fromJson(jsonMap));
        }
      }
    }
    return result;
  }

  static Auth2Permission? findInList(List<Auth2Permission>? contentList, { String? permission }) =>
    JsonUtils.cast(Auth2StringEntry.findInList(contentList, name: permission));
}

////////////////////////////////
// Auth2Role

class Auth2Role extends Auth2Permission {
  final List<Auth2Permission>? permissions;

  Auth2Role({super.id, super.name, this.permissions});

  factory Auth2Role.fromBase(Auth2Permission other, { List<Auth2Permission>? permissions }) => Auth2Role(
    id: other.id, name: other.name,
    permissions: permissions,
  );

  factory Auth2Role.fromJson(Map<String, dynamic> json) =>
    Auth2Role.fromBase(Auth2Permission.fromJson(json),
      permissions: Auth2Permission.listFromJson(JsonUtils.listValue(json['permissions'])),
    );

  @override
  Map<String, dynamic> toJson() =>
    super.toJson()..addAll({
      'permissions': Auth2StringEntry.listToJson(permissions)
    });

  @override
  bool operator ==(other) => (other is Auth2Role) && (super == other) &&
    (const DeepCollectionEquality().equals(other.permissions, permissions));

  @override
  int get hashCode => super.hashCode ^
    const DeepCollectionEquality().hash(permissions);

  bool hasPermission(String? permission) =>
    (Auth2Permission.findInList(permissions, permission: permission) != null);

  static List<Auth2Role>? listFromJson(List<dynamic>? jsonList) {
    List<Auth2Role>? result;
    if (jsonList != null) {
      result = <Auth2Role>[];
      for (dynamic jsonEntry in jsonList) {
        Map<String, dynamic>? jsonMap = JsonUtils.mapValue(jsonEntry);
        if (jsonMap != null) {
          result.add(Auth2Role.fromJson(jsonMap));
        }
      }
    }
    return result;
  }

  static Auth2Role? findInList(List<Auth2Role>? contentList, { String? permission }) {
    if (contentList != null) {
      for (Auth2Role contentEntry in contentList) {
        if (contentEntry.hasPermission(permission)) {
          return contentEntry;
        }
      }
    }
    return null;
  }

  static Set<Auth2Permission> permissionsInList(List<Auth2Role>? contentList) {
    Set<Auth2Permission> permissions = <Auth2Permission>{};
    if (contentList != null) {
      for (Auth2Role contentEntry in contentList) {
        if (contentEntry.permissions != null) {
          permissions.union(Set<Auth2Permission>.of(contentEntry.permissions!));
        }
      }
    }
    return permissions;
  }
}

////////////////////////////////
// Auth2Group

class Auth2Group extends Auth2Role {
  final List<Auth2Role>? roles;

  Auth2Group({super.id, super.name, super.permissions, this.roles});

  factory Auth2Group.fromBase(Auth2Role other, { List<Auth2Role>? roles }) => Auth2Group(
    id: other.id, name: other.name, permissions: other.permissions,
    roles: roles,
  );

  factory Auth2Group.fromJson(Map<String, dynamic> json) =>
    Auth2Group.fromBase(Auth2Role.fromJson(json),
      roles: Auth2Role.listFromJson(JsonUtils.listValue(json['roles'])),
    );

  @override
  Map<String, dynamic> toJson() =>
    super.toJson()..addAll({
      'roles': Auth2StringEntry.listToJson(roles)
    });

  @override
  bool operator ==(other) => (other is Auth2Group) && (super == other) &&
    (const DeepCollectionEquality().equals(other.roles, roles));

  @override
  int get hashCode => super.hashCode ^
    const DeepCollectionEquality().hash(roles);

  bool hasPermission(String? permission) => super.hasPermission(permission) ||
    (Auth2Role.findInList(roles, permission: permission) != null);

  static List<Auth2Group>? listFromJson(List<dynamic>? jsonList) {
    List<Auth2Group>? result;
    if (jsonList != null) {
      result = <Auth2Group>[];
      for (dynamic jsonEntry in jsonList) {
        Map<String, dynamic>? jsonMap = JsonUtils.mapValue(jsonEntry);
        if (jsonMap != null) {
          result.add(Auth2Group.fromJson(jsonMap));
        }
      }
    }
    return result;
  }

  static Auth2Group? findInList(List<Auth2Group>? contentList, { String? permission }) {
    if (contentList != null) {
      for (Auth2Group contentEntry in contentList) {
        if (contentEntry.hasPermission(permission)) {
          return contentEntry;
        }
      }
    }
    return null;
  }

  static Set<Auth2Permission> permissionsInList(List<Auth2Group>? contentList) {
    Set<Auth2Permission> permissions = <Auth2Permission>{};
    if (contentList != null) {
      for (Auth2Group contentEntry in contentList) {
        if (contentEntry.roles != null) {
          permissions.union(Auth2Role.permissionsInList(contentEntry.roles),);
        }
      }
    }
    return permissions;
  }

  static Set<Auth2Role> rolesInList(List<Auth2Group>? contentList) {
    Set<Auth2Role> roles = <Auth2Role>{};
    if (contentList != null) {
      for (Auth2Group contentEntry in contentList) {
        if (contentEntry.roles != null) {
          roles.union(Set<Auth2Role>.of(contentEntry.roles!));
        }
      }
    }
    return roles;
  }
}

////////////////////////////////
// Auth2UserProfileScope

enum Auth2UserProfileScope {
  firstName, middleName, lastName, pronouns,
  birthYear, photoUrl, pronunciationUrl,
  email, phone, website,
  address, address2, poBox, city, zip, state, country,
}

extension Auth2UserProfileScopeImpl on Auth2UserProfileScope {

  static Auth2UserProfileScope? fromString(String value) => Auth2UserProfileScope.values.firstWhereOrNull((field) => (field.toString() == value));

  static Set<Auth2UserProfileScope> get fullScope => Set<Auth2UserProfileScope>.from(Auth2UserProfileScope.values);

  T? pick<T>(T? v, T? d, { Set<Auth2UserProfileScope>? scope }) =>
    (scope != null) ? (scope.contains(this) ? v : d) : (v ?? d);

  String? pickString(String? v, String? d, { Set<Auth2UserProfileScope>? scope }) =>
    (scope != null) ? (scope.contains(this) ? v : d) : ((v?.isNotEmpty == true) ? v : d);

  int? pickInt(int? v, int? d, { Set<Auth2UserProfileScope>? scope }) =>
    (scope != null) ? (scope.contains(this) ? v : d) : (((v ?? 0) != 0) ? v : d);
}

////////////////////////////////
// Auth2Identifier

class Auth2Identifier {
  static const String typeEmail = 'email';
  static const String typePhone = 'phone';
  static const String typeUsername = 'username';
  static const String typeUin = 'uin';
  static const String typeNetId = 'net_id';

  final String? id;
  final String? code;
  final String? identifier;
  final bool? verified;
  final bool? linked;
  final bool? sensitive;
  final String? accountAuthTypeId;

  Auth2Identifier({this.id, this.code, this.identifier, this.verified, this.linked, this.sensitive, this.accountAuthTypeId});

  static Auth2Identifier? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2Identifier(
      id: JsonUtils.stringValue(json['id']),
      code: JsonUtils.stringValue(json['code']),
      identifier: JsonUtils.stringValue(json['identifier']),
      verified: JsonUtils.boolValue(json['verified']),
      linked: JsonUtils.boolValue(json['linked']),
      sensitive: JsonUtils.boolValue(json['sensitive']),
      accountAuthTypeId: JsonUtils.stringValue(json['account_auth_type_id']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'code': code,
      'identifier': identifier,
      'verified': verified,
      'linked': linked,
      'sensitive': sensitive,
      'account_auth_type_id': accountAuthTypeId,
    };
  }

  @override
  bool operator ==(other) =>
    (other is Auth2Identifier) &&
      (other.id == id) &&
      (other.code == code) &&
      (other.identifier == identifier) &&
      (other.verified == verified) &&
      (other.linked == linked) &&
      (other.sensitive == sensitive) &&
      (other.accountAuthTypeId == accountAuthTypeId);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (identifier?.hashCode ?? 0) ^
    (code?.hashCode ?? 0) ^
    (verified?.hashCode ?? 0) ^
    (linked?.hashCode ?? 0) ^
    (sensitive?.hashCode ?? 0) ^
    (accountAuthTypeId?.hashCode ?? 0);

  String? get uin {
    return (code == typeUin) ? identifier : null;
  }

  String? get phone {
    return (code == typePhone) ? identifier : null;
  }

  String? get email {
    return (code == typeEmail) ? identifier : null;
  }

  String? get username {
    return (code == typeUsername) ? identifier : null;
  }

  static List<Auth2Identifier>? listFromJson(List<dynamic>? jsonList) {
    List<Auth2Identifier>? result;
    if (jsonList != null) {
      result = <Auth2Identifier>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Auth2Identifier.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Auth2Identifier>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

////////////////////////////////
// Auth2Type

class Auth2Type {
  static const String typeAnonymous = 'anonymous';
  static const String typeApiKey = 'api_key';
  static const String typePassword = 'password';
  static const String typeCode = 'code';
  static const String typeOidc = 'oidc';
  static const String typeOidcIllinois = 'illinois_oidc';
  static const String typePasskey = 'webauthn';

  final String? id;
  final String? code;
  final bool? active;
  final bool? hasCredential;
  final Map<String, dynamic>? params;
  final DateTime? dateCreated;
  final DateTime? dateUpdated;

  final Auth2UiucUser? uiucUser;

  Auth2Type({this.id, this.code, this.active, this.hasCredential, this.params, this.dateCreated, this.dateUpdated}) :
        uiucUser = (params != null) ? Auth2UiucUser.fromJson(JsonUtils.mapValue(params['user'])) : null;

  static Auth2Type? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2Type(
      id: JsonUtils.stringValue(json['id']),
      code: JsonUtils.stringValue(json['auth_type_code']),
      active: JsonUtils.boolValue(json['active']),
      hasCredential: JsonUtils.boolValue(json['has_credential']),
      params: JsonUtils.mapValue(json['params']),
      dateCreated: AppDateTime().dateTimeLocalFromJson(json['date_created']),
      dateUpdated: AppDateTime().dateTimeLocalFromJson(json['date_updated']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'auth_type_code': code,
      'active': active,
      'has_credential': hasCredential,
      'params': params,
      'date_created': AppDateTime().dateTimeLocalToJson(dateCreated),
      'date_updated': AppDateTime().dateTimeLocalToJson(dateUpdated),
    };
  }

  @override
  bool operator ==(other) =>
    (other is Auth2Type) &&
      (other.id == id) &&
      (other.code == code) &&
      (other.active == active) &&
      (other.hasCredential == hasCredential) &&
      const DeepCollectionEquality().equals(other.params, params);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (code?.hashCode ?? 0) ^
    (active?.hashCode ?? 0) ^
    (hasCredential?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(params));

  static List<Auth2Type>? listFromJson(List<dynamic>? jsonList) {
    List<Auth2Type>? result;
    if (jsonList != null) {
      result = <Auth2Type>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Auth2Type.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Auth2Type>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  String? get platformName {
    if (code == typePasskey) {
      dynamic appTypeIdentifier = params?['app_type_identifier'];
      if (appTypeIdentifier is String) {
        if (appTypeIdentifier.contains('https')) {
          return 'web';
        }
        List<String> appTypeIdentifierParts = appTypeIdentifier.split('.');
        if (appTypeIdentifierParts.isNotEmpty) {
          return appTypeIdentifierParts.last;
        }
      }
    }
    return null;
  }

  bool get hasValidCredential {
    switch (code) {
      case typePassword: return hasCredential ?? true;
      case typePasskey: return hasCredential ?? true;
      default: return true;
    }
  }
}

////////////////////////////////
// Auth2Message

class Auth2Message {
  final String? message;
  final Map<String, dynamic>? params;

  Auth2Message({this.message, this.params});

  static Auth2Message? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2Message(
      message: JsonUtils.stringValue(json['message']),
      params: JsonUtils.mapValue(json['params']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'params' : params,
    };
  }

  @override
  bool operator ==(other) =>
      (other is Auth2Message) &&
          (other.params == params) &&
          (other.message == message);

  @override
  int get hashCode =>
      (params?.hashCode ?? 0) ^
      (message?.hashCode ?? 0);

}

////////////////////////////////
// Auth2Error

class Auth2Error {
  final String? status;
  final String? message;
  
  Auth2Error({this.status, this.message});

  static Auth2Error? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2Error(
      status: JsonUtils.stringValue(json['status']),
      message: JsonUtils.stringValue(json['message']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'status' : status,
      'message': message,
    };
  }

  @override
  bool operator ==(other) =>
    (other is Auth2Error) &&
      (other.status == status) &&
      (other.message == message);

  @override
  int get hashCode =>
    (status?.hashCode ?? 0) ^
    (message?.hashCode ?? 0);

}

////////////////////////////////
// Auth2UiucUser

class Auth2UiucUser {
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? identifier;
  final List<String>? groups;
  final Map<String, dynamic>? systemSpecific;
  final Set<String>? groupsMembership;
  
  Auth2UiucUser({this.email, this.firstName, this.lastName, this.middleName, this.identifier, this.groups, this.systemSpecific}) :
    groupsMembership = (groups != null) ? Set.from(groups) : null;

  static Auth2UiucUser? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2UiucUser(
      email: JsonUtils.stringValue(json['email']),
      firstName: JsonUtils.stringValue(json['first_name']),
      lastName: JsonUtils.stringValue(json['last_name']),
      middleName: JsonUtils.stringValue(json['middle_name']),
      identifier: JsonUtils.stringValue(json['identifier']),
      groups: JsonUtils.stringListValue(json['groups']),
      systemSpecific: JsonUtils.mapValue(json['system_specific']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'email' : email,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'identifier': identifier,
      'groups': groups,
      'system_specific': systemSpecific,
    };
  }

  @override
  bool operator ==(other) =>
    (other is Auth2UiucUser) &&
      (other.email == email) &&
      (other.firstName == firstName) &&
      (other.lastName == lastName) &&
      (other.middleName == middleName) &&
      (other.identifier == identifier) &&
      const DeepCollectionEquality().equals(other.groups, groups) &&
      const DeepCollectionEquality().equals(other.systemSpecific, systemSpecific);

  @override
  int get hashCode =>
    (email?.hashCode ?? 0) ^
    (firstName?.hashCode ?? 0) ^
    (lastName?.hashCode ?? 0) ^
    (middleName?.hashCode ?? 0) ^
    (identifier?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(groups)) ^
    (const DeepCollectionEquality().hash(systemSpecific));

  String? get uin {
    return ((systemSpecific != null) ? JsonUtils.stringValue(systemSpecific!['uiucedu_uin']) : null) ?? identifier;
  }

  String? get netId {
    return (systemSpecific != null) ? JsonUtils.stringValue(systemSpecific!['preferred_username']) : null;
  }

  String? get fullName {
    return StringUtils.fullName([firstName, middleName, lastName]);
  }

  static List<Auth2UiucUser>? listFromJson(List<dynamic>? jsonList) {
    List<Auth2UiucUser>? result;
    if (jsonList != null) {
      result = <Auth2UiucUser>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Auth2UiucUser.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Auth2UiucUser>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

////////////////////////////////
// Auth2UserPrefs

class Auth2UserPrefs {

  static const String notifyPrivacyLevelChanged  = "edu.illinois.rokwire.user.prefs.privacy.level.changed";
  static const String notifyRolesChanged         = "edu.illinois.rokwire.user.prefs.roles.changed";
  static const String notifyFavoriteChanged      = "edu.illinois.rokwire.user.prefs.favorite.changed";
  static const String notifyFavoritesChanged     = "edu.illinois.rokwire.user.prefs.favorites.changed";
  static const String notifyInterestsChanged     = "edu.illinois.rokwire.user.prefs.interests.changed";
  static const String notifyFoodChanged          = "edu.illinois.rokwire.user.prefs.food.changed";
  static const String notifyTagsChanged          = "edu.illinois.rokwire.user.prefs.tags.changed";
  static const String notifySettingsChanged      = "edu.illinois.rokwire.user.prefs.settings.changed";
  static const String notifyAnonymousIdsChanged  = "edu.illinois.rokwire.user.prefs.anonymous_ids.changed";
  static const String notifyVoterChanged         = "edu.illinois.rokwire.user.prefs.voter.changed";
  static const String notifyChanged              = "edu.illinois.rokwire.user.prefs.changed";

  static const String _foodIncludedTypes         = "included_types";
  static const String _foodExcludedIngredients   = "excluded_ingredients";

  int? _privacyLevel;
  Set<UserRole>? _roles;
  Map<String, LinkedHashSet<String>>?  _favorites;
  Map<String, Set<String>>?  _interests;
  Map<String, Set<String>>?  _foodFilters;
  Map<String, bool>? _tags;
  Map<String, dynamic>? _settings;
  Auth2VoterPrefs? _voter;
  Map<String, DateTime>? _anonymousIds;

  Auth2UserPrefs({int? privacyLevel, Set<UserRole>? roles, Map<String, LinkedHashSet<String>>? favorites, Map<String, Set<String>>? interests, Map<String, Set<String>>? foodFilters, Map<String, bool>? tags, Map<String, dynamic>? answers, Map<String, dynamic>? settings, Auth2VoterPrefs? voter, Map<String, DateTime>? anonymousIds}) {
    _privacyLevel = privacyLevel;
    _roles = roles;
    _favorites = favorites;
    _interests = interests;
    _foodFilters = foodFilters;
    _tags = tags;
    _settings = settings;
    _voter = Auth2VoterPrefs.fromOther(voter, onChanged: _onVoterChanged);
    _anonymousIds = anonymousIds;
  }

  static Auth2UserPrefs? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2UserPrefs(
      privacyLevel: JsonUtils.intValue(json['privacy_level']),
      roles: UserRole.setFromJson(JsonUtils.listValue(json['roles'])),
      favorites: JsonUtils.mapOfStringToLinkedHashSetOfStringsValue(json['favorites']),
      interests: JsonUtils.mapOfStringToSetOfStringsValue(json['interests']),
      foodFilters: JsonUtils.mapOfStringToSetOfStringsValue(json['food']),
      tags: _tagsFromJson(JsonUtils.mapValue(json['tags'])),
      answers: JsonUtils.mapValue(json['answers']),
      settings: JsonUtils.mapValue(json['settings']),
      voter: Auth2VoterPrefs.fromJson(JsonUtils.mapValue(json['voter'])),
      anonymousIds: _anonymousIdsFromJson(JsonUtils.mapValue(json['anonymous_ids'])),
    ) : null;
  }

  factory Auth2UserPrefs.empty() {
    return Auth2UserPrefs(
      privacyLevel: null,
      roles: <UserRole>{},
      favorites: <String, LinkedHashSet<String>>{},
      interests: <String, Set<String>>{},
      foodFilters: {
        _foodIncludedTypes : <String>{},
        _foodExcludedIngredients : <String>{},
      },
      tags: <String, bool>{},
      answers: <String, dynamic>{},
      settings: <String, dynamic>{},
      voter: Auth2VoterPrefs(),
      anonymousIds: null,
    );
  }

  factory Auth2UserPrefs.fromStorage({Map<String, dynamic>? profile, Set<String>? includedFoodTypes, Set<String>? excludedFoodIngredients, Map<String, dynamic>? answers, Map<String, dynamic>? settings}) {
    Map<String, dynamic>? privacy = (profile != null) ? JsonUtils.mapValue(profile['privacySettings']) : null;
    int? privacyLevel = (privacy != null) ? JsonUtils.intValue(privacy['level']) : null;
    Set<UserRole>? roles = (profile != null) ? UserRole.setFromJson(JsonUtils.listValue(profile['roles'])) : null;
    Map<String, LinkedHashSet<String>>? favorites = (profile != null) ? JsonUtils.mapOfStringToLinkedHashSetOfStringsValue(profile['favorites']) : null;
    Map<String, Set<String>>? interests = (profile != null) ? _interestsFromProfileList(JsonUtils.listValue(profile['interests'])) : null;
    Map<String, bool>? tags = (profile != null) ? _tagsFromProfileLists(positive: JsonUtils.listValue(profile['positiveInterestTags']), negative: JsonUtils.listValue(profile['negativeInterestTags'])) : null;
    Auth2VoterPrefs? voter = (profile != null) ? Auth2VoterPrefs.fromJson(profile) : null;
    Map<String, DateTime>? anonymousIds = (profile != null) ? _anonymousIdsFromJson(JsonUtils.mapValue(profile['anonymous_ids'])) : null;

    return Auth2UserPrefs(
      privacyLevel: privacyLevel,
      roles: roles ?? <UserRole>{},
      favorites: favorites ?? <String, LinkedHashSet<String>>{},
      interests: interests ?? <String, Set<String>>{},
      foodFilters: {
        _foodIncludedTypes : includedFoodTypes ?? <String>{},
        _foodExcludedIngredients : excludedFoodIngredients ?? <String>{},
      },
      tags: tags ?? <String, bool>{},
      answers: answers ?? <String, dynamic>{},
      settings: settings ?? <String, dynamic>{},
      voter: voter ?? Auth2VoterPrefs(),
      anonymousIds: anonymousIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privacy_level' : privacyLevel,
      'roles': UserRole.setToJson(roles),
      'favorites': JsonUtils.mapOfStringToLinkedHashSetOfStringsJsonValue(_favorites),
      'interests': JsonUtils.mapOfStringToSetOfStringsJsonValue(_interests),
      'food': JsonUtils.mapOfStringToSetOfStringsJsonValue(_foodFilters),
      'tags': _tags,
      'settings': _settings,
      'voter': _voter,
      'anonymous_ids': _anonymousIdsToJson(),
    };
  }

  @override
  bool operator ==(other) =>
      (other is Auth2UserPrefs) &&
          (other._privacyLevel == _privacyLevel) &&
          const DeepCollectionEquality().equals(other._roles, _roles) &&
          const DeepCollectionEquality().equals(other._favorites, _favorites) &&
          const DeepCollectionEquality().equals(other._interests, _interests) &&
          const DeepCollectionEquality().equals(other._foodFilters, _foodFilters) &&
          const DeepCollectionEquality().equals(other._tags, _tags) &&
          const DeepCollectionEquality().equals(other._settings, _settings) &&
          const DeepCollectionEquality().equals(other._anonymousIds, _anonymousIds) &&
          (other._voter == _voter);

  @override
  int get hashCode =>
      (_privacyLevel?.hashCode ?? 0) ^
      (const DeepCollectionEquality().hash(_roles)) ^
      (const DeepCollectionEquality().hash(_favorites)) ^
      (const DeepCollectionEquality().hash(_interests)) ^
      (const DeepCollectionEquality().hash(_foodFilters)) ^
      (const DeepCollectionEquality().hash(_tags)) ^
      (const DeepCollectionEquality().hash(_settings)) ^
      (const DeepCollectionEquality().hash(_anonymousIds)) ^
      (_voter?.hashCode ?? 0);

  bool apply(Auth2UserPrefs? prefs, { bool? notify, Set<Auth2UserPrefsScope>? scope }) {
    bool modified = false;
    if (prefs != null) {
      
      if ((prefs.privacyLevel != _privacyLevel) && (
            (scope?.contains(Auth2UserPrefsScope.privacyLevel) ?? false) ||
            (((prefs.privacyLevel ?? 0) > 0) && ((_privacyLevel ?? 0) == 0))
      )) {
        _privacyLevel = prefs._privacyLevel;
        modified = true;
      }
      
      if (!const DeepCollectionEquality().equals(prefs.roles, _roles) && (
            (scope?.contains(Auth2UserPrefsScope.roles) ?? false) ||
            ((prefs.roles?.isNotEmpty ?? false) && (_roles?.isEmpty ?? true))
      )) {
        _roles = prefs._roles;
        modified = true;
      }
      
      if (!const DeepCollectionEquality().equals(prefs._favorites, _favorites) && (
          (scope?.contains(Auth2UserPrefsScope.favorites) ?? false) ||
          (prefs.hasFavorites && !hasFavorites)
      )) {
        _favorites = prefs._favorites;
        modified = true;
      }
      
      if (!const DeepCollectionEquality().equals(prefs._interests, _interests) && (
        (scope?.contains(Auth2UserPrefsScope.interests) ?? false) ||
        ((prefs._interests?.isNotEmpty ?? false) && (_interests?.isEmpty ?? true))
      )) {
        _interests = prefs._interests;
        modified = true;
      }
      
      if (!const DeepCollectionEquality().equals(prefs._foodFilters, _foodFilters) && (
          (scope?.contains(Auth2UserPrefsScope.foodFilters) ?? false) ||
          (prefs.hasFoodFilters && !hasFoodFilters)
      )) {
        _foodFilters = prefs._foodFilters;
        modified = true;
      }

      if (!const DeepCollectionEquality().equals(prefs._tags, _tags) && (
          (scope?.contains(Auth2UserPrefsScope.tags) ?? false) ||
          ((prefs._tags?.isNotEmpty ?? false) &&  (_tags?.isEmpty ?? true))
      )) {
        _tags = prefs._tags;
        modified = true;
      }
      
      if (!const DeepCollectionEquality().equals(prefs._settings, _settings) && (
          (scope?.contains(Auth2UserPrefsScope.settings) ?? false) ||
          ((prefs._settings?.isNotEmpty ?? false) &&  (_settings?.isEmpty ?? true))
      )) {
        _settings = prefs._settings;
        modified = true;
      }

      if (prefs._anonymousIds?.isNotEmpty ?? false) {
        _anonymousIds ??= {};
        for (MapEntry<String, DateTime> id in prefs._anonymousIds!.entries) {
          modified = !_anonymousIds!.containsKey(id.key);
          _anonymousIds!.putIfAbsent(id.key, () => id.value);
        }
        if (notify == true) {
          NotificationService().notify(notifyAnonymousIdsChanged);
        }
      }

      if ((prefs._voter != _voter) &&  (
          (scope?.contains(Auth2UserPrefsScope.voter) ?? false) ||
          ((prefs._voter?.isNotEmpty ?? false) && (_voter?.isEmpty ?? true))
        )) {
        _voter = Auth2VoterPrefs.fromOther(prefs._voter, onChanged: _onVoterChanged);
        modified = true;
      }
    }
    return modified;
  }

  bool clear({ bool? notify }) {
    bool modified = false;

    if (_privacyLevel != null) {
        _privacyLevel = null;
        if (notify == true) {
          NotificationService().notify(notifyPrivacyLevelChanged);
        }
        modified = true;
    }

    if (_roles != null) {
      _roles = null;
      if (notify == true) {
        NotificationService().notify(notifyRolesChanged);
      }
      modified = true;
    }

    if (_favorites != null) {
      _favorites = null;
      if (notify == true) {
        NotificationService().notify(notifyFavoritesChanged);
      }
      modified = true;
    }
      
    if (_interests != null) {
      _interests = null;
      if (notify == true) {
        NotificationService().notify(notifyInterestsChanged);
      }
      modified = true;
    }
      
    if (_foodFilters != null) {
      _foodFilters = null;
      if (notify == true) {
        NotificationService().notify(notifyInterestsChanged);
      }
      modified = true;
    }

    if (_tags != null) {
      _tags = null;
      if (notify == true) {
        NotificationService().notify(notifyTagsChanged);
      }
      modified = true;
    }
    
    if (_settings != null) {
      _settings = null;
      if (notify == true) {
        NotificationService().notify(notifySettingsChanged);
      }
      modified = true;
    }
    
    if (_voter != null) {
      _voter = null;
      if (notify == true) {
        NotificationService().notify(notifyVoterChanged);
      }
      modified = true;
    }

    if (modified) {
      NotificationService().notify(notifyChanged, this);
    }

    return modified;
  }
  
  // Privacy

  int? get privacyLevel {
    return _privacyLevel;
  }
  
  set privacyLevel(int? value) {
    if (_privacyLevel != value) {
      _privacyLevel = value;
      NotificationService().notify(notifyPrivacyLevelChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  // Roles

  Set<UserRole>? get roles {
    return _roles;
  } 
  
  set roles(Set<UserRole>? value) {
    if (_roles != value) {
      _roles = (value != null) ? Set.from(value) : null;
      NotificationService().notify(notifyRolesChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  // Favorites

  Iterable<String>? get favoritesKeys => _favorites?.keys;

  LinkedHashSet<String>? getFavorites(String favoriteKey) {
    return (_favorites != null) ? _favorites![favoriteKey] : null;
  }

  void setFavorites(String favoriteKey, LinkedHashSet<String>? favorites) {
    if (!const DeepCollectionEquality().equals(favorites?.toList(), getFavorites(favoriteKey)?.toList())) {
      if (favorites != null) {
        _favorites ??= <String, LinkedHashSet<String>>{};
        _favorites![favoriteKey] = favorites;
      }
      else if (_favorites != null) {
        _favorites!.remove(favoriteKey);
      }
      //NotificationService().notify(notifyFavoriteChanged, ...);
      NotificationService().notify(notifyFavoritesChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void applyFavorites(String favoriteKey, Iterable<String>? favorites, bool value) {
    if ((favorites != null) && favorites.isNotEmpty) {
      bool isModified = false;
      LinkedHashSet<String>? favoritesContent = getFavorites(favoriteKey);
      for (String favorite in favorites) {
        if (value && !(favoritesContent?.contains(favorite) ?? false)) {
          if (favoritesContent == null) {
            // ignore: prefer_collection_literals
            favoritesContent = LinkedHashSet<String>();
            _favorites ??= <String, LinkedHashSet<String>>{};
            _favorites![favoriteKey] = favoritesContent;
          }
          favoritesContent.add(favorite);
          //NotificationService().notify(notifyFavoriteChanged, FavoriteItem(key: favoriteKey, id: favorite));
          isModified = true;
        }
        else if (!value && (favoritesContent?.contains(favorite) ?? false)) {
          favoritesContent?.remove(favorite);
          //NotificationService().notify(notifyFavoriteChanged, FavoriteItem(key: favoriteKey, id: favorite));
          isModified = true;
        }
      }
      if (isModified) {
        NotificationService().notify(notifyFavoritesChanged);
        NotificationService().notify(notifyChanged, this);
      }
    }
  }

  bool isFavorite(Favorite? favorite) {
    LinkedHashSet<String>? favoriteIdsForKey = ((_favorites != null) && (favorite != null)) ? _favorites![favorite.favoriteKey] : null;
    return (favoriteIdsForKey != null) && favoriteIdsForKey.contains(favorite?.favoriteId);
  }

  void toggleFavorite(Favorite? favorite) {
    if ((favorite != null) && (favorite.favoriteId != null)) {
      _favorites ??= <String, LinkedHashSet<String>>{};

      LinkedHashSet<String>? favoriteIdsForKey = _favorites![favorite.favoriteKey];
      bool shouldFavorite = (favoriteIdsForKey == null) || !favoriteIdsForKey.contains(favorite.favoriteId);
      if (shouldFavorite) {
        if (favoriteIdsForKey == null) {
          // ignore: prefer_collection_literals
          _favorites![favorite.favoriteKey] = favoriteIdsForKey = LinkedHashSet<String>();
        }
        SetUtils.add(favoriteIdsForKey, favorite.favoriteId);
      }
      else {
        favoriteIdsForKey.remove(favorite.favoriteId);
      }

      NotificationService().notify(notifyFavoriteChanged, favorite);
      NotificationService().notify(notifyFavoritesChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void setFavorite(Favorite? favorite, bool value) {
    if ((favorite != null) && (favorite.favoriteId != null)) {
      LinkedHashSet<String>? favoriteIdsForKey = (_favorites != null) ? _favorites![favorite.favoriteKey] : null;
      bool isFavorite = (favoriteIdsForKey != null) && favoriteIdsForKey.contains(favorite.favoriteId);
      bool isModified = false;
      if (value && !isFavorite) {
        if (favoriteIdsForKey == null) {
          _favorites ??= <String, LinkedHashSet<String>>{};
            // ignore: prefer_collection_literals
          _favorites![favorite.favoriteKey] = favoriteIdsForKey = LinkedHashSet<String>();
        }
        favoriteIdsForKey.add(favorite.favoriteId!);
        isModified = true;
      }
      else if (!value && isFavorite) {
        favoriteIdsForKey.remove(favorite.favoriteId);
        isModified = true;
      }

      if (isModified) {
        NotificationService().notify(notifyFavoriteChanged, favorite);
        NotificationService().notify(notifyFavoritesChanged);
        NotificationService().notify(notifyChanged, this);
      }
    }
  }

  bool isListFavorite(Iterable<Favorite>? favorites) {
    if ((favorites != null) && (_favorites != null)) {
      for (Favorite favorite in favorites) {
        if (!isFavorite(favorite)) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  void setListFavorite(Iterable<Favorite>? favorites, bool shouldFavorite, {Favorite? sourceFavorite}) {
    if (favorites != null) {

      bool isModified = false;
      for (Favorite favorite in favorites) {
        if (favorite.favoriteId != null) {
          LinkedHashSet<String>? favoriteIdsForKey = (_favorites != null) ? _favorites![favorite.favoriteKey] : null;
          bool isFavorite = (favoriteIdsForKey != null) && favoriteIdsForKey.contains(favorite.favoriteId);
          if (shouldFavorite && !isFavorite) {
            if (favoriteIdsForKey == null) {
              _favorites ??= <String, LinkedHashSet<String>>{};
              // ignore: prefer_collection_literals
              _favorites![favorite.favoriteKey] = favoriteIdsForKey = LinkedHashSet<String>();
            }
            favoriteIdsForKey.add(favorite.favoriteId!);
          }
          else if (!shouldFavorite && isFavorite) {
            favoriteIdsForKey.remove(favorite.favoriteId);
          }
          NotificationService().notify(notifyFavoriteChanged, favorite);
          isModified = true;
        }
      }
      if (isModified) {
        if (sourceFavorite != null) {
          NotificationService().notify(notifyFavoriteChanged, sourceFavorite);
        }
        NotificationService().notify(notifyFavoritesChanged);
        NotificationService().notify(notifyChanged, this);
      }
    }
  }

  void toggleListFavorite(Iterable<Favorite>? favorites, {Favorite? sourceFavorite}) {
    setListFavorite(favorites, !isListFavorite(favorites), sourceFavorite: sourceFavorite);
  }

  bool get hasFavorites {
    return favoritesNotEmpty(_favorites);
  }

  static bool favoritesNotEmpty(Map<String, LinkedHashSet<String>>? favorites) {
    bool result = false;
    favorites?.forEach((String key, LinkedHashSet<String> values) {
      if (values.isNotEmpty) {
        result = true;
      }
    });
    return result;
  }

  // Interests

  Iterable<String>? get interestCategories {
    return _interests?.keys;
  }

  void toggleInterestCategory(String? category) {
    _interests ??= <String, Set<String>>{};

    if ((category != null) && (_interests != null)) {
      if (_interests!.containsKey(category)) {
        _interests!.remove(category);
      }
      else {
        _interests![category] = <String>{};
      }

      NotificationService().notify(notifyInterestsChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void applyInterestCategories(Set<String>? categories) {
    _interests ??= <String, Set<String>>{};

    if ((categories != null) && (_interests != null)) {

      bool modified = false;
      Set<String>? categoriesToRemove;
      for (String category in _interests!.keys) {
        if (!categories.contains(category)) {
          categoriesToRemove ??= <String>{};
          categoriesToRemove.add(category);
        }
      }

      for (String category in categories) {
        if (!_interests!.containsKey(category)) {
          _interests![category] = <String>{};
          modified = true;
        }
      }

      if (categoriesToRemove != null) {
        for (String category in categoriesToRemove) {
          _interests!.remove(category);
          modified = true;
        }
      }

      if (modified) {
        NotificationService().notify(notifyInterestsChanged);
        NotificationService().notify(notifyChanged, this);
      }
    }
  }

  Set<String>? getInterestsFromCategory(String? category) {
    return ((_interests != null) && (category != null)) ? _interests![category] : null;
  }

  bool? hasInterest(String? category, String? interest) {
    Set<String>? interests = ((category != null) && (_interests != null)) ? _interests![category] : null;
    return ((interests != null) && (interest != null)) ? interests.contains(interest) : null;
  }

  void toggleInterest(String? category, String? interest) {
    _interests ??= <String, Set<String>>{};

    if ((category != null) && (interest != null) && (_interests != null)) {
      Set<String>? categories = _interests![category];
      if (categories == null) {
        _interests![category] = categories = <String>{};
      }
      if (categories.contains(interest)) {
        categories.remove(interest);
      }
      else {
        categories.add(interest);
      }

      NotificationService().notify(notifyInterestsChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void toggleInterests(String? category, Iterable<String>? interests) {
    _interests ??= <String, Set<String>>{};

    if ((category != null) && (interests != null) && interests.isNotEmpty && (_interests != null)) {
      Set<String>? categories = _interests![category];
      if (categories == null) {
        _interests![category] = categories = <String>{};
      }
      for (String interest in interests) {
        if (categories.contains(interest)) {
          categories.remove(interest);
        }
        else {
          categories.add(interest);
        }
      }

      NotificationService().notify(notifyInterestsChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void applyInterests(String? category, Iterable<String>? interests) {
    _interests ??= <String, Set<String>>{};

    if ((category != null) && (_interests != null)) {
      bool modified = false;
      if ((interests != null) && !const DeepCollectionEquality().equals(_interests![category], interests)) {
        _interests![category] = Set<String>.from(interests);
        modified = true;
      }
      else if (_interests!.containsKey(category)) {
        _interests!.remove(category);
        modified = true;
      }

      if (modified) {
        NotificationService().notify(notifyInterestsChanged);
        NotificationService().notify(notifyChanged, this);
      }
    }
  }

  void clearInterestsAndTags() {
    bool modified = false;

    if ((_interests == null) || _interests!.isNotEmpty) {
      _interests = <String, Set<String>>{};
      modified = true;
      NotificationService().notify(notifyInterestsChanged);
    }

    if ((_tags == null) || _tags!.isNotEmpty) {
      _tags = <String, bool>{};
      modified = true;
      NotificationService().notify(notifyTagsChanged);
    }

    if (modified) {
      NotificationService().notify(notifyChanged, this);
    }
  }

  // Sports

  static const String sportsInterestsCategory = "sports";  

  Set<String>? get sportsInterests => getInterestsFromCategory(sportsInterestsCategory);
  bool? hasSportInterest(String? sport) => hasInterest(sportsInterestsCategory, sport);
  void toggleSportInterest(String? sport) => toggleInterest(sportsInterestsCategory, sport);
  void toggleSportInterests(Iterable<String>? sports) => toggleInterests(sportsInterestsCategory, sports);

  // Food

  Set<String>? get excludedFoodIngredients {
    return (_foodFilters != null) ? _foodFilters![_foodExcludedIngredients] : null;
  }

  set excludedFoodIngredients(Set<String>? value) {
    if (!const SetEquality().equals(excludedFoodIngredients, value)) {
      if (value != null) {
        if (_foodFilters != null) {
          _foodFilters![_foodExcludedIngredients] = value;
        }
        else {
          _foodFilters = { _foodExcludedIngredients : value };
        }
      }
      else if (_foodFilters != null) {
        _foodFilters!.remove(_foodExcludedIngredients);
      }
      NotificationService().notify(notifyFoodChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  Set<String>? get includedFoodTypes {
    return (_foodFilters != null) ? _foodFilters![_foodIncludedTypes] : null;
  }

  set includedFoodTypes(Set<String>? value) {
    if (!const SetEquality().equals(includedFoodTypes, value)) {
      if (value != null) {
        if (_foodFilters != null) {
          _foodFilters![_foodIncludedTypes] = value;
        }
        else {
          _foodFilters = { _foodIncludedTypes : value };
        }
      }
      else if (_foodFilters != null) {
        _foodFilters!.remove(_foodIncludedTypes);
      }
      NotificationService().notify(notifyFoodChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  bool get hasFoodFilters {
    return foodFiltersNotEmpty(_foodFilters);
  }

  static bool foodFiltersNotEmpty(Map<String, Set<String>>? foodFilters) {
    return (foodFilters?[_foodIncludedTypes]?.isNotEmpty ?? false) || (foodFilters?[_foodExcludedIngredients]?.isNotEmpty ?? false);
  }

  void clearFoodFilters() {
    if (hasFoodFilters) {
      _foodFilters = <String, Set<String>>{};
      NotificationService().notify(notifyFoodChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  // Tags

  Set<String>? get positiveTags => getTags(positive: true);
  bool hasPositiveTag(String tag) => hasTag(tag, positive: true);
  void togglePositiveTag(String? tag) => toggleTag(tag, positive: true);

  Set<String>? getTags({ bool? positive }) {
    Set<String>? tags;
    if (_tags != null) {
      tags = <String>{};
      for (String tag in _tags!.keys) {
        if ((positive == null) || (_tags![tag] == positive)) {
          tags.add(tag);
        }
      }
    }
    return tags;
  }

  bool hasTag(String? tag, { bool? positive}) {
    if ((_tags != null) && (tag != null)) {
      bool? value = _tags![tag];
      return (value != null) && ((positive == null) || (value == positive));
    }
    return false;
  }

  void toggleTag(String? tag, { bool positive = true}) {
    _tags ??= <String, bool>{};

    if ((_tags != null) && (tag != null)) {
      if (_tags!.containsKey(tag)) {
        _tags!.remove(tag);
      }
      else {
        _tags![tag] = positive;
      }
    }
    NotificationService().notify(notifyTagsChanged);
    NotificationService().notify(notifyChanged, this);
  }

  void addTag(String? tag, { bool? positive }) {
    _tags ??= <String, bool>{};

    if ((_tags != null) && (tag != null) && (_tags![tag] != positive)) {
      _tags![tag] = positive ?? false;
      NotificationService().notify(notifyTagsChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void removeTag(String? tag) {
    if ((_tags != null) && (tag != null) && _tags!.containsKey(tag)) {
      _tags!.remove(tag);
      NotificationService().notify(notifyTagsChanged);
      NotificationService().notify(notifyChanged, this);
    }
  }

  void applyTags(Iterable<String>? tags, { bool positive = true }) {
    _tags ??= <String, bool>{};

    if ((_tags != null) && (tags != null)) {
      bool modified = false;
      for (String tag in tags) {
        if (_tags![tag] != positive) {
          _tags![tag] = positive;
          modified = true;
        }
      }
      if (modified) {
        NotificationService().notify(notifyTagsChanged);
        NotificationService().notify(notifyChanged, this);
      }
    }
  }

  // Settings

  bool? getBoolSetting(String? settingName, { bool? defaultValue }) =>
    JsonUtils.boolValue(getSetting(settingName)) ?? defaultValue;

  int? getIntSetting(String? settingName, { int? defaultValue }) =>
    JsonUtils.intValue(getSetting(settingName)) ?? defaultValue;

  String? getStringSetting(String? settingName, { String? defaultValue }) =>
    JsonUtils.stringValue(getSetting(settingName)) ?? defaultValue;

  dynamic getSetting(String? settingName) =>
    (_settings != null) ? _settings![settingName] : null;

  void applySetting(String settingName, dynamic settingValue) {
    if (settingValue != null) {
      _settings ??= <String, dynamic>{};
      _settings![settingName] = settingValue;
    }
    else if (_settings != null) {
      _settings!.remove(settingName);
    }
    NotificationService().notify(notifySettingsChanged);
    NotificationService().notify(notifyChanged, this);
  }

  // Voter

  Auth2VoterPrefs? get voter => _voter;

  void _onVoterChanged() {
    NotificationService().notify(notifyVoterChanged);
    NotificationService().notify(notifyChanged, this);
  }

  // Anonymous IDs

  Map<String, DateTime>? get anonymousIds => _anonymousIds;

  void addAnonymousId(String? id) {
    if (id != null) {
      _anonymousIds ??= {};
      _anonymousIds!.putIfAbsent(id, () => DateTime.now().toUtc());
    }
  }

  Map<String, String>? _anonymousIdsToJson() {
    Map<String, String>? json;
    if (_anonymousIds?.isNotEmpty ?? false) {
      json = {};
      for (MapEntry<String, DateTime> anonymousId in _anonymousIds!.entries) {
        String? dateAdded = DateTimeUtils.utcDateTimeToString(anonymousId.value);
        if (dateAdded != null) {
          json[anonymousId.key] = dateAdded;
        }
      }
    }
    return json;
  }

  // Helpers

  static Map<String, bool>? _tagsFromJson(Map<String, dynamic>? json) {
    try { return json?.cast<String, bool>(); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  static Map<String, bool>? _tagsFromProfileLists({List<dynamic>? positive, List<dynamic>? negative}) {
    Map<String, bool>? result = ((positive != null) || (negative != null)) ? <String, bool>{} : null;

    if (negative != null) {
      for (dynamic negativeEntry in negative) {
        if (negativeEntry is String) {
          result![negativeEntry] = false;
        }
      }
    }

    if (positive != null) {
      for (dynamic positiveEntry in positive) {
        if (positiveEntry is String) {
          result![positiveEntry] = true;
        }
      }
    }
    
    return result;
  }

  static Map<String, Set<String>>? _interestsFromProfileList(List<dynamic>? jsonList) {
    Map<String, Set<String>>? result;
    if (jsonList != null) {
      result = <String, Set<String>>{};
      for (dynamic jsonEntry in jsonList) {
        if (jsonEntry is Map) {
          String? category = JsonUtils.stringValue(jsonEntry['category']);
          if (category != null) {
            result[category] = JsonUtils.setStringsValue(jsonEntry['subcategories']) ?? <String>{};
          }
        }
      }
    }
    return result;
  }

  static Map<String, DateTime>? _anonymousIdsFromJson(Map<String, dynamic>? json) {
    Map<String, DateTime>? anonymousIds;
    if (json is Map) {
      anonymousIds = {};
      for (MapEntry anonymousId in json!.entries) {
        if (anonymousId.key is String && anonymousId.value is String) {
          DateTime? dateAdded = DateTimeUtils.parseDateTime(anonymousId.value, format: DateTimeUtils.defaultDateTimeFormat, isUtc: true);
          if (dateAdded != null) {
            anonymousIds[anonymousId.key] = dateAdded;
          }
        }
      }
    }
    return anonymousIds;
  }
}

enum Auth2UserPrefsScope { privacyLevel, roles, favorites, interests, foodFilters, tags, settings, voter }

extension Auth2UserPrefsScopeImpl on Auth2UserPrefsScope {
  static Set<Auth2UserPrefsScope> get fullScope => Set<Auth2UserPrefsScope>.from(Auth2UserPrefsScope.values);
}

class Auth2VoterPrefs {
  bool? _registeredVoter;
  String? _votePlace;
  bool? _voterByMail;
  bool? _voted;
  
  Function? onChanged;
  
  Auth2VoterPrefs({bool? registeredVoter, String? votePlace, bool? voterByMail, bool? voted, this.onChanged}) :
    _registeredVoter = registeredVoter,
    _votePlace = votePlace,
    _voterByMail = voterByMail,
    _voted = voted;

  static Auth2VoterPrefs? fromJson(Map<String, dynamic>? json, { Function? onChanged }) {
    return (json != null) ? Auth2VoterPrefs(
      registeredVoter: JsonUtils.boolValue(json['registered_voter']),
      votePlace: JsonUtils.stringValue(json['vote_place']),
      voterByMail: JsonUtils.boolValue(json['voter_by_mail']),
      voted: JsonUtils.boolValue(json['voted']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'registered_voter' : _registeredVoter,
      'vote_place': _votePlace,
      'voter_by_mail': _voterByMail,
      'voted': _voted,
    };
  }

  static Auth2VoterPrefs? fromOther(Auth2VoterPrefs? other, { Function? onChanged }) {
    return (other != null) ? Auth2VoterPrefs(
      registeredVoter: other.registeredVoter,
      votePlace: other.votePlace,
      voterByMail: other.voterByMail,
      voted: other.voted,
      onChanged: onChanged,
    ) : null;
  }

  
  @override
  bool operator ==(other) =>
    (other is Auth2VoterPrefs) &&
      (other._registeredVoter == _registeredVoter) &&
      (other._votePlace == _votePlace) &&
      (other._voterByMail == _voterByMail) &&
      (other._voted == _voted);

  @override
  int get hashCode =>
    (_registeredVoter?.hashCode ?? 0) ^
    (_votePlace?.hashCode ?? 0) ^
    (_voterByMail?.hashCode ?? 0) ^
    (_voted?.hashCode ?? 0);

  bool get isEmpty =>
    (_registeredVoter == null) &&
    (_votePlace == null) &&
    (_voterByMail == null) &&
    (_voted == null);

  bool get isNotEmpty => !isEmpty;
  
  void clear() {

    bool modified = false;
    if (_registeredVoter != null) {
      _registeredVoter = null;
      modified = true;
    }

    if (_votePlace != null) {
      _votePlace = null;
      modified = true;
    }

    if (_voterByMail != null) {
      _voterByMail = null;
      modified = true;
    }

    if (_voted != null) {
      _voted = null;
      modified = true;
    }

    if (modified) {
      _notifyChanged();
    }
  }

  bool? get registeredVoter => _registeredVoter;
  set registeredVoter(bool? value) {
    if (_registeredVoter != value) {
      _registeredVoter = value;
      _notifyChanged();
    }
  }

  String? get votePlace => _votePlace;
  set votePlace(String? value) {
    if (_votePlace != value) {
      _votePlace = value;
      _notifyChanged();
    }
  }
  
  bool? get voterByMail => _voterByMail;
  set voterByMail(bool? value) {
    if (_voterByMail != value) {
      _voterByMail = value;
      _notifyChanged();
    }
  }

  bool? get voted => _voted;
  set voted(bool? value) {
    if (_voted != value) {
      _voted = value;
      _notifyChanged();
    }
  }

  void _notifyChanged() {
    if (onChanged != null) {
      onChanged!();
    }
  }
}

////////////////////////////////
// UserRole

class UserRole {
  static const neomU = UserRole._internal('neom_u');
  static const talentAcademy = UserRole._internal('talent_academy');
  static const eriF = UserRole._internal('eri_f');
  static const ec12 = UserRole._internal('ec_12');
  static const debug = UserRole._internal('debug');

  static List<UserRole> get values {
    return [neomU, talentAcademy, eriF, ec12, debug];
  }

  final String _value;

  const UserRole._internal(this._value);

  static UserRole? fromString(String? value) {
    return (value != null) ? UserRole._internal(value) : null;
  }

  static UserRole? fromJson(dynamic value) {
    return (value is String) ? UserRole._internal(value) : null;
  }

  @override
  toString() => _value;
  
  toJson() => _value;

  @override
  bool operator==(Object other) {
    if (other is UserRole) {
      return other._value == _value;
    }
    return false;
  }

  @override
  int get hashCode => _value.hashCode;

  static List<UserRole>? listFromJson(List<dynamic>? jsonList) {
    List<UserRole>? result;
    if (jsonList != null) {
      result = <UserRole>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, UserRole.fromString(JsonUtils.stringValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<UserRole>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (UserRole contentEntry in contentList) {
        jsonList.add(contentEntry.toString());
      }
    }
    return jsonList;
  }

  static Set<UserRole>? setFromJson(List<dynamic>? jsonList) {
    Set<UserRole>? result;
    if (jsonList != null) {
      result = <UserRole>{};
      for (dynamic jsonEntry in jsonList) {
        SetUtils.add(result, (jsonEntry is String) ? UserRole.fromString(jsonEntry) : null);
      }
    }
    return result;
  }

  static List<dynamic>? setToJson(Set<UserRole>? contentSet) {
    List<dynamic>? jsonList;
    if (contentSet != null) {
      jsonList = <dynamic>[];
      for (UserRole? contentEntry in contentSet) {
        jsonList.add(contentEntry?.toString());
      }
    }
    return jsonList;
  }
}


////////////////////////////////
// Favorite

abstract class Favorite {
  String get favoriteKey;
  String? get favoriteId;
  
  @override
  String toString() => (favoriteId != null) ? "{$favoriteKey:$favoriteId}" : "{$favoriteKey}";
}

class FavoriteItem implements Favorite {
  final String key;
  final String? id;
  
  FavoriteItem({required this.key, this.id});

  @override bool operator == (other) => (other is FavoriteItem) && (other.key == key) && (other.id == id);
  @override int get hashCode => key.hashCode ^ (id?.hashCode ?? 0);

  @override String get favoriteKey => key;
  @override String? get favoriteId => id;
}


////////////////////////////////
// Auth2PhoneVerificationMethod

enum Auth2PhoneVerificationMethod { call, sms }

////////////////////////////////
// Auth2FieldVisibility

enum Auth2FieldVisibility { private, connections, public }

extension Auth2FieldVisibilityImpl on Auth2FieldVisibility {

  // JSON Serialization

  static Auth2FieldVisibility? fromJson(String? value) {
    switch (value) {
      case 'private': return Auth2FieldVisibility.private;
      case 'connections': return Auth2FieldVisibility.connections;
      case 'public': return Auth2FieldVisibility.public;
      default: return null;
    }
  }

  String toJson() {
    switch (this) {
      case Auth2FieldVisibility.private: return 'private';
      case Auth2FieldVisibility.connections: return 'connections';
      case Auth2FieldVisibility.public: return 'public';
    }
  }

  // JSON Map Serialization

  static Map<String, Auth2FieldVisibility?>? mapFromJson(Map<String, dynamic>? json) => (json != null) ?
    json.map<String, Auth2FieldVisibility?>((String key, dynamic value) => MapEntry(key, Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(value)))) : null;

  static Map<String, dynamic>? mapToJson(Map<String, Auth2FieldVisibility?>? map) => (map != null) ?
    map.map<String, dynamic>((String key, Auth2FieldVisibility? value) => MapEntry(key, value?.toJson())) : null;

}
