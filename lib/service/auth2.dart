import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:rokwire_plugin/ext/network.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Auth2 with Service, NetworkAuthProvider implements NotificationsListener {
  
  static const String notifyLoginStarted      = "edu.illinois.rokwire.auth2.login.started";
  static const String notifyLoginSucceeded    = "edu.illinois.rokwire.auth2.login.succeeded";
  static const String notifyLoginFailed       = "edu.illinois.rokwire.auth2.login.failed";
  static const String notifyLoginChanged      = "edu.illinois.rokwire.auth2.login.changed";
  static const String notifyLoginFinished     = "edu.illinois.rokwire.auth2.login.finished";
  static const String notifyLogout            = "edu.illinois.rokwire.auth2.logout";
  static const String notifyLinkChanged       = "edu.illinois.rokwire.auth2.link.changed";
  static const String notifyAccountChanged    = "edu.illinois.rokwire.auth2.account.changed";
  static const String notifyProfileChanged    = "edu.illinois.rokwire.auth2.profile.changed";
  static const String notifyPrefsChanged      = "edu.illinois.rokwire.auth2.prefs.changed";
  static const String notifyPrivacyChanged    = "edu.illinois.rokwire.auth2.privacy.changed";
  static const String notifyUserDeleted       = "edu.illinois.rokwire.auth2.user.deleted";

  static const String _deviceIdIdentifier     = 'edu.illinois.rokwire.device_id';

  static const Auth2AccountScope defaultLoginScope = const Auth2AccountScope(
    prefs: { Auth2UserPrefsScope.privacyLevel, Auth2UserPrefsScope.roles }
  );


  _OidcLogin? _oidcLogin;
  Auth2AccountScope? _oidcScope;
  bool? _oidcLink;
  List<Completer<Auth2OidcAuthenticateResult?>>? _oidcAuthenticationCompleters;
  bool? _processingOidcAuthentication;
  Timer? _oidcAuthenticationTimer;

  final Map<String, Future<Response?>> _refreshTokenFutures = {};
  final Map<String, int> _refreshTonenFailCounts = {};

  Client? _updateUserPrefsClient;
  Timer? _updateUserPrefsTimer;
  
  Client? _updateUserProfileClient;
  Timer? _updateUserProfileTimer;

  Auth2Token? _token;
  Auth2Account? _account;

  String? _anonymousId;
  Auth2Token? _anonymousToken;
  Auth2UserPrefs? _anonymousPrefs;
  Auth2UserProfile? _anonymousProfile;
  
  String? _deviceId;
  
  DateTime? _pausedDateTime;

  // Singletone Factory

  static Auth2? _instance;

  static Auth2? get instance => _instance;
  
  @protected
  static set instance(Auth2? value) => _instance = value;

  factory Auth2() => _instance ?? (_instance = Auth2.internal());

  @protected
  Auth2.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      DeepLink.notifyUri,
      AppLivecycle.notifyStateChanged,
      Auth2UserProfile.notifyChanged,
      Auth2UserPrefs.notifyChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _token = Storage().auth2Token;
    _account = Storage().auth2Account;

    _anonymousId = Storage().auth2AnonymousId;
    _anonymousToken = Storage().auth2AnonymousToken;
    _anonymousPrefs = Storage().auth2AnonymousPrefs;
    _anonymousProfile = Storage().auth2AnonymousProfile;

    _deviceId = await RokwirePlugin.getDeviceId(deviceIdIdentifier, deviceIdIdentifier2);

    if ((_account == null) && (_anonymousPrefs == null)) {
      Storage().auth2AnonymousPrefs = _anonymousPrefs = defaultAnonimousPrefs;
    }

    if ((_account == null) && (_anonymousProfile == null)) {
      Storage().auth2AnonymousProfile = _anonymousProfile = defaultAnonimousProfile;
    }

    if ((_anonymousId == null) || (_anonymousToken == null) || !_anonymousToken!.isValid) {
      if (!await authenticateAnonymously()) {
        throw ServiceError(
          source: this,
          severity: ServiceErrorSeverity.fatal,
          title: 'Authentication Initialization Failed',
          description: 'Failed to initialize anonymous authentication token.',
        );
      }
    }

    _refreshAccount();

    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Storage(), Config() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      onDeepLinkUri(JsonUtils.cast(param));
    }
    else if (name == Auth2UserProfile.notifyChanged) {
      onUserProfileChanged(param);
    }
    else if (name == Auth2UserPrefs.notifyChanged) {
      onUserPrefsChanged(param);
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      onAppLivecycleStateChanged(param);
    }
  }

  @protected
  void onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      createOidcAuthenticationTimerIfNeeded();

      //TMP: _log('Core Access Token: ${_token?.accessToken}');

      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _refreshAccount();
        }
      }
    }
  }

  @protected
  String get oidcRedirectUrl => '${DeepLink().appUrl}/oidc-auth';

  @protected
  void onDeepLinkUri(Uri? uri) {
    if ((uri != null) && uri.matchDeepLinkUri(Uri.tryParse(oidcRedirectUrl))) {
      handleOidcAuthentication(uri);
    }
  }

  // NetworkAuthProvider

  @override
  Map<String, String>? get networkAuthHeaders {
    String? accessToken = token?.accessToken;
    if ((accessToken != null) && accessToken.isNotEmpty) {
      String? tokenType = token?.tokenType ?? 'Bearer';
      return { HttpHeaders.authorizationHeader : "$tokenType $accessToken" };
    }
    return null;
  }

  @override
  dynamic get networkAuthToken => token;
  
  @override
  Future<bool> refreshNetworkAuthTokenIfNeeded(BaseResponse? response, dynamic token) async {
    if ((response?.statusCode == 401) && (token is Auth2Token) && (this.token == token)) {
      return (await refreshToken(token) != null);
    }
    return false;
  }

  // Auth2TokenNetworkAuthProvider

  NetworkAuthProvider? get networkAuthProvider =>
    (token != null) ? Auth2TokenNetworkAuthProvider(token: token) : null;

  // Getters
  Auth2LoginType get oidcLoginType => Auth2LoginType.oidcIllinois;
  Auth2LoginType get phoneLoginType => Auth2LoginType.phoneTwilio;
  Auth2LoginType get emailLoginType => Auth2LoginType.email;
  Auth2LoginType get usernameLoginType => Auth2LoginType.username;

  Auth2Token? get token => _token ?? _anonymousToken;
  Auth2Token? get userToken => _token;
  Auth2Token? get anonymousToken => _anonymousToken;
  Auth2Account? get account => _account;
  String? get deviceId => _deviceId;
  
  String? get accountId => _account?.id ?? _anonymousId;
  Auth2UserPrefs? get prefs => _account?.prefs ?? _anonymousPrefs;
  Auth2UserProfile? get profile => _account?.profile ?? _anonymousProfile;
  Auth2LoginType? get loginType => _account?.authType?.loginType;

  bool get isLoggedIn => (_account?.id != null);
  bool get isOidcLoggedIn => (_account?.authType?.loginType == oidcLoginType);
  bool get isPhoneLoggedIn => (_account?.authType?.loginType == phoneLoginType);
  bool get isEmailLoggedIn => (_account?.authType?.loginType == emailLoginType);
  bool get isUsernameLoggedIn => (_account?.authType?.loginType == usernameLoginType);

  bool get isOidcLinked => _account?.isAuthTypeLinked(oidcLoginType) ?? false;
  bool get isPhoneLinked => _account?.isAuthTypeLinked(phoneLoginType) ?? false;
  bool get isEmailLinked => _account?.isAuthTypeLinked(emailLoginType) ?? false;
  bool get isUsernameLinked => _account?.isAuthTypeLinked(usernameLoginType) ?? false;

  List<Auth2Type> get linkedOidc => _account?.getLinkedForAuthType(oidcLoginType) ?? [];
  List<Auth2Type> get linkedPhone => _account?.getLinkedForAuthType(phoneLoginType) ?? [];
  List<Auth2Type> get linkedEmail => _account?.getLinkedForAuthType(emailLoginType) ?? [];
  List<Auth2Type> get linkedUsername => _account?.getLinkedForAuthType(usernameLoginType) ?? [];

  bool get hasUin => (0 < (uin?.length ?? 0));
  String? get uin => _account?.authType?.uiucUser?.uin;
  String? get netId => _account?.authType?.uiucUser?.netId;

  String? get fullName => StringUtils.ensureNotEmpty(profile?.fullName, defaultValue: _account?.authType?.uiucUser?.fullName ?? '');
  String? get firstName => StringUtils.ensureNotEmpty(profile?.firstName, defaultValue: _account?.authType?.uiucUser?.firstName ?? '');
  String? get email => StringUtils.ensureNotEmpty(profile?.email, defaultValue: _account?.authType?.uiucUser?.email ?? '');
  String? get phone => StringUtils.ensureNotEmpty(profile?.phone, defaultValue: _account?.authType?.phone ?? '');
  String? get username => _account?.username;

  bool get isCalendarAdmin => hasPermission(Config().stringPathEntry('settings.auth.permissions.calendar_admin', defaults: 'calendar_admin'));
  bool get isManagedGroupAdmin => hasPermission(Config().stringPathEntry('settings.auth.permissions.managed_group_admin', defaults: 'managed_group_admin'));
  bool get isResearchProjectAdmin => hasPermission(Config().stringPathEntry('settings.auth.permissions.research_group_admin', defaults: 'research_group_admin'));

  bool get isStadiumPollManager => hasRole(Config().stringPathEntry('settings.auth.roles.stadium_poll_manager', defaults: 'stadium poll manager'));
  bool get isDebugManager => hasRole(Config().stringPathEntry('settings.auth.roles.debug', defaults: 'debug'));

  bool get isEventEditor => hasRole(Config().stringPathEntry('settings.auth.roles.event_approvers', defaults: 'event approvers')) ||
    hasPermission(Config().stringPathEntry('settings.auth.permissions.event_approvers', defaults: 'event_approvers'));

  bool get isGroupsAccess => hasRole(Config().stringPathEntry('settings.auth.roles.groups_access', defaults: 'groups access')) ||
    hasPermission(Config().stringPathEntry('settings.auth.permissions.groups_access', defaults: 'groups_access'));

  bool hasRole(String? role) => _account?.hasRole(role) == true;
  bool hasPermission(String? permission) => _account?.hasPermission(permission) == true;
  bool belongsToGroup(String? group) => _account?.belongsToGroup(group) == true;

  bool isShibbolethMemberOf(String group) => _account?.authType?.uiucUser?.groupsMembership?.contains(group) ?? false;

  bool privacyMatch(int requredPrivacyLevel) => 
    (prefs?.privacyLevel == null) || (prefs?.privacyLevel == 0) || (prefs!.privacyLevel! >= requredPrivacyLevel);

  bool isFavorite(Favorite? favorite) => prefs?.isFavorite(favorite) ?? false;
  bool isListFavorite(List<Favorite>? favorites) => prefs?.isListFavorite(favorites) ?? false;

  bool get isVoterRegistered => prefs?.voter?.registeredVoter ?? false;
  bool? get isVoterByMail => prefs?.voter?.voterByMail;
  bool get didVote => prefs?.voter?.voted ?? false;
  String? get votePlace => prefs?.voter?.votePlace;
  
  // Overrides

  @protected
  Auth2UserPrefs get defaultAnonimousPrefs => Auth2UserPrefs.empty();

  @protected
  Auth2UserProfile get defaultAnonimousProfile => Auth2UserProfile.empty();

  @protected
  String? get deviceIdIdentifier => _deviceIdIdentifier;

  @protected
  String? get deviceIdIdentifier2 => null;

  // Anonymous Authentication

  Future<bool> authenticateAnonymously() async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (Config().rokwireApiKey != null)) {
      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.anonymous),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'device': deviceInfo
      });
      
      Response? response = await Network().post(url, headers: headers, body: post);
      Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
      if (responseJson != null) {
        Auth2Token? anonymousToken = Auth2Token.fromJson(JsonUtils.mapValue(responseJson['token']));
        Map<String, dynamic>? params = JsonUtils.mapValue(responseJson['params']);
        String? anonymousId = (params != null) ? JsonUtils.stringValue(params['anonymous_id']) : null;
        if ((anonymousToken != null) && anonymousToken.isValid && (anonymousId != null) && anonymousId.isNotEmpty) {
          _refreshTonenFailCounts.remove(_anonymousToken?.refreshToken);
          Storage().auth2AnonymousId = _anonymousId = anonymousId;
          Storage().auth2AnonymousToken = _anonymousToken = anonymousToken;
          _log("Auth2: anonymous auth succeeded: ${response?.statusCode}\n${response?.body}");
          return true;
        }
      }
      _log("Auth2: anonymous auth failed: ${response?.statusCode}\n${response?.body}");
    }
    return false;
  }

  // OIDC Authentication

  Future<Auth2OidcAuthenticateResult?> authenticateWithOidc({ Auth2AccountScope? scope = defaultLoginScope, bool? link}) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null)) {

      if (_oidcAuthenticationCompleters == null) {
        _oidcAuthenticationCompleters = <Completer<Auth2OidcAuthenticateResult?>>[];
        NotificationService().notify(notifyLoginStarted, oidcLoginType);

        _OidcLogin? oidcLogin = await getOidcData();
        if (oidcLogin?.loginUrl != null) {
          _oidcLogin = oidcLogin;
          _oidcScope = scope;
          _oidcLink = link;

          //await RokwirePlugin.clearSafariVC();
          await _launchUrl(_preprocessOidcLoginUrl(_oidcLogin?.loginUrl));
        }
        else {
          completeOidcAuthentication(Auth2OidcAuthenticateResult.failed);
          return Auth2OidcAuthenticateResult.failed;
        }
      }

      Completer<Auth2OidcAuthenticateResult?> completer = Completer<Auth2OidcAuthenticateResult?>();
      _oidcAuthenticationCompleters!.add(completer);
      return completer.future;
    }
    
    return Auth2OidcAuthenticateResult.failed;
  }

  @protected
  Future<Auth2OidcAuthenticateResult> handleOidcAuthentication(Uri uri) async {
    
    await RokwirePlugin.dismissSafariVC();
    
    cancelOidcAuthenticationTimer();

    _processingOidcAuthentication = true;
    Auth2OidcAuthenticateResult result;
    if (_oidcLink == true) {
      Auth2LinkResult linkResult = await linkAccountAuthType(oidcLoginType, uri.toString(), _oidcLogin?.params);
      result = auth2OidcAuthenticateResultFromAuth2LinkResult(linkResult);
    }
    else {
      bool processResult = await processOidcAuthentication(uri);
      result = processResult ? Auth2OidcAuthenticateResult.succeeded : Auth2OidcAuthenticateResult.failed;
    }
    _processingOidcAuthentication = false;

    completeOidcAuthentication(result);
    return result;
  }

  @protected
  Future<bool> processOidcAuthentication(Uri? uri) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null)) {
      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(oidcLoginType),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'creds': uri?.toString(),
        'params': _oidcLogin?.params,
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
      });
      _oidcLogin = null;

      Response? response = await Network().post(url, headers: headers, body: post);
      Log.d("Login: ${response?.statusCode}, ${response?.body}", lineLength: 512);
      Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
      bool result = await processLoginResponse(responseJson, scope: _oidcScope);
      _oidcScope = null;
      _log(result ? "Auth2: login succeeded: ${response?.statusCode}\n${response?.body}" : "Auth2: login failed: ${response?.statusCode}\n${response?.body}");
      return result;
    }
    return false;
  }

  @protected
  Future<bool> processLoginResponse(Map<String, dynamic>? responseJson, { Auth2AccountScope? scope }) async {
    if (responseJson != null) {
      Auth2Token? token = Auth2Token.fromJson(JsonUtils.mapValue(responseJson['token']));
      Auth2Account? account = Auth2Account.fromJson(JsonUtils.mapValue(responseJson['account']),
        prefs: _anonymousPrefs ?? Auth2UserPrefs.empty(),
        profile: _anonymousProfile ?? Auth2UserProfile.empty());

      if ((token != null) && token.isValid && (account != null) && account.isValid) {
        await applyLogin(account, token, scope: scope, params: JsonUtils.mapValue(responseJson['params']));
        return true;
      }
    }
    return false;
  }

  @protected
  Future<void> applyLogin(Auth2Account account, Auth2Token token, { Auth2AccountScope? scope, Map<String, dynamic>? params }) async {

    _refreshTonenFailCounts.remove(_token?.refreshToken);

    bool? prefsUpdated = account.prefs?.apply(_anonymousPrefs, scope: scope?.prefs);
    bool? profileUpdated = account.profile?.apply(_anonymousProfile, scope: scope?.profile);
    Storage().auth2Token = _token = token;
    Storage().auth2Account = _account = account;
    Storage().auth2AnonymousPrefs = _anonymousPrefs = null;
    Storage().auth2AnonymousProfile = _anonymousProfile = null;

    if (prefsUpdated == true) {
      _saveAccountUserPrefs();
    }

    if (profileUpdated == true) {
      _saveAccountUserProfile();
    }

    NotificationService().notify(notifyProfileChanged);
    NotificationService().notify(notifyPrefsChanged);
    NotificationService().notify(notifyPrivacyChanged);
    NotificationService().notify(notifyLoginChanged);
  }

  @protected
  Future<_OidcLogin?> getOidcData() async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null)) {

      String url = "${Config().coreUrl}/services/auth/login-url";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(oidcLoginType),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'redirect_uri': oidcRedirectUrl,
      });
      Response? response = await Network().post(url, headers: headers, body: post);
      return _OidcLogin.fromJson(JsonUtils.decodeMap(response?.body));
    }
    return null;
  }

  @protected
  void createOidcAuthenticationTimerIfNeeded() {
    if ((_oidcAuthenticationCompleters != null) && (_processingOidcAuthentication != true)) {
      if (_oidcAuthenticationTimer != null) {
        _oidcAuthenticationTimer!.cancel();
      }
      _oidcAuthenticationTimer = Timer(const Duration(milliseconds: 100), () {
        completeOidcAuthentication(null);
        _oidcAuthenticationTimer = null;
      });
    }
  }

  @protected
  void cancelOidcAuthenticationTimer() {
    if(_oidcAuthenticationTimer != null){
      _oidcAuthenticationTimer!.cancel();
      _oidcAuthenticationTimer = null;
    }
  }

  @protected
  void completeOidcAuthentication(Auth2OidcAuthenticateResult? result) {
    
    _notifyLogin(oidcLoginType, result == Auth2OidcAuthenticateResult.succeeded);

    _oidcLogin = null;
    _oidcScope = null;
    _oidcLink = null;

    if (_oidcAuthenticationCompleters != null) {
      List<Completer<Auth2OidcAuthenticateResult?>> loginCompleters = _oidcAuthenticationCompleters!;
      _oidcAuthenticationCompleters = null;

      for(Completer<Auth2OidcAuthenticateResult?> completer in loginCompleters){
        completer.complete(result);
      }
    }
  }

  // Phone Authentication

  Future<Auth2PhoneRequestCodeResult> authenticateWithPhone(String? phoneNumber) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (phoneNumber != null)) {
      NotificationService().notify(notifyLoginStarted, phoneLoginType);

      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(phoneLoginType),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'creds': {
          "phone": phoneNumber,
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      if (response?.statusCode == 200) {
        return Auth2PhoneRequestCodeResult.succeeded;
      }
      else if (Auth2Error.fromJson(JsonUtils.decodeMap(response?.body))?.status == 'already-exists') {
        return Auth2PhoneRequestCodeResult.failedAccountExist;
      }
    }
    return Auth2PhoneRequestCodeResult.failed;
  }

  Future<Auth2PhoneSendCodeResult> handlePhoneAuthentication(String? phoneNumber, String? code, { Auth2AccountScope? scope = defaultLoginScope }) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (phoneNumber != null) && (code != null)) {
      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(phoneLoginType),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'creds': {
          "phone": phoneNumber,
          "code": code,
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      if (response?.statusCode == 200) {
        bool result = await processLoginResponse(JsonUtils.decodeMap(response?.body), scope: scope);
        _notifyLogin(phoneLoginType, result);
        return result ? Auth2PhoneSendCodeResult.succeeded : Auth2PhoneSendCodeResult.failed;
      }
      else {
        _notifyLogin(phoneLoginType, false);
        Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response?.body));
        if (error?.status == 'invalid') {
          return Auth2PhoneSendCodeResult.failedInvalid;
        }
      }
    }
    return Auth2PhoneSendCodeResult.failed;
  }

  // Email Authentication

  Future<Auth2EmailSignInResult> authenticateWithEmail(String? email, String? password, { Auth2AccountScope? scope = defaultLoginScope }) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (email != null) && (password != null)) {
      
      NotificationService().notify(notifyLoginStarted, emailLoginType);

      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(emailLoginType),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'creds': {
          "email": email,
          "password": password
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      if (response?.statusCode == 200) {
        bool result = await processLoginResponse(JsonUtils.decodeMap(response?.body), scope: scope);
        _notifyLogin(emailLoginType, result);
        return result ? Auth2EmailSignInResult.succeeded : Auth2EmailSignInResult.failed;
      }
      else {
        _notifyLogin(emailLoginType, false);
        Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response?.body));
        if (error?.status == 'unverified') {
          return Auth2EmailSignInResult.failedNotActivated;
        }
        else if (error?.status == 'verification-expired') {
          return Auth2EmailSignInResult.failedActivationExpired;
        }
        else if (error?.status == 'invalid') {
          return Auth2EmailSignInResult.failedInvalid;
        }
      }
    }
    return Auth2EmailSignInResult.failed;
  }

  Future<Auth2EmailSignUpResult> signUpWithEmail(String? email, String? password) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (email != null) && (password != null)) {
      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(emailLoginType),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'creds': {
          "email": email,
          "password": password
        },
        'params': {
          "sign_up": true,
          "confirm_password": password
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      if (response?.statusCode == 200) {
        return Auth2EmailSignUpResult.succeeded;
      }
      else if (Auth2Error.fromJson(JsonUtils.decodeMap(response?.body))?.status == 'already-exists') {
        return Auth2EmailSignUpResult.failedAccountExist;
      }
    }
    return Auth2EmailSignUpResult.failed;
  }

  Future<Auth2EmailAccountState?> checkEmailAccountState(String? email) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (email != null)) {
      String url = "${Config().coreUrl}/services/auth/account/exists";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(emailLoginType),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'user_identifier': email,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      if (response?.statusCode == 200) {
        //TBD: handle Auth2EmailAccountState.unverified
        return JsonUtils.boolValue(JsonUtils.decode(response?.body))! ? Auth2EmailAccountState.verified : Auth2EmailAccountState.nonExistent;
      }
    }
    return null;
  }

  Future<Auth2EmailForgotPasswordResult> resetEmailPassword(String? email) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (email != null)) {
      String url = "${Config().coreUrl}/services/auth/credential/forgot/initiate";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(emailLoginType),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'user_identifier': email,
        'identifier': email,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      if (response?.statusCode == 200) {
        return Auth2EmailForgotPasswordResult.succeeded;
      }
      else {
        Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response?.body));
        if (error?.status == 'verification-expired') {
          return Auth2EmailForgotPasswordResult.failedActivationExpired;
        } 
        else if (error?.status == 'unverified') {
          return Auth2EmailForgotPasswordResult.failedNotActivated;
        }
      }
    }
    return Auth2EmailForgotPasswordResult.failed;
  }

  Future<bool> resentActivationEmail(String? email) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (email != null)) {
      String url = "${Config().coreUrl}/services/auth/credential/send-verify";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(emailLoginType),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'user_identifier': email,
        'identifier': email,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      return (response?.statusCode == 200);
    }
    return false;
  }

  // Username Authentication

  Future<Auth2UsernameSignInResult> authenticateWithUsername(String? username, String? password, { Auth2AccountScope? scope = defaultLoginScope }) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (username != null) && (password != null)) {

      NotificationService().notify(notifyLoginStarted, usernameLoginType);

      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(usernameLoginType),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'creds': {
          "username": username,
          "password": password
        },
        'params': {
          "sign_up": false,
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      if (response?.statusCode == 200) {
        bool result = await processLoginResponse(JsonUtils.decodeMap(response?.body), scope: scope);
        _notifyLogin(usernameLoginType, result);
        return result ? Auth2UsernameSignInResult.succeeded : Auth2UsernameSignInResult.failed;
      }
      else {
        _notifyLogin(usernameLoginType, false);
        Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response?.body));
        if (error?.status == 'not-found') {
          return Auth2UsernameSignInResult.failedNotFound;
        } else if (error?.status == 'invalid') {
          return Auth2UsernameSignInResult.failedInvalid;
        }
      }
    }
    return Auth2UsernameSignInResult.failed;
  }

  Future<Auth2UsernameSignUpResult> signUpWithUsername(String? username, String? password, { Auth2AccountScope? scope = defaultLoginScope }) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (username != null) && (password != null)) {
      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(usernameLoginType),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'creds': {
          "username": username,
          "password": password
        },
        'params': {
          "sign_up": true,
          "confirm_password": password
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      if (response?.statusCode == 200) {
        bool result = await processLoginResponse(JsonUtils.decodeMap(response?.body), scope: scope);
        _notifyLogin(usernameLoginType, result);
        return result ? Auth2UsernameSignUpResult.succeeded : Auth2UsernameSignUpResult.failed;
      }
      else if (Auth2Error.fromJson(JsonUtils.decodeMap(response?.body))?.status == 'already-exists') {
        return Auth2UsernameSignUpResult.failedAccountExist;
      }
    }
    return Auth2UsernameSignUpResult.failed;
  }

  Future<Auth2UsernameAccountState?> checkUsernameAccountState(String? username) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (username != null)) {
      String url = "${Config().coreUrl}/services/auth/account/exists";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(usernameLoginType),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'user_identifier': username,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      if (response?.statusCode == 200) {
        //TBD: handle Auth2EmailAccountState.unverified
        return JsonUtils.boolValue(JsonUtils.decode(response?.body))! ? Auth2UsernameAccountState.exists : Auth2UsernameAccountState.nonExistent;
      }
    }
    return null;
  }

  // Notify Login

  void _notifyLogin(Auth2LoginType loginType, bool? result) {
    if (result != null) {
      NotificationService().notify(result ? notifyLoginSucceeded : notifyLoginFailed, loginType);
      NotificationService().notify(notifyLoginFinished, loginType);
    }
  }

  // Account Checks

  Future<bool?> canSignIn(String? identifier, Auth2LoginType loginType) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (identifier != null)) {
      String url = "${Config().coreUrl}/services/auth/account/can-sign-in";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(loginType),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'user_identifier': identifier,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      if (response?.statusCode == 200) {
        return JsonUtils.boolValue(JsonUtils.decode(response?.body))!;
      }
    }
    return null;
  }

  Future<bool?> canLink(String? identifier, Auth2LoginType loginType) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (Config().coreOrgId != null) && (identifier != null)) {
      String url = "${Config().coreUrl}/services/auth/account/can-link";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(loginType),
        'app_type_identifier': Config().appPlatformId,
        'api_key': Config().rokwireApiKey,
        'org_id': Config().coreOrgId,
        'user_identifier': identifier,
      });

      Response? response = await Network().post(url, headers: headers, body: post);
      if (response?.statusCode == 200) {
        return JsonUtils.boolValue(JsonUtils.decode(response?.body))!;
      }
    }
    return null;
  }

  // Account Linking

  Future<Auth2LinkResult> linkAccountAuthType(Auth2LoginType? loginType, dynamic creds, Map<String, dynamic>? params) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (loginType != null)) {
      String url = "${Config().coreUrl}/services/auth/account/auth-type/link";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(loginType),
        'app_type_identifier': Config().appPlatformId,
        'creds': creds,
        'params': params,
      });
      _oidcLink = null;

      Response? response = await Network().post(url, headers: headers, body: post, auth: Auth2());
      if (response?.statusCode == 200) {
        Map<String, dynamic>? responseJson = JsonUtils.decodeMap(response?.body);
        List<Auth2Type>? authTypes = (responseJson != null) ? Auth2Type.listFromJson(JsonUtils.listValue(responseJson['auth_types'])) : null;
        if (authTypes != null) {
          Storage().auth2Account = _account = Auth2Account.fromOther(_account, authTypes: authTypes);
          NotificationService().notify(notifyLinkChanged);
          return Auth2LinkResult.succeeded;
        }
      }
      else {
        Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response?.body));
        if (error?.status == 'verification-expired') {
          return Auth2LinkResult.failedActivationExpired;
        }
        else if (error?.status == 'unverified') {
          return Auth2LinkResult.failedNotActivated;
        }
        else if (error?.status == 'already-exists') {
          return Auth2LinkResult.failedAccountExist;
        }
        else if (error?.status == 'invalid') {
          return Auth2LinkResult.failedInvalid;
        }
      } 
    }
    return Auth2LinkResult.failed;
  }

  Future<bool> unlinkAccountAuthType(Auth2LoginType? loginType, String identifier) async {
    if ((Config().coreUrl != null) && (Config().appPlatformId != null) && (loginType != null)) {
      String url = "${Config().coreUrl}/services/auth/account/auth-type/link";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? body = JsonUtils.encode({
        'auth_type': auth2LoginTypeToString(loginType),
        'app_type_identifier': Config().appPlatformId,
        'identifier': identifier,
      });

      Response? response = await Network().delete(url, headers: headers, body: body, auth: Auth2());
      Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
      List<Auth2Type>? authTypes = (responseJson != null) ? Auth2Type.listFromJson(JsonUtils.listValue(responseJson['auth_types'])) : null;
      if (authTypes != null) {
        Storage().auth2Account = _account = Auth2Account.fromOther(_account, authTypes: authTypes);
        NotificationService().notify(notifyLinkChanged);
        return true;
      }
    }
    return false;
  }

  // Device Info

  @protected
  Map<String, dynamic> get deviceInfo {
    return {
      'type': "mobile",
      'device_id': _deviceId,
      'os': Platform.operatingSystem,
    };
  }

  // Logout

  void logout({ Auth2UserPrefs? prefs }) {
    if (_token != null) {
      _log("Auth2: logout");
      _refreshTonenFailCounts.remove(_token?.refreshToken);

      Storage().auth2AnonymousPrefs = _anonymousPrefs = prefs ?? _account?.prefs ?? Auth2UserPrefs.empty();
      Storage().auth2AnonymousProfile = _anonymousProfile = Auth2UserProfile.empty();
      Storage().auth2Token = _token = null;
      Storage().auth2Account = _account = null;

      _updateUserPrefsTimer?.cancel();
      _updateUserPrefsTimer = null;

      _updateUserPrefsClient?.close();
      _updateUserPrefsClient = null;

      _updateUserProfileTimer?.cancel();
      _updateUserProfileTimer = null;

      _updateUserProfileClient?.close();
      _updateUserProfileClient = null;

      NotificationService().notify(notifyProfileChanged);
      NotificationService().notify(notifyPrefsChanged);
      NotificationService().notify(notifyPrivacyChanged);
      NotificationService().notify(notifyLoginChanged);
      NotificationService().notify(notifyLogout);
    }
  }

  // Delete

  Future<bool?> deleteUser() async {
    bool? result = await _deleteUserAccount();
    if (result == true) {
      logout(prefs: Auth2UserPrefs.empty());
      NotificationService().notify(notifyUserDeleted);
    }
    return result;
  }

  Future<bool?> _deleteUserAccount() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/account";
      Response? response = await Network().delete(url, auth: Auth2());
      return response?.statusCode == 200;
    }
    return null;
  }

  // Refresh

  Future<Auth2Token?> refreshToken(Auth2Token token) async {
    if ((Config().coreUrl != null) && (token.refreshToken != null)) {
      try {
        Future<Response?>? refreshTokenFuture = _refreshTokenFutures[token.refreshToken];

        if (refreshTokenFuture != null) {
          _log("Auth2: will await refresh token:\nSource Token: ${token.refreshToken}");
          Response? response = await refreshTokenFuture;
          Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
          Auth2Token? responseToken = (responseJson != null) ? Auth2Token.fromJson(JsonUtils.mapValue(responseJson['token'])) : null;
          _log("Auth2: did await refresh token: ${responseToken?.isValid}\nSource Token: ${token.refreshToken}");
          return ((responseToken != null) && responseToken.isValid) ? responseToken : null;
        }
        else {
          _log("Auth2: will refresh token:\nSource Token: ${token.refreshToken}");

          _refreshTokenFutures[token.refreshToken!] = refreshTokenFuture = _refreshToken(token.refreshToken);
          Response? response = await refreshTokenFuture;
          _refreshTokenFutures.remove(token.refreshToken);

          Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
          if (responseJson != null) {
            Auth2Token? responseToken = Auth2Token.fromJson(JsonUtils.mapValue(responseJson['token']));
            if ((responseToken != null) && responseToken.isValid) {
              _log("Auth2: did refresh token:\nResponse Token: ${responseToken.refreshToken}\nSource Token: ${token.refreshToken}");
              _refreshTonenFailCounts.remove(token.refreshToken);

              if (token == _token) {
                applyToken(responseToken, params: JsonUtils.mapValue(responseJson['params']));
              }
              else if (token == _anonymousToken) {
                Storage().auth2AnonymousToken = _anonymousToken = responseToken;
              }
              return responseToken;
            }
          }

          _log("Auth2: failed to refresh token: ${response?.statusCode}\n${response?.body}\nSource Token: ${token.refreshToken}");
          int refreshTonenFailCount  = (_refreshTonenFailCounts[token.refreshToken] ?? 0) + 1;
          if (((response?.statusCode == 400) || (response?.statusCode == 401)) || (Config().refreshTokenRetriesCount <= refreshTonenFailCount)) {
            if (token == _token) {
              logout();
            }
            else if (token == _anonymousToken) {
              await authenticateAnonymously();
            }
          }
          else {
            _refreshTonenFailCounts[token.refreshToken!] = refreshTonenFailCount;
          }
        }
      }
      catch(e) {
        debugPrint(e.toString());
        _refreshTokenFutures.remove(token.refreshToken); // make sure to clear this in case something went wrong.
      }
    }
    return null;
  }

  @protected
  void applyToken(Auth2Token token, { Map<String, dynamic>? params }) {
    Storage().auth2Token = _token = token;
  }

  static Future<Response?> _refreshToken(String? refreshToken) async {
    if ((Config().coreUrl != null) && (refreshToken != null)) {
      String url = "${Config().coreUrl}/services/auth/refresh";
      
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'api_key': Config().rokwireApiKey,
        'refresh_token': refreshToken
      });

      return Network().post(url, headers: headers, body: post);
    }
    return null;
  }

  // User Prefs

  @protected
  Future<void> onUserPrefsChanged(Auth2UserPrefs? prefs) async {
    if (identical(prefs, _anonymousPrefs)) {
      Storage().auth2AnonymousPrefs = _anonymousPrefs;
      NotificationService().notify(notifyPrefsChanged);
    }
    else if (identical(prefs, _account?.prefs)) {
      Storage().auth2Account = _account;
      NotificationService().notify(notifyPrefsChanged);
      return _saveAccountUserPrefs();
    }
    return;
  }

  Future<void> _saveAccountUserPrefs() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null) && (_account?.prefs != null)) {
      String url = "${Config().coreUrl}/services/account/preferences";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode(_account!.prefs);

      Client client = Client();
      _updateUserPrefsClient?.close();
      _updateUserPrefsClient = client;
      
      Response? response = await Network().put(url, auth: Auth2(), headers: headers, body: post, client: _updateUserPrefsClient);
      
      if (identical(client, _updateUserPrefsClient)) {
        if (response?.statusCode == 200) {
          _updateUserPrefsTimer?.cancel();
          _updateUserPrefsTimer = null;
        }
        else {
          _updateUserPrefsTimer ??= Timer.periodic(const Duration(seconds: 3), (_) {
            if (_updateUserPrefsClient == null) {
              _saveAccountUserPrefs();
            }
          });
        }
        _updateUserPrefsClient = null;
      }
    }
  }

  /*Future<Auth2UserPrefs?> _loadAccountUserPrefs() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/account/preferences";
      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? Auth2UserPrefs.fromJson(JsonUtils.decodeMap(response?.body)) : null;
    }
    return null;
  }

  Future<void> _refreshAccountUserPrefs() async {
    Auth2UserPrefs? prefs = await _loadAccountUserPrefs();
    if ((prefs != null) && (prefs != _account?.prefs)) {
      if (_account?.prefs?.apply(prefs, notify: true) ?? false) {
        Storage().auth2Account = _account;
        NotificationService().notify(notifyPrefsChanged);
      }
    }
  }*/

  // User Profile
  
  @protected
  void onUserProfileChanged(Auth2UserProfile? profile) {
    if (identical(profile, _anonymousProfile)) {
      Storage().auth2AnonymousProfile = _anonymousProfile;
      NotificationService().notify(notifyProfileChanged);
    }
    else if (identical(profile, _account?.profile)) {
      Storage().auth2Account = _account;
      NotificationService().notify(notifyProfileChanged);
      onUserAccountProfileChanged(profile);
      _saveAccountUserProfile();
    }
  }

  @protected
  void onUserAccountProfileChanged(Auth2UserProfile? profile) {
  }

  Future<Auth2UserProfile?> loadUserProfile() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/account/profile";
      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? Auth2UserProfile.fromJson(JsonUtils.decodeMap(response?.body)) : null;
    }
    return null;
  }

  Future<bool> saveUserProfile(Auth2UserProfile? profile) async {
    if (await _saveUserProfile(profile)) {
      if (_account?.profile?.apply(profile, scope: Auth2UserProfileScopeImpl.fullScope) ?? false) {
        Storage().auth2Account = _account;
        NotificationService().notify(notifyProfileChanged);
        onUserAccountProfileChanged(profile);
      }
      return true;
    }
    return false;
  }

  Future<void> _saveAccountUserProfile() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null) && (_account?.profile != null)) {
      Client client = Client();
      _updateUserProfileClient?.close();
      _updateUserProfileClient = client;

      bool result = await _saveUserProfile(_account?.profile, client: _updateUserProfileClient);

      if (identical(client, _updateUserProfileClient)) {
        if (result) {
          _updateUserProfileTimer?.cancel();
          _updateUserProfileTimer = null;
        }
        else {
          _updateUserProfileTimer ??= Timer.periodic(const Duration(seconds: 3), (_) {
            if (_updateUserProfileClient == null) {
              _saveAccountUserProfile();
            }
          });
        }
        _updateUserProfileClient = null;
      }
    }
  }

  Future<bool> _saveUserProfile(Auth2UserProfile? profile, { Client? client }) async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null) && (profile != null)) {
      String url = "${Config().coreUrl}/services/account/profile";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode(profile.toJson());
      Response? response = await Network().put(url, auth: Auth2(), headers: headers, body: post, client: client);
      return (response?.statusCode == 200);
    }
    return false;
  }

  /*Future<void> _refreshAccountUserProfile() async {
    Auth2UserProfile? profile = await loadUserProfile();
    if ((profile != null) && (profile != _account?.profile)) {
      if (_account?.profile?.apply(profile) ?? false) {
        Storage().auth2Account = _account;
        NotificationService().notify(notifyProfileChanged);
      }
    }
  }*/

  // Privacy

  Future<Auth2UserPrivacy?> loadUserPrivacy() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/account/privacy";
      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? Auth2UserPrivacy.fromJson(JsonUtils.decodeMap(response?.body)) : null;
    }
    return null;
  }

  Future<bool> saveUserPrivacy(Auth2UserPrivacy? privacy) async {
    if (await _saveUserPrivacy(privacy)) {
      if (_account?.privacy != privacy) {
        Storage().auth2Account = _account = Auth2Account.fromOther(_account, privacy: privacy);
        NotificationService().notify(notifyPrivacyChanged);
      }
      return true;
    }
    return false;
  }

  // ignore: unused_element_parameter
  Future<bool> _saveUserPrivacy(Auth2UserPrivacy? privacy, { Client? client }) async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null) && (privacy != null)) {
      String url = "${Config().coreUrl}/services/account/privacy";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode(privacy.toJson());
      Response? response = await Network().put(url, auth: Auth2(), headers: headers, body: post);
      return (response?.statusCode == 200);
    }
    return false;
  }

  // Account

  Future<Response?> _loadAccountResponse() async {
    return ((Config().coreUrl != null) && (_token?.accessToken != null)) ?
      Network().get("${Config().coreUrl}/services/account", auth: Auth2()) : null;
  }

  Future<Auth2Account?> _loadAccount() async {
    Response? response = await _loadAccountResponse();
    return (response?.statusCode == 200) ? Auth2Account.fromJson(JsonUtils.decodeMap(response?.body)) : null;
  }

  Future<void> _refreshAccount() async {
    Auth2Account? account = await _loadAccount();
    if ((account != null) && (account != _account)) {
      
      bool profileUpdated = (account.profile != _account?.profile);
      bool prefsUpdated = (account.prefs != _account?.prefs);
      bool privacyChanged = (account.privacy != _account?.privacy);
      
      Storage().auth2Account = _account = account;
      NotificationService().notify(notifyAccountChanged);

      if (profileUpdated) {
        NotificationService().notify(notifyProfileChanged);
      }
      if (prefsUpdated) {
        NotificationService().notify(notifyPrefsChanged);
      }
      if (privacyChanged) {
        NotificationService().notify(notifyPrivacyChanged);
      }
    }
  }

  // User Data

  Future<Map<String, dynamic>?> loadUserDataJson() async {
    Response? response = (Config().coreUrl != null) ? await Network().get("${Config().coreUrl}/services/user-data", auth: Auth2()) : null;
    return (response?.succeeded == true) ? JsonUtils.decodeMap(response?.body) : null;
  }

  // Helpers

  static String? _preprocessOidcLoginUrl(String? loginUrl) {
    if ((loginUrl != null) && kDebugMode) {
      Uri? loginUri = Uri.tryParse(loginUrl);
      if (loginUri != null) {
        Map<String, String> queryParameters = Map<String, String>.from(loginUri.queryParameters);
        if (queryParameters['prompt'] == null) {
          queryParameters.addAll(<String, String>{
            'prompt': 'login'
          });
          loginUri = loginUri.replace(queryParameters: queryParameters);
          loginUrl = loginUri.toString();
        }
      }
    }
    return loginUrl;
  }

  static Future<void> _launchUrl(String? urlStr) async {
    try {
      if ((urlStr != null) && await canLaunchUrlString(urlStr)) {
        await launchUrlString(urlStr, mode: Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault);
      }
    }
    catch(e) {
      debugPrint(e.toString());
    }
  }

  static void _log(String message) {
    Log.d(message, lineLength: 512); // max line length of VS Code Debug Console
  }

}

class _OidcLogin {
  final String? loginUrl;
  final Map<String, dynamic>? params;
  
  _OidcLogin({this.loginUrl, this.params});

  static _OidcLogin? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? _OidcLogin(
      loginUrl: JsonUtils.stringValue(json['login_url']),
      params: JsonUtils.mapValue(json['params'])
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'login_url' : loginUrl,
      'params': params
    };
  }  

}

// Auth2TokenNetworkAuthProvider

class Auth2TokenNetworkAuthProvider with NetworkAuthProvider {

  final Auth2Token? token;
  Auth2TokenNetworkAuthProvider({this.token});

  @override
  Map<String, String>? get networkAuthHeaders {
    String? accessToken = token?.accessToken;
    if ((accessToken != null) && accessToken.isNotEmpty) {
      String? tokenType = token?.tokenType ?? 'Bearer';
      return { HttpHeaders.authorizationHeader : "$tokenType $accessToken" };
    }
    return null;
  }

  @override
  dynamic get networkAuthToken => token;
}



// Auth2PhoneRequestCodeResult

enum Auth2PhoneRequestCodeResult {
  succeeded,
  failed,
  failedAccountExist,
}

Auth2PhoneRequestCodeResult auth2PhoneRequestCodeResultFromAuth2LinkResult(Auth2LinkResult value) {
  switch (value) {
    case Auth2LinkResult.succeeded: return Auth2PhoneRequestCodeResult.succeeded;
    case Auth2LinkResult.failedAccountExist: return Auth2PhoneRequestCodeResult.failedAccountExist;
    default: return Auth2PhoneRequestCodeResult.failed;
  }
}

// Auth2PhoneSendCodeResult

enum Auth2PhoneSendCodeResult {
  succeeded,
  failed,
  failedInvalid,
}

Auth2PhoneSendCodeResult auth2PhoneSendCodeResultFromAuth2LinkResult(Auth2LinkResult value) {
  switch (value) {
    case Auth2LinkResult.succeeded: return Auth2PhoneSendCodeResult.succeeded;
    case Auth2LinkResult.failedInvalid: return Auth2PhoneSendCodeResult.failedInvalid;
    default: return Auth2PhoneSendCodeResult.failed;
  }
}

// Auth2EmailAccountState

enum Auth2EmailAccountState {
  nonExistent,
  unverified,
  verified,
}

// Auth2EmailSignUpResult

enum Auth2EmailSignUpResult {
  succeeded,
  failed,
  failedAccountExist,
}

Auth2EmailSignUpResult auth2EmailSignUpResultFromAuth2LinkResult(Auth2LinkResult value) {
  switch (value) {
    case Auth2LinkResult.succeeded: return Auth2EmailSignUpResult.succeeded;
    case Auth2LinkResult.failedAccountExist: return Auth2EmailSignUpResult.failedAccountExist;
    default: return Auth2EmailSignUpResult.failed;
  }
}

// Auth2EmailSignInResult

enum Auth2EmailSignInResult {
  succeeded,
  failed,
  failedActivationExpired,
  failedNotActivated,
  failedInvalid,
}

Auth2EmailSignInResult auth2EmailSignInResultFromAuth2LinkResult(Auth2LinkResult value) {
  switch (value) {
    case Auth2LinkResult.succeeded: return Auth2EmailSignInResult.succeeded;
    case Auth2LinkResult.failedNotActivated: return Auth2EmailSignInResult.failedNotActivated;
    case Auth2LinkResult.failedActivationExpired: return Auth2EmailSignInResult.failedActivationExpired;
    case Auth2LinkResult.failedInvalid: return Auth2EmailSignInResult.failedInvalid;
    default: return Auth2EmailSignInResult.failed;
  }
}

// Auth2EmailForgotPasswordResult

enum Auth2EmailForgotPasswordResult {
  succeeded,
  failed,
  failedActivationExpired,
  failedNotActivated,
}

// Auth2OidcAuthenticateResult

enum Auth2OidcAuthenticateResult {
  succeeded,
  failed,
  failedAccountExist,
}

Auth2OidcAuthenticateResult auth2OidcAuthenticateResultFromAuth2LinkResult(Auth2LinkResult value) {
  switch (value) {
    case Auth2LinkResult.succeeded: return Auth2OidcAuthenticateResult.succeeded;
    case Auth2LinkResult.failedAccountExist: return Auth2OidcAuthenticateResult.failedAccountExist;
    default: return Auth2OidcAuthenticateResult.failed;
  }
}

// Auth2UsernameAccountState

enum Auth2UsernameAccountState {
  nonExistent,
  exists,
}

// Auth2UsernameSignUpResult

enum Auth2UsernameSignUpResult {
  succeeded,
  failed,
  failedAccountExist,
}

Auth2UsernameSignUpResult auth2UsernameSignUpResultFromAuth2LinkResult(Auth2LinkResult value) {
  switch (value) {
    case Auth2LinkResult.succeeded: return Auth2UsernameSignUpResult.succeeded;
    case Auth2LinkResult.failedAccountExist: return Auth2UsernameSignUpResult.failedAccountExist;
    default: return Auth2UsernameSignUpResult.failed;
  }
}

// Auth2UsernameSignInResult

enum Auth2UsernameSignInResult {
  succeeded,
  failed,
  failedNotFound,
  failedInvalid,
}

Auth2UsernameSignInResult auth2UsernameSignInResultFromAuth2LinkResult(Auth2LinkResult value) {
  switch (value) {
    case Auth2LinkResult.succeeded: return Auth2UsernameSignInResult.succeeded;
    case Auth2LinkResult.failedInvalid: return Auth2UsernameSignInResult.failedInvalid;
    default: return Auth2UsernameSignInResult.failed;
  }
}

// Auth2LinkResult

enum Auth2LinkResult {
  succeeded,
  failed,
  failedActivationExpired,
  failedNotActivated,
  failedAccountExist,
  failedInvalid,
}