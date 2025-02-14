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

class PasskeyImpl extends BasePasskey {
  @override
  Future<bool> arePasskeysSupported() {
    throw Exception("Unimplemented");
  }

  @override
  Future<String?> getPasskey(String? optionsJson) {
    throw Exception("Unimplemented");
  }

  @override
  Future<String?> createPasskey(String? optionsJson) {
    throw Exception("Unimplemented");
  }
}