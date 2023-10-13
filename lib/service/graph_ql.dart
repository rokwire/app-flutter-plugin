/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:rokwire_plugin/service/service.dart';

class GraphQL with Service {

  // Singleton Factory

  static GraphQL? _instance;

  static GraphQL? get instance => _instance;
  
  @protected
  static set instance(GraphQL? value) => _instance = value;

  factory GraphQL() => _instance ?? (_instance = GraphQL.internal());

  @protected
  GraphQL.internal();

  // Service

  @override
  Future<void> initService() async {
    await initHiveForFlutter();
    await super.initService();
  }

  ValueNotifier<GraphQLClient> getClient(String url, {Map<String, Set<String>> possibleTypes = const {}, Map<String, String> defaultHeaders = const {}}) {
    ValueNotifier<GraphQLClient> client = ValueNotifier(GraphQLClient(
      link: HttpLink(url, defaultHeaders: defaultHeaders),
      defaultPolicies: DefaultPolicies(query: Policies(error: ErrorPolicy.all)),
      cache: GraphQLCache(store: HiveStore(), possibleTypes: possibleTypes, partialDataPolicy: PartialDataCachePolicy.accept),
    ));
    return client;
  }
}
