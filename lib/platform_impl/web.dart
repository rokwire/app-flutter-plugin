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
import 'package:flutter/foundation.dart';

import 'package:rokwire_plugin/platform_impl/base.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class PasskeyImpl extends BasePasskey {
  @override
  Future<bool> arePasskeysSupported() {
    return Future.value(window.navigator.credentials != null);
  }

  @override
  Future<String?> getPasskey(Map<String, dynamic>? options) async {
    dynamic response = await window.navigator.credentials!.get(options);
    return JsonUtils.stringValue(response);
  }

  @override
  Future<String?> createPasskey(Map<String, dynamic>? options) async {
    if (options?['publicKey']?['challenge'] is String) {
      String challenge = options!['publicKey']['challenge'];
      options['publicKey']['challenge'] = Uint8List.fromList(challenge.codeUnits).buffer;
    }
    if (options?['publicKey']?['user']?['id'] is String) {
      String userId = options!['publicKey']['user']['id'];
      options['publicKey']['user']['id'] = Uint8List.fromList(userId.codeUnits).buffer;
    }

    window.console.log(options?.toString());
    PublicKeyCredential credential = await window.navigator.credentials!.create(options);
    AuthenticatorResponse? authResponse = credential.response;
    if (authResponse is AuthenticatorAttestationResponse) {
      //TODO: how to read from this ByteBuffer?
      String rawId = StringUtils.base64UrlEncode(String.fromCharCodes(credential.rawId?.asUint8List() ?? []));
      //TODO: how to read from this ByteBuffer?
      String attestationObject = StringUtils.base64UrlEncode(String.fromCharCodes(authResponse.attestationObject?.asUint8List() ?? []));
      // this works
      String clientDataJson = StringUtils.base64UrlEncode(String.fromCharCodes(authResponse.clientDataJson?.asUint8List() ?? []));
      window.console.log(rawId);
      window.console.log(attestationObject);
      window.console.log(clientDataJson);
      Map<String, dynamic> response = {
        'id': credential.id,
        'rawId': rawId,
        'type': credential.type,
        'response': {
          'attestationObject': attestationObject,
          'clientDataJSON': clientDataJson,
        }
      };

      return JsonUtils.encode(response);
    }
    
    return null;
  }
}