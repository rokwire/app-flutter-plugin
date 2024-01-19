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
import 'package:flutter/foundation.dart';
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

  static const UiColors _emptyColors = UiColors.empty();
  static const UiFontFamilies _emptyFontFamilies = UiFontFamilies.empty();
  static const UiTextStyles _emptyTextStyles = UiTextStyles.empty();
  static const UiImages _emptyImages = UiImages.empty();

  Directory? _assetsDir;
  DateTime?  _pausedDateTime;

  Map<String, dynamic>? _assetsManifest;

  Map<String, dynamic>? _assetsStyles;
  Map<String, dynamic>? _appAssetsStyles;
  Map<String, dynamic>? _netAssetsStyles;
  Map<String, dynamic>? _debugAssetsStyles;

  UiColors? _colors;
  UiColors get colors => _colors ?? _emptyColors;

  UiFontFamilies? _fontFamilies;
  UiFontFamilies get fontFamilies => _fontFamilies ?? _emptyFontFamilies;

  UiTextStyles? _textStyles;
  UiTextStyles get textStyles => _textStyles ?? _emptyTextStyles;

  UiImages? _images;
  UiImages get images => _images ?? _emptyImages;

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
    _assetsManifest = await loadAssetsManifest();
    _assetsStyles = await loadFromAssets(assetsKey);
    _appAssetsStyles = await loadFromAssets(appAssetsKey);
    _netAssetsStyles = await loadFromCache(netCacheFileName);
    _debugAssetsStyles = await loadFromCache(debugCacheFileName);

    if ((_assetsStyles != null) || (_appAssetsStyles != null) || (_netAssetsStyles != null) || (_debugAssetsStyles != null)) {
      await build();
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
      await build();
      NotificationService().notify(notifyChanged, null);
    }
  }

  @protected
  Future<void> build() async {
    Map<String, dynamic> styles = contentMap;
    _colors = await compute(UiColors.fromJson, JsonUtils.mapValue(styles['color']));
    _fontFamilies = await compute(UiFontFamilies.fromJson, JsonUtils.mapValue(styles['font_family']));
    _textStyles = await compute(UiTextStyles.fromCreationParam, _UiTextStylesCreationParam(JsonUtils.mapValue(styles['text_style']), colors: _colors, fontFamilies: _fontFamilies));
    _images = await compute(UiImages.fromCreationParam, _UiImagesCreationParam(JsonUtils.mapValue(styles['image']), colors: _colors, assetPathResolver: resolveImageAssetPath));
  }

  Map<String, dynamic> get contentMap {
    Map<String, dynamic> stylesMap = <String, dynamic>{};
    MapUtils.merge(stylesMap, _assetsStyles, level: 1);
    MapUtils.merge(stylesMap, _appAssetsStyles, level: 1);
    MapUtils.merge(stylesMap, _netAssetsStyles, level: 1);
    MapUtils.merge(stylesMap, _debugAssetsStyles, level: 1);
    return stylesMap;
  }

  Map<String, dynamic>? get debugMap => _debugAssetsStyles;

  set debugMap(Map<String, dynamic>? value) {
    if (((value != null) && !const DeepCollectionEquality().equals(_debugAssetsStyles, value)) ||
        ((value == null) && (_debugAssetsStyles != null)))
      {
        _debugAssetsStyles = value;
        saveToCache(netCacheFileName, JsonUtils.encode(_debugAssetsStyles));
        build().then((_){
          NotificationService().notify(notifyChanged, null);
        });
      }
  }

  @protected
  List<String> get imageAssetsPaths => ['app/images', 'images'];

  @protected
  String resolveImageAssetPath(Uri uri) {
    if ((uri.pathSegments.length == 1) && (_assetsManifest != null)) {
      for (String assetsPath in imageAssetsPaths) {
        if (assetsPath.isNotEmpty) {
          String imagePath = "$assetsPath/${uri.pathSegments.first}";
          if (_assetsManifest!.containsKey(imagePath)) {
            return imagePath;
          }
        }
      }
    }
    return uri.path;
  }

  @protected
  Future<Map<String, dynamic>?> loadAssetsManifest() async {
    return JsonUtils.decodeMap(await rootBundle.loadString('AssetManifest.json'));
  }
}

class UiColors {

  final Map<String, Color> colorMap;

  const UiColors(this.colorMap);

  const UiColors.empty() : this(const <String, Color>{});

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
  Color? get textColorDisabled                  => colorMap['textColorDisabled'];
  Color? get fillColorPrimaryVariant            => colorMap['fillColorPrimaryVariant'];
  Color? get textColorPrimaryVariant            => colorMap['textColorPrimaryVariant'];
  Color? get fillColorSecondary                 => colorMap['fillColorSecondary'];
  Color? get fillColorSecondaryTransparent05    => colorMap['fillColorSecondaryTransparent05'];
  Color? get textColorSecondary                 => colorMap['textColorSecondary'];
  Color? get fillColorSecondaryVariant          => colorMap['fillColorSecondaryVariant'];
  Color? get textColorSecondaryVariant          => colorMap['textColorSecondaryVariant'];
  Color? get gradientColorPrimary               => colorMap['gradientColorPrimary'];

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
  Color? get textBackgroundVariant2      => colorMap['textBackgroundVariant2'];
  Color? get headlineText               => colorMap['headlineText'];

  Color? get accentColor1               => colorMap['accentColor1'];
  Color? get accentColor2               => colorMap['accentColor2'];
  Color? get accentColor3               => colorMap['accentColor3'];
  Color? get accentColor4               => colorMap['accentColor4'];

  Color? get iconColor                  => colorMap['iconColor'];

  Color? get eventColor                 => colorMap['eventColor'];
  Color? get diningColor                => colorMap['diningColor'];
  Color? get placeColor                 => colorMap['placeColor'];
  Color? get mtdColor                   => colorMap['mtdColor'];

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
  Color? get dividerLine                => colorMap['dividerLine'];
  Color? get dividerLineAccent          => colorMap['dividerLineAccent'];

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
  const UiFontFamilies(this.familyMap);

  const UiFontFamilies.empty() : this(const <String, String>{});

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

  final Map<String, TextStyle> styleMap;
  final UiColors? colors;

  const UiTextStyles(this.styleMap, { this.colors });

  const UiTextStyles.empty() : this(const <String, TextStyle>{});

  static UiTextStyles fromJson(Map<String, dynamic>? stylesJson, {UiColors? colors, UiFontFamilies? fontFamilies}){
    Map<String, TextStyle> stylesMap = <String, TextStyle> {};
    stylesJson?.forEach((key, value) {
      TextStyle? style = constructTextStyle(JsonUtils.mapValue(value), stylesJson: stylesJson, colors: colors, fontFamilies: fontFamilies);
      if(style!=null){
        stylesMap[key] = style;
      }
    });
    return UiTextStyles(stylesMap, colors: colors);
  }

  static UiTextStyles fromCreationParam(_UiTextStylesCreationParam param) =>
    UiTextStyles.fromJson(param.stylesJson, colors: param.colors, fontFamilies: param.fontFamilies);

  TextStyle? getTextStyle(String key){
    return styleMap[key];
  }

  static TextStyle? constructTextStyle(Map<String, dynamic>? style, { Map<String, dynamic>? stylesJson, UiColors? colors, UiFontFamilies? fontFamilies}){
    if(style == null){
      return null;
    }

    Color? color = _TextStyleUtils.extractTextStyleColor(JsonUtils.stringValue(style['color']), colors);
    Color? decorationColor = _TextStyleUtils.extractTextStyleColor(JsonUtils.stringValue(style['decoration_color']), colors);
    double? fontSize =  JsonUtils.doubleValue(style['size']);
    double? fontHeight = JsonUtils.doubleValue(style['height']);
    String? fontFamily = JsonUtils.stringValue(style['font_family']);
    String? fontFamilyRef = fontFamilies?.fromCode(fontFamily);
    TextDecoration? textDecoration = _TextStyleUtils.textDecorationFromString(JsonUtils.stringValue(style["decoration"]));
    TextOverflow? textOverflow = _TextStyleUtils.textOverflowFromString(JsonUtils.stringValue(style["overflow"]));
    TextDecorationStyle? decorationStyle = _TextStyleUtils.textDecorationStyleFromString(JsonUtils.stringValue(style["decoration_style"]));
    FontWeight? fontWeight = _TextStyleUtils.fontWeightFromString(JsonUtils.stringValue(style["weight"]));
    double? letterSpacing = JsonUtils.doubleValue(style['letter_spacing']);
    double? wordSpacing = JsonUtils.doubleValue(style['word_spacing']);
    double? decorationThickness = JsonUtils.doubleValue(style['decoration_thickness']);
    bool inherit =  JsonUtils.boolValue(style["inherit"]) ?? true;

    TextStyle textStyle = TextStyle(fontFamily: fontFamilyRef ?? fontFamily, fontSize: fontSize, color: color, letterSpacing: letterSpacing, wordSpacing: wordSpacing, decoration: textDecoration,
        overflow: textOverflow, height: fontHeight, fontWeight: fontWeight, decorationThickness: decorationThickness, decorationStyle: decorationStyle, decorationColor: decorationColor, inherit: inherit);

    //Extending capabilities
    String? extendsKey = JsonUtils.stringValue(style['extends']);
    Map<String, dynamic>?  ancestorStyleMap = (StringUtils.isNotEmpty(extendsKey) && stylesJson!=null ? JsonUtils.mapValue(stylesJson[extendsKey]) : null);
    TextStyle? ancestorTextStyle = constructTextStyle(ancestorStyleMap, stylesJson: stylesJson, colors: colors, fontFamilies: fontFamilies);
    bool overrides =  JsonUtils.boolValue(style["override"]) ?? true;

    if(ancestorTextStyle != null ){
      return overrides ? ancestorTextStyle.merge(textStyle) : ancestorTextStyle;
    }

    return textStyle;
  }
}

class _UiTextStylesCreationParam {
  final Map<String, dynamic>? stylesJson;
  final UiColors? colors;
  final UiFontFamilies? fontFamilies;
  _UiTextStylesCreationParam(this.stylesJson, {this.colors, this.fontFamilies});
}

class UiImages {
  final Map<String, dynamic>? imageMap;
  final UiColors? colors;
  final String Function(Uri uri)? assetPathResolver;

  const UiImages(this.imageMap, { this.colors, this.assetPathResolver});

  const UiImages.empty() : this(const <String, dynamic>{});

  static UiImages fromCreationParam(_UiImagesCreationParam param) =>
    UiImages(param.imageMap, colors: param.colors, assetPathResolver: param.assetPathResolver);

  Widget? getImage(String? imageKey, {ImageSpec? defaultSpec, Key? key, String? type, dynamic source, double? scale, double? size,
    double? fill, dynamic weight, double? grade, double? opticalSize,
    double? width, double? height, Color? color, String? semanticLabel, bool excludeFromSemantics = false,
    bool isAntiAlias = false, bool matchTextDirection = false, bool gaplessPlayback = false, AlignmentGeometry? alignment,
    Animation<double>? opacity, BlendMode? colorBlendMode, BoxFit? fit, FilterQuality? filterQuality, ImageRepeat? repeat,
    Rect? centerSlice, String? fontFamily, String? fontPackage, TextDirection? textDirection, Map<String, String>? networkHeaders,
    Widget Function(BuildContext, Widget, int?, bool)? frameBuilder, 
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder}
  ) {

    Map<String, dynamic> imageJson = (imageMap != null && imageKey != null) ? JsonUtils.mapValue(imageMap![imageKey]) ?? {} : {};
    ImageSpec? imageSpec = ImageSpec.fromJson(imageJson) ?? defaultSpec;
    if (imageSpec != null) {
      if (imageSpec is FlutterImageSpec) {
        return _getFlutterImage(imageSpec, type: type, source: source, key: key,
            scale: scale, size: size, width: width, height: height, color: color,
            semanticLabel: semanticLabel, excludeFromSemantics: excludeFromSemantics,
            isAntiAlias: isAntiAlias, matchTextDirection: matchTextDirection, gaplessPlayback: gaplessPlayback,
            alignment: alignment, opacity: opacity, colorBlendMode: colorBlendMode, fit: fit, filterQuality: filterQuality,
            repeat: repeat, centerSlice: centerSlice, networkHeaders: networkHeaders,
            frameBuilder: frameBuilder, loadingBuilder: loadingBuilder, errorBuilder: errorBuilder);
      } else if (imageSpec is FontAwesomeImageSpec && (weight is String || weight == null)) {
        return _getFaIcon(imageSpec, type: type, source: source, key: key, size: size ?? height ?? width, weight: weight,
            color: color, textDirection: textDirection, semanticLabel: semanticLabel, excludeFromSemantics: excludeFromSemantics);
      } else if (imageSpec is MaterialIconImageSpec && (weight is double || weight == null)) {
        return _getMaterialIcon(imageSpec, type: type, source: source, key: key, size: size, fill: fill, weight: weight,
            grade: grade, opticalSize: opticalSize, color: color, semanticLabel: semanticLabel, textDirection: textDirection,
            excludeFromSemantics: excludeFromSemantics, fontFamily: fontFamily, fontPackage: fontPackage, matchTextDirection: matchTextDirection);
      } else {
        return null;
      }
    }

    // If no image definition for that key - try with asset name / network source
    if (imageKey != null) {
      Uri? uri = Uri.tryParse(imageKey);
      if (uri != null) {
        return _getDefaultFlutterImage(uri, key: key,
            scale: scale, width: width ?? size, height: height ?? size, color: color,
            semanticLabel: semanticLabel, excludeFromSemantics: excludeFromSemantics,
            isAntiAlias: isAntiAlias, matchTextDirection: matchTextDirection, gaplessPlayback: gaplessPlayback,
            alignment: alignment, opacity: opacity, colorBlendMode: colorBlendMode, fit: fit, filterQuality: filterQuality,
            repeat: repeat, centerSlice: centerSlice, networkHeaders: networkHeaders,
            frameBuilder: frameBuilder, loadingBuilder: loadingBuilder, errorBuilder: errorBuilder);
      }
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

  Image? _getFlutterImage(FlutterImageSpec imageSpec, { String? type, dynamic source, Key? key,
    double? scale, double? size, double? width, double? height, Color? color, String? semanticLabel,
    bool excludeFromSemantics = false, bool isAntiAlias = false, bool matchTextDirection = false, bool gaplessPlayback = false,
    AlignmentGeometry? alignment, Animation<double>? opacity, BlendMode? colorBlendMode, BoxFit? fit, FilterQuality? filterQuality, 
    ImageRepeat? repeat, Rect? centerSlice, Map<String, String>? networkHeaders, Widget Function(BuildContext, Widget, int?, bool)? frameBuilder, 
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder, Widget Function(BuildContext, Object, StackTrace?)? errorBuilder }
  ) {
    type ??= imageSpec.type;
    source ??= imageSpec.source;

    scale ??= imageSpec.scale;
    size ??= imageSpec.size;
    width ??= imageSpec.width ?? size;
    height ??= imageSpec.height ?? size;
    alignment ??= imageSpec.alignment ?? Alignment.center;
    color ??= imageSpec.color;

    // Image Enums
    colorBlendMode ??= imageSpec.colorBlendMode;
    fit ??= imageSpec.fit;
    filterQuality ??= imageSpec.filterQuality ?? FilterQuality.low;
    repeat ??= imageSpec.repeat ?? ImageRepeat.noRepeat;
    
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
          scale: scale ?? 1.0, width: width, height: height, color: color, opacity: opacity, colorBlendMode: colorBlendMode, fit: fit, alignment: alignment, repeat: repeat,
          centerSlice: centerSlice, matchTextDirection: matchTextDirection, gaplessPlayback: gaplessPlayback, isAntiAlias: isAntiAlias, filterQuality: filterQuality, 
        ) : null;
      
      case 'flutter.network':
        String? urlString = JsonUtils.stringValue(source);
        return (urlString != null) ? Image.network(urlString,
          key: key, frameBuilder: frameBuilder, loadingBuilder: loadingBuilder, errorBuilder: errorBuilder, semanticLabel: semanticLabel, excludeFromSemantics: excludeFromSemantics,
          scale: scale ?? 1.0, width: width, height: height, color: color, opacity: opacity, colorBlendMode: colorBlendMode, fit: fit, alignment: alignment, repeat: repeat,
          centerSlice: centerSlice, matchTextDirection: matchTextDirection, gaplessPlayback: gaplessPlayback, isAntiAlias: isAntiAlias, filterQuality: filterQuality,
          headers: networkHeaders
        ) : null;
      
      case 'flutter.memory':
        Uint8List? bytes = _ImageUtils.bytesValue(source);
        return (bytes != null) ? Image.memory(bytes, key: key, frameBuilder: frameBuilder, errorBuilder: errorBuilder, semanticLabel: semanticLabel,  excludeFromSemantics: excludeFromSemantics,
          scale: scale ?? 1.0, width: width, height: height, color: color, opacity: opacity, colorBlendMode: colorBlendMode, fit: fit, alignment: alignment, repeat: repeat,
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

  Widget? _getFaIcon(FontAwesomeImageSpec imageSpec, {String? type, dynamic source,
    Key? key, double? size, String? weight, Color? color, TextDirection? textDirection,
    String? semanticLabel, bool excludeFromSemantics = false}) {
    type ??= imageSpec.type;
    weight ??= imageSpec.weight ?? 'regular';
    source ??= imageSpec.source;

    size ??= imageSpec.size;
    color ??= imageSpec.color;
    textDirection ??= imageSpec.textDirection;
    semanticLabel ??= imageSpec.semanticLabel;

    try { switch (type) {
      case 'fa.icon':

        IconData? iconData = _ImageUtils.faIconDataValue(weight, codePoint: _ImageUtils.faCodePointValue(source));
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

      if (uri.scheme.isNotEmpty) {
        return Image.network(uri.toString(),
          key: key, frameBuilder: frameBuilder, loadingBuilder: loadingBuilder, errorBuilder: errorBuilder, semanticLabel: semanticLabel, excludeFromSemantics: excludeFromSemantics,
          scale: scale, width: width, height: height, color: color, opacity: opacity, colorBlendMode: colorBlendMode, fit: fit, alignment: alignment, repeat: repeat,
          centerSlice: centerSlice, matchTextDirection: matchTextDirection, gaplessPlayback: gaplessPlayback, isAntiAlias: isAntiAlias, filterQuality: filterQuality,
          headers: networkHeaders
        );
      }
      else if (uri.path.isNotEmpty) {
        return Image.asset((assetPathResolver != null) ? assetPathResolver!(uri) : uri.path,
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

  Widget? _getMaterialIcon(MaterialIconImageSpec imageSpec, { String? type, dynamic source, Key? key,
    double? size, double? fill, double? weight, double? grade, double? opticalSize,
    Color? color, String? fontFamily, String? fontPackage, TextDirection? textDirection, bool? matchTextDirection,
    String? semanticLabel, bool excludeFromSemantics = false,
  }) {
    // TODO: Did not include Icon shadows
    type ??= imageSpec.type;
    source ??= imageSpec.source;
    
    size ??= imageSpec.size;
    fill ??= imageSpec.fill;
    weight ??= imageSpec.weight;
    grade ??= imageSpec.grade;
    opticalSize ??= imageSpec.opticalSize;
    
    color ??= imageSpec.color;
    fontFamily ??= imageSpec.fontFamily;
    fontPackage ??= imageSpec.fontPackage;
    textDirection ??= imageSpec.textDirection;
    matchTextDirection = imageSpec.matchTextDirection ?? false;

    semanticLabel ??= imageSpec.semanticLabel;

    try { switch (type) {
      case 'material.icon':
        IconData iconData = IconData(_ImageUtils.faCodePointValue(source) ?? 0, fontFamily: fontFamily, fontPackage: fontPackage, matchTextDirection: matchTextDirection);
        return ExcludeSemantics( excluding: excludeFromSemantics, child:
          Icon(iconData, key: key, size: size, fill: fill, weight: weight, grade: grade, opticalSize: opticalSize, color: color, textDirection: textDirection, semanticLabel: semanticLabel,),
        );
    }}
    catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }
}

class _UiImagesCreationParam {
  final Map<String, dynamic>? imageMap;
  final UiColors? colors;
  final String Function(Uri uri)? assetPathResolver;
  _UiImagesCreationParam(this.imageMap, {this.colors, this.assetPathResolver});
}

abstract class ImageSpec {
  final String type;
  final dynamic source;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  const ImageSpec({required this.type, this.source, this.size, this.color, this.semanticLabel});

  static ImageSpec? fromJson(Map<String, dynamic> json) {
    String? type = JsonUtils.stringValue(json['type']);
    if (type == null) {
      return null;
    } else if (type.startsWith('flutter.')) {
      return FlutterImageSpec.fromJson(json);
    } else if (type.startsWith('fa.')) {
      return FontAwesomeImageSpec.fromJson(json);
    } else if (type.startsWith('material.')) {
      return MaterialIconImageSpec.fromJson(json);
    }
    return null;
  }

  factory ImageSpec.baseFromJson(Map<String, dynamic> json) {
    Color? color = _ImageUtils.colorValue(JsonUtils.stringValue(json['color']), colors: Styles().colors);
    return _BaseImageSpec(
      type: JsonUtils.stringValue(json['type']) ?? '',
      source: json['src'],
      size: JsonUtils.doubleValue(json['size']),
      color: color,
      semanticLabel: JsonUtils.stringValue(json['semantic_label']),
    );
  }
}

class _BaseImageSpec extends ImageSpec {
  _BaseImageSpec({required String type, dynamic source, double? size, Color? color, String? semanticLabel}) :
        super(type: type, source: source, size: size, color: color, semanticLabel: semanticLabel);
}

class FlutterImageSpec extends ImageSpec {
  final double? scale;
  final double? width;
  final double? height;
  final bool? isAntiAlias;
  final bool? matchTextDirection;
  final bool? gaplessPlayback;
  final AlignmentGeometry? alignment;
  final BlendMode? colorBlendMode;
  final BoxFit? fit;
  final FilterQuality? filterQuality;
  final ImageRepeat? repeat;

  const FlutterImageSpec({required String type, dynamic source, double? size, Color? color, String? semanticLabel,
    this.scale, this.width, this.height, this.isAntiAlias, this.matchTextDirection, this.gaplessPlayback,
    this.alignment, this.colorBlendMode, this.fit, this.filterQuality, this.repeat}) :
        super(type: type, source: source, size: size, color: color, semanticLabel: semanticLabel);
  
  FlutterImageSpec.fromBase(ImageSpec base,
    {this.scale, this.width, this.height, this.isAntiAlias, this.matchTextDirection, this.gaplessPlayback,
      this.alignment, this.colorBlendMode, this.fit, this.filterQuality, this.repeat}) :
        super(type: base.type, source: base.source, size: base.size, color: base.color, semanticLabel: base.semanticLabel);

  factory FlutterImageSpec.fromJson(Map<String, dynamic> json) {
    ImageSpec base = ImageSpec.baseFromJson(json);
    return FlutterImageSpec.fromBase(base,
      scale: JsonUtils.doubleValue(json['scale']),
      width: JsonUtils.doubleValue(json['width']),
      height: JsonUtils.doubleValue(json['height']),
      isAntiAlias: JsonUtils.boolValue(json['is_anti_alias']),
      matchTextDirection: JsonUtils.boolValue(json['match_text_direction']),
      gaplessPlayback: JsonUtils.boolValue(json['gapless_playback']),
      alignment: _ImageUtils.alignmentGeometryValue(JsonUtils.stringValue(json['alignment'])),
      colorBlendMode: _ImageUtils.lookup(BlendMode.values, JsonUtils.stringValue(json['color_blend_mode'])),
      fit: _ImageUtils.lookup(BoxFit.values, JsonUtils.stringValue(json['fit'])),
      filterQuality: _ImageUtils.lookup(FilterQuality.values, JsonUtils.stringValue(json['filter_quality'])),
      repeat: _ImageUtils.lookup(ImageRepeat.values, JsonUtils.stringValue(json['repeat'])),
    );
  }
}

class FontAwesomeImageSpec extends ImageSpec {
  final String? weight;
  final TextDirection? textDirection;

  const FontAwesomeImageSpec({required String type, dynamic source, double? size, Color? color,
    String? semanticLabel, this.weight, this.textDirection}) :
        super(type: type, source: source, size: size, color: color, semanticLabel: semanticLabel);

  FontAwesomeImageSpec.fromBase(ImageSpec base, {this.weight, this.textDirection}) :
        super(type: base.type, source: base.source, size: base.size, color: base.color, semanticLabel: base.semanticLabel);

  factory FontAwesomeImageSpec.fromJson(Map<String, dynamic> json) {
    ImageSpec base = ImageSpec.baseFromJson(json);
    TextDirection? textDirection = _ImageUtils.lookup(TextDirection.values, JsonUtils.stringValue(json['text_direction']));
    return FontAwesomeImageSpec.fromBase(base,
      weight: JsonUtils.stringValue(json['weight']),
      textDirection: textDirection,
    );
  }
}

class MaterialIconImageSpec extends ImageSpec {
  // TODO: Did not include shadows
  final double? fill;
  final double? weight;
  final double? grade;
  final double? opticalSize;
  final String? fontFamily;
  final String? fontPackage;
  final TextDirection? textDirection;
  final bool? matchTextDirection;

  const MaterialIconImageSpec({required String type, dynamic source, double? size, Color? color,
    String? semanticLabel, this.fill, this.weight, this.grade, this.opticalSize,
    this.fontFamily, this.fontPackage, this.textDirection, this.matchTextDirection}) :
        super(type: type, source: source, size: size, color: color, semanticLabel: semanticLabel);

  MaterialIconImageSpec.fromBase(ImageSpec base, { this.fill, this.weight, this.grade, this.opticalSize,
    this.fontFamily, this.fontPackage, this.textDirection, this.matchTextDirection}) :
        super(type: base.type, source: base.source, size: base.size, color: base.color, semanticLabel: base.semanticLabel);

  factory MaterialIconImageSpec.fromJson(Map<String, dynamic> json) {
    ImageSpec base = ImageSpec.baseFromJson(json);
    return MaterialIconImageSpec.fromBase(base,
      fill: JsonUtils.doubleValue(json['fill']),
      weight: JsonUtils.doubleValue(json['weight']),
      grade: JsonUtils.doubleValue(json['grade']),
      opticalSize: JsonUtils.doubleValue(json['optical_size']),
      fontFamily: JsonUtils.stringValue(json['font_family']),
      fontPackage: JsonUtils.stringValue(json['font_package']),
      textDirection: _ImageUtils.lookup(TextDirection.values, JsonUtils.stringValue(json['text_direction'])),
      matchTextDirection: JsonUtils.boolValue(json['match_text_direction'])
    );
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
        // Duotone icons are not supported in flutter. Ref: https://github.com/fluttercommunity/font_awesome_flutter/issues/192
        // case 'duotone': return IconDataDuotone(codePoint);
        case 'thin': return IconDataThin(codePoint);
        case 'light': return IconDataLight(codePoint);
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

class _TextStyleUtils {

  static TextDecoration? textDecorationFromString(String? decoration){
    switch(decoration){
      case "lineThrough" : return TextDecoration.lineThrough;
      case "overline" : return TextDecoration.overline;
      case "underline" : return TextDecoration.underline;
      default : return null;
    }
  }

  static TextOverflow? textOverflowFromString(String? value) {
    switch (value) {
      case "clip" : return TextOverflow.clip;
      case "fade" :return TextOverflow.fade;
      case "ellipsis" :return TextOverflow.ellipsis;
      case "visible" :return TextOverflow.visible;
      default : return null;
    }
  }

  static TextDecorationStyle? textDecorationStyleFromString(String? value) {
    switch (value) {
      case "dotted" : return TextDecorationStyle.dotted;
      case "dashed" : return TextDecorationStyle.dashed;
      case "double" : return TextDecorationStyle.double;
      case "solid" : return TextDecorationStyle.solid;
      case "wavy" : return TextDecorationStyle.wavy;
      default : return null;
    }
  }

  static FontWeight? fontWeightFromString(String? value) {
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

  static Color? extractTextStyleColor(String? rawColorData, UiColors? colors){
    if(rawColorData != null){
      if(rawColorData.startsWith("#")){
        return UiColors.fromHex(rawColorData);
      } else {
        return colors?.getColor(rawColorData);
      }
    }
    return null;
  }
}
