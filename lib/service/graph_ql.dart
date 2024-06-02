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

  GraphQLClient getClient(String url, {Map<String, Set<String>> possibleTypes = const {},
    Map<String, String> defaultHeaders = const {}, AuthLink? authLink,
    FetchPolicy? defaultFetchPolicy, bool useCache = true}) {
    Link link = HttpLink(url, defaultHeaders: defaultHeaders,
        parser: GraphQLResponseParser());
    if (authLink != null) {
      link = authLink.concat(link);
    }
    GraphQLClient client = GraphQLClient(
      link: link,
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: defaultFetchPolicy,
          error: ErrorPolicy.all,
          cacheReread: CacheRereadPolicy.ignoreAll
        ),
        mutate: Policies(
          fetch: defaultFetchPolicy,
          error: ErrorPolicy.all,
          cacheReread: CacheRereadPolicy.ignoreAll
        )
      ),
      cache: GraphQLCache(
        store: useCache ? HiveStore() : NoOpStore(),
        possibleTypes: possibleTypes,
        partialDataPolicy: PartialDataCachePolicy.accept
      ),
    );
    return client;
  }

  ValueNotifier<GraphQLClient> getNotifier(GraphQLClient client) {
    return ValueNotifier(client);
  }
}

class GraphQLResponseParser extends ResponseParser {
  @override
  Response parseResponse(Map<String, dynamic> body) => Response(
    errors: (body["errors"] as List?)
        ?.map(
          (dynamic error) {
            if (error is Map<String, dynamic>) {
              return parseError(error);
            }
            return GraphQLError(message: error.toString());
          },
    ).toList(),
    data: body["data"] as Map<String, dynamic>?,
    response: body,
    context: Context().withEntry(
      ResponseExtensions(
        body["extensions"],
      ),
    ),
  );

  @override
  GraphQLError parseError(Map<String, dynamic> error) {
    dynamic extensions = error["extensions"];
    return GraphQLError(
      message: error["message"] as String,
      path: error["path"] as List?,
      locations: (error["locations"] as List?)
          ?.map(
            (dynamic location) =>
            parseLocation(location as Map<String, dynamic>),
      )
          .toList(),
      extensions: extensions is Map<String, dynamic>? ? extensions : null,
    );
  }
}

class NoOpStore implements Store {
  Map<String, dynamic>? get(String dataId) => null;

  void put(String dataId, Map<String, dynamic>? value) => null;

  void putAll(Map<String, Map<String, dynamic>?> data) => null;

  void delete(String dataId) => null;

  void reset() => null;

  Map<String, Map<String, dynamic>?> toMap() => {};
}
