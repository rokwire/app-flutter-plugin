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

import 'package:rokwire_plugin/utils/utils.dart';

//////////////////////////////
/// Explore

abstract class Explore implements Comparable<Explore> {

  String?   get exploreId => null;
  String?   get exploreTitle => null;
  String?   get exploreDescription => null;
  DateTime? get exploreDateTimeUtc => null;
  String?   get exploreImageURL => null;
  ExploreLocation? get exploreLocation => null;

  @override
  int compareTo(Explore other) {
    return ((exploreDateTimeUtc != null) && (other.exploreDateTimeUtc != null)) ?
      SortUtils.compare(exploreDateTimeUtc, other.exploreDateTimeUtc) :
      SortUtils.compare(exploreTitle, other.exploreTitle);
  }
}

//////////////////////////////
/// ExploreLocation

class ExploreLocation {
  final String? id;
  final double? latitude;
  final double? longitude;
  final String? name;
  final String? description;
  final String? building;
  final String? fullAddress;
  final String? address;
  final String? city;
  final String? state;
  final String? zip;
  final String? floor;
  final String? room;

  ExploreLocation({
    this.id,
    this.latitude,
    this.longitude,
    this.name,
    this.description,
    this.building,
    this.fullAddress,
    this.address,
    this.city,
    this.state,
    this.zip,
    this.floor,
    this.room,
  });

  static ExploreLocation? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ExploreLocation(
      id: JsonUtils.stringValue(json['id']),
      latitude: JsonUtils.doubleValue(json['latitude']),
      longitude: JsonUtils.doubleValue(json['longitude']),
      name: JsonUtils.stringValue(json['name']),
      description: JsonUtils.stringValue(json['description']),
      building: JsonUtils.stringValue(json['building']),
      fullAddress: JsonUtils.stringValue(json['full_address']),
      address: JsonUtils.stringValue(json['address']),
      city: JsonUtils.stringValue(json['city']),
      state: JsonUtils.stringValue(json['state']),
      zip: JsonUtils.stringValue(json['zip']),
      floor: JsonUtils.stringValue(json['floor']),
      room: JsonUtils.stringValue(json['room']),
    ) : null;
  }

  toJson() {
    return {
      "id": id,
      "latitude": latitude,
      "longitude": longitude,
      "name": name,
      "description": description,
      "building": building,
      "fullAddress": fullAddress,
      "address": address,
      "city": city,
      "state": state,
      "zip": zip,
      "floor": floor,
      "room": room,
    };
  }

  factory ExploreLocation.fromOther(ExploreLocation? other, {
    String? id,
    double? latitude,
    double? longitude,
    String? description,
    String? name,
    String? building,
    String? fullAddress,
    String? address,
    String? city,
    String? state,
    String? zip,
    String? floor,
    String? room,
  }) => ExploreLocation(
    id: id ?? other?.id,
    latitude: latitude ?? other?.latitude,
    longitude: longitude ?? other?.longitude,
    name: name ?? other?.name,
    description: description ?? other?.description,
    building: building ?? other?.building,
    fullAddress: fullAddress ?? other?.fullAddress,
    address: address ?? other?.address,
    city: city ?? other?.city,
    state: state ?? other?.state,
    zip: zip ?? other?.zip,
    floor: floor ?? other?.floor,
    room: room ?? other?.room,
  );

  @override
  bool operator ==(other) => (other is ExploreLocation) &&
    (other.id == id) &&
    (other.latitude == latitude) &&
    (other.longitude == longitude) &&
    (other.name == name) &&
    (other.description == description) &&
    (other.building == building) &&
    (other.fullAddress == fullAddress) &&
    (other.address == address) &&
    (other.city == city) &&
    (other.state == state) &&
    (other.zip == zip) &&
    (other.floor == floor) &&
    (other.room == room);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (latitude?.hashCode ?? 0) ^
    (longitude?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (building?.hashCode ?? 0) ^
    (fullAddress?.hashCode ?? 0) ^
    (address?.hashCode ?? 0) ^
    (city?.hashCode ?? 0) ^
    (state?.hashCode ?? 0) ^
    (zip?.hashCode ?? 0) ^
    (floor?.hashCode ?? 0) ^
    (room?.hashCode ?? 0);

  String? get analyticsValue {
    if ((name != null) && name!.isNotEmpty) {
      return name;
    }
    else if ((building != null) && building!.isNotEmpty) {
      return building;
    }
    else if ((fullAddress != null) && fullAddress!.isNotEmpty) {
      return fullAddress;
    }
    else if ((description != null) && description!.isNotEmpty) {
      return description;
    }
    else {
      return null;
    }
  }

  bool get isLocationCoordinateValid {
    return (latitude != null) && (latitude != 0) && (longitude != null) && (longitude != 0);
  }
}
