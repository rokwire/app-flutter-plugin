// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'places.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Place _$PlaceFromJson(Map<String, dynamic> json) => Place(
      id: json['id'] as String,
      name: json['name'] as String?,
      subtitle: json['subtitle'] as String?,
      address: json['address'] as String?,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => Image.fromJson(e as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      userData: json['user_data'] == null
          ? null
          : UserPlace.fromJson(json['user_data'] as Map<String, dynamic>),
      types:
          (json['types'] as List<dynamic>?)?.map((e) => e as String).toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      dateCreated: json['date_created'] == null
          ? null
          : DateTime.parse(json['date_created'] as String),
      dateUpdated: json['date_updated'] == null
          ? null
          : DateTime.parse(json['date_updated'] as String),
    );

Map<String, dynamic> _$PlaceToJson(Place instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'subtitle': instance.subtitle,
      'address': instance.address,
      'images': instance.images?.map((e) => e.toJson()).toList(),
      'description': instance.description,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'user_data': instance.userData?.toJson(),
      'types': instance.types,
      'tags': instance.tags,
      'date_created': instance.dateCreated?.toIso8601String(),
      'date_updated': instance.dateUpdated?.toIso8601String(),
    };

UserPlace _$UserPlaceFromJson(Map<String, dynamic> json) => UserPlace(
      id: json['id'] as String,
      visited: (json['visited'] as List<dynamic>?)
          ?.map((e) => e == null ? null : DateTime.parse(e as String))
          .toList(),
      dateCreated: json['date_created'] == null
          ? null
          : DateTime.parse(json['date_created'] as String),
      dateUpdated: json['date_updated'] == null
          ? null
          : DateTime.parse(json['date_updated'] as String),
    );

Map<String, dynamic> _$UserPlaceToJson(UserPlace instance) => <String, dynamic>{
      'id': instance.id,
      'visited': instance.visited?.map((e) => e?.toIso8601String()).toList(),
      'date_created': instance.dateCreated?.toIso8601String(),
      'date_updated': instance.dateUpdated?.toIso8601String(),
    };

Image _$ImageFromJson(Map<String, dynamic> json) => Image(
      imageUrl: json['image_url'] as String,
      caption: json['caption'] as String?,
    );

Map<String, dynamic> _$ImageToJson(Image instance) => <String, dynamic>{
      'image_url': instance.imageUrl,
      'caption': instance.caption,
    };
