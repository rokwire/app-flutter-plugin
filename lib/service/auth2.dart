import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';

import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  static const String notifyUserDeleted       = "edu.illinois.rokwire.auth2.user.deleted";
  static const String notifyPrepareUserDelete = "edu.illinois.rokwire.auth2.user.prepare.delete";

  static const String _deviceIdIdentifier     = 'edu.illinois.rokwire.device_id';

  _OidcLogin? _oidcLogin;
  bool? _oidcLink;
  List<Completer<Auth2OidcAuthenticateResult?>>? _oidcAuthenticationCompleters;
  bool? _processingOidcAuthentication;
  Timer? _oidcAuthenticationTimer;

  final Map<String, Future<Response?>> _refreshTokenFutures = {};
  final Map<String, int> _refreshTokenFailCounts = {};

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
      AppLifecycle.notifyStateChanged,
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
    _token = await Storage().getAuth2Token();
    _account = await Storage().getAuth2Account();

    _anonymousId = Storage().auth2AnonymousId;
    _anonymousToken = await Storage().getAuth2AnonymousToken();
    _anonymousPrefs = await Storage().getAuth2AnonymousPrefs();
    _anonymousProfile = await Storage().getAuth2AnonymousProfile();

    _deviceId = await RokwirePlugin.getDeviceId(deviceIdIdentifier, deviceIdIdentifier2);

    if ((_account == null) && (_anonymousPrefs == null)) {
      await Storage().setAuth2AnonymousPrefs(_anonymousPrefs = defaultAnonymousPrefs);
    }

    if ((_account == null) && (_anonymousProfile == null)) {
      await Storage().setAuth2AnonymousProfile(_anonymousProfile = defaultAnonymousProfile);
    }

    if ((_anonymousId == null) || (_anonymousToken == null) || !_anonymousToken!.isValid) {
      if (!await authenticateAnonymously()) {
        // throw ServiceError(
        //   source: this,
        //   severity: ServiceErrorSeverity.fatal,
        //   title: 'Authentication Initialization Failed',
        //   description: 'Failed to initialize anonymous authentication token.',
        // );
      }
    }

    // if (kIsWeb && _token == null) {
    //   refreshToken().then((token) {
    //     if (token != null) {
    //       debugPrint('refresh on init succeeded...');
    //       NotificationService().notify(Auth2.notifyLoginSucceeded, null);
    //     }
    //   });
    // }
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
      onDeepLinkUri(param);
    }
    else if (name == Auth2UserProfile.notifyChanged) {
      onUserProfileChanged(param);
    }
    else if (name == Auth2UserPrefs.notifyChanged) {
      onUserPrefsChanged(param);
    }
    else if (name == AppLifecycle.notifyStateChanged) {
      onAppLifecycleStateChanged(param);
    }
  }

  @protected
  void onAppLifecycleStateChanged(AppLifecycleState? state) {
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
    if (uri != null) {
      if (!kIsWeb) {
        Uri? redirectUri = Uri.tryParse(oidcRedirectUrl);
        if ((redirectUri == null) ||
            (redirectUri.scheme != uri.scheme) ||
            (redirectUri.authority != uri.authority) ||
            (redirectUri.path != uri.path)) {
          return;
        }
      }

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
      return (await refreshToken(token: token) != null);
    }
    return false;
  }

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

  bool get isEventEditor => hasRole("event approvers");
  bool get isStadiumPollManager => hasRole("stadium poll manager");
  bool get isDebugManager => hasRole("debug");
  bool get isGroupsAccess => hasRole("groups access");

  bool hasRole(String role) => _account?.hasRole(role) ?? false;

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
  Auth2UserPrefs get defaultAnonymousPrefs => Auth2UserPrefs.empty();

  @protected
  Auth2UserProfile get defaultAnonymousProfile => Auth2UserProfile.empty();

  @protected
  String? get deviceIdIdentifier => _deviceIdIdentifier;

  @protected
  String? get deviceIdIdentifier2 => null;

  // Anonymous Authentication

  Future<bool> authenticateAnonymously() async {
    if (Config().supportsAnonymousAuth && (Config().authBaseUrl != null)) {
      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(Auth2LoginType.anonymous),
        'device': deviceInfo,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return false;
      }
      
      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData));
      Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
      if (responseJson != null) {
        Auth2Token? anonymousToken = Auth2Token.fromJson(JsonUtils.mapValue(responseJson['token']));
        Map<String, dynamic>? params = JsonUtils.mapValue(responseJson['params']);
        String? anonymousId = (params != null) ? JsonUtils.stringValue(params['anonymous_id']) : null;
        if ((anonymousToken != null) && anonymousToken.isValid && (anonymousId != null) && anonymousId.isNotEmpty) {
          _refreshTokenFailCounts.remove(_anonymousToken?.refreshToken);
          await Storage().setAuth2AnonymousId(_anonymousId = anonymousId);
          await Storage().setAuth2AnonymousToken(_anonymousToken = anonymousToken);
          _log("Auth2: anonymous auth succeeded: ${response?.statusCode}\n${response?.body}");
          return true;
        }
      }
      _log("Auth2: anonymous auth failed: ${response?.statusCode}\n${response?.body}");
    }
    return false;
  }

  // OIDC Authentication

  Future<Auth2OidcAuthenticateResult?> authenticateWithOidc({bool? link}) async {
    if (Config().authBaseUrl != null) {

      if (_oidcAuthenticationCompleters == null) {
        _oidcAuthenticationCompleters = <Completer<Auth2OidcAuthenticateResult?>>[];
        NotificationService().notify(notifyLoginStarted, oidcLoginType);

        _OidcLogin? oidcLogin = await getOidcData();
        if (oidcLogin?.loginUrl != null) {
          _oidcLogin = oidcLogin;
          _oidcLink = link;
          await _launchUrl(_oidcLogin?.loginUrl);
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
    
    RokwirePlugin.dismissSafariVC();
    
    cancelOidcAuthenticationTimer();

    _processingOidcAuthentication = true;
    Auth2OidcAuthenticateResult result;
    if (_oidcLink == true) {
      Auth2LinkResult linkResult = await linkAccountAuthType(oidcLoginType, uri.toString(), _oidcLogin?.params);
      result = auth2OidcAuthenticateResultFromAuth2LinkResult(linkResult);
    } else {
      bool processResult = await processOidcAuthentication(uri);
      result = processResult ? Auth2OidcAuthenticateResult.succeeded : Auth2OidcAuthenticateResult.failed;
    }
    _processingOidcAuthentication = false;

    completeOidcAuthentication(result);
    return result;
  }

  @protected
  Future<bool> processOidcAuthentication(Uri? uri) async {
    if (Config().authBaseUrl != null) {
      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(oidcLoginType),
        'creds': uri?.toString(),
        'params': _oidcLogin?.params,
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return false;
      }
      _oidcLogin = null;

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      Log.d("Login: ${response?.statusCode}, ${response?.body}", lineLength: 512);
      Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
      bool result = await processLoginResponse(responseJson);
      _log(result ? "Auth2: login succeeded: ${response?.statusCode}\n${response?.body}" : "Auth2: login failed: ${response?.statusCode}\n${response?.body}");
      return result;
    }
    return false;
  }

  @protected
  Future<bool> processLoginResponse(Map<String, dynamic>? responseJson) async {
    if (responseJson != null) {
      Auth2Token? token = Auth2Token.fromJson(JsonUtils.mapValue(responseJson['token']));
      Auth2Account? account = Auth2Account.fromJson(JsonUtils.mapValue(responseJson['account']),
        prefs: _anonymousPrefs ?? Auth2UserPrefs.empty(),
        profile: _anonymousProfile ?? Auth2UserProfile.empty());

      if ((token != null) && token.isValid && (account != null) && account.isValid) {
        await applyLogin(account, token, params: JsonUtils.mapValue(responseJson['params']));
        return true;
      }
    }
    return false;
  }

  @protected
  Future<void> applyLogin(Auth2Account account, Auth2Token token, { Map<String, dynamic>? params }) async {

    _refreshTokenFailCounts.remove(_token?.refreshToken);

    bool? prefsUpdated = account.prefs?.apply(_anonymousPrefs);
    bool? profileUpdated = account.profile?.apply(_anonymousProfile);
    _token = token;
    _account = account;
    await Storage().setAuth2AnonymousPrefs(_anonymousPrefs = null);
    await Storage().setAuth2AnonymousProfile(_anonymousProfile = null);
    if (!kIsWeb) {
      await Storage().setAuth2Token(_token = token);
      await Storage().setAuth2Account(_account = account);
    }

    if (prefsUpdated == true) {
      _saveAccountUserPrefs();
    }

    if (profileUpdated == true) {
      _saveAccountUserProfile();
    }

    NotificationService().notify(notifyProfileChanged);
    NotificationService().notify(notifyPrefsChanged);
    NotificationService().notify(notifyLoginChanged);
  }

  @protected
  Future<_OidcLogin?> getOidcData() async {
    if (Config().authBaseUrl != null) {

      String url = "${Config().authBaseUrl}/auth/login-url";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(oidcLoginType),
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
        postData['redirect_uri'] = oidcRedirectUrl;
      } else {
        return null;
      }
      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
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
    if ((Config().authBaseUrl != null) && (phoneNumber != null)) {
      NotificationService().notify(notifyLoginStarted, phoneLoginType);

      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(phoneLoginType),
        'creds': {
          "phone": phoneNumber,
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2PhoneRequestCodeResult.failed;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData));
      if (response?.statusCode == 200) {
        return Auth2PhoneRequestCodeResult.succeeded;
      }
      else if (Auth2Error.fromJson(JsonUtils.decodeMap(response?.body))?.status == 'already-exists') {
        return Auth2PhoneRequestCodeResult.failedAccountExist;
      }
    }
    return Auth2PhoneRequestCodeResult.failed;
  }

  Future<Auth2PhoneSendCodeResult> handlePhoneAuthentication(String? phoneNumber, String? code) async {
    if ((Config().authBaseUrl != null) && (phoneNumber != null) && (code != null)) {
      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(phoneLoginType),
        'creds': {
          "phone": phoneNumber,
          "code": code,
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2PhoneSendCodeResult.failed;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData));
      if (response?.statusCode == 200) {
        bool result = await processLoginResponse(JsonUtils.decodeMap(response?.body));
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

  Future<Auth2EmailSignInResult> authenticateWithEmail(String? email, String? password) async {
    if ((Config().authBaseUrl != null) && (email != null) && (password != null)) {
      
      NotificationService().notify(notifyLoginStarted, emailLoginType);

      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(emailLoginType),
        'creds': {
          "email": email,
          "password": password
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2EmailSignInResult.failed;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData));
      if (response?.statusCode == 200) {
        bool result = await processLoginResponse(JsonUtils.decodeMap(response?.body));
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
    if ((Config().authBaseUrl != null) && (email != null) && (password != null)) {
      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(emailLoginType),
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
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2EmailSignUpResult.failed;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData));
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
    if ((Config().authBaseUrl != null) && (email != null)) {
      String url = "${Config().authBaseUrl}/auth/account/exists";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(emailLoginType),
        'user_identifier': email,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return null;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData));
      if (response?.statusCode == 200) {
        //TBD: handle Auth2EmailAccountState.unverified
        return JsonUtils.boolValue(JsonUtils.decode(response?.body))! ? Auth2EmailAccountState.verified : Auth2EmailAccountState.nonExistent;
      }
    }
    return null;
  }

  Future<Auth2EmailForgotPasswordResult> resetEmailPassword(String? email) async {
    if ((Config().authBaseUrl != null) && (email != null)) {
      String url = "${Config().authBaseUrl}/auth/credential/forgot/initiate";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(emailLoginType),
        'user_identifier': email,
        'identifier': email,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2EmailForgotPasswordResult.failed;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData));
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
    if ((Config().authBaseUrl != null) && (email != null)) {
      String url = "${Config().authBaseUrl}/auth/credential/send-verify";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(emailLoginType),
        'user_identifier': email,
        'identifier': email,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return false;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData));
      return (response?.statusCode == 200);
    }
    return false;
  }

  // Username Authentication

  Future<Auth2UsernameSignInResult> authenticateWithUsername(String? username, String? password) async {
    if ((Config().authBaseUrl != null) && (username != null) && (password != null)) {

      NotificationService().notify(notifyLoginStarted, usernameLoginType);

      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(usernameLoginType),
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
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2UsernameSignInResult.failed;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData));
      if (response?.statusCode == 200) {
        bool result = await processLoginResponse(JsonUtils.decodeMap(response?.body));
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

  Future<Auth2UsernameSignUpResult> signUpWithUsername(String? username, String? password) async {
    if ((Config().authBaseUrl != null) && (username != null) && (password != null)) {
      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(usernameLoginType),
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
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2UsernameSignUpResult.failed;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData));
      if (response?.statusCode == 200) {
        bool result = await processLoginResponse(JsonUtils.decodeMap(response?.body));
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
    if ((Config().authBaseUrl != null) && (username != null)) {
      String url = "${Config().authBaseUrl}/auth/account/exists";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(usernameLoginType),
        'user_identifier': username,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return null;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData));
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
    if ((Config().authBaseUrl != null) && (identifier != null)) {
      String url = "${Config().authBaseUrl}/auth/account/can-sign-in";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(loginType),
        'user_identifier': identifier,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return null;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData));
      if (response?.statusCode == 200) {
        return JsonUtils.boolValue(JsonUtils.decode(response?.body))!;
      }
    }
    return null;
  }

  Future<bool?> canLink(String? identifier, Auth2LoginType loginType) async {
    if ((Config().authBaseUrl != null) && (identifier != null)) {
      String url = "${Config().authBaseUrl}/auth/account/can-link";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': auth2LoginTypeToString(loginType),
        'user_identifier': identifier,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return null;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData));
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
          await Storage().setAuth2Account(_account = Auth2Account.fromOther(_account, authTypes: authTypes));
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
        await Storage().setAuth2Account(_account = Auth2Account.fromOther(_account, authTypes: authTypes));
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
      'type': kIsWeb ? 'web' : 'mobile',
      'device_id': kIsWeb ? 'web' : _deviceId,
      'os': kIsWeb ? 'web' : Config().operatingSystem,
    };
  }

  // Logout

  Future<void> logout({ Auth2UserPrefs? prefs }) async {
    _log("Auth2: logout");
    _refreshTokenFailCounts.remove(_token?.refreshToken);

    await Storage().setAuth2AnonymousPrefs(_anonymousPrefs = prefs ?? _account?.prefs ?? Auth2UserPrefs.empty());
    await Storage().setAuth2AnonymousProfile(_anonymousProfile = Auth2UserProfile.empty());
    await Storage().setAuth2Token(_token = null);
    await Storage().setAuth2Account(_account = null);

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
    NotificationService().notify(notifyLoginChanged);
    NotificationService().notify(notifyLogout);
  }

  // Delete

  Future<bool> deleteUser() async {
    NotificationService().notify(notifyPrepareUserDelete);
    if (await _deleteUserAccount()) {
      logout(prefs: Auth2UserPrefs.empty());
      NotificationService().notify(notifyUserDeleted);
      return true;
    }
    return false;
  }

  Future<bool> _deleteUserAccount() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/account";
      Response? response = await Network().delete(url, auth: Auth2());
      return response?.statusCode == 200;
    }
    return false;
  }

  // Refresh

  Future<Auth2Token?> refreshToken({Auth2Token? token}) async {
    if (Config().authBaseUrl != null) {
      try {
        Future<Response?>? refreshTokenFuture = token?.refreshToken != null ? _refreshTokenFutures[token!.refreshToken] : null;

        if (refreshTokenFuture != null) {
          _log("Auth2: will await refresh token:\nSource Token: ${token?.refreshToken}");
          Response? response = await refreshTokenFuture;
          Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
          Auth2Token? responseToken = (responseJson != null) ? Auth2Token.fromJson(JsonUtils.mapValue(responseJson['token'])) : null;
          _log("Auth2: did await refresh token: ${responseToken?.isValid}\nSource Token: ${token?.refreshToken}");
          return ((responseToken != null) && responseToken.isValid) ? responseToken : null;
        }
        else {
          _log("Auth2: will refresh token:\nSource Token: ${token?.refreshToken}");

          refreshTokenFuture = _refreshToken(token?.refreshToken);
          if (token?.refreshToken != null) {
            _refreshTokenFutures[token!.refreshToken!];
          }
          Response? response = await refreshTokenFuture;
          _refreshTokenFutures.remove(token?.refreshToken);

          Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
          if (responseJson != null) {
            Auth2Token? responseToken = Auth2Token.fromJson(JsonUtils.mapValue(responseJson['token']));
            if ((responseToken != null) && responseToken.isValid) {
              _log("Auth2: did refresh token:\nResponse Token: ${responseToken.refreshToken}\nSource Token: ${token?.refreshToken}");
              _refreshTokenFailCounts.remove(token?.refreshToken);

              if (token == _token) {
                applyToken(responseToken, params: JsonUtils.mapValue(responseJson['params']));
                return responseToken;
              }
              else if (token == _anonymousToken) {
                await Storage().setAuth2AnonymousToken(_anonymousToken = responseToken);
                return responseToken;
              }
            }
          }

          _log("Auth2: failed to refresh token: ${response?.statusCode}\n${response?.body}\nSource Token: ${token?.refreshToken}");
          int refreshTokenFailCount = 1;
          if (token?.refreshToken != null) {
            refreshTokenFailCount += _refreshTokenFailCounts[token!.refreshToken!] ?? 0;
          }
          if (((response?.statusCode == 400) || (response?.statusCode == 401)) || (Config().refreshTokenRetriesCount <= refreshTokenFailCount)) {
            if (token == _token) {
              logout();
            }
            else if (token == _anonymousToken) {
              await authenticateAnonymously();
            }
          }
          else if (token?.refreshToken != null) {
            _refreshTokenFailCounts[token!.refreshToken!] = refreshTokenFailCount;
          }
        }
      }
      catch(e) {
        debugPrint(e.toString());
        _refreshTokenFutures.remove(token?.refreshToken); // make sure to clear this in case something went wrong.
      }
    }
    return null;
  }

  @protected
  Future<void> applyToken(Auth2Token token, { Map<String, dynamic>? params }) async {
    _token = token;
    if (!kIsWeb) {
      await Storage().setAuth2Token(token);
    }
  }

  static Future<Response?> _refreshToken(String? refreshToken) async {
    if (Config().authBaseUrl != null) {
      String url = "${Config().authBaseUrl}/auth/refresh";
      
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post;
      if (!kIsWeb) {
        if (refreshToken == null) {
          return null;
        }
        post = JsonUtils.encode({
          'api_key': Config().rokwireApiKey,
          'refresh_token': refreshToken
        });
      }

      return Network().post(url, headers: headers, body: post, auth: Auth2Csrf());
    }
    return null;
  }

  // User Prefs

  @protected
  Future<void> onUserPrefsChanged(Auth2UserPrefs? prefs) async {
    if (identical(prefs, _anonymousPrefs)) {
      await Storage().setAuth2AnonymousPrefs(_anonymousPrefs);
      NotificationService().notify(notifyPrefsChanged);
    }
    else if (identical(prefs, _account?.prefs)) {
      await Storage().setAuth2Account(_account);
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
  Future<void> onUserProfileChanged(Auth2UserProfile? profile) async {
    if (identical(profile, _anonymousProfile)) {
      await Storage().setAuth2AnonymousProfile(_anonymousProfile);
      NotificationService().notify(notifyProfileChanged);
    }
    else if (identical(profile, _account?.profile)) {
      await Storage().setAuth2Account(_account);
      NotificationService().notify(notifyProfileChanged);
      _saveAccountUserProfile();
    }
  }

  Future<Auth2UserProfile?> loadUserProfile() async {
    return await _loadAccountUserProfile();
  }

  Future<bool> saveAccountUserProfile(Auth2UserProfile? profile) async {
    if (await _saveExternalAccountUserProfile(profile)) {
      if (_account?.profile?.apply(profile) ?? false) {
        await Storage().setAuth2Account(_account);
        NotificationService().notify(notifyProfileChanged);
      }
      return true;
    }
    return false;
  }

  Future<Auth2UserProfile?> _loadAccountUserProfile() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/account/profile";
      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? Auth2UserProfile.fromJson(JsonUtils.decodeMap(response?.body)) : null;
    }
    return null;
  }

  Future<void> _saveAccountUserProfile() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null) && (_account?.profile != null)) {
      String url = "${Config().coreUrl}/services/account/profile";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode(profile!.toJson());

      Client client = Client();
      _updateUserProfileClient?.close();
      _updateUserProfileClient = client;

      Response? response = await Network().put(url, auth: Auth2(), headers: headers, body: post);

      if (identical(client, _updateUserProfileClient)) {
        if (response?.statusCode == 200) {
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

  Future<bool> _saveExternalAccountUserProfile(Auth2UserProfile? profile) async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/account/profile";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode(profile!.toJson());
      Response? response = await Network().put(url, auth: Auth2(), headers: headers, body: post);
      return (response?.statusCode == 200);
    }
    return false;
  }

  /*Future<void> _refreshAccountUserProfile() async {
    Auth2UserProfile? profile = await _loadAccountUserProfile();
    if ((profile != null) && (profile != _account?.profile)) {
      if (_account?.profile?.apply(profile) ?? false) {
        Storage().auth2Account = _account;
        NotificationService().notify(notifyProfileChanged);
      }
    }
  }*/

  // Account

  Future<Auth2Account?> _loadAccount() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/account";
      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? Auth2Account.fromJson(JsonUtils.decodeMap(response?.body)) : null;
    }
    return null;
  }

  Future<void> _refreshAccount() async {
    Auth2Account? account = await _loadAccount();
    if ((account != null) && (account != _account)) {
      
      bool profileUpdated = (account.profile != _account?.profile);
      bool prefsUpdated = (account.prefs != _account?.prefs);

      await Storage().setAuth2Account(_account = account);
      NotificationService().notify(notifyAccountChanged);

      if (profileUpdated) {
        NotificationService().notify(notifyProfileChanged);
      }
      if (prefsUpdated) {
        NotificationService().notify(notifyPrefsChanged);
      }
    }
  }

  // Helpers

  Future<void> _launchUrl(String? urlStr) async {
    try {
      if ((urlStr != null)) {
        if (kIsWeb) {
          FlutterWebAuth2.authenticate(url: urlStr, callbackUrlScheme: Uri.tryParse(urlStr)?.host ?? '').then((String url) {
            onDeepLinkUri(Uri.tryParse(url));
          });
        } else if (await canLaunchUrlString(urlStr)) {
          await launchUrlString(urlStr, mode: Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault);
        }
      }
    }
    catch(e) {
      debugPrint(e.toString());
    }
  }

  static void _log(String message) {
    Log.d(message, lineLength: 512); // max line length of VS Code Debug Console
  }

  Map<String, dynamic>? _getConfigParams(Map<String, dynamic> params) {
    if (!Config().isReleaseWeb) {
      if (Config().appPlatformId == null || Config().coreOrgId == null || Config().rokwireApiKey == null) {
        return null;
      }
      params['app_type_identifier'] = Config().appPlatformId;
      params['api_key'] = Config().rokwireApiKey;
      params['org_id'] = Config().coreOrgId;
    }
    return params;
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

class Auth2Csrf with NetworkAuthProvider {
  static const String _csrfTokenName = 'rokwire-csrf-token';

  @override
  Map<String, String>? get networkAuthHeaders {
    if (kIsWeb) {
      String cookieName = _csrfTokenName;
      if (Config().authBaseUrl?.contains("localhost") == false) {
        cookieName = '__Host-' + cookieName;
      }
      return {_csrfTokenName: WebUtils.getCookie(cookieName)};
    }

    return null;
  }

  @override
  dynamic get networkAuthToken => null;
  
  @override
  Future<bool> refreshNetworkAuthTokenIfNeeded(BaseResponse? response, dynamic token) async {
    if ((response?.statusCode == 401) && (token is Auth2Token) && (Auth2().token == token)) {
      return (await Auth2().refreshToken(token: token) != null);
    }
    return false;
  }
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