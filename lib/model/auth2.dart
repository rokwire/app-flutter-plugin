
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
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
// Auth2LoginType

enum Auth2LoginType { anonymous, apiKey, email, phone, username, phoneTwilio, oidc, oidcIllinois }

String? auth2LoginTypeToString(Auth2LoginType value) {
  switch (value) {
    case Auth2LoginType.anonymous: return 'anonymous';
    case Auth2LoginType.apiKey: return 'api_key';
    case Auth2LoginType.email: return 'email';
    case Auth2LoginType.phone: return 'phone';
    case Auth2LoginType.username: return 'username';
    case Auth2LoginType.phoneTwilio: return 'twilio_phone';
    case Auth2LoginType.oidc: return 'oidc';
    case Auth2LoginType.oidcIllinois: return 'illinois_oidc';
  }
}

Auth2LoginType? auth2LoginTypeFromString(String? value) {
  if (value == 'anonymous') {
    return Auth2LoginType.anonymous;
  }
  else if (value == 'api_key') {
    return Auth2LoginType.apiKey;
  }
  else if (value == 'email') {
    return Auth2LoginType.email;
  }
  else if (value == 'phone') {
    return Auth2LoginType.phone;
  }
  else if (value == 'username') {
    return Auth2LoginType.username;
  }
  else if (value == 'twilio_phone') {
    return Auth2LoginType.phoneTwilio;
  }
  else if (value == 'oidc') {
    return Auth2LoginType.oidc;
  }
  else if (value == 'illinois_oidc') {
    return Auth2LoginType.oidcIllinois;
  }
  return null;
}

////////////////////////////////
// Auth2Account

class Auth2Account {
  final String? id;
  final String? username;
  final Auth2UserProfile? profile;
  final Auth2UserPrefs? prefs;
  final Auth2UserPrivacy? privacy;
  final List<Auth2Permission>? permissions;
  final List<Auth2Role>? roles;
  final List<Auth2Group>? groups;
  final List<Auth2Type>? authTypes;
  final Map<String, dynamic>? systemConfigs;
  
  Auth2Account({this.id, this.username, this.profile, this.prefs, this.privacy, this.permissions, this.roles, this.groups, this.authTypes, this.systemConfigs});

  factory Auth2Account.fromOther(Auth2Account? other, {String? id, String? username, Auth2UserProfile? profile, Auth2UserPrefs? prefs, Auth2UserPrivacy? privacy, List<Auth2Permission>? permissions, List<Auth2Role>? roles, List<Auth2Group>? groups, List<Auth2Type>? authTypes, Map<String, dynamic>? systemConfigs}) {
    return Auth2Account(
      id: id ?? other?.id,
      username: username ?? other?.username,
      profile: profile ?? other?.profile,
      prefs: prefs ?? other?.prefs,
      privacy: privacy ?? other?.privacy,
      permissions: permissions ?? other?.permissions,
      roles: roles ?? other?.roles,
      groups: groups ?? other?.groups,
      authTypes: authTypes ?? other?.authTypes,
      systemConfigs: systemConfigs ?? other?.systemConfigs,
    );
  }

  static Auth2Account? fromJson(Map<String, dynamic>? json, { Auth2UserPrefs? prefs, Auth2UserProfile? profile, Auth2UserPrivacy? privacy }) {
    return (json != null) ? Auth2Account(
      id: JsonUtils.stringValue(json['id']),
      username: JsonUtils.stringValue(json['username']),
      profile: Auth2UserProfile.fromJson(JsonUtils.mapValue(json['profile'])) ?? profile,
      prefs: Auth2UserPrefs.fromJson(JsonUtils.mapValue(json['preferences'])) ?? prefs, //TBD Auth2
      privacy: Auth2UserPrivacy.fromJson(JsonUtils.mapValue(json['privacy'])) ?? privacy,
      permissions: Auth2Permission.listFromJson(JsonUtils.listValue(json['permissions'])),
      roles: Auth2Role.listFromJson(JsonUtils.listValue(json['roles'])),
      groups: Auth2Group.listFromJson(JsonUtils.listValue(json['groups'])),
      authTypes: Auth2Type.listFromJson(JsonUtils.listValue(json['auth_types'])),
      systemConfigs: JsonUtils.mapValue(json['system_configs']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'username' : username,
      'profile': profile?.toJson(),
      'preferences': prefs?.toJson(),
      'privacy': privacy?.toJson(),
      'permissions': Auth2StringEntry.listToJson(permissions),
      'roles': Auth2StringEntry.listToJson(roles),
      'groups': Auth2StringEntry.listToJson(groups),
      'auth_types': Auth2Type.listToJson(authTypes),
      'system_configs': systemConfigs,
    };
  }

  @override
  bool operator ==(other) =>
    (other is Auth2Account) &&
      (other.id == id) &&
      (other.username == username) &&
      (other.profile == profile) &&
      (other.privacy == privacy) &&
      const DeepCollectionEquality().equals(other.permissions, permissions) &&
      const DeepCollectionEquality().equals(other.roles, roles) &&
      const DeepCollectionEquality().equals(other.groups, groups) &&
      const DeepCollectionEquality().equals(other.authTypes, authTypes) &&
      const DeepCollectionEquality().equals(other.systemConfigs, systemConfigs);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (username?.hashCode ?? 0) ^
    (profile?.hashCode ?? 0) ^
    (privacy?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(permissions)) ^
    (const DeepCollectionEquality().hash(roles)) ^
    (const DeepCollectionEquality().hash(groups)) ^
    (const DeepCollectionEquality().hash(authTypes)) ^
    (const DeepCollectionEquality().hash(systemConfigs));

  bool get isValid {
    return (id != null) && id!.isNotEmpty /* && (profile != null) && profile.isValid*/;
  }

  Auth2Type? get authType {
    return ((authTypes != null) && authTypes!.isNotEmpty) ? authTypes?.first : null;
  }

  bool isAuthTypeLinked(Auth2LoginType loginType) {
    if (authTypes != null) {
      for (Auth2Type authType in authTypes!) {
        if (authType.loginType == loginType) {
          return true;
        }
      }
    }
    return false;
  }

  List<Auth2Type> getLinkedForAuthType(Auth2LoginType loginType) {
    List<Auth2Type> linkedTypes = <Auth2Type>[];
    if (authTypes != null) {
      for (Auth2Type authType in authTypes!) {
        if (authType.loginType == loginType) {
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
      (other.fieldsVisibility == fieldsVisibility);

  @override
  int get hashCode =>
    (public?.hashCode ?? 0) ^
    (fieldsVisibility?.hashCode ?? 0);
}

////////////////////////////////
// Auth2AccountFieldsVisibility

class Auth2AccountFieldsVisibility {
  final Auth2UserProfileFieldsVisibility? profile;

  Auth2AccountFieldsVisibility({this.profile});

  factory Auth2AccountFieldsVisibility.fromOther(Auth2AccountFieldsVisibility? other, {
    Auth2UserProfileFieldsVisibility? profile,
  }) => Auth2AccountFieldsVisibility(
    profile: profile ?? other?.profile,
  );

  static Auth2AccountFieldsVisibility? fromJson(Map<String, dynamic>? json) => (json != null) ? Auth2AccountFieldsVisibility(
    profile: Auth2UserProfileFieldsVisibility.fromJson(JsonUtils.mapValue(json['profile']))
  ) : null;
  
  Map<String, dynamic> toJson() => {
    'profile': profile?.toJson(),
  };

  @override
  bool operator ==(other) =>
    (other is Auth2AccountFieldsVisibility) &&
    (other.profile == profile);

  @override
  int get hashCode =>
    (profile?.hashCode ?? 0);
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

  static const String collegeDataKey = 'college';
  static const String departmentDataKey = 'department';
  static const String majorDataKey = 'major';
  static const String titleDataKey = 'title';
  static const String email2DataKey = 'email2';

  String? _id;

  String? _firstName;
  String? _middleName;
  String? _lastName;
  String? _pronouns;

  int?    _birthYear;
  String? _photoUrl;
  String? _pronunciationUrl;

  String? _email;
  String? _phone;
  String? _website;

  String? _address;
  String? _state;
  String? _zip;
  String? _country;

  Map<String, dynamic>? _data;
  
  Auth2UserProfile({String? id,
    String? firstName, String? middleName, String? lastName, String? pronouns,
    int? birthYear, String? photoUrl, String? pronunciationUrl,
    String? email, String? phone, String? website,
    String? address, String? state, String? zip, String? country,
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

    _email = email,
    _phone = phone,
    _website = website,

    _address = address,
    _state  = state,
    _zip  = zip,
    _country = country,

    _data = data;

  factory Auth2UserProfile.fromOther(Auth2UserProfile? other, {String? id,
    String? firstName, String? middleName, String? lastName, String? pronouns,
    int? birthYear, String? photoUrl, String? pronunciationUrl,
    String? email, String? phone, String? website,
    String? address, String? state, String? zip, String? country,
    Map<String, dynamic>? data}) {

    return Auth2UserProfile(
      id: id ?? other?._id,

      firstName: firstName ?? other?._firstName,
      middleName: middleName ?? other?._middleName,
      lastName: lastName ?? other?._lastName,
      pronouns: pronouns ?? other?._pronouns,

      birthYear: birthYear ?? other?._birthYear,
      photoUrl: photoUrl ?? other?._photoUrl,
      pronunciationUrl: pronunciationUrl ?? other?._pronunciationUrl,

      email: email ?? other?._email,
      phone: phone ?? other?._phone,
      website: website ?? other?._website,

      address: address ?? other?._address,
      state: state ?? other?._state,
      zip: zip ?? other?._zip,
      country: country ?? other?._country,

      data: MapUtils.combine(other?._data, data),
    );
  }

  static Auth2UserProfile? fromFieldsVisibility(Auth2UserProfile? source, Auth2UserProfileFieldsVisibility? visibility, {
    Set<Auth2FieldVisibility> permitted = const <Auth2FieldVisibility>{Auth2FieldVisibility.public}
  }) {

    return (source != null) ? Auth2UserProfile(
      id: source._id,

      firstName: permitted.contains(visibility?.firstName) ? source._firstName : null,
      middleName: permitted.contains(visibility?.middleName) ? source._middleName : null,
      lastName: permitted.contains(visibility?.lastName) ? source._lastName : null,
      pronouns: permitted.contains(visibility?.pronouns) ? source._pronouns : null,

      birthYear: permitted.contains(visibility?.birthYear) ? source._birthYear : null,
      photoUrl: permitted.contains(visibility?.photoUrl) ? source._photoUrl : null,
      pronunciationUrl: permitted.contains(visibility?.pronunciationUrl) ? source._pronunciationUrl : null,

      email: permitted.contains(visibility?.email) ? source._email : null,
      phone: permitted.contains(visibility?.phone) ? source._phone : null,
      website: permitted.contains(visibility?.website) ? source._website : null,

      address: permitted.contains(visibility?.address) ? source._address : null,
      state: permitted.contains(visibility?.state) ? source._state : null,
      zip: permitted.contains(visibility?.zip) ? source._zip : null,
      country: permitted.contains(visibility?.country) ? source._country : null,

      data: Auth2UserProfileFieldsVisibility.buildPermitted(source._data, visibility?.data , permitted: permitted),
    ) : null;
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

      email: JsonUtils.stringValue(json['email']),
      phone: JsonUtils.stringValue(json['phone']),
      website: JsonUtils.stringValue(json['website']),

      address: JsonUtils.stringValue(json['address']),
      state: JsonUtils.stringValue(json['state']),
      zip: JsonUtils.stringValue(json['zip_code']),
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

      'email': _email,
      'phone': _phone,
      'website': _website,

      'address': _address,
      'state': _state,
      'zip_code': _zip,
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

      (other._email == _email) &&
      (other._phone == _phone) &&
      (other._website == _website) &&

      (other._address == _address) &&
      (other._state == _state) &&
      (other._zip == _zip) &&
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

    (_email?.hashCode ?? 0) ^
    (_phone?.hashCode ?? 0) ^
    (_website?.hashCode ?? 0) ^

    (_address?.hashCode ?? 0) ^
    (_state?.hashCode ?? 0) ^
    (_zip?.hashCode ?? 0) ^
    (_country?.hashCode ?? 0) ^

    (const DeepCollectionEquality().hash(_data));

  bool apply(Auth2UserProfile? profile, { Set<Auth2UserProfileScope>? scope }) {
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

      if ((profile._email != _email) && (
          (scope?.contains(Auth2UserProfileScope.email) == true) ||
          ((profile._email?.isNotEmpty ?? false) && (_email?.isEmpty ?? true))
      )) {
        _email = profile._email;
        modified = true;
      }
      if ((profile._phone != _phone) && (
          (scope?.contains(Auth2UserProfileScope.phone) == true) ||
          ((profile._phone?.isNotEmpty ?? false) && (_phone?.isEmpty ?? true))
      )) {
        _phone = profile._phone;
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
      if ((profile._state != _state) && (
          (scope?.contains(Auth2UserProfileScope.state) == true) ||
          ((profile._state?.isNotEmpty ?? false) && (_state?.isEmpty ?? true))
      )) {
        _state = profile._state;
        modified = true;
      }
      if ((profile._zip != _zip) && (
          (scope?.contains(Auth2UserProfileScope.zip) == true) ||
          ((profile._zip?.isNotEmpty ?? false) && (_zip?.isEmpty ?? true))
      )) {
        _zip = profile._zip;
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

  String? get email => _email;
  String? get phone => _phone;
  String? get website => _website;

  String? get address => _address;
  String? get state => _state;
  String? get zip => _zip;
  String? get country => _country;

  Map<String, dynamic>? get data => _data;

  bool   get isValid => StringUtils.isNotEmpty(id);
  String? get fullName => StringUtils.fullName([firstName, middleName, lastName]);

  // Other Data Fields


  String? get college => JsonUtils.stringValue(_data?[collegeDataKey]);
  String? get department => JsonUtils.stringValue(_data?[departmentDataKey]);
  String? get major => JsonUtils.stringValue(_data?[majorDataKey]);
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

  final Auth2FieldVisibility? email;
  final Auth2FieldVisibility? phone;
  final Auth2FieldVisibility? website;

  final Auth2FieldVisibility? address;
  final Auth2FieldVisibility? state;
  final Auth2FieldVisibility? zip;
  final Auth2FieldVisibility? country;

  final Map<String, Auth2FieldVisibility?>? data;

  Auth2UserProfileFieldsVisibility({
    this.firstName, this.middleName, this.lastName, this.pronouns,
    this.birthYear, this.photoUrl, this.pronunciationUrl,
    this.email, this.phone, this.website,
    this.address, this.state, this.zip, this.country,
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

    Auth2FieldVisibility? email,
    Auth2FieldVisibility? phone,
    Auth2FieldVisibility? website,

    Auth2FieldVisibility? address,
    Auth2FieldVisibility? state,
    Auth2FieldVisibility? zip,
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

    email: email ?? other?.email,
    phone: phone ?? other?.phone,
    website: website ?? other?.website,

    address: address ?? other?.address,
    state: state ?? other?.state,
    zip: zip ?? other?.zip,
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

    email: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['email'])),
    phone: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['phone'])),
    website: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['website'])),

    address: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['address'])),
    state: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['state'])),
    zip: Auth2FieldVisibilityImpl.fromJson(JsonUtils.stringValue(json['zip_code'])),
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

      'email': email?.toJson(),
      'phone': phone?.toJson(),
      'website': website?.toJson(),

      'address': address?.toJson(),
      'state': state?.toJson(),
      'zip_code': zip?.toJson(),
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

      (other.email == email) &&
      (other.phone == phone) &&
      (other.website == website) &&

      (other.address == address) &&
      (other.state == state) &&
      (other.zip == zip) &&
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

    (email?.hashCode ?? 0) ^
    (phone?.hashCode ?? 0) ^
    (website?.hashCode ?? 0) ^

    (address?.hashCode ?? 0) ^
    (state?.hashCode ?? 0) ^
    (zip?.hashCode ?? 0) ^
    (country?.hashCode ?? 0) ^

    (const DeepCollectionEquality().hash(data));

  // Other Data dields

  Auth2FieldVisibility? get college => data?[Auth2UserProfile.collegeDataKey];
  Auth2FieldVisibility? get department => data?[Auth2UserProfile.departmentDataKey];
  Auth2FieldVisibility? get major => data?[Auth2UserProfile.majorDataKey];
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
  address, state, zip, country,
}

////////////////////////////////
// Auth2Type

class Auth2Type {
  final String? id;
  final String? identifier;
  final bool? active;
  final bool? active2fa;
  final bool? unverified;
  final String? code;
  final Map<String, dynamic>? params;
  
  final Auth2UiucUser? uiucUser;
  final Auth2LoginType? loginType;
  
  Auth2Type({this.id, this.identifier, this.active, this.active2fa, this.unverified, this.code, this.params}) :
    uiucUser = (params != null) ? Auth2UiucUser.fromJson(JsonUtils.mapValue(params['user'])) : null,
    loginType = auth2LoginTypeFromString(code);

  static Auth2Type? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Auth2Type(
      id: JsonUtils.stringValue(json['id']),
      identifier: JsonUtils.stringValue(json['identifier']),
      active: JsonUtils.boolValue(json['active']),
      active2fa: JsonUtils.boolValue(json['active_2fa']),
      unverified: JsonUtils.boolValue(json['unverified']),
      code: JsonUtils.stringValue(json['code']),
      params: JsonUtils.mapValue(json['params']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'identifier': identifier,
      'active': active,
      'active_2fa': active2fa,
      'unverified': unverified,
      'code': code,
      'params': params,
    };
  }

  @override
  bool operator ==(other) =>
    (other is Auth2Type) &&
      (other.id == id) &&
      (other.identifier == identifier) &&
      (other.active == active) &&
      (other.active2fa == active2fa) &&
      (other.unverified == unverified) &&
      (other.code == code) &&
      const DeepCollectionEquality().equals(other.params, params);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (identifier?.hashCode ?? 0) ^
    (active?.hashCode ?? 0) ^
    (active2fa?.hashCode ?? 0) ^
    (unverified?.hashCode ?? 0) ^
    (code?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(params));

  String? get uin {
    return (loginType == Auth2LoginType.oidcIllinois) ? identifier : null;
  }

  String? get phone {
    return (loginType == Auth2LoginType.phoneTwilio) ? identifier : null;
  }

  String? get email {
    return (loginType == Auth2LoginType.email) ? identifier : null;
  }

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

  Auth2UserPrefs({int? privacyLevel, Set<UserRole>? roles, Map<String, LinkedHashSet<String>>? favorites, Map<String, Set<String>>? interests, Map<String, Set<String>>? foodFilters, Map<String, bool>? tags, Map<String, dynamic>? answers, Map<String, dynamic>? settings, Auth2VoterPrefs? voter}) {
    _privacyLevel = privacyLevel;
    _roles = roles;
    _favorites = favorites;
    _interests = interests;
    _foodFilters = foodFilters;
    _tags = tags;
    _settings = settings;
    _voter = Auth2VoterPrefs.fromOther(voter, onChanged: _onVoterChanged);
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
      'voter': _voter
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
    (_voter?.hashCode ?? 0);

  bool apply(Auth2UserPrefs? prefs, { Set<Auth2UserPrefsScope>? scope }) {
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
}

enum Auth2UserPrefsScope { privacyLevel, roles, favorites, interests, foodFilters, tags, settings, voter }

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
  static const student = UserRole._internal('student');
  static const visitor = UserRole._internal('visitor');
  static const fan = UserRole._internal('fan');
  static const employee = UserRole._internal('employee');
  static const alumni = UserRole._internal('alumni');
  static const parent = UserRole._internal('parent');
  static const gies = UserRole._internal('gies');

  static List<UserRole> get values {
    return [student, visitor, fan, employee, alumni, parent, gies];
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
