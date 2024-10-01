import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';

part 'places.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Place {
  String id;
  String? name;
  String? address;
  List<String>? imageUrls;
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
    this.address,
    this.imageUrls,
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

  static List<Place>? listFromJson(List<dynamic>? jsonList) {
    List<Place>? result;
    if (jsonList != null) {
      result = [];
      for (dynamic jsonEntry in jsonList) {
        try{
          Place place = Place.fromJson(jsonEntry);
          result.add(place);
        }
        catch(e){
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
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class UserPlace {
  String id;
  List<DateTime>? visited;
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