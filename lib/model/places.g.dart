// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'places.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Place _$PlaceFromJson(Map<String, dynamic> json) => Place(
      id: json['id'] as String?,
      orgId: json['org_id'] as String?,
      appId: json['app_id'] as String?,
      name: json['name'] as String?,
      address: json['address'] as String?,
      imageUrls: (json['image_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
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
      'org_id': instance.orgId,
      'app_id': instance.appId,
      'name': instance.name,
      'address': instance.address,
      'image_urls': instance.imageUrls,
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
      id: json['id'] as String?,
      orgId: json['org_id'] as String?,
      appId: json['app_id'] as String?,
      placeId: json['place_id'] as String?,
      userId: json['user_id'] as String?,
      visited: json['visited'] == null
          ? null
          : DateTime.parse(json['visited'] as String),
      dateCreated: json['date_created'] == null
          ? null
          : DateTime.parse(json['date_created'] as String),
      dateUpdated: json['date_updated'] == null
          ? null
          : DateTime.parse(json['date_updated'] as String),
    );

Map<String, dynamic> _$UserPlaceToJson(UserPlace instance) => <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'app_id': instance.appId,
      'place_id': instance.placeId,
      'user_id': instance.userId,
      'visited': instance.visited?.toIso8601String(),
      'date_created': instance.dateCreated?.toIso8601String(),
      'date_updated': instance.dateUpdated?.toIso8601String(),
    };
