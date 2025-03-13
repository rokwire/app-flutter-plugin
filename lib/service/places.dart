import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/ext/uri.dart';
import 'package:rokwire_plugin/model/places.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'auth2.dart';
import 'config.dart';
import 'deep_link.dart';
import 'network.dart';

class Places extends Service implements NotificationsListener {

  static const String notifyPlacesDetail = "edu.illinois.rokwire.places.detail";

  // Singletone Factory

  static Places? _instance;

  factory Places() => _instance ?? (_instance = Places.internal());

  @protected
  static set instance(Places? value) => _instance = value;

  @protected
  Places.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      DeepLink.notifyUiUri,
    ]);
    super.createService();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { DeepLink() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUiUri) {
      onDeepLinkUri(JsonUtils.cast(param));
    }
  }

  // DeepLinks

  static String get placeDetailRawUrl => '${DeepLink().appUrl}/place_detail';
  static String placeDetailUrl(Place? place) => UrlUtils.buildWithQueryParameters(placeDetailRawUrl, <String, String>{'place_id' : "${place?.id}"});

  @protected
  void onDeepLinkUri(Uri? uri) {
    if ((uri != null) && uri.matchDeepLinkUri(Uri.tryParse(placeDetailRawUrl))) {
      try { NotificationService().notify(notifyPlacesDetail, uri.queryParameters.cast<String, dynamic>()); }
      catch (e) { print(e.toString()); }
    }
  }

  // Implementation

  /// Retrieves all places based on provided filters.
  Future<List<Place>?> getAllPlaces({
    Set<String>? ids,
    Set<String>? types,
    Set<String>? tags,
  }) async {
    Map<String, String> queryParams = {};

    if (ids != null && ids.isNotEmpty) queryParams['ids'] = ids.join(',');
    if (types != null && types.isNotEmpty) queryParams['types'] = types.join(',');
    if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags.join(',');

    Uri uri;
    try {
      uri = Uri.parse('${Config().placesUrl}/places').replace(queryParameters: queryParams);
    } catch (e) {
      debugPrint('Failed to parse URI: $e');
      return null;
    }

    try {
      final response = await Network().get(uri.toString(), auth: Auth2());

      if (response?.statusCode == 200) {
        List<dynamic>? jsonList = JsonUtils.decodeList(response?.body);
        if (jsonList != null) {
          try {
            return Place.listFromJson(jsonList);
          } catch (e) {
            debugPrint('Failed to parse places: $e');
            return null;
          }
        } else {
          debugPrint('Failed to decode places list');
          return null;
        }
      } else {
        debugPrint('Failed to load places: ${response?.statusCode} ${response?.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Network error while fetching places: $e');
      return null;
    }
  }

  /// Updates the 'visited' status of a place.
  Future<UserPlace?> updatePlaceVisited(String id, bool visited) async {
    Map<String, String> queryParams = {'visited': visited.toString()};

    Uri uri;
    try {
      uri = Uri.parse('${Config().placesUrl}/places/$id/visited').replace(queryParameters: queryParams);
    } catch (e) {
      debugPrint('Failed to parse URI: $e');
      return null;
    }

    try {
      final response = await Network().put(
        uri.toString(),
        headers: {'Content-Type': 'application/json'},
        auth: Auth2(),
      );

      if (response?.statusCode == 200) {
        Map<String, dynamic>? jsonMap = JsonUtils.decodeMap(response?.body);
        if (jsonMap != null) {
          try {
            return UserPlace.fromJson(jsonMap);
          } catch (e) {
            debugPrint('Failed to parse place from JSON: $e');
            return null;
          }
        } else {
          debugPrint('Failed to decode response body');
          return null;
        }
      } else {
        debugPrint('Failed to update place visited status: ${response?.statusCode} ${response?.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Network error while updating place visited status: $e');
      return null;
    }
  }

  /// Deletes a visited place record.
  Future<bool> deleteVisitedPlace(String id, DateTime visited) async {
    Map<String, String> queryParams = {
      'visited': visited.toIso8601String(),
    };

    Uri uri;
    try {
      uri = Uri.parse('${Config().placesUrl}/places/$id/visited').replace(queryParameters: queryParams);
    } catch (e) {
      debugPrint('Failed to parse URI: $e');
      return false;
    }

    try {
      final response = await Network().delete(
        uri.toString(),
        auth: Auth2(),
      );

      if (response?.statusCode == 200) {
        return true;
      } else {
        debugPrint('Failed to delete visited place: ${response?.statusCode} ${response?.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Network error while deleting visited place: $e');
      return false;
    }
  }
}
