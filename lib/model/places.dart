import 'package:json_annotation/json_annotation.dart';

part 'places.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Place {
  String? id;
  String? orgId;
  String? appId;
  String? name;
  String? address;
  List<String>? imageUrls;
  String? description;
  double? latitude;
  double? longitude;
  UserPlace? userData;
  List<String>? types;
  List<String>? tags;
  DateTime? dateCreated;
  DateTime? dateUpdated;

  Place({
    this.id,
    this.orgId,
    this.appId,
    this.name,
    this.address,
    this.imageUrls,
    this.description,
    this.latitude,
    this.longitude,
    this.userData,
    this.types,
    this.tags,
    this.dateCreated,
    this.dateUpdated,
  });

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);

  Map<String, dynamic> toJson() => _$PlaceToJson(this);
}

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class UserPlace {
  String? id;
  String? orgId;
  String? appId;
  String? placeId;
  String? userId;
  DateTime? visited;
  DateTime? dateCreated;
  DateTime? dateUpdated;

  UserPlace({
    this.id,
    this.orgId,
    this.appId,
    this.placeId,
    this.userId,
    this.visited,
    this.dateCreated,
    this.dateUpdated,
  });

  factory UserPlace.fromJson(Map<String, dynamic> json) => _$UserPlaceFromJson(json);

  Map<String, dynamic> toJson() => _$UserPlaceToJson(this);
}
