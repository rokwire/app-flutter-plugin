import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  static const String notifyLoginStarted         = "edu.illinois.rokwire.auth2.login.started";
  static const String notifyLoginSucceeded       = "edu.illinois.rokwire.auth2.login.succeeded";
  static const String notifyLoginFailed          = "edu.illinois.rokwire.auth2.login.failed";
  static const String notifyLoginChanged         = "edu.illinois.rokwire.auth2.login.changed";
  static const String notifyLoginFinished        = "edu.illinois.rokwire.auth2.login.finished";
  static const String notifyLogoutStarted        = "edu.illinois.rokwire.auth2.logout.started";
  static const String notifyLogout               = "edu.illinois.rokwire.auth2.logout";
  static const String notifyLinkChanged          = "edu.illinois.rokwire.auth2.link.changed";
  static const String notifyAccountChanged       = "edu.illinois.rokwire.auth2.account.changed";
  static const String notifyProfileChanged       = "edu.illinois.rokwire.auth2.profile.changed";
  static const String notifyPrefsChanged         = "edu.illinois.rokwire.auth2.prefs.changed";
  static const String notifySecretsChanged       = "edu.illinois.rokwire.auth2.secrets.changed";
  static const String notifyUserDeleted          = "edu.illinois.rokwire.auth2.user.deleted";
  static const String notifyPrepareUserDelete    = "edu.illinois.rokwire.auth2.user.prepare.delete";

  //TODO: Remove if not needed
  static const String notifyGetPasskeySuccess    = "edu.illinois.rokwire.auth2.passkey.get.succeeded";
  static const String notifyGetPasskeyFailed     = "edu.illinois.rokwire.auth2.passkey.get.failed";
  static const String notifyCreatePasskeySuccess = "edu.illinois.rokwire.auth2.passkey.create.succeeded";
  static const String notifyCreatePasskeyFailed  = "edu.illinois.rokwire.auth2.passkey.create.failed";
  //

  static const String _deviceIdIdentifier     = 'edu.illinois.rokwire.device_id';


  _OidcLogin? _oidcLogin;
  Auth2AccountScope? _oidcScope;
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

  Client? _updateUserSecretsClient;
  Timer? _updateUserSecretsTimer;

  Auth2Token? _token;
  Auth2Account? _account;

  Auth2Token? _oidcToken;

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
      Auth2Account.notifySecretsChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    await _initServiceOffline();

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

    if (kIsWeb && _token == null) {
      refreshToken(ignoreUnauthorized: true).then((token) {
        if (token != null) {
          _refreshAccount();
          NotificationService().notify(Auth2.notifyLoginSucceeded, null);
        }
      });
    } else {
      _refreshAccount();
    }

    await super.initService();
  }

  @override
  Future<void> initServiceFallback() async {
    await _initServiceOffline();
  }

  Future<void> _initServiceOffline() async {
    _token = await Storage().getAuth2Token();
    _account = await Storage().getAuth2Account();
    _oidcToken = await Storage().getAuth2OidcToken();

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
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Storage(), Config() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    //TODO: try to do this without explicit web check
    if (name == DeepLink.notifyUri && !kIsWeb) {
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
    else if (name == Auth2Account.notifySecretsChanged) {
      onAccountSecretsChanged(param);
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
    if ((response?.statusCode == 401) && (token is Auth2Token) && (this.token == token) &&
      (!(Config().coreUrl?.contains('http://') ?? true) || (response?.request?.url.origin.contains('http://') ?? false))) {
      return (await refreshToken(token: token) != null);
    }
    return false;
  }

  @override
  Future<bool> refreshNetworkAuthTokenIfExpired(dynamic token) async {
    if (token is Auth2Token && token.accessIsExpired == true) {
      return (await Auth2().refreshToken(token: token) != null);
    }
    return false;
  }

  // Getters
  Auth2Token? get token => _token ?? _anonymousToken;
  Auth2Token? get userToken => _token;
  Auth2Token? get anonymousToken => _anonymousToken;
  Auth2Account? get account => _account;
  String? get deviceId => _deviceId;

  Auth2Token? get oidcToken => _oidcToken;

  bool get associateAnonymousIds => false;
  String? get accountId => _account?.id ?? _anonymousId;
  Auth2UserPrefs? get prefs => _account?.prefs ?? _anonymousPrefs;
  Auth2UserProfile? get profile => _account?.profile ?? _anonymousProfile;
  String? get loginType => _account?.authType?.code;

  bool get isLoggedIn => (_account?.id != null);
  bool get isOidcLoggedIn => (_account?.authType?.code == oidcAuthType || _account?.authType?.code == Auth2Type.typeOidc);
  bool get isCodeLoggedIn => (_account?.authType?.code == Auth2Type.typeCode);
  bool get isPasswordLoggedIn => (_account?.authType?.code == Auth2Type.typePassword);
  bool get isPasskeyLoggedIn => (_account?.authType?.code == Auth2Type.typePasskey);

  bool get isEmailLinked => _account?.isIdentifierLinked(Auth2Identifier.typeEmail) ?? false;
  bool get isPhoneLinked => _account?.isIdentifierLinked(Auth2Identifier.typePhone) ?? false;
  bool get isUsernameLinked => _account?.isIdentifierLinked(Auth2Identifier.typeUsername) ?? false;

  bool get isOidcLinked => _account?.isAuthTypeLinked(oidcAuthType) ?? false;
  bool get isCodeLinked => _account?.isAuthTypeLinked(Auth2Type.typeCode) ?? false;
  bool get isPasswordLinked => _account?.isAuthTypeLinked(Auth2Type.typePassword) ?? false;
  bool get isPasskeyLinked => _account?.isAuthTypeLinked(Auth2Type.typePasskey) ?? false;

  List<Auth2Identifier> get linkedEmail => _account?.getLinkedForIdentifierType(Auth2Identifier.typeEmail) ?? [];
  List<Auth2Identifier> get linkedPhone => _account?.getLinkedForIdentifierType(Auth2Identifier.typePhone) ?? [];
  List<Auth2Identifier> get linkedUsername => _account?.getLinkedForIdentifierType(Auth2Identifier.typeUsername) ?? [];
  List<Auth2Identifier> get linkedOidcIdentifiers {
    List<Auth2Identifier> identifiers = [];
    for (Auth2Type oidcType in linkedOidc) {
      if (oidcType.id != null) {
        identifiers.addAll(_account?.getLinkedForAuthTypeId(oidcType.id!) ?? []);
      }
    }
    return identifiers;
  }

  List<Auth2Type> get linkedOidc => _account?.getLinkedForAuthType(oidcAuthType) ?? [];
  List<Auth2Type> get linkedCode => _account?.getLinkedForAuthType(Auth2Type.typeCode) ?? [];
  List<Auth2Type> get linkedPassword => _account?.getLinkedForAuthType(Auth2Type.typePassword) ?? [];
  List<Auth2Type> get linkedPasskey => _account?.getLinkedForAuthType(Auth2Type.typePasskey) ?? [];

  bool get hasUin => (0 < (uin?.length ?? 0));
  String? get uin => _account?.authType?.uiucUser?.uin;
  String? get netId => _account?.authType?.uiucUser?.netId;

  String? get fullName => StringUtils.ensureNotEmpty(profile?.fullName, defaultValue: _account?.authType?.uiucUser?.fullName ?? '');
  String? get firstName => StringUtils.ensureNotEmpty(profile?.firstName, defaultValue: _account?.authType?.uiucUser?.firstName ?? '');
  String? get username => _account?.username;

  List<String> get emails {
    List<String> emailStrings = [];
    for (Auth2Identifier emailIdentifier in linkedEmail) {
      if (emailIdentifier.identifier != null) {
        emailStrings.add(emailIdentifier.identifier!);
      }
    }
    return emailStrings;
  }
  
  List<String> get phones {
    List<String> phoneStrings = [];
    for (Auth2Identifier phoneIdentifier in linkedPhone) {
      if (phoneIdentifier.identifier != null) {
        phoneStrings.add(phoneIdentifier.identifier!);
      }
    }
    return phoneStrings;
  }

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
  String get oidcAuthType => Auth2Type.typeOidcIllinois;

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
        'auth_type': Auth2Type.typeAnonymous,
        'device': deviceInfo,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return false;
      }
      
      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
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

  // Passkey authentication

  Future<Auth2PasskeySignInResult> authenticateWithPasskey({String? identifier, String identifierType = Auth2Identifier.typeUsername, String? identifierId}) async {
    String? errorMessage;
    if (Config().authBaseUrl != null) {
      if (!await RokwirePlugin.arePasskeysSupported()) {
        return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.failedNotSupported);
      }

      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> creds = {};
      if (StringUtils.isNotEmpty(identifier)) {
        creds[identifierType] = identifier;
      }
      Map<String, dynamic> postData = {
        'auth_type': Auth2Type.typePasskey,
        'creds': creds,
        'params': {
          'sign_up': false,
        },
        'username': identifierType == Auth2Identifier.typeUsername ? identifier : null,
        'profile': profile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
        'account_identifier_id': identifierId,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.failed);
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      if (response  != null && response.statusCode == 200) {
        // Obtain creationOptions from the server
        String? responseBody = response.body;
        Auth2Message? message = Auth2Message.fromJson(JsonUtils.decode(responseBody));
        try {
          String? responseData = await RokwirePlugin.getPasskey(message?.message);
          debugPrint(responseData);
          return _completeSignInWithPasskey(responseData, identifier: identifier, identifierType: identifierType, identifierId: identifierId);
        } catch(error) {
          if (error is PlatformException) {
            switch (error.code) {
              // no credentials found
              case "NoCredentialException": return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.failedNoCredentials);
              // user cancelled on device auth
              case "GetPublicKeyCredentialDomException": return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.failedCancelled);
              // user cancelled on select passkey
              case "GetCredentialCancellationException": return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.failedCancelled);
            }
          }
          errorMessage = error.toString();
          debugPrint(errorMessage);
          Log.e(errorMessage);
        }
      } else {
        Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response?.body));
        if (error?.status == 'unverified') {
          return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.failedNotActivated);
        }
        else if (error?.status == 'not-found') {
          return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.failedNotFound);
        }
        else if (error?.status == 'verification-expired') {
          return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.failedActivationExpired);
        }
      }
    }
    return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.failed, error: errorMessage);
  }

  Future<Auth2PasskeySignInResult> _completeSignInWithPasskey(String? responseData, {String? identifier, String identifierType = Auth2Identifier.typeUsername, String? identifierId}) async {
    if ((Config().authBaseUrl != null) && (responseData != null)) {
      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, dynamic>? requestJson = JsonUtils.decode(responseData);
      // TODO: remove if statement once plugin is fixed
      if (Config().operatingSystem == 'ios') {
        String? userHandle = requestJson?['response']['userHandle'];
        requestJson?['response']['userHandle'] = StringUtils.base64UrlDecode(userHandle ?? '');
      }
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> creds = {
        "response": JsonUtils.encode(requestJson),
      };
      if (StringUtils.isNotEmpty(identifier)) {
        creds[identifierType] = identifier;
      }
      Map<String, dynamic> postData = {
        'auth_type': Auth2Type.typePasskey,
        'creds': creds,
        'username': identifierType == Auth2Identifier.typeUsername ? identifier : null,
        'device': deviceInfo,
        'account_identifier_id': identifierId,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.failed);
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      if (response != null && response.statusCode == 200) {
        Map<String, dynamic>? responseJson = JsonUtils.decode(response.body);
        bool success = await processLoginResponse(responseJson);
        if (success) {
          return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.succeeded);
        }
      } else {
        Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response?.body));
        if (error?.status == 'unverified') {
          return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.failedNotActivated);
        }
        else if (error?.status == 'not-found') {
          return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.failedNotFound);
        }
        else if (error?.status == 'verification-expired') {
          return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.failedActivationExpired);
        }
      }
    }
    return Auth2PasskeySignInResult(Auth2PasskeySignInResultStatus.failed);
  }

  Future<Auth2PasskeySignUpResult> signUpWithPasskey(String identifier, {String? displayName, String identifierType = Auth2Identifier.typeUsername, bool? public = false, bool verifyIdentifier = false}) async {
    String? errorMessage;
    if (Config().authBaseUrl != null) {
      if (!await RokwirePlugin.arePasskeysSupported()) {
        return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failedNotSupported);
      }

      Auth2UserProfile? profile = _anonymousProfile;
      List<String>? nameParts = displayName?.split(' ');
      if (nameParts != null && nameParts.length >= 2) {
        Auth2UserProfile nameData = Auth2UserProfile(firstName: nameParts[0], lastName: nameParts.skip(1).join(' '));
        if (profile != null) {
          profile.apply(nameData);
        } else {
          profile = nameData;
        }
      }

      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': Auth2Type.typePasskey,
        'creds': {
          identifierType: identifier,
        },
        'params': {
          "display_name": displayName,
        },
        'privacy': {
          'public': public,
        },
        'username': identifierType == Auth2Identifier.typeUsername ? identifier : null,
        'profile': profile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failed);
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      if (response != null && response.statusCode == 200) {
        // Obtain creationOptions from the server
        Auth2Message? message = Auth2Message.fromJson(JsonUtils.decode(response.body));
        if (message != null) {
          if (verifyIdentifier) {
            return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.succeeded, creationOptions: message.message);
          }
          try {
            String? responseData = await RokwirePlugin.createPasskey(message.message);
            return completeSignUpWithPasskey(identifier, responseData, identifierType: identifierType);
          } catch(error) {
            try {
              String? responseData = await RokwirePlugin.getPasskey(message.message);
              Auth2PasskeySignInResult result = await _completeSignInWithPasskey(responseData, identifier: identifier, identifierType: identifierType);
              if (result.status == Auth2PasskeySignInResultStatus.succeeded) {
                return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.succeeded);
              }
            } catch(error) {
              if (error is PlatformException && error.code == "NoCredentialException") {
                return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failedNoCredentials);
              }

              debugPrint(error.toString());
            }

            if (error is PlatformException) {
              switch (error.code) {
                // user cancelled on device auth
                case "GetPublicKeyCredentialDomException": return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failedCancelled);
                // user cancelled on select passkey
                case "GetCredentialCancellationException": return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failedCancelled);
              }
            }
            
            debugPrint(error.toString());
          }
        } else {
          Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response.body));
          if (error?.status == 'unverified') {
            return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failedNotActivated);
          }
          else if (error?.status == 'verification-expired') {
            return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failedActivationExpired);
          }
          else if (error?.status == 'already-exists') {
            return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failedAccountExist);
          }
        }
      }
      // else if (Auth2Error.fromJson(JsonUtils.decodeMap(response?.body))?.status == 'already-exists') {
      //   return Auth2PasskeySignUpResult.failedAccountExist;
      // }
    }
    return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failed, error: errorMessage);
  }

  Future<Auth2PasskeySignUpResult> completeSignUpWithPasskey(String identifier, String? responseData, {String identifierType = Auth2Identifier.typeUsername}) async {
    if ((Config().authBaseUrl != null) && (responseData != null)) {
      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': Auth2Type.typePasskey,
        'creds': {
          identifierType: identifier,
          "response": responseData,
        },
        'username': identifierType == Auth2Identifier.typeUsername ? identifier : null,
        'device': deviceInfo,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failed);
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      if (response != null && response.statusCode == 200) {
        Map<String, dynamic>? responseJson = JsonUtils.decode(response.body);
        bool success = await processLoginResponse(responseJson);
        if (success) {
          return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.succeeded);
        }
      } else {
        Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response?.body));
        if (error?.status == 'unverified') {
          return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failedNotActivated);
        }
        else if (error?.status == 'not-found') {
          return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failedNotFound);
        }
        else if (error?.status == 'verification-expired') {
          return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failedActivationExpired);
        }
      }
    }
    return Auth2PasskeySignUpResult(Auth2PasskeySignUpResultStatus.failed);
  }

  // OIDC Authentication

  Future<Auth2OidcAuthenticateResult?> authenticateWithOidc({Auth2AccountScope? scope, bool? link}) async {
    if (Config().authBaseUrl != null) {

      if (_oidcAuthenticationCompleters == null) {
        _oidcAuthenticationCompleters = <Completer<Auth2OidcAuthenticateResult?>>[];
        NotificationService().notify(notifyLoginStarted, oidcAuthType);

        _OidcLogin? oidcLogin = await getOidcData();
        if (oidcLogin?.loginUrl != null) {
          _oidcLogin = oidcLogin;
          _oidcScope = scope;
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
      Auth2LinkResult linkResult = await linkAccountAuthType(oidcAuthType, uri.toString(), _oidcLogin?.params);
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
    if (Config().authBaseUrl != null) {
      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': oidcAuthType,
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
    Auth2Token? oidcToken = (params != null) ? Auth2Token.fromJson(JsonUtils.mapValue(params['oidc_token'])) : null;

    _refreshTokenFailCounts.remove(_token?.refreshToken);

    if (associateAnonymousIds) {
      _anonymousPrefs?.addAnonymousId(_anonymousId);
    }
    bool? prefsUpdated = account.prefs?.apply(_anonymousPrefs, scope: scope?.prefs);
    bool? profileUpdated = account.profile?.apply(_anonymousProfile, scope: scope?.profile);
    _token = token;
    _oidcToken = oidcToken;
    _account = account;
    await Storage().setAuth2AnonymousPrefs(_anonymousPrefs = null);
    await Storage().setAuth2AnonymousProfile(_anonymousProfile = null);
    if (!kIsWeb) {
      await Storage().setAuth2Token(token);
      await Storage().setAuth2OidcToken(oidcToken);
      await Storage().setAuth2Account(account);
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
        'auth_type': oidcAuthType,
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
    
    _notifyLogin(oidcAuthType, result == Auth2OidcAuthenticateResult.succeeded);

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

  // Code Authentication

  Future<Auth2RequestCodeResult> authenticateWithCode(String? identifier, {String identifierType = Auth2Identifier.typePhone, bool? public = false, String? identifierId}) async {
    if ((Config().authBaseUrl != null) && (identifier != null || identifierId != null)) {
      NotificationService().notify(notifyLoginStarted, Auth2Type.typeCode);

      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> creds = {};
      if (StringUtils.isNotEmpty(identifier)) {
        creds[identifierType] = identifier;
      }
      Map<String, dynamic> postData = {
        'auth_type': Auth2Type.typeCode,
        'creds': creds,
        'privacy': {
          'public': public,
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
        'account_identifier_id': identifierId,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2RequestCodeResult.failed;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      if (response?.statusCode == 200) {
        return Auth2RequestCodeResult.succeeded;
      }
      else if (Auth2Error.fromJson(JsonUtils.decodeMap(response?.body))?.status == 'already-exists') {
        return Auth2RequestCodeResult.failedAccountExist;
      }
    }
    return Auth2RequestCodeResult.failed;
  }

  Future<Auth2SendCodeResult> handleCodeAuthentication(String? identifier, String? code, {String identifierType = Auth2Identifier.typePhone, String? identifierId, Auth2AccountScope? scope}) async {
    if ((Config().authBaseUrl != null) && (identifier != null || identifierId != null) && (code != null)) {
      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> creds = {
        "code": code,
      };
      if (StringUtils.isNotEmpty(identifier)) {
        creds[identifierType] = identifier;
      }
      Map<String, dynamic> postData = {
        'auth_type': Auth2Type.typeCode,
        'creds': creds,
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
        'account_identifier_id': identifierId,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2SendCodeResult.failed;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      if (response?.statusCode == 200) {
        bool result = await processLoginResponse(JsonUtils.decodeMap(response?.body), scope: scope);
        _notifyLogin(Auth2Type.typeCode, result);
        return result ? Auth2SendCodeResult.succeeded : Auth2SendCodeResult.failed;
      }
      else {
        _notifyLogin(Auth2Type.typeCode, false);
        Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response?.body));
        if (error?.status == 'invalid') {
          return Auth2SendCodeResult.failedInvalid;
        }
      }
    }
    return Auth2SendCodeResult.failed;
  }

  // Password Authentication

  Future<Auth2PasswordSignInResult> authenticateWithPassword(String? identifier, String? password, {String identifierType = Auth2Identifier.typeEmail, String? identifierId, Auth2AccountScope? scope}) async {
    if ((Config().authBaseUrl != null) && (identifier != null || identifierId != null) && (password != null)) {
      
      NotificationService().notify(notifyLoginStarted, Auth2Type.typePassword);

      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> creds = {
        "password": password,
      };
      if (StringUtils.isNotEmpty(identifier)) {
        creds[identifierType] = identifier;
      }
      Map<String, dynamic> postData = {
        'auth_type': Auth2Type.typePassword,
        'creds': creds,
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
        'account_identifier_id': identifierId,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2PasswordSignInResult.failed;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      if (response?.statusCode == 200) {
        bool result = await processLoginResponse(JsonUtils.decodeMap(response?.body), scope: scope);
        _notifyLogin(Auth2Type.typePassword, result);
        return result ? Auth2PasswordSignInResult.succeeded : Auth2PasswordSignInResult.failed;
      }
      else {
        _notifyLogin(Auth2Type.typePassword, false);
        Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response?.body));
        if (error?.status == 'unverified') {
          return Auth2PasswordSignInResult.failedNotActivated;
        }
        else if (error?.status == 'not-found') {
          return Auth2PasswordSignInResult.failedNotFound;
        }
        else if (error?.status == 'verification-expired') {
          return Auth2PasswordSignInResult.failedActivationExpired;
        }
        else if (error?.status == 'invalid') {
          return Auth2PasswordSignInResult.failedInvalid;
        }
      }
    }
    return Auth2PasswordSignInResult.failed;
  }

  Future<Auth2PasswordSignUpResult> signUpWithPassword(String? identifier, String? password, {String identifierType = Auth2Identifier.typeEmail, bool? public = false}) async {
    if ((Config().authBaseUrl != null) && (identifier != null) && (password != null)) {
      String url = "${Config().authBaseUrl}/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': Auth2Type.typePassword,
        'creds': {
          identifierType: identifier,
          "password": password
        },
        'params': {
          "sign_up": true,
          "confirm_password": password
        },
        'privacy': {
          'public': public,
        },
        'profile': _anonymousProfile?.toJson(),
        'preferences': _anonymousPrefs?.toJson(),
        'device': deviceInfo,
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2PasswordSignUpResult.failed;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      if (response?.statusCode == 200) {
        return Auth2PasswordSignUpResult.succeeded;
      }
      else if (Auth2Error.fromJson(JsonUtils.decodeMap(response?.body))?.status == 'already-exists') {
        return Auth2PasswordSignUpResult.failedAccountExist;
      }
    }
    return Auth2PasswordSignUpResult.failed;
  }

  Future<Auth2AccountState?> checkAccountState(String? identifier, {String identifierType = Auth2Identifier.typeEmail}) async {
    if ((Config().authBaseUrl != null) && (identifier != null)) {
      String url = "${Config().authBaseUrl}/auth/account/exists";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'identifier': {
          identifierType: identifier,
        }
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return null;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      if (response?.statusCode == 200) {
        //TBD: handle Auth2AccountState.unverified
        return JsonUtils.boolValue(JsonUtils.decode(response?.body))! ? Auth2AccountState.verified : Auth2AccountState.nonExistent;
      }
    }
    return null;
  }

  Future<Auth2ForgotPasswordResult> resetPassword(String? identifier, {String identifierType = Auth2Identifier.typeEmail}) async {
    if ((Config().authBaseUrl != null) && (identifier != null)) {
      String url = "${Config().authBaseUrl}/auth/credential/forgot/initiate";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'auth_type': Auth2Type.typePassword,
        'identifier': {
          identifierType: identifier,
        },
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return Auth2ForgotPasswordResult.failed;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      if (response?.statusCode == 200) {
        return Auth2ForgotPasswordResult.succeeded;
      }
      else {
        Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response?.body));
        if (error?.status == 'verification-expired') {
          return Auth2ForgotPasswordResult.failedActivationExpired;
        } 
        else if (error?.status == 'unverified') {
          return Auth2ForgotPasswordResult.failedNotActivated;
        }
      }
    }
    return Auth2ForgotPasswordResult.failed;
  }

  Future<bool> resendIdentifierVerification(String? identifier, {String identifierType = Auth2Identifier.typeEmail}) async {
    if ((Config().authBaseUrl != null) && (identifier != null)) {
      String url = "${Config().authBaseUrl}/auth/identifier/send-verify";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'identifier': {
          identifierType: identifier,
        },
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return false;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      return (response?.statusCode == 200);
    }
    return false;
  }

  // Notify Login

  void _notifyLogin(String loginType, bool? result) {
    if (result != null) {
      NotificationService().notify(result ? notifyLoginSucceeded : notifyLoginFailed, loginType);
      NotificationService().notify(notifyLoginFinished, loginType);
    }
  }

  // Account Checks

  Future<bool?> canSignIn(String? identifier, String identifierType) async {
    if ((Config().authBaseUrl != null) && (identifier != null)) {
      String url = "${Config().authBaseUrl}/auth/account/can-sign-in";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'identifier': {
          identifierType: identifier,
        },
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return null;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      if (response?.statusCode == 200) {
        return JsonUtils.boolValue(JsonUtils.decode(response?.body))!;
      }
    }
    return null;
  }

  Future<bool?> canLink(String? identifier, String identifierType) async {
    if ((Config().authBaseUrl != null) && (identifier != null)) {
      String url = "${Config().authBaseUrl}/auth/account/can-link";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'identifier': {
          identifierType: identifier,
        },
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return null;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      if (response?.statusCode == 200) {
        return JsonUtils.boolValue(JsonUtils.decode(response?.body))!;
      }
    }
    return null;
  }

  // Sign in options

  Future<Auth2SignInOptionsResult?> signInOptions(String? identifier, String identifierType) async {
    if ((Config().authBaseUrl != null) && (identifier != null)) {
      String url = "${Config().authBaseUrl}/auth/account/sign-in-options";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, dynamic> postData = {
        'identifier': {
          identifierType: identifier,
        },
      };
      Map<String, dynamic>? additionalParams = _getConfigParams(postData);
      if (additionalParams != null) {
        postData.addAll(additionalParams);
      } else {
        return null;
      }

      Response? response = await Network().post(url, headers: headers, body: JsonUtils.encode(postData), auth: Auth2Csrf());
      if (response?.statusCode == 200) {
        Map<String, dynamic>? responseJson = JsonUtils.decodeMap(response?.body);
        List<Auth2Identifier>? identifiers = (responseJson != null) ? Auth2Identifier.listFromJson(JsonUtils.listValue(responseJson['identifiers'])) : null;
        List<Auth2Type>? authTypes = (responseJson != null) ? Auth2Type.listFromJson(JsonUtils.listValue(responseJson['auth_types'])) : null;
        return Auth2SignInOptionsResult(identifierOptions: identifiers, authTypeOptions: authTypes);
      }
    }
    return null;
  }

  // Account Identifier Linking

  Future<Auth2LinkResult> linkAccountIdentifier(String? identifier, String identifierType) async {
    if ((Config().coreUrl != null) && (identifier != null)) {
      String url = "${Config().coreUrl}/services/auth/account/identifier/link";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'identifier': {
          identifierType: identifier,
        },
      });

      Response? response = await Network().post(url, headers: headers, body: post, auth: Auth2());
      if (response?.statusCode == 200) {
        Map<String, dynamic>? responseJson = JsonUtils.decodeMap(response?.body);
        List<Auth2Identifier>? identifiers = (responseJson != null) ? Auth2Identifier.listFromJson(JsonUtils.listValue(responseJson['identifiers'])) : null;
        String? message = (responseJson != null) ? JsonUtils.stringValue(responseJson['message']) : null;
        if (identifiers != null) {
          await Storage().setAuth2Account(_account = Auth2Account.fromOther(_account, identifiers: identifiers));
          NotificationService().notify(notifyLinkChanged);
          return Auth2LinkResult(Auth2LinkResultStatus.succeeded, message: message);
        }
      }
      else {
        Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response?.body));
        if (error?.status == 'verification-expired') {
          return Auth2LinkResult(Auth2LinkResultStatus.failedActivationExpired);
        }
        else if (error?.status == 'unverified') {
          return Auth2LinkResult(Auth2LinkResultStatus.failedNotActivated);
        }
        else if (error?.status == 'already-exists') {
          return Auth2LinkResult(Auth2LinkResultStatus.failedAccountExist);
        }
        else if (error?.status == 'invalid') {
          return Auth2LinkResult(Auth2LinkResultStatus.failedInvalid);
        }
      } 
    }
    return Auth2LinkResult(Auth2LinkResultStatus.failed);
  }

  Future<bool> unlinkAccountIdentifier(String? id) async {
    if ((Config().coreUrl != null) && (id != null)) {
      String url = "${Config().coreUrl}/services/auth/account/identifier/link";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? body = JsonUtils.encode({
        'id': id
      });

      Response? response = await Network().delete(url, headers: headers, body: body, auth: Auth2());
      Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
      List<Auth2Identifier>? identifiers = (responseJson != null) ? Auth2Identifier.listFromJson(JsonUtils.listValue(responseJson['identifiers'])) : null;
      if (identifiers != null) {
        await Storage().setAuth2Account(_account = Auth2Account.fromOther(_account, identifiers: identifiers));
        NotificationService().notify(notifyLinkChanged);
        return true;
      }
    }
    return false;
  }

  // Account Auth Type Linking

  Future<Auth2LinkResult> linkAccountAuthType(String? loginType, dynamic creds, Map<String, dynamic>? params) async {
    if ((Config().coreUrl != null) && (loginType != null)) {
      String url = "${Config().coreUrl}/services/auth/account/auth-type/link";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode({
        'auth_type': loginType,
        'app_type_identifier': Config().appPlatformId,
        'creds': creds,
        'params': params,
      });
      _oidcLink = null;

      Response? response = await Network().post(url, headers: headers, body: post, auth: Auth2());
      if (response?.statusCode == 200) {
        Map<String, dynamic>? responseJson = JsonUtils.decodeMap(response?.body);
        List<Auth2Identifier>? identifiers = (responseJson != null) ? Auth2Identifier.listFromJson(JsonUtils.listValue(responseJson['identifiers'])) : null;
        List<Auth2Type>? authTypes = (responseJson != null) ? Auth2Type.listFromJson(JsonUtils.listValue(responseJson['auth_types'])) : null;
        String? message = (responseJson != null) ? JsonUtils.stringValue(responseJson['message']) : null;
        // Map<String, dynamic>? requestJson = JsonUtils.decode(message ?? '');
        if (authTypes != null) {
          await Storage().setAuth2Account(_account = Auth2Account.fromOther(_account, identifiers: identifiers, authTypes: authTypes));
          NotificationService().notify(notifyLinkChanged);
          return Auth2LinkResult(Auth2LinkResultStatus.succeeded, message: message);
        }
      }
      else {
        Auth2Error? error = Auth2Error.fromJson(JsonUtils.decodeMap(response?.body));
        if (error?.status == 'verification-expired') {
          return Auth2LinkResult(Auth2LinkResultStatus.failedActivationExpired);
        }
        else if (error?.status == 'unverified') {
          return Auth2LinkResult(Auth2LinkResultStatus.failedNotActivated);
        }
        else if (error?.status == 'already-exists') {
          return Auth2LinkResult(Auth2LinkResultStatus.failedAccountExist);
        }
        else if (error?.status == 'invalid') {
          return Auth2LinkResult(Auth2LinkResultStatus.failedInvalid);
        }
      } 
    }
    return Auth2LinkResult(Auth2LinkResultStatus.failed);
  }

  Future<bool> unlinkAccountAuthType(String? id) async {
    if ((Config().coreUrl != null) && (id != null)) {
      String url = "${Config().coreUrl}/services/auth/account/auth-type/link";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? body = JsonUtils.encode({
        'id': id
      });

      Response? response = await Network().delete(url, headers: headers, body: body, auth: Auth2());
      Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
      List<Auth2Identifier>? identifiers = (responseJson != null) ? Auth2Identifier.listFromJson(JsonUtils.listValue(responseJson['identifiers'])) : null;
      List<Auth2Type>? authTypes = (responseJson != null) ? Auth2Type.listFromJson(JsonUtils.listValue(responseJson['auth_types'])) : null;
      if (authTypes != null) {
        await Storage().setAuth2Account(_account = Auth2Account.fromOther(_account, identifiers: identifiers, authTypes: authTypes));
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
      'os': Config().operatingSystem,
    };
  }

  // Logout

  Future<void> logout({ Auth2UserPrefs? prefs }) async {
    NotificationService().notify(notifyLogoutStarted);
    _log("Auth2: logout");
    _refreshTokenFailCounts.remove(_token?.refreshToken);

    if (Config().authBaseUrl != null) {
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? body = JsonUtils.encode({
        'all_sessions': false,
      });
      Network().post("${Config().authBaseUrl}/auth/logout", headers: headers, body: body, auth: Auth2Csrf(token: token));
    }

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

  Future<Auth2Token?> refreshToken({Auth2Token? token, bool ignoreUnauthorized = false}) async {
    //TODO: validate that using CSRF token as futures and fail counts key works on web
    String futureKey = token?.refreshToken ?? WebUtils.getCookie(Auth2Csrf.csrfTokenName);
    if (Config().authBaseUrl != null) {
      try {
        Future<Response?>? refreshTokenFuture = futureKey.isNotEmpty ? _refreshTokenFutures[futureKey] : null;

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
          if (futureKey.isNotEmpty) {
            _refreshTokenFutures[futureKey] = refreshTokenFuture;
          }
          Response? response = await refreshTokenFuture;
          _refreshTokenFutures.remove(futureKey);

          Map<String, dynamic>? responseJson = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body) : null;
          if (responseJson != null) {
            Auth2Token? responseToken = Auth2Token.fromJson(JsonUtils.mapValue(responseJson['token']));
            if ((responseToken != null) && responseToken.isValid) {
              _log("Auth2: did refresh token:\nResponse Token: ${responseToken.refreshToken}\nSource Token: ${token?.refreshToken}");
              _refreshTokenFailCounts.remove(futureKey);

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
          if (futureKey.isNotEmpty) {
            refreshTokenFailCount += _refreshTokenFailCounts[futureKey] ?? 0;
          }
          if (((response?.statusCode == 400) || (!ignoreUnauthorized && response?.statusCode == 401)) || (Config().refreshTokenRetriesCount <= refreshTokenFailCount)) {
            if (token == _token) {
              logout();
            }
            else if (token == _anonymousToken) {
              await authenticateAnonymously();
            }
          }
          else if (futureKey.isNotEmpty) {
            _refreshTokenFailCounts[futureKey] = refreshTokenFailCount;
          }
        }
      }
      catch(e) {
        debugPrint(e.toString());
        _refreshTokenFutures.remove(futureKey); // make sure to clear this in case something went wrong.
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
      if (!Config().isReleaseWeb) {
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

  // Account Secrets

  @protected
  Future<void> onAccountSecretsChanged(Map<String, dynamic>? secrets) async {
    if (identical(secrets, _account?.secrets)) {
      await Storage().setAuth2Account(_account);
      NotificationService().notify(notifySecretsChanged);
      return _saveAccountSecrets();
    }
    return;
  }

  Future<void> _saveAccountSecrets() async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null) && (_account?.secrets != null)) {
      String url = "${Config().coreUrl}/services/account/secrets";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String? post = JsonUtils.encode(_account!.secrets);

      Client client = Client();
      _updateUserSecretsClient?.close();
      _updateUserSecretsClient = client;

      Response? response = await Network().put(url, auth: Auth2(), headers: headers, body: post, client: _updateUserSecretsClient);

      if (identical(client, _updateUserSecretsClient)) {
        if (response?.statusCode == 200) {
          _updateUserSecretsTimer?.cancel();
          _updateUserSecretsClient = null;
        }
        else {
          _updateUserSecretsTimer ??= Timer.periodic(const Duration(seconds: 3), (_) {
            if (_updateUserSecretsClient == null) {
              _saveAccountSecrets();
            }
          });
        }
        _updateUserSecretsClient = null;
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

  Future<bool> updateUsername(String username) async {
    if ((Config().coreUrl != null) && (_token?.accessToken != null)) {
      String url = "${Config().coreUrl}/services/account/username";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      Map<String, String> body = {
        'username': username.toLowerCase().trim(),
      };
      String? bodyJson = JsonUtils.encode(body);
      Response? response = await Network().put(url, auth: Auth2(), headers: headers, body: bodyJson);
      if (response?.statusCode == 200) {
        _refreshAccount();
        return true;
      }
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
          await launchUrlString(urlStr);
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

  // Plugin

  Future<dynamic> onPluginNotification(String? name, dynamic arguments) async {
    switch (name) {
      case 'onGetPasskeySuccess':
        String? responseJson = JsonUtils.stringValue(arguments);
        NotificationService().notify(notifyGetPasskeySuccess, responseJson);
        break;
      case 'onGetPasskeyFailed':
        String? error = JsonUtils.stringValue(arguments);
        NotificationService().notify(notifyGetPasskeyFailed, error);
        break;
      case 'onCreatePasskeySuccess':
        String? responseJson = JsonUtils.stringValue(arguments);
        NotificationService().notify(notifyCreatePasskeySuccess, responseJson);
        break;
      case 'onCreatePasskeyFailed':
        String? error = JsonUtils.stringValue(arguments);
        NotificationService().notify(notifyCreatePasskeyFailed, error);
        break;
    }
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
  Auth2Token? token;

  Auth2Csrf({this.token});

  static const String csrfTokenName = 'rokwire-csrf-token';

  @override
  Map<String, String>? get networkAuthHeaders {
    String cookieName = csrfTokenName;
    if (Config().authBaseUrl?.contains("localhost") == false) {
      cookieName = '__Host-' + cookieName;
    }

    Map<String, String> headers = {};
    String cookieValue = WebUtils.getCookie(cookieName);
    if (cookieValue.isNotEmpty) {
      headers[csrfTokenName] = cookieValue;
    }

    if (StringUtils.isNotEmpty(token?.accessToken)) {
      String tokenType = token!.tokenType ?? 'Bearer';
      headers[HttpHeaders.authorizationHeader] = "$tokenType ${token!.accessToken}";
    }
    return headers;
  }

  @override
  dynamic get networkAuthToken => token;

  @override
  Future<bool> refreshNetworkAuthTokenIfNeeded(BaseResponse? response, dynamic token) async {
    if ((response?.statusCode == 401) && (token is Auth2Token) && (Auth2().token == token) &&
      (!(Config().coreUrl?.contains('http://') ?? true) || (response?.request?.url.origin.contains('http://') ?? false))) {
      return (await Auth2().refreshToken(token: token) != null);
    }
    return false;
  }

  @override
  Future<bool> refreshNetworkAuthTokenIfExpired(dynamic token) async {
    if (token is Auth2Token && token.accessIsExpired == true) {
      return (await Auth2().refreshToken(token: token) != null);
    }
    return false;
  }
}

// Auth2PasskeySignUpResult

class Auth2PasskeySignUpResult {
  Auth2PasskeySignUpResultStatus status;
  String? error;
  String? creationOptions;
  Auth2PasskeySignUpResult(this.status, {this.error, this.creationOptions});
}

enum Auth2PasskeySignUpResultStatus {
  succeeded,
  failed,
  failedNotSupported,
  failedAccountExist,
  failedNotFound,
  failedActivationExpired,
  failedNotActivated,
  failedNoCredentials,
  failedCancelled,
}

// Auth2PasskeySignInResult
class Auth2PasskeySignInResult {
  Auth2PasskeySignInResultStatus status;
  String? error;
  Auth2PasskeySignInResult(this.status, {this.error});
}

enum Auth2PasskeySignInResultStatus {
  succeeded,
  failed,
  failedNotFound,
  failedActivationExpired,
  failedNotActivated,
  failedNotSupported,
  failedNoCredentials,
  failedCancelled,
}

// Auth2RequestCodeResult

enum Auth2RequestCodeResult {
  succeeded,
  failed,
  failedAccountExist,
}

Auth2RequestCodeResult auth2RequestCodeResultFromAuth2LinkResult(Auth2LinkResult value) {
  switch (value.status) {
    case Auth2LinkResultStatus.succeeded: return Auth2RequestCodeResult.succeeded;
    case Auth2LinkResultStatus.failedAccountExist: return Auth2RequestCodeResult.failedAccountExist;
    default: return Auth2RequestCodeResult.failed;
  }
}

// Auth2SendCodeResult

enum Auth2SendCodeResult {
  succeeded,
  failed,
  failedInvalid,
}

Auth2SendCodeResult auth2SendCodeResultFromAuth2LinkResult(Auth2LinkResult value) {
  switch (value.status) {
    case Auth2LinkResultStatus.succeeded: return Auth2SendCodeResult.succeeded;
    case Auth2LinkResultStatus.failedInvalid: return Auth2SendCodeResult.failedInvalid;
    default: return Auth2SendCodeResult.failed;
  }
}

// Auth2AccountState

enum Auth2AccountState {
  nonExistent,
  unverified,
  verified,
}

// Auth2SignInOptionsResult
class Auth2SignInOptionsResult {
  List<Auth2Identifier>? identifierOptions;
  List<Auth2Type>? authTypeOptions;
  Auth2SignInOptionsResult({this.identifierOptions, this.authTypeOptions});
}

// Auth2PasswordSignUpResult

enum Auth2PasswordSignUpResult {
  succeeded,
  failed,
  failedAccountExist,
}

Auth2PasswordSignUpResult auth2PasswordSignUpResultFromAuth2LinkResult(Auth2LinkResult value) {
  switch (value.status) {
    case Auth2LinkResultStatus.succeeded: return Auth2PasswordSignUpResult.succeeded;
    case Auth2LinkResultStatus.failedAccountExist: return Auth2PasswordSignUpResult.failedAccountExist;
    default: return Auth2PasswordSignUpResult.failed;
  }
}

// Auth2PasswordSignInResult

enum Auth2PasswordSignInResult {
  succeeded,
  failed,
  failedNotFound,
  failedActivationExpired,
  failedNotActivated,
  failedInvalid,
}

Auth2PasswordSignInResult auth2PasswordSignInResultFromAuth2LinkResult(Auth2LinkResult value) {
  switch (value.status) {
    case Auth2LinkResultStatus.succeeded: return Auth2PasswordSignInResult.succeeded;
    case Auth2LinkResultStatus.failedNotActivated: return Auth2PasswordSignInResult.failedNotActivated;
    case Auth2LinkResultStatus.failedActivationExpired: return Auth2PasswordSignInResult.failedActivationExpired;
    case Auth2LinkResultStatus.failedInvalid: return Auth2PasswordSignInResult.failedInvalid;
    default: return Auth2PasswordSignInResult.failed;
  }
}

// Auth2ForgotPasswordResult

enum Auth2ForgotPasswordResult {
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
  switch (value.status) {
    case Auth2LinkResultStatus.succeeded: return Auth2OidcAuthenticateResult.succeeded;
    case Auth2LinkResultStatus.failedAccountExist: return Auth2OidcAuthenticateResult.failedAccountExist;
    default: return Auth2OidcAuthenticateResult.failed;
  }
}

// Auth2LinkResult

class Auth2LinkResult {
  Auth2LinkResultStatus status;
  String? message;
  Auth2LinkResult(this.status, {this.message});
}

enum Auth2LinkResultStatus {
  succeeded,
  failed,
  failedActivationExpired,
  failedNotActivated,
  failedAccountExist,
  failedInvalid,
}