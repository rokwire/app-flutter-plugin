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

class Explore implements Comparable<Explore> {

  String?   get exploreId => null;
  String?   get exploreTitle => null;
  String?   get exploreLongDescription => null;
  DateTime? get exploreStartDateUtc => null;
  String?   get exploreImageURL => null;
  ExploreLocation? get exploreLocation => null;

  @override
  int compareTo(Explore other) {
    return ((exploreStartDateUtc != null) && (other.exploreStartDateUtc != null)) ?
      SortUtils.compare(exploreStartDateUtc, other.exploreStartDateUtc) :
      SortUtils.compare(exploreTitle, other.exploreTitle);
  }
}

//////////////////////////////
/// ExploreLocation

class ExploreLocation {
  String? locationId;
  String? name;
  String? building;
  String? address;
  String? city;
  String? state;
  String? zip;
  num? latitude;
  num? longitude;
  int? floor;
  String? description;

  ExploreLocation(
      {this.locationId,
      this.name,
      this.building,
      this.address,
      this.city,
      this.state,
      this.zip,
      this.latitude,
      this.longitude,
      this.floor,
      this.description});

  static ExploreLocation? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ExploreLocation(
      locationId: JsonUtils.stringValue(json['locationId']),
      name: JsonUtils.stringValue(json['name']),
      building: JsonUtils.stringValue(json['building']),
      address: JsonUtils.stringValue(json['address']),
      city: JsonUtils.stringValue(json['city']),
      state: JsonUtils.stringValue(json['state']),
      zip: JsonUtils.stringValue(json['zip']),
      latitude: JsonUtils.doubleValue(json['latitude']),
      longitude: JsonUtils.doubleValue(json['longitude']),
      floor: JsonUtils.intValue(json['floor']),
      description: JsonUtils.stringValue(json['description'])) : null;
  }

  toJson() {
    return {
      "locationId": locationId,
      "name": name,
      "building": building,
      "address": address,
      "city": city,
      "state": state,
      "zip": zip,
      "latitude": latitude,
      "longitude": longitude,
      "floor": floor,
      "description": description
    };
  }

  @override
  bool operator ==(other) => (other is ExploreLocation) &&
    (other.locationId == locationId) &&
    (other.name == name) &&
    (other.building == building) &&
    (other.address == address) &&
    (other.city == city) &&
    (other.state == state) &&
    (other.zip == zip) &&
    (other.latitude == latitude) &&
    (other.longitude == longitude) &&
    (other.floor == floor) &&
    (other.description == description);

  @override
  int get hashCode =>
    (locationId?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (building?.hashCode ?? 0) ^
    (address?.hashCode ?? 0) ^
    (city?.hashCode ?? 0) ^
    (state?.hashCode ?? 0) ^
    (zip?.hashCode ?? 0) ^
    (latitude?.hashCode ?? 0) ^
    (longitude?.hashCode ?? 0) ^
    (floor?.hashCode ?? 0) ^
    (description?.hashCode ?? 0);

  String getDisplayName() {
    String displayText = "";

    if ((name != null) && name!.isNotEmpty) {
      if (displayText.isNotEmpty) {
        displayText += ", ";
      }
      displayText += name!;
    }

    if ((building != null) && building!.isNotEmpty) {
      if (displayText.isNotEmpty) {
        displayText += ", ";
      }
      displayText += building!;
    }

    return displayText;
  }

  String getDisplayAddress() {
    String displayText = "";

    if ((address != null) && address!.isNotEmpty) {
      if (displayText.isNotEmpty) {
        displayText += ", ";
      }
      displayText += address!;
    }

    if ((city != null) && city!.isNotEmpty) {
      if (displayText.isNotEmpty) {
        displayText += ", ";
      }
      displayText += city!;
    }

    String delimiter = ", ";

    if ((state != null) && state!.isNotEmpty) {
      if (displayText.isNotEmpty) {
        displayText += ", ";
      }
      displayText += state!;
      delimiter = " ";
    }

    if ((zip != null) && zip!.isNotEmpty) {
      if (displayText.isNotEmpty) {
        displayText += delimiter;
      }
      displayText += zip!;
    }

    return displayText;
  }

  String? get coordinatesString =>
    ((latitude != null) && (longitude != null)) ? "[$latitude, $longitude]" : null;

  String? get displayCoordinates =>
    ((latitude != null) && (longitude != null)) ? "[${latitude?.toStringAsFixed(6)}, ${longitude?.toStringAsFixed(6)}]" : null;


  String? get analyticsValue {
    if ((name != null) && name!.isNotEmpty) {
      return name;
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
