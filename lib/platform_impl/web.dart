// Copyright 2023 Board of Trustees of the University of Illinois.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:html';
import 'dart:typed_data';

import 'package:rokwire_plugin/platform_impl/base.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'package:js/js.dart';

@JS('atob')
external String atob(String value);

@JS('btoa')
external String btoa(String value);

class PasskeyImpl extends BasePasskey {
  @override
  Future<bool> arePasskeysSupported() {
    return Future.value(window.navigator.credentials != null);
  }

  @override
  Future<String?> getPasskey(Map<String, dynamic>? options) async {
    if (options?['publicKey']?['challenge'] is String) {
      String challenge = options!['publicKey']['challenge'];
      options['publicKey']['challenge'] = _encodedStringToBuffer(challenge);
    }
    if (options?['publicKey']?['allowCredentials'] is Iterable) {
      Iterable<dynamic> credentials = options!['publicKey']?['allowCredentials'];
      for (int i = 0; i < credentials.length; i++) {
        dynamic credential = credentials.elementAt(i);
        if (credential is Map<String, dynamic> && credential['id'] is String) {
          credentials.elementAt(i)['id'] = _encodedStringToBuffer(credential['id']);
        }
      }
    }
    
    PublicKeyCredential credential = await window.navigator.credentials!.get(options);
    AuthenticatorResponse? authResponse = credential.response;
    if (authResponse is AuthenticatorAssertionResponse) {
      Map<String, dynamic> response = {
        'id': credential.id,
        'rawId': _bufferToEncodedString(credential.rawId),
        'type': credential.type,
        'response': {
          'authenticatorData': _bufferToEncodedString(authResponse.authenticatorData),
          'clientDataJSON': _bufferToEncodedString(authResponse.clientDataJson),
          'signature': _bufferToEncodedString(authResponse.signature),
        }
      };

      return JsonUtils.encode(response);
    }
    
    return null;
  }

  @override
  Future<String?> createPasskey(Map<String, dynamic>? options) async {
    if (options?['publicKey']?['challenge'] is String) {
      String challenge = options!['publicKey']['challenge'];
      options['publicKey']['challenge'] = _encodedStringToBuffer(challenge);
    }
    if (options?['publicKey']?['user']?['id'] is String) {
      String userId = options!['publicKey']['user']['id'];
      options['publicKey']['user']['id'] = _encodedStringToBuffer(userId);
    }

    PublicKeyCredential credential = await window.navigator.credentials!.create(options);
    AuthenticatorResponse? authResponse = credential.response;
    if (authResponse is AuthenticatorAttestationResponse) {
      Map<String, dynamic> response = {
        'id': credential.id,
        'rawId': _bufferToEncodedString(credential.rawId),
        'type': credential.type,
        'response': {
          'attestationObject': _bufferToEncodedString(authResponse.attestationObject),
          'clientDataJSON': _bufferToEncodedString(authResponse.clientDataJson),
        }
      };

      return JsonUtils.encode(response);
    }
    
    return null;
  }

  ByteBuffer _encodedStringToBuffer(String value) => Uint8List.fromList(atob(value.replaceAll('_', '/').replaceAll('-', '+')).codeUnits).buffer;

  String _bufferToEncodedString(ByteBuffer? buffer) => btoa(String.fromCharCodes(buffer?.asUint8List() ?? [])).replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
}