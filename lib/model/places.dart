import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';

import 'explore.dart';

part 'places.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Place with Explore{
  String id;
  String? name;
  String? subtitle;
  String? address;
  List<Image>? images;
  String? description;
  double latitude;
  double longitude;
  UserPlace? userData;
  List<String>? types;
  List<String>? tags;
  DateTime? dateCreated;
  DateTime? dateUpdated;

  Place({
    required this.id,
    this.name,
    this.subtitle,
    this.address,
    this.images,
    this.description,
    required this.latitude,
    required this.longitude,
    this.userData,
    this.types,
    this.tags,
    this.dateCreated,
    this.dateUpdated,
  });

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);

  Map<String, dynamic> toJson() => _$PlaceToJson(this);

  @override
  String? get exploreId => id;
  @override
  String? get exploreTitle => name;
  @override
  String? get exploreDescription => description;
  @override
  String? get exploreImageURL => images?.isNotEmpty == true ? images?.first.imageUrl : null;
  @override
  ExploreLocation? get exploreLocation => ExploreLocation(id: id,
      longitude: longitude, latitude: latitude, fullAddress: address,
      name: name, description: description);

  static List<Place>? listFromJson(List<dynamic>? jsonList) {
    List<Place>? result;
    if (jsonList != null) {
      result = [];
      for (dynamic jsonEntry in jsonList) {
        try {
          Place place = Place.fromJson(jsonEntry);
          result.add(place);
        } catch (e) {
          debugPrint("Error decoding places list $e");
        }
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Place>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (Place contentEntry in contentList) {
        jsonList.add(contentEntry.toJson());
      }
    }
    return jsonList;
  }
}

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class UserPlace {
  String id;
  List<DateTime?>? visited;
  DateTime? dateCreated;
  DateTime? dateUpdated;

  UserPlace({
    required this.id,
    this.visited,
    this.dateCreated,
    this.dateUpdated,
  });

  factory UserPlace.fromJson(Map<String, dynamic> json) => _$UserPlaceFromJson(json);

  Map<String, dynamic> toJson() => _$UserPlaceToJson(this);
}

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Image {
  String imageUrl;
  String? caption;

  Image({
    required this.imageUrl,
    this.caption,
  });

  factory Image.fromJson(Map<String, dynamic> json) => _$ImageFromJson(json);

  Map<String, dynamic> toJson() => _$ImageToJson(this);
}
