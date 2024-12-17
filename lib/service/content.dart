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
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

// Content service does rely on Service initialization API so it does not override service interfaces and is not registered in Services.
class Content with Service implements NotificationsListener, ContentItemCategoryClient {

  static const String notifyContentItemsChanged           = "edu.illinois.rokwire.content.content_items.changed";
  static const String notifyContentAttributesChanged      = "edu.illinois.rokwire.content.attributes.changed";
  static const String notifyContentImagesChanged          = "edu.illinois.rokwire.content.images.changed";
  static const String notifyContentWidgetsChanged         = "edu.illinois.rokwire.content.widgetss.changed";
  static const String notifyUserProfilePictureChanged     = "edu.illinois.rokwire.content.user.picture_profile.changed";

  static const String _attributesContentCategory = "attributes";
  static const String _imagesContentCategory = "images";
  static const String _widgetsContentCategory = "widgets";
  static const String _contentItemsCacheFileName = "contentItems.json";

  Directory? _appDocDir;
  DateTime?  _pausedDateTime;

  Map<String, dynamic>? _contentItems;

  ContentAttributes? _contentAttributes;
  final Map<String, ContentAttributes> _contentAttributesByScope = <String, ContentAttributes>{};
  Map<String, Uint8List?> _fileContentCache = {};
  Map<String, Future<Response?>?> _fileContentFutures = {};

  // Singletone Factory

  static Content? _instance;

  static Content? get instance => _instance;

  @protected
  static set instance(Content? value) => _instance = value;

  factory Content() => _instance ?? (_instance = Content.internal());

  @protected
  Content.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this,[
      AppLivecycle.notifyStateChanged,
    ]);
    super.createService();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Future<void> initService() async {
    _appDocDir = await getAppDocumentsDirectory();

    _contentItems = await loadContentItemsFromCache();
    if (_contentItems != null) {
      updateContentItemsFromNet();
    }
    else {
      _contentItems = await loadContentItemsFromNet();
      if (_contentItems != null) {
        await saveContentItemsToCache(_contentItems);
      }
    }

    _contentAttributes = ContentAttributes.fromJson(_contentAttributesJson);

    if (_contentItems != null) {
      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.nonFatal,
        title: 'Content Initialization Failed',
        description: 'Failed to initialize Content service.',
      );
    }

    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Config(), Storage(), Auth2() };
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
          updateContentItemsFromNet();
        }
      }
    }
  }

  // Caching

  @protected
  Future<Directory?> getAppDocumentsDirectory() async {
    try {
      return kIsWeb ? null : await getApplicationDocumentsDirectory();
    }
    catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  // Content Items

  @protected
  List<String> get contentItemsCategories {
    List<String> result = <String>[];
    Services().enumServices((Service service) {
      if (service is ContentItemCategoryClient) {
        result.addAll(((service as ContentItemCategoryClient)).contentItemCategory);
      }
    });
    return result;
  }

  dynamic contentItem(String category) =>
    (_contentItems != null) ? _contentItems![category] : null;

  Map<String, dynamic>? contentMapItem(String category) =>
    JsonUtils.mapValue(contentItem(category));

  List<dynamic>? contentListItem(String category) =>
    JsonUtils.listValue(contentItem(category));

  @protected
  File? getContentItemsCacheFile()  =>
    (_appDocDir != null) ? File(join(_appDocDir?.path ?? '', _contentItemsCacheFileName)) : null;

  @protected
  Future<Map<String, dynamic>?> loadContentItemsFromCache() async {
    File? contentItemsCacheFile = getContentItemsCacheFile();
    String? contentItemsString = (await contentItemsCacheFile?.exists() == true) ? await contentItemsCacheFile?.readAsString() : null;
    return JsonUtils.decodeMapAsync(contentItemsString);
  }

  @protected
  Future<void> saveContentItemsToCache(Map<String, dynamic>? value) async {
    File? contentItemsCacheFile = getContentItemsCacheFile();
    String? contentItemsString = await JsonUtils.encodeAsync(value);
    if (contentItemsString != null) {
      await contentItemsCacheFile?.writeAsString(contentItemsString, flush: true);
    }
    else {
      await contentItemsCacheFile?.delete();
    }
  }

  @protected
  Future<Map<String, dynamic>?> loadContentItemsFromNet() async =>
    loadContentItems(contentItemsCategories);

  Future<Map<String, dynamic>?> loadContentItems(List<String> categories) async {
    Map<String, dynamic>? result;
    if (Config().contentUrl != null) {
      Response? response = await Network().get("${Config().contentUrl}/content_items", body: JsonUtils.encode({'categories': categories}), auth: Auth2());
      List<dynamic>? responseList = (response?.statusCode == 200) ? await JsonUtils.decodeListAsync(response?.body)  : null;
      if (responseList != null) {
        result = <String, dynamic>{};
        for (dynamic responseEntry in responseList) {
          Map<String, dynamic>? contentItem = JsonUtils.mapValue(responseEntry);
          if (contentItem != null) {
            String? category = JsonUtils.stringValue(contentItem['category']);
            dynamic data = contentItem['data'];
            if ((category != null) && (data != null)) {
              dynamic existingCategoryEntry = result[category];
              if (existingCategoryEntry == null) {
                result[category] = data;
              }
              else if (existingCategoryEntry is List) {
                if (data is List) {
                  existingCategoryEntry.addAll(data);
                }
                else {
                  existingCategoryEntry.add(data);
                }
              }
              else {
                List<dynamic> newCategoryEntry = <dynamic>[existingCategoryEntry];
                if (data is List) {
                  newCategoryEntry.addAll(data);
                }
                else {
                  newCategoryEntry.add(data);
                }
                result[category] = newCategoryEntry;
              }
            }
          }
        }
      }
    }
    return result;
  }

  Future<dynamic> loadContentItem(String category) async {
    Map<String, dynamic>? contentItems = await loadContentItems([category]);
    return (contentItems != null) ? contentItems[category] : null;
  }

  @protected
  Future<void> updateContentItemsFromNet() async {
    Map<String, dynamic>? contentItems = await loadContentItemsFromNet();
    if (contentItems != null) {
      Set<String>? categoriesDiff = await compute(_compareContentItemsInParam, _CompareContentItemsParam(_contentItems, contentItems));
      if ((categoriesDiff != null) && categoriesDiff.isNotEmpty) {
        _contentItems = contentItems;
        await saveContentItemsToCache(contentItems);
        onContentItemsChanged(categoriesDiff);
      }
    }
  }

  static Set<String>? _compareContentItemsInParam(_CompareContentItemsParam param) =>
    _compareContentItems(param.items1, param.items2);

  static Set<String>? _compareContentItems(Map<String, dynamic>? items1, Map<String, dynamic>? items2) {
    if (items1 != null) {
      if (items2 != null) {
        Set<String>? result = <String>{};
        Set<String> passed = <String>{};
        for (String key in items1.keys) {
          dynamic item1 = items1[key];
          dynamic item2 = items2[key];
          if (const DeepCollectionEquality().equals(item1, item2) != true) {
            result.add(key);
          }
          passed.add(key);
        }
        for (String key in items2.keys) {
          if (!passed.contains(key)) {
            result.add(key);
          }
        }
        return result.isNotEmpty ? result : null;
      }
      else {
        return items1.keys.isNotEmpty ? Set<String>.from(items1.keys) : null;
      }
    }
    else if (items2 != null) {
      return items2.keys.isNotEmpty ? Set<String>.from(items2.keys) : null;
    }
    else {
      return null;
    }
  }

  @protected
  void onContentItemsChanged(Set<String> categoriesDiff) {
    if (categoriesDiff.contains(attributesContentCategory)) {
      _onContentAttributesChanged();
    }
    if (categoriesDiff.contains(imagesContentCategory)) {
      _onContentImagesChanged();
    }
    if (categoriesDiff.contains(widgetsContentCategory)) {
      _onContentWidgetsChanged();
    }
    NotificationService().notify(notifyContentItemsChanged, categoriesDiff);
  }

  // Attributes Content Items

  @protected
  String get attributesContentCategory =>
    _attributesContentCategory;

  Map<String, dynamic>? get _contentAttributesJson =>
    contentMapItem(attributesContentCategory);

  ContentAttributes? contentAttributes(String scope) => (_contentAttributes != null) ?
      (_contentAttributesByScope[scope] ??= (ContentAttributes.fromOther(_contentAttributes, scope: scope) ?? ContentAttributes())) : null;

  void _onContentAttributesChanged() {
    _contentAttributes = ContentAttributes.fromJson(_contentAttributesJson);
    _contentAttributesByScope.clear();
    NotificationService().notify(notifyContentAttributesChanged);
  }

  // Images Content Items

  @protected
  String get imagesContentCategory =>
    _imagesContentCategory;

  Map<String, dynamic>? get contentImages =>
    contentMapItem(imagesContentCategory);

  String? randomImageUrl(String key) {
    List<dynamic>? list = JsonUtils.listValue(MapPathKey.entry(contentImages, "random.$key"));
    return ((list != null) && list.isNotEmpty) ? JsonUtils.stringValue(list[Random().nextInt(list.length)]) : null;
  }

  void _onContentImagesChanged() {
    NotificationService().notify(notifyContentImagesChanged);
  }

  // Widgets Content Items

  @protected
  String get widgetsContentCategory =>
    _widgetsContentCategory;

  Map<String, dynamic>? get contentWidgets =>
    contentMapItem(widgetsContentCategory);

  Map<String, dynamic>? contentWidget(String key) =>
    contentWidgets?[key];

  void _onContentWidgetsChanged() {
    NotificationService().notify(notifyContentWidgetsChanged);
  }

  // ContentItemCategoryClient

  @override
  List<String> get contentItemCategory => <String>[
    attributesContentCategory,
    imagesContentCategory,
    widgetsContentCategory,
  ];

  // Images

  Future<ImagesResult> useUrl({String? storageDir, required String url, int? width}) async {
    // 1. first check if the url gives an image
    Uri? uri = Uri.tryParse(url);
    Response? headersResponse = (uri != null) ? await head(Uri.parse(url)) : null;
    if ((headersResponse != null) && (headersResponse.statusCode == 200)) {
      //check content type
      Map<String, String> headers = headersResponse.headers;
      String? contentType = headers["content-type"];
      bool isImage = _isValidImage(contentType);
      if (isImage) {
        // 2. download the image
        Response response = await get(Uri.parse(url));
        Uint8List imageContent = response.bodyBytes;
        // 3. call the Content service api
        String fileName = const Uuid().v1();
        return uploadImage(storagePath: storageDir, imageBytes: imageContent, fileName: fileName, width: width, mediaType: contentType);
      } else {
        return ImagesResult.error(ImagesErrorType.contentTypeNotSupported, "The provided content type is not supported");
      }
    } else {
      return ImagesResult.error(ImagesErrorType.headerFailed, "Error on checking the resource content type");
    }
  }

  bool _isValidImage(String? contentType) {
    if (contentType == null) return false;
    return contentType.startsWith("image/");
  }

  Future<ImagesResult?> selectImageFromDevice({String? storagePath, int? width, bool? isUserPic}) async {
    XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) {
      // User has cancelled operation
      return ImagesResult.cancel();
    }
    try {
      if ((0 < await image.length())) {
        Uint8List? imageBytes = await _rotateImage(image.path);
        String fileName = basename(image.path);
        String? contentType = mime(fileName);
        return uploadImage(
            storagePath: storagePath,
            imageBytes: imageBytes,
            width: width,
            fileName: fileName,
            mediaType: contentType,
            isUserPic: isUserPic);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<Uint8List?> _rotateImage(String filePath) async {
    if (StringUtils.isEmpty(filePath)) {
      return null;
    }
    File rotatedImage = await FlutterExifRotation.rotateImage(path: filePath);
    return await rotatedImage.readAsBytes();
  }

  Future<ImagesResult> uploadImage(
      {List<int>? imageBytes, String? fileName, String? storagePath, int? width, String? mediaType, bool? isUserPic}) async {
    String? serviceUrl = Config().contentUrl;
    if (StringUtils.isEmpty(serviceUrl)) {
      return ImagesResult.error(ImagesErrorType.serviceNotAvailable, 'Missing images BB url.');
    }
    if (CollectionUtils.isEmpty(imageBytes)) {
      return ImagesResult.error(ImagesErrorType.contentNotSupplied, 'No file bytes.');
    }
    if (StringUtils.isEmpty(fileName)) {
      return ImagesResult.error(ImagesErrorType.fileNameNotSupplied, 'Missing file name.');
    }
    if ((isUserPic != true) && StringUtils.isEmpty(storagePath)) {
      return ImagesResult.error(ImagesErrorType.storagePathNotSupplied, 'Missing storage path.');
    }
    if ((isUserPic != true) && ((width == null) || (width <= 0))) {
      return ImagesResult.error(ImagesErrorType.dimensionsNotSupplied, 'Invalid image width. Please, provide positive number.');
    }
    if (StringUtils.isEmpty(mediaType)) {
      return ImagesResult.error(ImagesErrorType.mediaTypeNotSupplied, 'Missing media type.');
    }
    String url = (isUserPic == true) ? "$serviceUrl/profile_photo" : "$serviceUrl/image";
    Map<String, String> imageRequestFields = {
      'quality': 100.toString() // Use maximum quality - 100
    };
    if (isUserPic != true) {
      imageRequestFields.addAll({'path': storagePath!, 'width': width.toString()});
    }
    StreamedResponse? response = await Network().multipartPost(
        url: url,
        fileKey: 'fileName',
        fileName: fileName,
        fileBytes: imageBytes,
        contentType: mediaType,
        fields: imageRequestFields,
        auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String responseString = (await response?.stream.bytesToString())!;
    if (responseCode == 200) {
      Map<String, dynamic>? json = JsonUtils.decodeMap(responseString);
      String? imageUrl = (json != null) ? JsonUtils.stringValue(json['url']) : null;
      if (isUserPic == true) {
        NotificationService().notify(notifyUserProfilePictureChanged, null);
      }
      return ImagesResult.succeed(imageUrl: imageUrl, imageData: (imageBytes != null) ? Uint8List.fromList(imageBytes) : null);
    } else {
      debugPrint("Failed to upload image. Reason: $responseCode $responseString");
      return ImagesResult.error(ImagesErrorType.uploadFailed, "Failed to upload image: $responseString");
    }
  }

  // User Photo

  Future<ImagesResult> deleteUserPhoto() async {
    String? serviceUrl = Config().contentUrl;
    if (StringUtils.isEmpty(serviceUrl)) {
      return ImagesResult.error(ImagesErrorType.serviceNotAvailable, 'Missing content BB url.');
    }
    String url = '$serviceUrl/profile_photo';
    Response? response = await Network().delete(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    if (responseCode == 200) {
      NotificationService().notify(notifyUserProfilePictureChanged, null);
      return ImagesResult.succeed();
    } else {
      String? responseString = response?.body;
      debugPrint("Failed to delete user's profile image. Reason: $responseCode $responseString");
      return ImagesResult.error(ImagesErrorType.deleteFailed, "Failed to delete user's profile image: $responseString", );
    }
  }

  Future<ImagesResult?> loadUserPhoto({ UserProfileImageType? type, String? accountId }) async {
    String? url = getUserPhotoUrl(accountId: accountId, type: type);
    if (StringUtils.isNotEmpty(url)) {
      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? ImagesResult.succeed(imageData: response?.bodyBytes) : ImagesResult.error(ImagesErrorType.retrieveFailed, response?.body);
    }
    else {
      return null;
    }
  }

  Future<bool?> checkUserPhoto({ String? accountId }) async {
    String? url = getUserPhotoUrl(accountId: accountId);
    if (StringUtils.isNotEmpty(url)) {
      Response? response = await Network().get(url, auth: Auth2()); //TBD: use HEAD Http reqiest.
      return (response?.statusCode == 200);
    }
    else {
      return null;
    }
  }

  String? getUserPhotoUrl({ String? accountId, UserProfileImageType? type, Map<String, String>? params }) {
    String? serviceUrl = Config().contentUrl;
    if (StringUtils.isNotEmpty(serviceUrl)) {
      String imageUrl = (accountId != null) ? '$serviceUrl/profile_photo/$accountId' : '$serviceUrl/profile_photo';
      Map<String, String>? urlParams;
      if (type != null) {
        urlParams = (params != null) ? Map<String, String>.from(params) : {};
        urlParams['size'] = _profileImageTypeToString(type);
      }
      else {
        urlParams = params;
      }
      return (urlParams != null) ? UrlUtils.buildWithQueryParameters(imageUrl, urlParams) : imageUrl;
    }
    else {
      return null;
    }
  }

  static String _profileImageTypeToString(UserProfileImageType type) {
    switch (type) {
      case UserProfileImageType.defaultType:
        return 'default';
      case UserProfileImageType.medium:
        return 'medium';
      case UserProfileImageType.small:
        return 'small';
    }
  }

  // Profile Voice Record

  Future<AudioResult> uploadUserNamePronunciation(Uint8List? audioFile) async{ //TBD return type
    String? serviceUrl = Config().contentUrl;
    if (StringUtils.isEmpty(serviceUrl)) {
      return AudioResult.error(AudioErrorType.serviceNotAvailable, 'Missing voice_record BB url.');
    }
    if (CollectionUtils.isEmpty(audioFile)) {
      return AudioResult.error(AudioErrorType.fileNameNotSupplied, 'Missing file.');
    }
    String url = "$serviceUrl/voice_record";
    StreamedResponse? response = await Network().multipartPost(
        url: url,
        fileKey: "voiceRecord",
        fileName: "record.m4a",
        // fileName: audioFile.name,
        fileBytes: audioFile,
        contentType: 'audio/m4a',
        auth: Auth2()
    );

    int responseCode = response?.statusCode ?? -1;
    if (responseCode == 200) {
      return AudioResult.succeed(audioData: audioFile);
    } else {
      String? responseString = (await response?.stream.bytesToString());
      debugPrint("Failed to upload audio. Reason: $responseCode $responseString");
      return AudioResult.error(AudioErrorType.uploadFailed, "Failed to upload audio: $responseString");
    }
  }

  Future<AudioResult?> deleteUserNamePronunciation() async {
    String? serviceUrl = Config().contentUrl;
    if (StringUtils.isEmpty(serviceUrl)) {
      return AudioResult.error(AudioErrorType.serviceNotAvailable, 'Missing voice_record BB url.');
    }
    String url = "$serviceUrl/voice_record";
    Response? response = await Network().delete(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    if (responseCode == 200) {
      return AudioResult.succeed();
    } else {
      String? responseString = response?.body;
      debugPrint("Failed to delete user's profile voice record. Reason: $responseCode $responseString");
      return AudioResult.error(AudioErrorType.deleteFailed, "Failed to delete user's profile voice record: $responseString", );
    }
  }

  Future<AudioResult?> loadUserNamePronunciation({ String? accountId }) =>
      loadUserNamePronunciationFromUrl(getUserNamePronunciationUrl(accountId: accountId));

  Future<AudioResult?> loadUserNamePronunciationFromUrl(String? url) async {
    if (StringUtils.isNotEmpty(url)) {
      Response? response = await Network().get(url, auth: Auth2());
      return  (response?.statusCode == 200) ? AudioResult.succeed(audioData: response?.bodyBytes) : AudioResult.error(AudioErrorType.retrieveFailed, response?.body);
    }
    else {
      return null;
    }
  }

  Future<bool?> checkUserNamePronunciation({ String? accountId }) async {
    String? url = getUserNamePronunciationUrl(accountId: accountId);
    if (StringUtils.isNotEmpty(url)) {
      Response? response = await Network().get(url, auth: Auth2()); //TBD: use HEAD Http reqiest.
      return (response?.statusCode == 200);
    }
    else {
      return null;
    }
  }

  String? getUserNamePronunciationUrl({ String? accountId }) {
    String? serviceUrl = Config().contentUrl;
    if (StringUtils.isNotEmpty(serviceUrl)) {
      return (accountId != null) ? '$serviceUrl/voice_record/$accountId' : '$serviceUrl/voice_record';
    }
    else {
      return null;
    }
  }

  Future<Uint8List?> getFileContentItem(String fileName, String category) async {
    String key = '${fileName}_${category}';
    if (_fileContentCache[key] != null) {
      return _fileContentCache[key];
    }
    if (StringUtils.isNotEmpty(Config().contentUrl)) {
      Response? response;
      if (_fileContentFutures[key] == null) {
        Map<String, String> queryParams = {
          'fileName': fileName,
          'category': category,
        };
        String url = "${Config().contentUrl}/files";
        if (queryParams.isNotEmpty) {
          url = UrlUtils.addQueryParameters(url, queryParams);
        }

        _fileContentFutures[key] = Network().get(url, auth: Auth2());
      }
      response = await _fileContentFutures[key];
      _fileContentFutures[key] = null;

      int? responseCode = response?.statusCode;
      if (responseCode == 200) {
        Uint8List? fileContent = response?.bodyBytes;
        if (fileContent != null) {
          return _fileContentCache[key] = fileContent;
        }
      } else {
        String? responseString = response?.body;
        debugPrint("Failed to get file content item. Reason: $responseCode $responseString");
      }
    }
    return null;
  }
}

abstract class ContentItemCategoryClient {
  List<String> get contentItemCategory;
}

class _CompareContentItemsParam {
  final Map<String, dynamic>? items1;
  final Map<String, dynamic>? items2;
  _CompareContentItemsParam(this.items1, this.items2);
}

enum ImagesResultType { error, cancelled, succeeded }
enum ImagesErrorType {
  headerFailed,
  contentTypeNotSupported,
  serviceNotAvailable,
  contentNotSupplied,
  fileNameNotSupplied,
  storagePathNotSupplied,
  dimensionsNotSupplied,
  mediaTypeNotSupplied,
  uploadFailed,
  deleteFailed,
  retrieveFailed,
}

class ImagesResult {
  final ImagesResultType resultType;
  final ImagesErrorType? errorType;
  final String? errorMessage;
  final String? imageUrl;
  final Uint8List? imageData;

  ImagesResult(this.resultType, { this.errorType, this.errorMessage, this.imageUrl, this.imageData});

  factory ImagesResult.error(ImagesErrorType? errorType, String? errorMessage) =>
    ImagesResult(ImagesResultType.error, errorType: errorType, errorMessage: errorMessage);

  factory ImagesResult.cancel() =>
    ImagesResult(ImagesResultType.cancelled);

  factory ImagesResult.succeed({String? imageUrl, Uint8List? imageData}) =>
    ImagesResult(ImagesResultType.succeeded, imageUrl: imageUrl, imageData: imageData);

  bool get succeeded => (resultType == ImagesResultType.succeeded);
}

enum UserProfileImageType { defaultType, medium, small }

enum AudioResultType { error, cancelled, succeeded }
enum AudioErrorType {serviceNotAvailable, fileNameNotSupplied, uploadFailed, deleteFailed, retrieveFailed}

class AudioResult {
  final AudioResultType resultType;
  final AudioErrorType? errorType;
  final String? errorMessage;
  final Uint8List? audioData;

  AudioResult(this.resultType, { this.errorType, this.errorMessage, this.audioData});

  factory AudioResult.error(AudioErrorType? errorType, String? errorMessage) =>
    AudioResult(AudioResultType.error, errorType: errorType, errorMessage: errorMessage);

  factory AudioResult.cancel() =>
      AudioResult(AudioResultType.cancelled);

  factory AudioResult.succeed({ Uint8List? audioData }) =>
    AudioResult(AudioResultType.succeeded, audioData: audioData);

  bool get succeeded => (resultType == AudioResultType.succeeded);
}

extension FileExtention on FileSystemEntity{ //file.name
  String? get name {
    return this.path.split(Platform.pathSeparator).last;
  }
}