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

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class Styles extends Service implements NotificationsListener{
  
  static const String notifyChanged    = "edu.illinois.rokwire.styles.changed";
  
  static const String _assetsName       = "styles.json";
  static const String _debugAssetsName  = "styles.debug.json";

  
  Directory? _assetsDir;
  DateTime?  _pausedDateTime;

  Map<String, dynamic>? _assetsStyles;
  Map<String, dynamic>? _appAssetsStyles;
  Map<String, dynamic>? _netAssetsStyles;
  Map<String, dynamic>? _debugAssetsStyles;

  UiColors? _colors;
  UiColors? get colors => _colors;

  UiFontFamilies? _fontFamilies;
  UiFontFamilies? get fontFamilies => _fontFamilies;

  UiTextStyles? _textStyles;
  UiTextStyles? get textStyles => _textStyles;

  UiImages? _uiImages;
  UiImages? get uiImages => _uiImages;

  // Singletone Factory

  static Styles? _instance;

  static Styles? get instance => _instance;
  
  @protected
  static set instance(Styles? value) => _instance = value;

  factory Styles() => _instance ?? (_instance = Styles.internal());

  @protected
  Styles.internal();

  // Initialization

  @override
  void createService() {
    NotificationService().subscribe(this, AppLivecycle.notifyStateChanged);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    
    _assetsDir = await getAssetsDir();
    _assetsStyles = await loadFromAssets(assetsKey);
    _appAssetsStyles = await loadFromAssets(appAssetsKey);
    _netAssetsStyles = await loadFromCache(netCacheFileName);
    _debugAssetsStyles = await loadFromCache(debugCacheFileName);

    if ((_assetsStyles != null) || (_appAssetsStyles != null) || (_netAssetsStyles != null) || (_debugAssetsStyles != null)) {
      build();
      updateFromNet();
      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.fatal,
        title: 'Styles Configuration Initialization Failed',
        description: 'Failed to initialize application styles configuration.',
      );
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Config() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          updateFromNet();
        }
      }
    }
  }

  // Implementation

  @protected
  Future<Directory?> getAssetsDir() async {
    Directory? assetsDir = Config().assetsCacheDir;
    if ((assetsDir != null) && !await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    return assetsDir;
  }

  @protected
  String get assetsKey => 'assets/$_assetsName';

  @protected
  String get appAssetsKey => 'app/assets/$_assetsName';

  @protected
  Future<Map<String, dynamic>?> loadFromAssets(String assetsKey) async {
    try { return JsonUtils.decodeMap(await rootBundle.loadString(assetsKey)); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  @protected
  String get netCacheFileName => _assetsName;

  @protected
  String get debugCacheFileName => _debugAssetsName;

  @protected
  Future<Map<String, dynamic>?> loadFromCache(String cacheFileName) async {
    try { 
      if (_assetsDir != null) {
        String cacheFilePath = join(_assetsDir!.path, cacheFileName);
        File cacheFile = File(cacheFilePath);
        if (await cacheFile.exists()) {
          return JsonUtils.decodeMap(await cacheFile.readAsString());
        }
      }
    }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  @protected
  Future<void> saveToCache(String cacheFileName, String? content) async {
    try { 
      if (_assetsDir != null) {
        String cacheFilePath = join(_assetsDir!.path, cacheFileName);
        File cacheFile = File(cacheFilePath);
        if (content != null) {
          cacheFile.writeAsString(content, flush: true);
        }
        else if (await cacheFile.exists()) {
          await cacheFile.delete();
        }
      }
    }
    catch(e) { debugPrint(e.toString()); }
  }

  @protected
  String get netAssetFileName => _assetsName;

  @protected
  Future<String?> loadContentStringFromNet() async {
    if (Config().assetsUrl != null) {
      http.Response? response = await Network().get("${Config().assetsUrl}/$netAssetFileName");
      return (response?.statusCode == 200) ? response?.body : null;
    }
    return null;
  }

  @protected
  Future<void> updateFromNet() async {
    String? netAssetsString = await loadContentStringFromNet();
    Map<String, dynamic>? netAssetsStyles = JsonUtils.decodeMap(netAssetsString);
    if (((netAssetsStyles != null) && !const DeepCollectionEquality().equals(netAssetsStyles, _netAssetsStyles)) ||
        ((netAssetsStyles == null) && (_netAssetsStyles != null)))
    {
      _netAssetsStyles = netAssetsStyles;
      await saveToCache(netCacheFileName, netAssetsString);
      build();
      NotificationService().notify(notifyChanged, null);
    }
  }

  @protected
  void build() {
    Map<String, dynamic> styles = contentMap;
    _colors = UiColors.fromJson(JsonUtils.mapValue(styles['color']));
    _fontFamilies = UiFontFamilies.fromJson(JsonUtils.mapValue(styles['font_family']));
    _textStyles = UiTextStyles(JsonUtils.mapValue(styles['text_style']), colors: _colors);
    _uiImages = UiImages(imageMap: JsonUtils.mapValue(styles['image']), colors: _colors);
  }

  Map<String, dynamic> get contentMap {
    Map<String, dynamic> stylesMap = <String, dynamic>{};
    _StyleUtils.merge(stylesMap, _assetsStyles, level: 1);
    _StyleUtils.merge(stylesMap, _appAssetsStyles, level: 1);
    _StyleUtils.merge(stylesMap, _netAssetsStyles, level: 1);
    _StyleUtils.merge(stylesMap, _debugAssetsStyles, level: 1);
    return stylesMap;
  }

  Map<String, dynamic>? get debugMap => _debugAssetsStyles;

  set debugMap(Map<String, dynamic>? value) {
    if (((value != null) && !const DeepCollectionEquality().equals(_debugAssetsStyles, value)) ||
        ((value == null) && (_debugAssetsStyles != null)))
      {
        _debugAssetsStyles = value;
        build();
        NotificationService().notify(notifyChanged, null);
        saveToCache(netCacheFileName, JsonUtils.encode(_debugAssetsStyles));
      }
  }

}

class UiColors {

  final Map<String, Color> colorMap;

  UiColors(this.colorMap);

  static UiColors? fromJson(Map<String, dynamic>? json) {
    Map<String, Color> colors = <String, Color>{};
    json?.forEach((String key, dynamic value) {
      if ((value is String) && value.startsWith("#")) {
        Color? color = UiColors.fromHex(value);
        if (color != null) {
          colors[key] = color;
        }
      }
    });
    return UiColors(colors);
  }

  Color? get fillColorPrimary                   => colorMap['fillColorPrimary'];
  Color? get fillColorPrimaryTransparent03      => colorMap['fillColorPrimaryTransparent03'];
  Color? get fillColorPrimaryTransparent05      => colorMap['fillColorPrimaryTransparent05'];
  Color? get fillColorPrimaryTransparent09      => colorMap['fillColorPrimaryTransparent09'];
  Color? get fillColorPrimaryTransparent015     => colorMap['fillColorPrimaryTransparent015'];
  Color? get textColorPrimary                   => colorMap['textColorPrimary'];
  Color? get fillColorPrimaryVariant            => colorMap['fillColorPrimaryVariant'];
  Color? get textColorPrimaryVariant            => colorMap['textColorPrimaryVariant'];
  Color? get fillColorSecondary                 => colorMap['fillColorSecondary'];
  Color? get fillColorSecondaryTransparent05    => colorMap['fillColorSecondaryTransparent05'];
  Color? get textColorSecondary                 => colorMap['textColorSecondary'];
  Color? get fillColorSecondaryVariant          => colorMap['fillColorSecondaryVariant'];
  Color? get textColorSecondaryVariant          => colorMap['textColorSecondaryVariant'];

  Color? get surface                    => colorMap['surface'];
  Color? get textSurface                => colorMap['textSurface'];
  Color? get textSurfaceTransparent15   => colorMap['textSurfaceTransparent15'];
  Color? get surfaceAccent              => colorMap['surfaceAccent'];
  Color? get surfaceAccentTransparent15 => colorMap['surfaceAccentTransparent15'];
  Color? get textSurfaceAccent          => colorMap['textSurfaceAccent'];
  Color? get background                 => colorMap['background'];
  Color? get textBackground             => colorMap['textBackground'];
  Color? get backgroundVariant          => colorMap['backgroundVariant'];
  Color? get textBackgroundVariant      => colorMap['textBackgroundVariant'];

  Color? get accentColor1               => colorMap['accentColor1'];
  Color? get accentColor2               => colorMap['accentColor2'];
  Color? get accentColor3               => colorMap['accentColor3'];
  Color? get accentColor4               => colorMap['accentColor4'];

  Color? get iconColor                  => colorMap['iconColor'];

  Color? get eventColor                 => colorMap['eventColor'];
  Color? get diningColor                => colorMap['diningColor'];
  Color? get placeColor                 => colorMap['placeColor'];

  Color? get white                      => colorMap['white'];
  Color? get whiteTransparent01         => colorMap['whiteTransparent01'];
  Color? get whiteTransparent06         => colorMap['whiteTransparent06'];
  Color? get blackTransparent06         => colorMap['blackTransparent06'];
  Color? get blackTransparent018        => colorMap['blackTransparent018'];

  Color? get mediumGray                 => colorMap['mediumGray'];
  Color? get mediumGray1                => colorMap['mediumGray1'];
  Color? get mediumGray2                => colorMap['mediumGray2'];
  Color? get lightGray                  => colorMap['lightGray'];
  Color? get disabledTextColor          => colorMap['disabledTextColor'];
  Color? get disabledTextColorTwo       => colorMap['disabledTextColorTwo'];

  Color? get mango                      => colorMap['mango'];

  Color? get saferLocationWaitTimeColorRed        => colorMap['saferLocationWaitTimeColorRed'];
  Color? get saferLocationWaitTimeColorYellow     => colorMap['saferLocationWaitTimeColorYellow'];
  Color? get saferLocationWaitTimeColorGreen      => colorMap['saferLocationWaitTimeColorGreen'];
  Color? get saferLocationWaitTimeColorGrey       => colorMap['saferLocationWaitTimeColorGrey'];

  Color? getColor(String key) => colorMap[key];

  static Color? fromHex(String? value) {
    if (value != null) {
      final buffer = StringBuffer();
      if (value.length == 6 || value.length == 7) {
        buffer.write('ff');
      }
      buffer.write(value.replaceFirst('#', ''));

      try { return Color(int.parse(buffer.toString(), radix: 16)); }
      on Exception catch (e) { debugPrint(e.toString()); }
    }
    return null;
  }

  static String? toHex(Color? value, {bool leadingHashSign = true}) {
    if (value != null) {
      return (leadingHashSign ? '#' : '') +
          value.alpha.toRadixString(16).padLeft(2, '0') +
          value.red.toRadixString(16).padLeft(2, '0') +
          value.green.toRadixString(16).padLeft(2, '0') +
          value.blue.toRadixString(16).padLeft(2, '0');
    }
    return null;
  }
}

class UiFontFamilies {
  final Map<String, String> familyMap;
  UiFontFamilies(this.familyMap);

  static UiFontFamilies? fromJson(Map<String, dynamic>? json) {
    Map<String, String>? familyMap;
    try { familyMap = (json != null) ? json.cast<String, String>() : null; }
    catch(e) { debugPrint(e.toString()); }
    return UiFontFamilies(familyMap ?? <String, String>{});
  }

  String? get black        => familyMap["black"];
  String? get blackIt      => familyMap["black_italic"];
  String? get bold         => familyMap["bold"];
  String? get boldIt       => familyMap["bold_italic"];
  String? get extraBold    => familyMap["extra_bold"];
  String? get extraBoldIt  => familyMap["extra_bold_italic"];
  String? get light        => familyMap["light"];
  String? get lightIt      => familyMap["light_italic"];
  String? get medium       => familyMap["medium"];
  String? get mediumIt     => familyMap["medium_italic"];
  String? get regular      => familyMap["regular"];
  String? get regularIt    => familyMap["regular_italic"];
  String? get semiBold     => familyMap["semi_bold"];
  String? get semiBoldIt   => familyMap["semi_bold_italic"];
  String? get thin         => familyMap["thin"];
  String? get thinIt       => familyMap["thin_italic"];

  String? fromCode(String? code) => familyMap[code];
}

class UiTextStyles {

  final Map<String, dynamic> styleMap;
  final UiColors? colors;

  UiTextStyles(Map<String, dynamic>? styleMap, { this.colors }) :
    styleMap = styleMap ?? <String, dynamic> {};

  TextStyle? getTextStyle(String key , {Map<String, dynamic>? data}){
    return constructTextStyle(key: key, data: null);
  }

  TextStyle? constructTextStyle({String? key, Map<String, dynamic>? data}){
    if(StringUtils.isEmpty(key)){
      return null;
    }

    Map<String, dynamic>? style = JsonUtils.mapValue(styleMap[key]);

    if(style == null){
      return null;
    }
    Color? color = extractTextStyleColor(JsonUtils.stringValue(style['color']), data);
    Color? decorationColor = extractTextStyleColor(JsonUtils.stringValue(style['decoration_color']), data);
    double? fontSize = extractCustomValue(style['size'], data) ?? JsonUtils.doubleValue(style['size']);
    double? fontHeight = extractCustomValue(style['height'], data) ?? JsonUtils.doubleValue(style['height']);
    String? fontFamily = extractCustomValue(style['font_family'], data) ?? JsonUtils.stringValue(style['font_family']);
    TextDecoration? textDecoration = extractCustomValue(style['decoration'], data) ?? textDecorationFromString(JsonUtils.stringValue(style["decoration"])); // Not mandatory
    TextOverflow? textOverflow = extractCustomValue(style['overflow'], data) ?? textOverflowFromString(JsonUtils.stringValue(style["overflow"])); // Not mandatory
    TextDecorationStyle? decorationStyle = extractCustomValue(style['decoration_style'], data) ?? textDecorationStyleFromString(JsonUtils.stringValue(style["decoration_style"])); // Not mandatory
    FontWeight? fontWeight = extractCustomValue(style['weight'], data) ?? fontWeightFromString(JsonUtils.stringValue(style["weight"])); // Not mandatory
    double? letterSpacing = extractCustomValue(style['letter_spacing'], data) ?? JsonUtils.doubleValue(style['letter_spacing']); // Not mandatory
    double? wordSpacing = extractCustomValue(style['word_spacing'], data) ?? JsonUtils.doubleValue(style['word_spacing']); // Not mandatory
    double? decorationThickness = extractCustomValue(style['decoration_thickness'], data) ?? JsonUtils.doubleValue(style['decoration_thickness']); // Not mandatory

    return  TextStyle(fontFamily: fontFamily, fontSize: fontSize, color: color, letterSpacing: letterSpacing, wordSpacing: wordSpacing, decoration: textDecoration,
        overflow: textOverflow, height: fontHeight, fontWeight: fontWeight, decorationThickness: decorationThickness, decorationStyle: decorationStyle, decorationColor: decorationColor);
  }

  Color? extractTextStyleColor(String? rawColorData,  Map<String, dynamic>? values){
    if(rawColorData != null){
      if(rawColorData.startsWith("#")){
        return UiColors.fromHex(rawColorData);
      } else if(rawColorData.startsWith('\$')){
        Color? customColor = extractCustomValue(rawColorData, values);
        if(customColor != null) {
          return customColor;
        }
      } else {
        return colors!.getColor(rawColorData);
      }
    }
    return null;
  }

  //TextStyle Custom values like color or height
  static T? extractCustomValue<T>(dynamic rawValue, Map<String, dynamic>? values){
    if(rawValue!= null && rawValue is String && rawValue.startsWith('\$')){
      String customValueKey = rawValue.replaceFirst("\$", "");
      dynamic customValue = values!= null && values.containsKey(customValueKey) ? values[customValueKey] : null;
      if(customValue != null && customValue is T){
        return customValue;
      }
    }
    return null;
  }
}

//Text style properties from string
TextDecoration? textDecorationFromString(String? decoration){
  switch(decoration){
    case "lineThrough" : return TextDecoration.lineThrough;
    case "overline" : return TextDecoration.overline;
    case "underline" : return TextDecoration.underline;
    default : return null;
  }
}

TextOverflow? textOverflowFromString(String? value) {
    switch (value) {
      case "clip" : return TextOverflow.clip;
      case "fade" :return TextOverflow.fade;
      case "ellipsis" :return TextOverflow.ellipsis;
      case "visible" :return TextOverflow.visible;
      default : return null;
    }
  }

TextDecorationStyle? textDecorationStyleFromString(String? value) {
  switch (value) {
    case "dotted" : return TextDecorationStyle.dotted;
    case "dashed" : return TextDecorationStyle.dashed;
    case "double" : return TextDecorationStyle.double;
    case "solid" : return TextDecorationStyle.solid;
    case "wavy" : return TextDecorationStyle.wavy;
    default : return null;
  }
}

FontWeight? fontWeightFromString(String? value) {
  switch (value) {
    case "w100" : return FontWeight.w100;
    case "w200" : return FontWeight.w200;
    case "w300" : return FontWeight.w300;
    case "w400" : return FontWeight.w400;
    case "w500" : return FontWeight.w500;
    case "w600" : return FontWeight.w600;
    case "w700" : return FontWeight.w700;
    case "w800" : return FontWeight.w800;
    case "w900" : return FontWeight.w900;
    default : return null;
  }

}

class UiImages {
  final Map<String, dynamic>? imageMap;
  final UiColors? colors;

  UiImages({this.imageMap, this.colors});

  Widget? getImage(String imageKey, {Key? key, dynamic source, double? scale, double? width, double? height, Color? color, String? semanticLabel, bool excludeFromSemantics = false,
    bool isAntiAlias = false, bool matchTextDirection = false, bool gaplessPlayback = false, AlignmentGeometry? alignment, Animation<double>? opacity, BlendMode? colorBlendMode, BoxFit? fit, 
    FilterQuality? filterQuality, ImageRepeat? repeat, Rect? centerSlice, TextDirection? textDirection, Map<String, String>? networkHeaders,
    Widget Function(BuildContext, Widget, int?, bool)? frameBuilder, 
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder}
  ) {

    Map<String, dynamic>? imageSpec = (imageMap != null) ? JsonUtils.mapValue(imageMap![imageKey]) : null;
    String? type = (imageSpec != null) ? JsonUtils.stringValue(imageSpec['type']) : null;
    if (type != null) {
      if (type.startsWith('flutter.')) {
        return _getFlutterImage(imageSpec!, type: type, source: source, key: key,
          scale: scale, width: width, height: height, color: color,
          semanticLabel: semanticLabel, excludeFromSemantics: excludeFromSemantics,
          isAntiAlias: isAntiAlias, matchTextDirection: matchTextDirection, gaplessPlayback: gaplessPlayback,
          alignment: alignment, opacity: opacity, colorBlendMode: colorBlendMode, fit: fit, filterQuality: filterQuality,
          repeat: repeat, centerSlice: centerSlice, networkHeaders: networkHeaders,
          frameBuilder: frameBuilder, loadingBuilder: loadingBuilder, errorBuilder: errorBuilder);
      }
      else if (type.startsWith('fa.')) {
        return _getFaIcon(imageSpec!, type: type, source: source, key: key, size: height ?? width, color: color, textDirection: textDirection, semanticLabel: semanticLabel, excludeFromSemantics: excludeFromSemantics);
      }
      else {
        return null;
      }
    }

    // If no image definition for that key - try with asset name / network source
    Uri? uri = Uri.tryParse(imageKey);
    if (uri != null) {
      return _getDefaultFlutterImage(uri, key: key,
        scale: scale, width: width, height: height, color: color,
        semanticLabel: semanticLabel, excludeFromSemantics: excludeFromSemantics,
        isAntiAlias: isAntiAlias, matchTextDirection: matchTextDirection, gaplessPlayback: gaplessPlayback,
        alignment: alignment, opacity: opacity, colorBlendMode: colorBlendMode, fit: fit, filterQuality: filterQuality,
        repeat: repeat, centerSlice: centerSlice, networkHeaders: networkHeaders,
        frameBuilder: frameBuilder, loadingBuilder: loadingBuilder, errorBuilder: errorBuilder);
    }
    
    return null;
  }

  /* Example:
    "flutter-image":{
      "type":"flutter.asset",
      "src":"images/example.png",
      "height":24,
      "width":24,
      "scale":1.0,
      "alignment":"center",
      "fit":"cover",
      "color":"#ffffff",
      "color_blend_mode":"srcIn",
      "filter_quality":"none",
      "repeat":"noRepeat"
    }
  */

  Image? _getFlutterImage(Map<String, dynamic> json, { String? type, dynamic source, Key? key, double? scale, double? width, double? height, Color? color, String? semanticLabel,
    bool excludeFromSemantics = false, bool isAntiAlias = false, bool matchTextDirection = false, bool gaplessPlayback = false,
    AlignmentGeometry? alignment, Animation<double>? opacity, BlendMode? colorBlendMode, BoxFit? fit, FilterQuality? filterQuality, 
    ImageRepeat? repeat, Rect? centerSlice, Map<String, String>? networkHeaders, Widget Function(BuildContext, Widget, int?, bool)? frameBuilder, 
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder, Widget Function(BuildContext, Object, StackTrace?)? errorBuilder }
  ) {
    type ??= JsonUtils.stringValue(json['type']);
    source ??= json['src'];

    scale ??= JsonUtils.doubleValue(json['scale']) ?? 1.0;
    width ??= JsonUtils.doubleValue(json['width']);
    height ??= JsonUtils.doubleValue(json['height']);
    alignment ??= _ImageUtils.alignmentGeometryValue(JsonUtils.stringValue(json['alignment'])) ?? Alignment.center;
    color ??= _ImageUtils.colorValue(JsonUtils.stringValue(json['color']));

    // Image Enums
    colorBlendMode ??= _ImageUtils.lookup(BlendMode.values, JsonUtils.stringValue(json['color_blend_mode']));
    fit ??= _ImageUtils.lookup(BoxFit.values, JsonUtils.stringValue(json['fit']));
    filterQuality ??= _ImageUtils.lookup(FilterQuality.values, JsonUtils.stringValue(json['filter_quality'])) ?? FilterQuality.low;
    repeat ??= _ImageUtils.lookup(ImageRepeat.values, JsonUtils.stringValue(json['repeat'])) ?? ImageRepeat.noRepeat;
    
    try { switch (type) {
      
      case 'flutter.asset':
        String? assetString = JsonUtils.stringValue(source);
        return (assetString != null) ? Image.asset(assetString,
          key: key, frameBuilder: frameBuilder, errorBuilder: errorBuilder, semanticLabel: semanticLabel, excludeFromSemantics: excludeFromSemantics,
          scale: scale, width: width, height: height, color: color, opacity: opacity, colorBlendMode: colorBlendMode, fit: fit, alignment: alignment, repeat: repeat,
          centerSlice: centerSlice, matchTextDirection: matchTextDirection, gaplessPlayback: gaplessPlayback, isAntiAlias: isAntiAlias, filterQuality: filterQuality,
        ) : null;
      
      case 'flutter.file':
        File? sourceFile = _ImageUtils.fileValue(source);
        return (sourceFile != null) ? Image.file(sourceFile,
          key: key, frameBuilder: frameBuilder, errorBuilder: errorBuilder, semanticLabel: semanticLabel, excludeFromSemantics: excludeFromSemantics,
          scale: scale, width: width, height: height, color: color, opacity: opacity, colorBlendMode: colorBlendMode, fit: fit, alignment: alignment, repeat: repeat,
          centerSlice: centerSlice, matchTextDirection: matchTextDirection, gaplessPlayback: gaplessPlayback, isAntiAlias: isAntiAlias, filterQuality: filterQuality, 
        ) : null;
      
      case 'flutter.network':
        String? urlString = JsonUtils.stringValue(source);
        return (urlString != null) ? Image.network(urlString,
          key: key, frameBuilder: frameBuilder, loadingBuilder: loadingBuilder, errorBuilder: errorBuilder, semanticLabel: semanticLabel, excludeFromSemantics: excludeFromSemantics,
          scale: scale, width: width, height: height, color: color, opacity: opacity, colorBlendMode: colorBlendMode, fit: fit, alignment: alignment, repeat: repeat,
          centerSlice: centerSlice, matchTextDirection: matchTextDirection, gaplessPlayback: gaplessPlayback, isAntiAlias: isAntiAlias, filterQuality: filterQuality,
          headers: networkHeaders
        ) : null;
      
      case 'flutter.memory':
        Uint8List? bytes = _ImageUtils.bytesValue(source);
        return (bytes != null) ? Image.memory(bytes, key: key, frameBuilder: frameBuilder, errorBuilder: errorBuilder, semanticLabel: semanticLabel,  excludeFromSemantics: excludeFromSemantics,
          scale: scale, width: width, height: height, color: color, opacity: opacity, colorBlendMode: colorBlendMode, fit: fit, alignment: alignment, repeat: repeat,
          centerSlice: centerSlice, matchTextDirection: matchTextDirection, gaplessPlayback: gaplessPlayback, isAntiAlias: isAntiAlias, filterQuality: filterQuality
        ) : null;
    }}
    catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  /* Example:
    "fa-icon":{
      "type":"fa.icon",
      "weight":"regular",
      "src":"0xf057",
      "size":28.0,
      "color":"fillColorPrimary",
      "text_direction":"ltr"
    }
  */

  Widget? _getFaIcon(Map<String, dynamic> json, { String? type, dynamic source, Key? key, double? size, Color? color, TextDirection? textDirection, String? semanticLabel, bool excludeFromSemantics = false}) {

    type ??= JsonUtils.stringValue(json['type']);
    source ??= json['src'];

    size ??= JsonUtils.doubleValue(json['size']);
    color ??= _ImageUtils.colorValue(JsonUtils.stringValue(json['color']));
    textDirection ??= _ImageUtils.lookup(TextDirection.values, JsonUtils.stringValue(json['text_direction']));

    try { switch (type) {
      case 'fa.icon':
        IconData? iconData = _ImageUtils.faIconDataValue(JsonUtils.stringValue(json['weight']) ?? 'regular', codePoint: _ImageUtils.faCodePointValue(source));
        return (iconData != null) ? ExcludeSemantics(excluding: excludeFromSemantics, child:
          FaIcon(iconData, key: key, size: size, color: color, semanticLabel: semanticLabel, textDirection: textDirection,)
        ) : null;
    }}
    catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Image? _getDefaultFlutterImage(Uri uri, { Key? key, double? scale, double? width, double? height, Color? color, String? semanticLabel,
    bool excludeFromSemantics = false, bool isAntiAlias = false, bool matchTextDirection = false, bool gaplessPlayback = false,
    AlignmentGeometry? alignment, Animation<double>? opacity, BlendMode? colorBlendMode, BoxFit? fit, FilterQuality? filterQuality, 
    ImageRepeat? repeat, Rect? centerSlice, Map<String, String>? networkHeaders, Widget Function(BuildContext, Widget, int?, bool)? frameBuilder, 
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder, Widget Function(BuildContext, Object, StackTrace?)? errorBuilder }
  ) {
    try {
      scale ??= 1.0;
      alignment ??= Alignment.center;
      repeat ??= ImageRepeat.noRepeat;
      filterQuality ??= FilterQuality.low;

      if (uri.hasScheme) {
        return Image.network(uri.toString(),
          key: key, frameBuilder: frameBuilder, loadingBuilder: loadingBuilder, errorBuilder: errorBuilder, semanticLabel: semanticLabel, excludeFromSemantics: excludeFromSemantics,
          scale: scale, width: width, height: height, color: color, opacity: opacity, colorBlendMode: colorBlendMode, fit: fit, alignment: alignment, repeat: repeat,
          centerSlice: centerSlice, matchTextDirection: matchTextDirection, gaplessPlayback: gaplessPlayback, isAntiAlias: isAntiAlias, filterQuality: filterQuality,
          headers: networkHeaders
        );
      }
      else if (!uri.hasEmptyPath) {
        return Image.asset(uri.toString(),
          key: key, frameBuilder: frameBuilder, errorBuilder: errorBuilder, semanticLabel: semanticLabel, excludeFromSemantics: excludeFromSemantics,
          scale: scale, width: width, height: height, color: color, opacity: opacity, colorBlendMode: colorBlendMode, fit: fit, alignment: alignment, repeat: repeat,
          centerSlice: centerSlice, matchTextDirection: matchTextDirection, gaplessPlayback: gaplessPlayback, isAntiAlias: isAntiAlias, filterQuality: filterQuality,
        );
      }
      else {
        return null;
      }
    }
    catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }
}

class _StyleUtils {

  static void merge(Map<String, dynamic> dest, Map<String, dynamic>? src, { int? level }) {
    src?.forEach((String key, dynamic srcV) {
      dynamic destV = dest[key];
      Map<String, dynamic>? destMapV = JsonUtils.mapValue(destV);
      Map<String, dynamic>? srcMapV = JsonUtils.mapValue(srcV);
      
      if (((level == null) || (0 < level)) && (destMapV != null) && (srcMapV != null)) {
        merge(destMapV, srcMapV, level: (level != null) ? (level - 1) : null);
      }
      else {
        dest[key] = (((level == null) || (0 < level)) && (srcMapV != null)) ? Map<String, dynamic>.from(srcMapV) : srcV;
      }
    });
  }

}

class _ImageUtils {
  
  static File? fileValue(dynamic value) {
    if (value is File) {
      return value;
    }
    else if (value is String) {
      return File(value);
    }
    else {
      return null;
    }
  }

  static Uint8List? bytesValue(dynamic value) {
    if (value is Uint8List) {
      return value;
    }
    else if (value is String) {
      return base64Decode(value); // TBD: handle Base64 decoding asynchronically via compute API.
    }
    else {
      return null;
    }
  }

  static AlignmentGeometry? alignmentGeometryValue(dynamic value) {
    if (value is AlignmentGeometry) {
      return value;
    }
    else if (value is String) {
      switch (value) {
        case "topLeft":      return Alignment.topLeft;
        case "topCenter":    return Alignment.topCenter;
        case "topRight":     return Alignment.topRight;
        case "centerLeft":   return Alignment.centerLeft;
        case "center":       return Alignment.center;
        case "centerRight":  return Alignment.centerRight;
        case "bottomLeft":   return Alignment.bottomLeft;
        case "bottomCenter": return Alignment.bottomCenter;
        case "bottomRight":  return Alignment.bottomRight;
        default:             return null;
      }
    }
    else {
      return null;
    }
  }

  static Color? colorValue(dynamic value, {UiColors? colors}) {
    if (value is Color) {
      return value;
    }
    else if (value is String) {
      if (value.startsWith('#')) {
        return UiColors.fromHex(value);
      }
      else {
        return colors?.getColor(value);
      }
    }
    else {
      return null;
    }
  }

  static int? faCodePointValue(dynamic value) {
    if (value is int) {
      return value;
    }
    else if (value is String) {
      return int.tryParse(value);
    }
    else {
      return null;
    }
  }

  static IconData? faIconDataValue(dynamic value, {int? codePoint}) {
    if (value is IconData) {
      return value;
    }
    else if ((value is String) && (codePoint != null)) {
      switch(value) {
        case 'solid': return IconDataSolid(codePoint);
        case 'regular': return IconDataRegular(codePoint);
        case 'brands': return IconDataBrands(codePoint);
        default: return null;
      }
    }
    else {
      return null;
    }
    
  }

  static T? lookup<T>(List<T> values, String? value) =>
    (value != null) ? values.firstWhereOrNull((e) => e.toString() == '${T.toString()}.$value') : null;
}

