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
// import 'dart:ui';

import 'package:collection/collection.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class Styles extends Service implements NotificationsListener{
  static const String notifyChanged    = "edu.illinois.rokwire.styles.changed";
  static const String _assetsName      = "styles.json";

  File?      _cacheFile;
  DateTime?  _pausedDateTime;

  StylesContentMode? _contentMode;
  Map<String, dynamic>? _stylesData;
  Map<String, dynamic>? get stylesData => _stylesData;
  
  UiColors? _colors;
  UiColors? get colors => _colors;

  UiFontFamilies? _fontFamilies;
  UiFontFamilies? get fontFamilies => _fontFamilies;

  UiStyles? _uiStyles;
  UiStyles? get uiStyles => _uiStyles;

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
    await getCacheFile();
    
    _contentMode = stylesContentModeFromString(Storage().stylesContentMode) ?? StylesContentMode.auto;
    if (_contentMode == StylesContentMode.auto) {
      await loadFromCache();
      if (_stylesData == null) {
        await loadFromAssets();
      }
      if (_stylesData == null) {
        await loadFromNet();
      }
      else {
        loadFromNet();
      }
    }
    else if (_contentMode == StylesContentMode.assets) {
      await loadFromAssets();
    }
    else if (_contentMode == StylesContentMode.debug) {
      await loadFromCache();
      if (_stylesData == null) {
        await loadFromAssets();
      }
    }
    
    if (_stylesData != null) {
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
    return {Storage(), Config()};
  }

  // ContentMode

  StylesContentMode? get contentMode {
    return _contentMode;
  }

  set contentMode(StylesContentMode? contentMode) {
    setContentMode(contentMode);
  }

  Future<void> setContentMode(StylesContentMode? contentMode, [String? stylesContent]) async {
    if (_contentMode != contentMode) {
      _contentMode = contentMode;
      Storage().stylesContentMode = stylesContentModeToString(contentMode);

      _stylesData = null;
      clearCache();

      if (_contentMode == StylesContentMode.auto) {
        await loadFromAssets();
        await loadFromNet(notifyUpdate: false);
      }
      else if (_contentMode == StylesContentMode.assets) {
        await loadFromAssets();
      }
      else if (_contentMode == StylesContentMode.debug) {
        if (stylesContent != null) {
          applyContent(stylesContent, cacheContent: true);
        }
        else {
          await loadFromAssets();
        }
      }

      NotificationService().notify(notifyChanged, null);
    }
    else if (contentMode == StylesContentMode.debug) {
      if (stylesContent != null) {
        applyContent(stylesContent, cacheContent: true);
      }
      else {
        _stylesData = null;
        clearCache();
        await loadFromAssets();
      }
      NotificationService().notify(notifyChanged, null);
    }
  }

  Map<String, dynamic>? get content {
    return _stylesData;
  }

  // Public
  TextStyle? getTextStyle(String key, {Map<String, dynamic>? data}){
    return constructTextStyle(key: key, data: data);
  }

  // Private

  @protected
  String get cacheFileName => _assetsName;

  @protected
  Future<void> getCacheFile() async {
    Directory? assetsDir = Config().assetsCacheDir;
    if ((assetsDir != null) && !await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    String? cacheFilePath = (assetsDir != null) ? join(assetsDir.path, cacheFileName) : null;
    _cacheFile = (cacheFilePath != null) ? File(cacheFilePath) : null;
  }

  @protected
  Future<void> loadFromCache() async {
    try {
      String? stylesContent = ((_cacheFile != null) && await _cacheFile!.exists()) ? await _cacheFile!.readAsString() : null;
      await applyContent(stylesContent);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @protected
  Future<void> clearCache() async {
    if ((_cacheFile != null) && await _cacheFile!.exists()) {
      try { await _cacheFile!.delete(); }
      catch (e) { debugPrint(e.toString()); }
    }
  }

  @protected
  String get resourceAssetsKey => 'assets/$_assetsName';

  @protected
  Future<String?> loadResourceAssetsJsonString() => rootBundle.loadString(resourceAssetsKey);

  @protected
  Future<void> loadFromAssets() async {
    try {
      String? stylesContent = await loadResourceAssetsJsonString();
      await applyContent(stylesContent);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @protected
  String get networkAssetName => _assetsName;

  @protected
  Future<void> loadFromNet({bool cacheContent = true, bool notifyUpdate = true}) async {
    try {
      http.Response? response = (Config().assetsUrl != null) ? await Network().get("${Config().assetsUrl}/$networkAssetName") : null;
      String? stylesContent =  ((response != null) && (response.statusCode == 200)) ? response.body : null;
      if(stylesContent != null) {
        await applyContent(stylesContent, cacheContent: cacheContent, notifyUpdate: notifyUpdate);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @protected
  Future<void> applyContent(String? stylesContent, {bool cacheContent = false, bool notifyUpdate = false}) async {
    try {
      Map<String, dynamic>? styles = (stylesContent != null) ? JsonUtils.decode(stylesContent) : null;
      if ((styles != null) && styles.isNotEmpty && ((_stylesData == null) || !const DeepCollectionEquality().equals(_stylesData, styles))) {
        _stylesData = styles;
        buildData();
        if ((_cacheFile != null) && cacheContent) {
          await _cacheFile!.writeAsString(stylesContent!, flush: true);
        }
        if (notifyUpdate) {
          NotificationService().notify(notifyChanged, null);
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @protected
  void buildData(){
    buildColorsData();
    buildFontFamiliesData();
    _uiImages = UiImages(imageMap: (_stylesData != null) ? JsonUtils.mapValue(_stylesData!['image']) : null, colors: _colors);
  }

  @protected
  void buildColorsData(){
    if(_stylesData != null) {
      dynamic colorsData = _stylesData!["color"];
      Map<String, Color> colors = <String, Color>{};
      if(colorsData is Map){
        colorsData.forEach((dynamic key, dynamic value){
          if(key is String && value is String){
            Color? color;
            if(value.startsWith("#")){
              color = UiColors.fromHex(value);
            } else if(value.contains(".")){
              color = UiColors.fromHex(MapPathKey.entry(_stylesData, value));
            }
            if (color != null) {
              colors[key] = color;
            }
          }
        });
      }
      _colors = UiColors(colors);
    }
  }

  @protected
  void buildFontFamiliesData(){
    if(_stylesData != null) {
      dynamic familyData = _stylesData!["font_family"];
      if(familyData is Map) {
        Map<String, String> castedData = familyData.cast();
        _fontFamilies = UiFontFamilies(castedData);
      }
    }
  }

  TextStyle? constructTextStyle({String? key, Map<String, dynamic>? data}){
    if(StringUtils.isEmpty(key)){
      return null;
    }

    Map<String, dynamic>? stylesData = JsonUtils.mapValue(_stylesData!["text_style"]);
    Map<String, dynamic>? style = stylesData != null ? JsonUtils.mapValue(stylesData[key]) : null;

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
        if ((Config().refreshTimeout < pausedDuration.inSeconds) && (_contentMode == StylesContentMode.auto)) {
          loadFromNet();
        }
      }
    }
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

//TextStyle Custom values like color or height
T? extractCustomValue<T>(dynamic rawValue, Map<String, dynamic>? values){
  if(rawValue!= null && rawValue is String && rawValue.startsWith('\$')){
    String customValueKey = rawValue.replaceFirst("\$", "");
    dynamic customValue = values!= null && values.containsKey(customValueKey) ? values[customValueKey] : null;
    if(customValue != null && customValue is T){
      return customValue;
    }
  }
  return null;
}

enum StylesContentMode { auto, assets, debug }

String? stylesContentModeToString(StylesContentMode? contentMode) {
  if (contentMode == StylesContentMode.auto) {
    return 'auto';
  }
  else if (contentMode == StylesContentMode.assets) {
    return 'assets';
  }
  else if (contentMode == StylesContentMode.debug) {
    return 'debug';
  }
  else {
    return null;
  }
}

StylesContentMode? stylesContentModeFromString(String? value) {
  if (value == 'auto') {
    return StylesContentMode.auto;
  }
  else if (value == 'assets') {
    return StylesContentMode.assets;
  }
  else if (value == 'debug') {
    return StylesContentMode.debug;
  }
  else {
    return null;
  }
}

class UiColors {

  final Map<String,Color> _colorMap;

  UiColors(this._colorMap);

  Color? get fillColorPrimary                   => _colorMap['fillColorPrimary'];
  Color? get fillColorPrimaryTransparent03      => _colorMap['fillColorPrimaryTransparent03'];
  Color? get fillColorPrimaryTransparent05      => _colorMap['fillColorPrimaryTransparent05'];
  Color? get fillColorPrimaryTransparent09      => _colorMap['fillColorPrimaryTransparent09'];
  Color? get fillColorPrimaryTransparent015     => _colorMap['fillColorPrimaryTransparent015'];
  Color? get textColorPrimary                   => _colorMap['textColorPrimary'];
  Color? get fillColorPrimaryVariant            => _colorMap['fillColorPrimaryVariant'];
  Color? get textColorPrimaryVariant            => _colorMap['textColorPrimaryVariant'];
  Color? get fillColorSecondary                 => _colorMap['fillColorSecondary'];
  Color? get fillColorSecondaryTransparent05    => _colorMap['fillColorSecondaryTransparent05'];
  Color? get textColorSecondary                 => _colorMap['textColorSecondary'];
  Color? get fillColorSecondaryVariant          => _colorMap['fillColorSecondaryVariant'];
  Color? get textColorSecondaryVariant          => _colorMap['textColorSecondaryVariant'];

  Color? get surface                    => _colorMap['surface'];
  Color? get textSurface                => _colorMap['textSurface'];
  Color? get textSurfaceTransparent15   => _colorMap['textSurfaceTransparent15'];
  Color? get surfaceAccent              => _colorMap['surfaceAccent'];
  Color? get surfaceAccentTransparent15 => _colorMap['surfaceAccentTransparent15'];
  Color? get textSurfaceAccent          => _colorMap['textSurfaceAccent'];
  Color? get background                 => _colorMap['background'];
  Color? get textBackground             => _colorMap['textBackground'];
  Color? get backgroundVariant          => _colorMap['backgroundVariant'];
  Color? get textBackgroundVariant      => _colorMap['textBackgroundVariant'];
  Color? get headlineText               => _colorMap['headlineText'];

  Color? get accentColor1               => _colorMap['accentColor1'];
  Color? get accentColor2               => _colorMap['accentColor2'];
  Color? get accentColor3               => _colorMap['accentColor3'];
  Color? get accentColor4               => _colorMap['accentColor4'];

  Color? get iconColor                  => _colorMap['iconColor'];

  Color? get eventColor                 => _colorMap['eventColor'];
  Color? get diningColor                => _colorMap['diningColor'];
  Color? get placeColor                 => _colorMap['placeColor'];

  Color? get white                      => _colorMap['white'];
  Color? get whiteTransparent01         => _colorMap['whiteTransparent01'];
  Color? get whiteTransparent06         => _colorMap['whiteTransparent06'];
  Color? get blackTransparent06         => _colorMap['blackTransparent06'];
  Color? get blackTransparent018        => _colorMap['blackTransparent018'];

  Color? get mediumGray                 => _colorMap['mediumGray'];
  Color? get mediumGray1                => _colorMap['mediumGray1'];
  Color? get mediumGray2                => _colorMap['mediumGray2'];
  Color? get lightGray                  => _colorMap['lightGray'];
  Color? get surfaceGrey                => _colorMap['surfaceGrey'];
  Color? get disabledTextColor          => _colorMap['disabledTextColor'];
  Color? get disabledTextColorTwo       => _colorMap['disabledTextColorTwo'];
  Color? get dividerLine                => _colorMap['dividerLine'];

  Color? get mango                      => _colorMap['mango'];

  Color? get saferLocationWaitTimeColorRed        => _colorMap['saferLocationWaitTimeColorRed'];
  Color? get saferLocationWaitTimeColorYellow     => _colorMap['saferLocationWaitTimeColorYellow'];
  Color? get saferLocationWaitTimeColorGreen      => _colorMap['saferLocationWaitTimeColorGreen'];
  Color? get saferLocationWaitTimeColorGrey       => _colorMap['saferLocationWaitTimeColorGrey'];

  Color? getColor(String key){
    dynamic color = _colorMap[key];
    return (color is Color) ? color : null;
  }

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

class UiFontFamilies{
  final Map<String, String> _familyMap;
  UiFontFamilies(this._familyMap);

  String? get black        => _familyMap["black"];
  String? get blackIt      => _familyMap["black_italic"];
  String? get bold         => _familyMap["bold"];
  String? get boldIt       => _familyMap["bold_italic"];
  String? get extraBold    => _familyMap["extra_bold"];
  String? get extraBoldIt  => _familyMap["extra_bold_italic"];
  String? get light        => _familyMap["light"];
  String? get lightIt      => _familyMap["light_italic"];
  String? get medium       => _familyMap["medium"];
  String? get mediumIt     => _familyMap["medium_italic"];
  String? get regular      => _familyMap["regular"];
  String? get regularIt    => _familyMap["regular_italic"];
  String? get semiBold     => _familyMap["semi_bold"];
  String? get semiBoldIt   => _familyMap["semi_bold_italic"];
  String? get thin         => _familyMap["thin"];
  String? get thinIt       => _familyMap["thin_italic"];

  String? fromCode(String? code) => _familyMap[code];
}

class UiStyles {

  final Map<String, TextStyle> _styleMap;
  UiStyles(this._styleMap);

  TextStyle? get headerBar          => _styleMap['header_bar'];
  TextStyle? get headline1          => _styleMap["headline1"];
  TextStyle? get headline2          => _styleMap["headline2"];
  TextStyle? get headline3          => _styleMap["headline3"];
  TextStyle? get headline4          => _styleMap["headline4"];
  TextStyle? get headline5          => _styleMap["headline5"];
  TextStyle? get body               => _styleMap["body"];

  TextStyle? get label              => _styleMap["label"];
  TextStyle? get labelSelected      => _styleMap["labelSelected"];
  TextStyle? get list               => _styleMap["list"];
  TextStyle? get link               => _styleMap["link"];
  TextStyle? get alert              => _styleMap["alert"];
  TextStyle? get success            => _styleMap["success"];

  TextStyle? get quizzesHeadline1 => _styleMap["quizzesHeadline1"];

  TextStyle? get appBarTitle => _styleMap["appBarTitle"];
  TextStyle? get sectionTitle => _styleMap["sectionTitle"];

  TextStyle? get readingCard => _styleMap["readingCard"];
  TextStyle? get readingCard2 => _styleMap["readingCard2"];

  TextStyle? get cardHeadline1 => _styleMap["cardHeadline1"];
  TextStyle? get cardHeadline2 => _styleMap["cardHeadline2"];
  TextStyle? get cardHeadline3 => _styleMap["cardHeadline3"];
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