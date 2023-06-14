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

import 'package:rokwire_plugin/platform_impl/base.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'package:flutter_passkey/flutter_passkey.dart';

class PasskeyImpl extends BasePasskey {
  final flutterPasskeyPlugin = FlutterPasskey();

  @override
  Future<bool> arePasskeysSupported() async {
    return await flutterPasskeyPlugin.isSupported();
  }

  @override
  Future<String?> getPasskey(Map<String, dynamic>? options) async {
    Map<String, dynamic>? pubKeyRequest = options?['publicKey'];
    return await flutterPasskeyPlugin.getCredential(JsonUtils.encode(pubKeyRequest) ?? '');
  }

  @override
  Future<String?> createPasskey(Map<String, dynamic>? options) async {
    Map<String, dynamic>? pubKeyRequest = options?['publicKey'];
    return await flutterPasskeyPlugin.createCredential(JsonUtils.encode(pubKeyRequest) ?? '');
  }
}