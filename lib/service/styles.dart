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

import 'dart:io';
import 'dart:typed_data';
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
  
  Map<String, TextStyle>? _textStylesMap;
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


  TextStyle? getTextStyle(String key){
    dynamic style = (_textStylesMap != null) ? _textStylesMap![key] : null;
    return (style is TextStyle) ? style : null;
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
    buildStylesData();
    buildImagesData();
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

  @protected
  void buildStylesData(){
    if(_stylesData != null) {
      dynamic stylesData = _stylesData!["text_style"];
      Map<String, TextStyle> styles = <String, TextStyle>{};
      if(stylesData is Map){
        stylesData.forEach((dynamic key, dynamic value){
          if(key is String && value is Map){
            double? fontSize = JsonUtils.doubleValue(value['size']);
            double? fontHeight = JsonUtils.doubleValue(value['height']);
            String? fontFamily = JsonUtils.stringValue(value['font_family']);
            String? rawColor = JsonUtils.stringValue(value['color']);
            Color? color = rawColor != null ? (rawColor.startsWith("#") ? UiColors.fromHex(rawColor) : colors!.getColor(rawColor)) : null;
            String? rawDecorationColor = JsonUtils.stringValue(value['decoration_color']);
            Color? decorationColor = rawDecorationColor != null ? (rawDecorationColor.startsWith("#") ? UiColors.fromHex(rawDecorationColor) : colors!.getColor(rawDecorationColor)) : null;
            TextDecoration textDecoration = textDecorationFromString(JsonUtils.stringValue(value["decoration"])); // Not mandatory
            TextOverflow? textOverflow = textOverflowFromString(JsonUtils.stringValue(value["overflow"])); // Not mandatory
            TextDecorationStyle? decorationStyle = textDecorationStyleFromString(JsonUtils.stringValue(value["decoration_style"])); // Not mandatory
            FontWeight? fontWeight = fontWeightFromString(JsonUtils.stringValue(value["weight"])); // Not mandatory
            double? letterSpacing = JsonUtils.doubleValue(value['letter_spacing']); // Not mandatory
            double? wordSpacing = JsonUtils.doubleValue(value['word_spacing']); // Not mandatory
            double? decorationThickness = JsonUtils.doubleValue(value['decoration_thickness']); // Not mandatory

            styles[key] = TextStyle(fontFamily: fontFamily, fontSize: fontSize, color: color, letterSpacing: letterSpacing, wordSpacing: wordSpacing, decoration: textDecoration,
                overflow: textOverflow, height: fontHeight, fontWeight: fontWeight, decorationThickness: decorationThickness, decorationStyle: decorationStyle, decorationColor: decorationColor);
          }
        });
      }
      _textStylesMap = styles;
      //if we need UiStyles...
      // if(_textStylesMap!=null)
      //   _uiStyles = UiStyles(_textStylesMap!);
      // }
    }

  }

  @protected
  void buildImagesData(){
    if(_stylesData != null) {
      dynamic imagesData = _stylesData!["image"];
      Map<String, Map> imageJson = <String, Map>{};
      Map<String, IconData> faIconData = <String, IconData>{};
      if(imagesData is Map){
        imagesData.forEach((dynamic key, dynamic value){
          if(key is String && value is Map){
            imageJson[key] = value;

            String? type = JsonUtils.stringValue(value['type']);
            String? source = JsonUtils.stringValue(value['src']);
            Match? faMatch = type?.matchAsPrefix("fa.");
            if (faMatch != null && source != null) {
              int? code = int.tryParse(source, radix: 16);
              if (code != null) {
                switch (type!.substring(faMatch.end)) {
                  case 'solid': faIconData[key] = IconDataSolid(code); break;
                  case 'regular': faIconData[key] = IconDataRegular(code); break;
                  case 'brands': faIconData[key] = IconDataBrands(code); break;
                }
              }
            }
          }
        });
      }

      _uiImages = UiImages(imageJson, faIconData, colors!);
    }
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
TextDecoration textDecorationFromString(String? decoration){
  switch(decoration){
    case "lineThrough" : return TextDecoration.lineThrough;
    case "overline" : return TextDecoration.overline;
    case "underline" : return TextDecoration.underline;
    default : return TextDecoration.none;
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
  Color? get disabledTextColor          => _colorMap['disabledTextColor'];
  Color? get disabledTextColorTwo       => _colorMap['disabledTextColorTwo'];

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
}

class UiImages {
  final Map<String, Map> _imageJson;
  final Map<String, IconData> _faIconData;
  final UiColors _colors;

  UiImages(this._imageJson, this._faIconData, this._colors);

  Widget? fromString(String str, {Uint8List? imageData, double? scale, double? width, double? height, Color? color, String? semanticLabel, bool excludeFromSemantics = false,
    bool antiAlias = false, bool matchTextDirection = false, Widget Function(BuildContext, Widget, int?, bool)? frameBuilder, 
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder, Widget Function(BuildContext, Object, StackTrace?)? errorBuilder}
  ) {
    Map? json = _imageJson[str];
    if (json != null) {
      IconData? iconData = _faIconData[str];
      if (iconData != null) {
        return _faIconFromData(iconData, json, width, color, semanticLabel, excludeFromSemantics);
      } else {
        return _imageFromProvider(json, imageData, scale, width, height, color, semanticLabel, excludeFromSemantics, antiAlias, matchTextDirection, 
          frameBuilder, loadingBuilder, errorBuilder);
      }
    }
    return null;
  }

  Image? _imageFromProvider(Map json, Uint8List? imageData, double? scale, double? width, double? height, Color? color, String? semanticLabel, 
    bool excludeFromSemantics, bool antiAlias, bool matchTextDirection, Widget Function(BuildContext, Widget, int?, bool)? frameBuilder, 
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder, Widget Function(BuildContext, Object, StackTrace?)? errorBuilder
  ) {
    String type = JsonUtils.stringValue(json['type'])!;
    String source = JsonUtils.stringValue(json['src'])!;
    // headers for network images opacity

    scale ??= JsonUtils.doubleValue(json['scale']) ?? 1.0;
    width ??= JsonUtils.doubleValue(json['width']);
    height ??= JsonUtils.doubleValue(json['height']);
    if (color == null) {
      String? rawColor = JsonUtils.stringValue(json['color']);
      color = rawColor != null ? (rawColor.startsWith("#") ? UiColors.fromHex(rawColor) : _colors.getColor(rawColor)) : null;
    }
    
    AlignmentGeometry alignment = _alignmentFromString(JsonUtils.stringValue(json['alignment'])) ?? Alignment.center;

    // Enums
    String? colorBlendMode = JsonUtils.stringValue(json['color_blend_mode']) ?? '';
    BlendMode? cbm = BlendMode.values.firstWhereOrNull((e) => e.toString() == 'BlendMode.' + colorBlendMode);
    
    String? boxFit = JsonUtils.stringValue(json['fit']) ?? '';
    BoxFit? bf = BoxFit.values.firstWhereOrNull((e) => e.toString() == 'BoxFit.' + boxFit);

    String? filterQuality = JsonUtils.stringValue(json['filter_quality']) ?? '';
    FilterQuality fq = FilterQuality.values.firstWhereOrNull((e) => e.toString() == 'FilterQuality.' + filterQuality) ?? FilterQuality.low;

    String? imageRepeat = JsonUtils.stringValue(json['repeat']) ?? '';
    ImageRepeat ir = ImageRepeat.values.firstWhereOrNull((e) => e.toString() == 'ImageRepeat.' + imageRepeat) ?? ImageRepeat.noRepeat;
    
    switch (type) {
      case 'flutter.asset': return Image.asset(source, frameBuilder: frameBuilder, errorBuilder: errorBuilder, semanticLabel: semanticLabel, 
          excludeFromSemantics: excludeFromSemantics, scale: scale, width: width, height: height, color: color, colorBlendMode: cbm, fit: bf, alignment: alignment, 
          repeat: ir, isAntiAlias: antiAlias, matchTextDirection: matchTextDirection, filterQuality: fq);
      case 'flutter.file': return Image.file(File(source), frameBuilder: frameBuilder, errorBuilder: errorBuilder, semanticLabel: semanticLabel, 
          excludeFromSemantics: excludeFromSemantics, scale: scale, width: width, height: height, color: color, colorBlendMode: cbm, fit: bf, alignment: alignment, 
          repeat: ir, isAntiAlias: antiAlias, matchTextDirection: matchTextDirection, filterQuality: fq);
      case 'flutter.network': {
        source = _checkImageSource(source);
        return Image.network(source, frameBuilder: frameBuilder, loadingBuilder: loadingBuilder, errorBuilder: errorBuilder, semanticLabel: semanticLabel, 
          excludeFromSemantics: excludeFromSemantics, scale: scale, width: width, height: height, color: color, colorBlendMode: cbm, fit: bf, alignment: alignment, 
          repeat: ir, isAntiAlias: antiAlias, matchTextDirection: matchTextDirection, filterQuality: fq);
      }
      case 'flutter.memory': {
        if (imageData != null) {
          return Image.memory(imageData, scale: scale, frameBuilder: frameBuilder, errorBuilder: errorBuilder, semanticLabel: semanticLabel, 
            excludeFromSemantics: excludeFromSemantics, width: width, height: height, color: color, colorBlendMode: cbm, fit: bf, alignment: alignment, 
            repeat: ir, isAntiAlias: antiAlias, matchTextDirection: matchTextDirection, filterQuality: fq);
        }
        return null;
      }
      default: return null;
    }
  }

  Widget _faIconFromData(IconData data, Map json, double? size, Color? color, String? semanticLabel, bool excludeFromSemantics) {
    size ??= JsonUtils.doubleValue(json['width']);
    if (color == null) {
      String? rawColor = JsonUtils.stringValue(json['color']);
      color = rawColor != null ? (rawColor.startsWith("#") ? UiColors.fromHex(rawColor) : _colors.getColor(rawColor)) : null;
    }

    String? textDirection = JsonUtils.stringValue(json['text_direction']) ?? '';
    TextDirection? td = TextDirection.values.firstWhereOrNull((e) => e.toString() == 'TextDirection.' + textDirection);

    FaIcon icon = FaIcon(data, size: size, color: color, semanticLabel: semanticLabel, textDirection: td,);
    return ExcludeSemantics(excluding: excludeFromSemantics, child: icon);
  }

  String _checkImageSource(String imageSource) {
    Match? prefixMatch = imageSource.matchAsPrefix("Config()");
    if (prefixMatch?.end != null) {
      return MapPathKey.entry(Config().content, imageSource.substring(prefixMatch!.end)).toString();
    }
    return imageSource;
  }

  AlignmentGeometry? _alignmentFromString(String? str) {
    switch (str) {
      case "topLeft": return Alignment.topLeft;
      case "topCenter": return Alignment.topCenter;
      case "topRight": return Alignment.topRight;
      case "centerLeft": return Alignment.centerLeft;
      case "center": return Alignment.center;
      case "centerRight": return Alignment.centerRight;
      case "bottomLeft": return Alignment.bottomLeft;
      case "bottomCenter": return Alignment.bottomCenter;
      case "bottomRight": return Alignment.bottomRight;
      default: return null;
    }
  }
}
