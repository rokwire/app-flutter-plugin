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

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path_package;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timezone/timezone.dart' as timezone;
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;

class StringUtils {

  static bool isEmpty(String? stringToCheck) {
    return (stringToCheck == null || stringToCheck.isEmpty);
  }

  static bool isNotEmpty(String? stringToCheck) {
    return !isEmpty(stringToCheck);
  }

  static String ensureNotEmpty(String? value, {String defaultValue = ''}) {
    if (isEmpty(value)) {
      return defaultValue;
    }
    return value!;
  }

  static String wrapRange(String s, String firstValue, String secondValue, int startPosition, int endPosition) {
    String word = s.substring(startPosition, endPosition);
    String wrappedWord = firstValue + word + secondValue;
    String updatedString = s.replaceRange(startPosition, endPosition, wrappedWord);
    return updatedString;
  }

  static String getMaskedPhoneNumber(String? phoneNumber) {
    if(StringUtils.isEmpty(phoneNumber)) {
      return "*********";
    }
    int phoneNumberLength = phoneNumber!.length;
    int lastXNumbers = math.min(phoneNumberLength, 4);
    int starsCount = (phoneNumberLength - lastXNumbers);
    String replacement = "*" * starsCount;
    String maskedPhoneNumber = phoneNumber.replaceRange(0, starsCount, replacement);
    return maskedPhoneNumber;
  }

  static String capitalize(String value, { bool allWords = false, Pattern splitDelimiter = ' ', String joinDelimiter = ' '}) {

    if (allWords) {
      List<String> words = value.split(splitDelimiter);
      List<String> result = <String>[];
      for (String word in words) {
        result.add(capitalize(word, allWords : false));
      }
      return result.join(joinDelimiter);
    }
    else {
      if (value.isEmpty) {
        return '';
      }
      else if (value.length == 1) {
        return value[0].toUpperCase();
      }
      else {
        return "${value[0].toUpperCase()}${value.substring(1).toLowerCase()}";
      }
    }

  }

  static String stripHtmlTags(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'&[^;]+;'), ' ');
  }

  static String? fullName(List<String?> names) {
    String? fullName;
    for (String? name in names) {
      if ((name != null) && name.isNotEmpty) {
        if (fullName == null) {
          fullName = name;
        }
        else {
          fullName += ' $name';
        }
      }
    }
    return fullName;
  }

  /// US Phone validation  https://github.com/rokwire/illinois-app/issues/47

  static const String _usPhonePattern1 = "^[2-9][0-9]{9}\$";          // Valid:   23456789120
  static const String _usPhonePattern2 = "^[1][2-9][0-9]{9}\$";       // Valid:  123456789120
  static const String _usPhonePattern3 = "^\\+[1][2-9][0-9]{9}\$";   // Valid: +123456789120

  static const String _phonePattern = "^((\\+?\\d{1,3})?[\\(\\- ]?\\d{3,5}[\\)\\- ]?)?(\\d[.\\- ]?\\d)+\$";   // Valid: +123456789120


  static bool isUsPhoneValid(String? phone){
    if(isNotEmpty(phone)){
      return (phone!.length == 10 && RegExp(_usPhonePattern1).hasMatch(phone))
          || (phone.length == 11 && RegExp(_usPhonePattern2).hasMatch(phone))
          || (phone.length == 12 && RegExp(_usPhonePattern3).hasMatch(phone));
    }
    return false;
  }

  static bool isUsPhoneNotValid(String? phone){
    return !isUsPhoneValid(phone);
  }

  static bool isPhoneValid(String? phone) {
    return isNotEmpty(phone) && RegExp(_phonePattern).hasMatch(phone!);
  }

  /// US Phone construction

  static String? constructUsPhone(String? phone){
    if(isUsPhoneValid(phone)){
      if(phone!.length == 10 && RegExp(_usPhonePattern1).hasMatch(phone)){
        return "+1$phone";
      }
      else if (phone.length == 11 && RegExp(_usPhonePattern2).hasMatch(phone)){
        return "+$phone";
      }
      else if (phone.length == 12 && RegExp(_usPhonePattern3).hasMatch(phone)){
        return phone;
      }
    }
    return null;
  }

  /// Email validation  https://github.com/rokwire/illinois-app/issues/47

  static const String _emailPattern = "^[a-zA-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*\$" ;

  static bool isEmailValid(String email){
    return isNotEmpty(email) && RegExp(_emailPattern).hasMatch(email);
  }

  /// UIN validation - 'XXXXXXXXX' where X is a number

  static const String _uinPattern = '[0-9]{9}';

  static bool isUinValid(String? uin) {
    return isNotEmpty(uin) && RegExp(_uinPattern).hasMatch(uin!);
  }

  static String base64UrlEncode(String value) => utf8.fuse(base64Url).encode(value);

  static String base64UrlDecode(String value) => utf8.fuse(base64Url).decode(value);
}

class CollectionUtils {
  static bool isNotEmpty(Iterable<Object?>? collection) {
    return collection != null && collection.isNotEmpty;
  }

  static bool isEmpty(Iterable<Object?>? collection) {
    return !isNotEmpty(collection);
  }

  static int length(Iterable<dynamic>? collection) {
    return collection?.length ?? 0;
  }

  static bool equals(dynamic e1, dynamic e2) =>
    const DeepCollectionEquality().equals(e1, e2);

  static Future<bool> equalsAsync(dynamic e1, dynamic e2) =>
    compute(_equals, _EqualsParam(e1, e2));

  static bool _equals(_EqualsParam param) =>
    equals(param.e1, param.e2);
}

class _EqualsParam {
  final dynamic e1;
  final dynamic e2;
  _EqualsParam(this.e1, this.e2);
}

class ListUtils {
  static List<T>? from<T>(Iterable<T>? elements) {
    return (elements != null) ? List<T>.from(elements) : null;
  }

  static List<T>? reversed<T>(List<T>? elements) {
    return (elements != null) ? List<T>.from(elements.reversed) : null;
  }

  static void add<T>(List<T>? list, T? entry) {
    if ((list != null) && (entry != null)) {
      list.add(entry);
    }
  }

  static T? entry<T>(List<T>? list, int index) {
    return ((list != null) && (0 <= index) && (index < list.length)) ? list[index] : null;
  }

  static bool? contains(Iterable<dynamic>? list, dynamic item, {bool checkAll = false}) {
    if (list == null) {
      return null;
    }
    if (item is Iterable<dynamic>) {
      for (dynamic val in item) {
        if (list.contains(val)) {
          if (!checkAll) {
            return true;
          }
        } else if (checkAll) {
          return false;
        }
      }
      return checkAll;
    }
    return list.contains(item);
  }

  static void sort<T>(List<T> list, int Function(T a, T b)? compare) =>
    list.sort(compare);

  static void _sort<T>(_SortListParam<T> param) =>
    param.list.sort(param.compare);

  static Future<void> sortAsync<T>(List<T> list, int Function(T a, T b)? compare) =>
    compute(_sort, _SortListParam(list, compare));
}

class _SortListParam<T> {
  final List<T> list;
  final int Function(T a, T b)? compare;
  _SortListParam(this.list, this.compare);
}

class SetUtils {
  static Set<T>? from<T>(Iterable<T>? elements) {
    return (elements != null) ? Set<T>.from(elements) : null;
  }

  static void add<T>(Set<T>? set, T? entry) {
    if ((set != null) && (entry != null)) {
      set.add(entry);
    }
  }

  static void toggle<T>(Set<T>? set, T? entry) {
    if ((set != null) && (entry != null)) {
      if (set.contains(entry)) {
        set.remove(entry);
      }
      else {
        set.add(entry);
      }
    }
  }
}

class LinkedHashSetUtils {
  static LinkedHashSet<T>? from<T>(Iterable<T>? elements) {
    return (elements != null) ? LinkedHashSet<T>.from(elements) : null;
  }

  static void add<T>(LinkedHashSet<T>? set, T? entry) {
    if ((set != null) && (entry != null)) {
      set.add(entry);
    }
  }

  static void toggle<T>(LinkedHashSet<T>? set, T? entry) {
    if ((set != null) && (entry != null)) {
      if (set.contains(entry)) {
        set.remove(entry);
      }
      else {
        set.add(entry);
      }
    }
  }
}

class MapUtils {

  static Map<K, T>? from<K, T>(Map<K, T>? other) {
    return (other != null) ? Map<K, T>.from(other) : null;
  }

  static T? get<K, T>(Map<K, T>? map, K? key) {
    return ((map != null) && (key != null)) ? map[key] : null;
  }

  static void set<K, T>(Map<K, T>? map, K? key, T? value) {
    if ((map != null) && (key != null)) {
      if (value != null) {
        map[key] = value;
      }
      else {
        map.remove(key);
      }
    }
  }

  static T? get2<K, T>(Map<K, T>? map, List<K?>? keys) {
    if ((map != null) && (keys != null)) {
      for (K? key in keys) {
        if (key != null) {
          T? value = map[key];
          if (value != null) {
            return value;
          }
        }
      }
    }
    return null;
  }

  static void merge(Map<String, dynamic> dest, Map<String, dynamic>? src, { int? level }) {
    src?.forEach((String key, dynamic srcV) {
      dynamic destV = dest[key];
      Map<String, dynamic>? destMapV = JsonUtils.mapValue(destV);
      Map<String, dynamic>? srcMapV = JsonUtils.mapValue(srcV);
      
      if (((level == null) || (0 < level)) && (destMapV != null) && (srcMapV != null)) {
        merge(destMapV, srcMapV, level: (level != null) ? (level - 1) : null);
      }
      else {
        dest[key] = _mergeClone(srcV, level: level);
      }
    });
  }

  static dynamic _mergeClone(dynamic value, { int? level }) {
    if ((value is Map) && ((level == null) || (0 < level))) {
      return value.map<String, dynamic>((key, item) =>
        MapEntry<String, dynamic>(key, _mergeClone(item, level: (level != null) ? (level - 1) : null)));
    }
    else {
      return value;
    }
  }

  static Map<K, T>? combine<K, T>(Map<K, T>? map1, Map<K, T>? map2, {bool copy = false}) {
    if (map1 != null) {
      if (map2 != null) {
        Map<K, T> combined = Map<K, T>.from(map1);
        combined.addAll(map2);
        return combined;
      }
      else {
        return copy ? Map<K, T>.from(map1) : map1;
      }
    }
    else {
      if (map2 != null) {
        return copy ? Map<K, T>.from(map2) : map2;
      }
      else {
        return null;
      }
    }
  }

}

class ColorUtils {
  static Color? fromHex(String? strValue) {
    if (strValue != null) {
      if (strValue.startsWith("#")) {
        strValue = strValue.substring(1);
      }
      
      int? intValue = int.tryParse(strValue, radix: 16);
      if (intValue != null) {
        if (strValue.length <= 6) {
          intValue += 0xFF000000;
        }
        
        return Color(intValue);
      }
    }
    return null;
  }

  static String toHex(Color value) {
    if (value.alpha < 0xFF) {
      return "#${value.alpha.toRadixString(16)}${value.red.toRadixString(16)}${value.green.toRadixString(16)}${value.blue.toRadixString(16)}";
    }
    else {
      return "#${value.red.toRadixString(16)}${value.green.toRadixString(16)}${value.blue.toRadixString(16)}";
    }
  }

  static int hueFromColor(Color color) => hueFromRGB(color.red, color.green, color.blue);

  static int hueFromRGB(int red, int green, int blue) {
    double min = math.min(math.min(red, green), blue).toDouble();
    double max = math.max(math.max(red, green), blue).toDouble();

    if (min == max) {
      return 0;
    }

    double hue = 0.0;
    if (max == red) {
      hue = (green - blue) / (max - min);
    }
    else if (max == green) {
      hue = 2.0 + (blue - red) / (max - min);
    }
    else {
      hue = 4.0 + (red - green) / (max - min);
    }

    hue = hue * 60;
    if (hue < 0) hue = hue + 360;

    return hue.round();
  }
}

class AppVersion {

  static int compareVersions(String? versionString1, String? versionString2) {
    List<String> versionList1 = (versionString1 is String) ? versionString1.split('.') : [];
    List<String> versionList2 = (versionString2 is String) ? versionString2.split('.') : [];
    int minLen = math.min(versionList1.length, versionList2.length);
    for (int index = 0; index < minLen; index++) {
      String s1 = versionList1[index], s2 = versionList2[index];
      int? n1 = int.tryParse(s1), n2 = int.tryParse(s2);
      int result = ((n1 != null) && (n2 != null)) ? n1.compareTo(n2) : s1.compareTo(s2);
      if (result != 0) {
        return result;
      }
    }
    if (versionList1.length < versionList2.length) {
      return -1;
    }
    else if (versionList1.length > versionList2.length) {
      return 1;
    }
    else {
      return 0;
    }
  }

  static bool matchVersions(String? versionString1, String? versionString2) {
    List<String> versionList1 = (versionString1 is String) ? versionString1.split('.') : [];
    List<String> versionList2 = (versionString2 is String) ? versionString2.split('.') : [];
    int minLen = math.min(versionList1.length, versionList2.length);
    for (int index = 0; index < minLen; index++) {
      String s1 = versionList1[index], s2 = versionList2[index];
      int? n1 = int.tryParse(s1), n2 = int.tryParse(s2);
      int result = ((n1 != null) && (n2 != null)) ? n1.compareTo(n2) : s1.compareTo(s2);
      if (result != 0) {
        return false;
      }
    }
    return true;
  }

  static String? majorVersion(String? versionString, int versionsLength) {
    if (versionString is String) {
      List<String> versionList = versionString.split('.');
      if (versionsLength < versionList.length) {
        versionList = versionList.sublist(0, versionsLength);
      }
      return versionList.join('.');
    }
    return null;
  }
}

class UrlUtils {  
  static String? getScheme(String? url) {
    try {
      Uri? uri = (url != null) ? Uri.parse(url) : null;
      return (uri != null) ? uri.scheme : null;
    } catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  static String? getHost(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    return (uri != null) ? (uri.host.isNotEmpty ? uri.host : (uri.path.isNotEmpty ? uri.path : null)) : null;
  }

  static String? getExt(String? url) {
    try {
      Uri? uri = (url != null) ? Uri.parse(url) : null;
      String? path = (uri != null) ? uri.path : null;
      return (path != null) ? path_package.extension(path) : null;
    } catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  static bool isPdf(String? url) {
    return (getExt(url) == '.pdf');
  }

  static bool isWebScheme(String? url) {
    String? scheme = getScheme(url);
    return (scheme == 'http') || (scheme == 'https');
  }

  static bool launchInternal(String? url) {
    return UrlUtils.isWebScheme(url) && !(Platform.isAndroid && UrlUtils.isPdf(url));
  }

  static Future<bool?> launchExternal(String? url) async {
    if (StringUtils.isNotEmpty(url)) {
      Uri? uri = Uri.tryParse(url!);
      if (uri != null) {
        return launchUrl(UrlUtils.fixUri(uri) ?? uri, mode: Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault);
      }
    }
    return null;
  }

  static String addQueryParameters(String url, Map<String, String> queryParameters) {
    if (StringUtils.isNotEmpty(url)) {
      Uri uri = Uri.parse(url);
      Map<String, String> urlParams = uri.queryParameters;
      queryParameters.addAll(urlParams);
      uri = uri.replace(queryParameters: queryParameters);
      url = uri.toString();
    }
    return url;
  }

  static bool isValidUrl(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    return (uri != null) && StringUtils.isNotEmpty(uri.scheme) && (StringUtils.isNotEmpty(uri.host) || StringUtils.isNotEmpty(uri.path));
  }

  static String? fixUrl(String url) {
    Uri? uri = Uri.tryParse(url);
    Uri? fixedUri = (uri != null) ? fixUri(uri) : null;
    return (fixedUri != null) ? fixedUri.toString() : null;
  }

  static Uri? fixUri(Uri uri) {
    return uri.scheme.isEmpty ? Uri(
      scheme: 'http',
      userInfo: uri.userInfo.isNotEmpty ? uri.userInfo : null,
      host: uri.host.isNotEmpty ? uri.host : (uri.path.isNotEmpty ? uri.path : null),
      port: (0 < uri.port) ? uri.port : null,
      path: (uri.host.isNotEmpty && uri.path.isNotEmpty) ? uri.path : null,
      //pathSegments: uri.pathSegments.isNotEmpty ? uri.pathSegments : null,
      query: uri.query.isNotEmpty ? uri.query : null,
      //queryParameters: uri.queryParameters.isNotEmpty ? uri.queryParameters : null,
      fragment: uri.fragment.isNotEmpty ? uri.fragment : null) : null;
  }

  static Future<bool> isHostAvailable(String? url) async {
    List<InternetAddress>? result;
    String? host = getHost(url);
    try {
      result = (host != null) ? await InternetAddress.lookup(host) : null;
    }
    on SocketException catch (e) {
      debugPrint(e.toString());
    }
    return ((result != null) && result.isNotEmpty && result.first.rawAddress.isNotEmpty);
  }

}


class JsonUtils {

  static String? encode(dynamic value, { bool? prettify }) =>
    ((prettify == true) ? _prettify : _encode)(value);

  static Future<String?> encodeAsync(dynamic value, { bool? prettify }) =>
    compute((prettify == true) ? _prettify : _encode, value);

  static String? _encode(dynamic value) {
    try { return (value != null) ? json.encode(value) : null; }
    catch (e) { debugPrint(e.toString());}
    return null;
  }

  static String? _prettify(dynamic value) {
    try { return (value != null) ? const JsonEncoder.withIndent("  ").convert(value) : null; }
    catch (e) { debugPrint(e.toString()); }
    return null;
  }

  // TBD: Use everywhere decodeMap or decodeList to guard type cast
  static dynamic decode(String? jsonString) {
    dynamic jsonContent;
    if (StringUtils.isNotEmpty(jsonString)) {
      try {
        jsonContent = json.decode(jsonString!);
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return jsonContent;
  }

  static Future<dynamic> decodeAsync(String? jsonString) =>
    compute(decode, jsonString);

  static List<dynamic>? decodeList(String? jsonString) {
    try {
      return (decode(jsonString) as List?)?.cast<dynamic>();
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  static Future<List<dynamic>?> decodeListAsync(String? jsonString) =>
    compute(decodeList, jsonString);

  static Map<String, dynamic>? decodeMap(String? jsonString) {
    try {
      return (decode(jsonString) as Map?)?.cast<String, dynamic>();
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  static Future<Map<String, dynamic>?> decodeMapAsync(String? jsonString) =>
    compute(decodeMap, jsonString);

  static String? stringValue(dynamic value) {
    if (value is String) {
      return value;
    }
    else if (value != null) {
      try {
        return value.toString();
      }
      catch(e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  static int? intValue(dynamic value) {
    return (value is int) ? value : null;
  }

  static bool? boolValue(dynamic value) {
    return (value is bool) ? value : null;
  }

  static double? doubleValue(dynamic value) {
    if (value is double) {
      return value;
    }
    else if (value is int) {
      return value.toDouble();
    }
    else if (value is String) {
      return double.tryParse(value);
    }
    else {
      return null;
    }
  }

  static Map<String, dynamic>? mapValue(dynamic value) {
    try {
      return (value is Map) ? value.cast<String, dynamic>() : null;
    }
    catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  static List<T>? listValue<T>(dynamic value) {
    try {
      return (value is List) ? value.cast<T>() : null;
    }
    catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  static Set<T>? setValue<T>(dynamic value) {
    try {
      return (value is Set) ? value.cast<T>() : null;
    }
    catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  static LinkedHashSet<T>? linkedHashSetValue<T>(dynamic value) {
    Set<T>? set = setValue(value);
    return (set != null) ? LinkedHashSet.from(set) : null;
  }

  static List<String>? stringListValue(dynamic value) {
    List<String>? result;
    if (value is List) {
      result = <String>[];
      for (dynamic entry in value) {
        result.add(entry.toString());
      }
    }
    return result;
  }

  static Set<String>? stringSetValue(dynamic value) {
    Set<String>? result;
    if (value is List) {
      result = <String>{};
      for (dynamic entry in value) {
        result.add(entry.toString());
      }
    }
    return result;
  }
  
  static List<String>? listStringsValue(dynamic value) {
    try {
      if (value is List) {
        return value.cast<String>();
      }
      else if (value is Set) {
        return List<String>.from(value.cast<String>());
      }
    }
    catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  static List<int>? listIntsValue(dynamic value) {
    try {
      if (value is List) {
        return value.cast<int>();
      }
      else if (value is Set) {
        return List<int>.from(value.cast<int>());
      }
    }
    catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  static Set<String>? setStringsValue(dynamic value) {
    try {
      if (value is Set) {
        return value.cast<String>();
      }
      else if (value is List) {
        return Set<String>.from(value.cast<String>());
      }
    }
    catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  static LinkedHashSet<String>? linkedHashSetStringsValue(dynamic value) {
    try {
      return (value is List) ? LinkedHashSet<String>.from(value.cast<String>()) : null;
    }
    catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  static Map<String, LinkedHashSet<String>>? mapOfStringToLinkedHashSetOfStringsValue(dynamic value) {
    Map<String, LinkedHashSet<String>>? result;
    if (value is Map) {
      result = <String, LinkedHashSet<String>>{};
      for (dynamic key in value.keys) {
        if (key is String) {
          MapUtils.set(result, key, linkedHashSetStringsValue(value[key]));
        }
      }
    }
    return result;
  }

  static Map<String, dynamic>? mapOfStringToLinkedHashSetOfStringsJsonValue(Map<String, LinkedHashSet<String>>? contentMap) {
    Map<String, dynamic>? jsonMap;
    if (contentMap != null) {
      jsonMap = <String, dynamic>{};
      for (String key in contentMap.keys) {
        jsonMap[key] = List.from(contentMap[key]!);
      }
    }
    return jsonMap;
  }

  static Map<String, Set<String>>? mapOfStringToSetOfStringsValue(dynamic value) {
    Map<String, Set<String>>? result;
    if (value is Map) {
      result = <String, Set<String>>{};
      for (dynamic key in value.keys) {
        if (key is String) {
          MapUtils.set(result, key, JsonUtils.setStringsValue(value[key]));
        }
      }
    }
    return result;
  }


  static Map<String, dynamic>? mapOfStringToSetOfStringsJsonValue(Map<String, Set<String>>? contentMap) {
    Map<String, dynamic>? jsonMap;
    if (contentMap != null) {
      jsonMap = <String, dynamic>{};
      for (String key in contentMap.keys) {
        jsonMap[key] = List.from(contentMap[key]!);
      }
    }
    return jsonMap;
  }

  static T? mapOrNull<T>(T Function(Map<String, dynamic>) construct, dynamic json) {
    if (json is Map<String, dynamic>) {
      return construct(json);
    }
    return null;
  }

  static T? listOrNull<T>(T Function(List<dynamic>) construct, dynamic json) {
    if (json is List<dynamic>) {
      return construct(json);
    }
    return null;
  }

  static List<double>? doubleListValue(dynamic value) {
    List<double>? result;
    if (value is List) {
      result = [];
      for (dynamic entry in value) {
        double? val = JsonUtils.doubleValue(entry);
        if (val == null) {
          return null;
        }
        result.add(val);
      }
    }
    return result;
  }

  static Duration? durationValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Duration(days: value['days'] ?? 0, hours: value['hours'] ?? 0, minutes: value['minutes'] ?? 0, seconds: value['seconds'] ?? 0, milliseconds: value['milliseconds'] ?? 0, microseconds: value['microseconds'] ?? 0);
    }
    return null;
  }
}

class AppToast {
  static void show(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
      timeInSecForIosWeb: 3,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0x99000000),
    );
  }
}

class MapPathKey {

  static const String pathDelimiter = '.';

  static dynamic entry(Map<String, dynamic>? map, dynamic key) {
    if ((map != null) && (key != null)) {
      if (key is String) {
        return _pathKeyEntry(map, key);
      }
      else if (key is List) {
        return _listKeyEntry(map, key);
      }
    }
    return null;
  }
  
  static dynamic _pathKeyEntry(Map map, String key) {
    String field;
    dynamic entry;
    int position, start = 0;
    Map source = map;

    while (0 <= (position = key.indexOf(pathDelimiter, start))) {
      field = key.substring(start, position);
      entry = source[field];
      if ((entry != null) && (entry is Map)) {
        source = entry;
        start = position + pathDelimiter.length;
      }
      else {
        break;
      }
    }

    if (0 < start) {
      field = key.substring(start);
      return source[field];
    }
    else {
      return source[key];
    }
  }

  static dynamic _listKeyEntry(Map map, List keys) {
    dynamic entry;
    Map source = map;
    for (dynamic key in keys) {
      entry = source[key];

      if (entry is Map) {
        source = entry;
      }
      else {
        return null;
      }
    }

    return source;
  }

}

class SortUtils {

  static int compare<T>(T? v1, T? v2, { bool descending = false}) {
    int result;
    if (v1 is Comparable<T>) {
      result = (v2 is Comparable<T>) ? v1.compareTo(v2) : -1;
    }
    else {
      result = (v2 is Comparable<T>) ? 1 : 0;
    }
    return descending ? -result : result;
  }

  static void sort<T>(List<T>? list, { bool descending = false}) {
    list?.sort((T t1, T t2) => compare(t1, t2, descending: descending));
  }
}

class GeometryUtils {

  static Size scaleSizeToFit(Size size, Size boundsSize) {
    double fitW = boundsSize.width;
    double fitH = boundsSize.height;
    double ratioW = (0.0 < boundsSize.width) ? (size.width / boundsSize.width) : double.maxFinite;
    double ratioH = (0.0 < boundsSize.height) ? (size.height / boundsSize.height) : double.maxFinite;
    if(ratioW < ratioH) {
      fitW = (0.0 < size.height) ? (size.width * boundsSize.height / size.height) : boundsSize.width;
    }
    else if(ratioH < ratioW) {
      fitH = (0.0 < size.width) ? (size.height * boundsSize.width / size.width) : boundsSize.height;
    }
    return Size(fitW, fitH);
  }

  static Size scaleSizeToFill(Size size, Size boundsSize) {
    double fitW = boundsSize.width;
    double fitH = boundsSize.height;
    double ratioW = (0.0 < boundsSize.width) ? (size.width / boundsSize.width) : double.maxFinite;
    double ratioH = (0.0 < boundsSize.height) ? (size.height / boundsSize.height) : double.maxFinite;
    if(ratioW < ratioH) {
  		fitH = (0.0 < size.width) ? (size.height * boundsSize.width / size.width) : boundsSize.height;
    }
    else if(ratioH < ratioW) {
  		fitW = (0.0 < size.height) ? (size.width * boundsSize.height / size.height) : boundsSize.width;
    }
    return Size(fitW, fitH);
  }
}

class BoolExpr {
  
  static bool eval(dynamic expr, bool? Function(String?)? evalArg) {
    
    if (expr is String) {

      if (expr == 'TRUE') {
        return true;
      }
      if (expr == 'FALSE') {
        return false;
      }

      bool? argValue = (evalArg != null) ? evalArg(expr) : null;
      return argValue ?? true; // allow everything that is not defined or we do not understand
    }

    else if (expr is bool) {
      
      return expr;
    
    }
    
    else if (expr is List) {
      
      if (expr.length == 1) {
        return eval(expr[0], evalArg);
      }
      
      if (expr.length == 2) {
        dynamic operation = expr[0];
        dynamic argument = expr[1];
        if (operation is String) {
          if (operation == 'NOT') {
            return !eval(argument, evalArg);
          }
        }
      }

      if (expr.length > 2) {
        bool result = eval(expr[0], evalArg);
        for (int index = 1; (index + 1) < expr.length; index += 2) {
          dynamic operation = expr[index];
          dynamic argument = expr[index + 1];
          if (operation is String) {
            if (operation == 'AND') {
              result = result && eval(argument, evalArg);
            }
            else if (operation == 'OR') {
              result = result || eval(argument, evalArg);
            }
          }
        }
        return result;
      }
    }
    
    return true; // allow everything that is not defined or we do not understand
  }
}

class AppBundle {
  
  static Future<String?> loadString(String key, {bool cache = true}) async {
    try { return await rootBundle.loadString(key, cache: cache); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  static Future<ByteData?> loadBytes(String key) async {
    try { return await rootBundle.load(key); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }
}


class HtmlUtils {
  static String replaceNewLineSymbols(String? value) {
    if (StringUtils.isEmpty(value)) {
      return value!;
    }
    return value!.replaceAll('\r\n', '</br>').replaceAll('\n', '</br>');
  }
}

enum DayPart { morning, afternoon, evening, night }

String? dayPartToString(DayPart? dayPart) {
  switch(dayPart) {
    case DayPart.morning: return "morning";
    case DayPart.afternoon: return "afternoon";
    case DayPart.evening: return "evening";
    case DayPart.night: return "night";
    default: return null;
  }
}

DayPart? dayPartFromString(String? value) {
  switch(value) {
    case "morning": return DayPart.morning;
    case "afternoon": return DayPart.afternoon;
    case "evening": return DayPart.evening;
    case "night": return DayPart.night;
    default: return null;
  }
}

class DateTimeUtils {

  static const String defaultDateTimeFormat = 'yyyy-MM-ddTHH:mm:ss.SSS';

  static DateTime? dateTimeFromString(String? dateTimeString, {String? format, bool isUtc = false}) {
    if (StringUtils.isEmpty(dateTimeString)) {
      return null;
    }
    DateTime? dateTime;
    try {
      dateTime = StringUtils.isNotEmpty(format) ?
        DateFormat(format).parse(dateTimeString!, isUtc) :
        DateTime.tryParse(dateTimeString!);
    }
    on Exception catch (e) {
      debugPrint(e.toString());
    }
    return dateTime;
  }

  static String? utcDateTimeToString(DateTime? dateTime, { String format =  defaultDateTimeFormat }) {
    return (dateTime != null) ? (DateFormat(format).format(dateTime.isUtc ? dateTime : dateTime.toUtc()) + 'Z') : null;
  }

  static String? localDateTimeToString(DateTime? dateTime, { String format = defaultDateTimeFormat }) {
    return (dateTime != null) ? (DateFormat(format).format(dateTime.toLocal())) : null;
  }

  static DateTime? dateTimeFromSecondsSinceEpoch(int? seconds) =>
    (seconds != null) ? DateTime.fromMillisecondsSinceEpoch(seconds * 1000) : null;

  static int? dateTimeToSecondsSinceEpoch(DateTime? dateTime) =>
    (dateTime != null) ? (dateTime.millisecondsSinceEpoch ~/ 1000) : null;


  static int getWeekDayFromString(String weekDayName){
    switch (weekDayName){
      case "monday"   : return 1;
      case "tuesday"  : return 2;
      case "wednesday": return 3;
      case "thursday" : return 4;
      case "friday"   : return 5;
      case "saturday" : return 6;
      case "sunday"   : return 7;
      default: return 0;
    }
  }

  static DayPart getDayPart({DateTime? dateTime}) {
    int hour = (dateTime ?? DateTime.now()).hour;
    if (hour < 6) {
      return DayPart.night;
    }
    else if ((6 <= hour) && (hour < 12)) {
      return DayPart.morning;
    }
    else if ((12 <= hour) && (hour < 17)) {
      return DayPart.afternoon;
    }
    else if ((17 <= hour) && (hour < 20)) {
      return DayPart.evening;
    }
    else /* if (20 <= hour) */ {
      return DayPart.night;
    }
  }

  static DateTime? midnight(DateTime? date) {
    return (date != null) ? DateTime(date.year, date.month, date.day) : null;
  }

  static DateTime dayStart(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime dayEnd(DateTime date) {
    return dayStart(date).add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
  }

  static DateTime nowTimezone(timezone.Location? location) {
    DateTime now = DateTime.now();
    if (location != null) {
      return timezone.TZDateTime.from(now, location);
    }
    return now;
  }

  static bool isToday(DateTime? date, {DateTime? now, timezone.Location? location}) {
    if (date == null) {
      return false;
    }
    now ??= nowTimezone(location);
    return now.day == date.day && now.month == date.month && now.year == date.year;
  }

  static bool isYesterday(DateTime? date, {DateTime? now, timezone.Location? location}) {
    if (date == null) {
      return false;
    }
    now ??= nowTimezone(location);
    DateTime yesterday = now.subtract(const Duration(days: 1));
    return yesterday.day == date.day && yesterday.month == date.month && yesterday.year == date.year;
  }

  static bool isTomorrow(DateTime? date, {DateTime? now, timezone.Location? location}) {
    if (date == null) {
      return false;
    }
    now ??= nowTimezone(location);
    DateTime tomorrow = now.add(const Duration(days: 1));
    return tomorrow.day == date.day && tomorrow.month == date.month && tomorrow.year == date.year;
  }

  static bool isThisWeek(DateTime? date, {DateTime? now, timezone.Location? location}) {
    return isInRange(date, start: weekStart(now: now, location: location), end: weekEnd(now: now, location: location));
  }

  static DateTime weekStart({DateTime? now, timezone.Location? location}) {
    now ??= nowTimezone(location);
    DateTime today = dayStart(now);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  static DateTime weekEnd({DateTime? now, timezone.Location? location}) {
    return weekStart(now: now, location: location).add(const Duration(days: 7)).subtract(const Duration(microseconds: 1));
  }

  static bool isInRange(DateTime? date, {DateTimeRange? range, DateTime? start, DateTime? end}) {
    if (date == null) {
      return false;
    }
    if (range != null && date.isAfter(range.start) && date.isBefore(range.end)) {
      return true;
    }
    if (start != null && end != null && date.isAfter(start) && date.isBefore(end)) {
      return true;
    }
    return false;
  }
  
  static timezone.TZDateTime? changeTimeZoneToDate(DateTime time, timezone.Location location) {
    try{
     return timezone.TZDateTime(location,time.year,time.month,time.day, time.hour, time.minute);
    } catch(e){
      debugPrint(e.toString());
    }
    return null;
  }

  static DateTime copyDateTime(DateTime date){
    return DateTime(date.year, date.month, date.day, date.hour, date.minute, date.second);
  }

  static DateTime? parseDateTime(String dateTimeString, {String? format, bool isUtc = false}) {
    if (StringUtils.isNotEmpty(dateTimeString)) {
      if (StringUtils.isNotEmpty(format)) {
        try {
          return DateFormat(format).parse(dateTimeString, isUtc);
        }
        catch (e) {
          debugPrint(e.toString());
        }
      }
      else {
        return DateTime.tryParse(dateTimeString);
      }
    }
    return null;
  }

  static Duration? parseDelimitedDurationString(String durationString, Pattern delimiter) {
    List<String> durationParts = durationString.split(delimiter);
    if (CollectionUtils.isEmpty(durationParts)) {
      return null;
    }

    int days = int.tryParse(durationParts[0]) ?? 0;
    int hours = durationParts.length > 1 ? int.tryParse(durationParts[1]) ?? 0 : 0;
    int minutes = durationParts.length > 2 ? int.tryParse(durationParts[2]) ?? 0 : 0;
    int seconds = durationParts.length > 3 ? int.tryParse(durationParts[3]) ?? 0 : 0;
    int milliseconds = durationParts.length > 4 ? int.tryParse(durationParts[4]) ?? 0 : 0;
    int microseconds = durationParts.length > 5 ? int.tryParse(durationParts[5]) ?? 0 : 0;
    return Duration(days: days, hours: hours, minutes: minutes, seconds: seconds, milliseconds: milliseconds, microseconds: microseconds);
  }

  static DateTime min(DateTime v1, DateTime v2) => (v1.isBefore(v2)) ? v1 : v2;
  static DateTime max(DateTime v1, DateTime v2) => (v1.isAfter(v2)) ? v1 : v2;
}

class TZDateTimeUtils {
  static timezone.TZDateTime dateOnly(timezone.TZDateTime dateTime, { timezone.Location? location, bool inclusive = false }) =>
    dateTime.dateOnly(location: location, inclusive: inclusive);

  static timezone.TZDateTime startOfNextMonth(timezone.TZDateTime dateTime, { timezone.Location? location }) =>
    dateTime.startOfNextMonth(location: location);

  static timezone.TZDateTime endOfThisMonth(timezone.TZDateTime dateTime, { timezone.Location? location }) =>
    dateTime.endOfThisMonth(location: location);

  static dynamic toJson(timezone.TZDateTime? dateTime) =>
    dateTime?.toJson;

  static timezone.TZDateTime? fromJson(dynamic json) =>
    TZDateTimeExt.fromJson(json);

  static timezone.TZDateTime? copyFromDateTime(DateTime? time, timezone.Location location) =>
    (time != null) ? timezone.TZDateTime.from(time, location) : null;


  static timezone.TZDateTime min(timezone.TZDateTime v1, timezone.TZDateTime v2) => (v1.isBefore(v2)) ? v1 : v2;
  static timezone.TZDateTime max(timezone.TZDateTime v1, timezone.TZDateTime v2) => (v1.isAfter(v2)) ? v1 : v2;
}

extension TZDateTimeExt on timezone.TZDateTime {
  timezone.TZDateTime dateOnly({ timezone.Location? location, bool inclusive = false }) =>
    timezone.TZDateTime(location ?? this.location, year, month, day, inclusive ? 23 : 0, inclusive ? 59 : 0, inclusive ? 59 : 0);

  timezone.TZDateTime startOfNextMonth({ timezone.Location? location }) => (month < 12) ?
    timezone.TZDateTime(location ?? this.location, year, month + 1, 1) :
    timezone.TZDateTime(location ?? this.location, year + 1, 1, 1);

  timezone.TZDateTime endOfThisMonth({ timezone.Location? location }) =>
    startOfNextMonth(location: location).subtract(const Duration(days: 1)).dateOnly(inclusive: true);

  toJson() => {
    'location': location.name,
    'timestamp': millisecondsSinceEpoch
  };

  static timezone.TZDateTime? fromJson(dynamic json) {
    if (json is Map) {
      String? locationName = JsonUtils.stringValue(json['location']);
      timezone.Location? location = (locationName != null) ? timezone.getLocation(locationName) : null;
      int? timestamp = JsonUtils.intValue(json['timestamp']);
      if ((location != null) && (timestamp != null)) {
        return timezone.TZDateTime.fromMillisecondsSinceEpoch(location, timestamp);
      }
    }
    return null;
  }
}

class WebUtils {
  static String getCookie(String name) {
    String? cookie = html.document.cookie;
    if (StringUtils.isNotEmpty(cookie)) {
      for (String item in cookie!.split(";")) {
        final split = item.split("=");
        if (split[0].trim() == name) {
          return split[1];
        }
      }
    }
    return "";
  }
}

class Pair<L,R> {
  final L left;
  final R right;

  Pair(this.left, this.right);

  @override
  String toString() => 'Pair[$left, $right]';
}
