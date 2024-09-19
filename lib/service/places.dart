import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/places.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'auth2.dart';
import 'config.dart';
import 'network.dart';

class PlacesService {
  // Singleton Pattern
  static final PlacesService _instance = PlacesService._internal();

  factory PlacesService() => _instance;

  PlacesService._internal();

  /// Retrieves all places based on provided filters.
  Future<List<Place>?> getAllPlaces({
    String? ids,
    String? types,
    String? tags,
  }) async {
    Map<String, String> queryParams = {};
    if (ids != null) queryParams['ids'] = ids;
    if (types != null) queryParams['types'] = types;
    if (tags != null) queryParams['tags'] = tags;

    Uri uri = Uri.parse('${Config().placesUrl}/places').replace(queryParameters: queryParams);

    final response = await Network().get(uri.toString(), auth: Auth2());

    if (response?.statusCode == 200) {
      List<dynamic>? jsonList = JsonUtils.decodeList(response?.body);
      if (jsonList != null) {
        return jsonList.map((json) => Place.fromJson(json)).toList();
      } else {
        debugPrint('Failed to decode places list');
        return null;
      }
    } else {
      debugPrint('Failed to load places: ${response?.statusCode} ${response?.body}');
      return null;
    }
  }

  /// Updates the 'visited' status of a place.
  Future<Place?> updatePlaceVisited(String id, bool visited) async {
    Map<String, String> queryParams = {'visited': visited.toString()};

    Uri uri = Uri.parse('${Config().placesUrl}/places/visited/$id').replace(queryParameters: queryParams);

    final response = await Network().put(
      uri.toString(),
      headers: {'Content-Type': 'application/json'},
      auth: Auth2(),
    );

    if (response?.statusCode == 200) {
      Map<String, dynamic>? jsonMap = JsonUtils.decodeMap(response?.body);
      if (jsonMap != null) {
        return Place.fromJson(jsonMap);
      } else {
        debugPrint('Failed to decode response body');
        return null;
      }
    } else {
      debugPrint('Failed to update place visited status: ${response?.statusCode} ${response?.body}');
      return null;
    }
  }
}
