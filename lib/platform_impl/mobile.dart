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

import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:rokwire_plugin/platform_impl/base.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'package:flutter_passkey/flutter_passkey.dart';
import 'package:path_provider/path_provider.dart';

class PasskeyImpl extends BasePasskey {
  final flutterPasskeyPlugin = FlutterPasskey();

  @override
  Future<bool> arePasskeysSupported() async {
    return await flutterPasskeyPlugin.isSupported();
  }

  @override
  Future<String?> getPasskey(String? optionsJson) async {
    dynamic options = JsonUtils.decode(optionsJson ?? '');
    if (options is Map) {
      Map<String, dynamic>? pubKeyRequest = options['publicKey'];
      return await flutterPasskeyPlugin.getCredential(JsonUtils.encode(pubKeyRequest) ?? '');
    }

    return null;
  }

  @override
  Future<String?> createPasskey(String? optionsJson) async {
    dynamic options = JsonUtils.decode(optionsJson ?? '');
    if (options is Map) {
      Map<String, dynamic>? pubKeyRequest = options['publicKey'];
      return await flutterPasskeyPlugin.createCredential(JsonUtils.encode(pubKeyRequest) ?? '');
    }

    return null;
  }
}

class FileImpl extends BaseFile {
  Future<bool> saveDownload(String name, Uint8List data) async {
    if (Platform.isAndroid) {
      Directory downloadsDir = Directory("/storage/emulated/0/Download");
      if (!await downloadsDir.exists()) {
        downloadsDir = await getExternalStorageDirectory();
      }
      File downloadsFile = File('${downloadsDir.path}/$name');
      downloadsFile = await downloadsFile.writeAsBytes(data);
      FileStat stats = await downloadsFile.stat();
      return stats.size > 0;
    }
    //TODO: implement for iOS
    return false;
  }
}