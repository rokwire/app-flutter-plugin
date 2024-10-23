import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/places.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'auth2.dart';
import 'config.dart';
import 'deep_link.dart';
import 'network.dart';

class Places extends Service implements NotificationsListener {

  static final Places _instance = Places._internal();

  factory Places() => _instance;

  Places._internal();


  static String get placesDetailUrl => '${DeepLink().appUrl}/places';
  static const String notifyPlacesDetail = "edu.illinois.rokwire.places.detail";

  List<Uri>? _deepLinkUrisCache;

  @override
  void createService() {
    super.createService();
    NotificationService().subscribe(this, [
      DeepLink.notifyUri,
    ]);
    _deepLinkUrisCache = <Uri>[];
  }

  @override
  void destroyService() {
    super.destroyService();
    NotificationService().unsubscribe(this);
  }

  @override
  void initServiceUI() {
    super.initServiceUI();
    _processCachedDeepLinkUris();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { DeepLink() };
  }

  void _onDeepLinkUri(Uri? uri) {
    if (uri != null) {
      if (_deepLinkUrisCache != null) {
        _cacheDeepLinkUri(uri);
      } else {
        _processDeepLinkUri(uri);
      }
    }
  }

  void _processDeepLinkUri(Uri uri) {
    if (uri.matchDeepLinkUri(Uri.tryParse(placesDetailUrl))) {
      NotificationService().notify(notifyPlacesDetail, uri.queryParameters.cast<String, dynamic>());
    }
  }

  void _cacheDeepLinkUri(Uri uri) {
    _deepLinkUrisCache?.add(uri);
  }

  void _processCachedDeepLinkUris() {
    if (_deepLinkUrisCache != null) {
      List<Uri> deepLinkUrisCache = _deepLinkUrisCache!;
      _deepLinkUrisCache = null;

      for (Uri deepLinkUri in deepLinkUrisCache) {
        _processDeepLinkUri(deepLinkUri);
      }
    }
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      _onDeepLinkUri(param);
    }
  }

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
