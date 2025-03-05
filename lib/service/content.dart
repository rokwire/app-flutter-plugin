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

import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/ext/network.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:async/async.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:universal_io/io.dart';

//import 'package:flutter/services.dart' show rootBundle;

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

  static const String conversationsContentCategory = "conversations";
  static const String awsS3UploadPartQueryParamPartNumber = "partNumber";
  static const String awsS3UploadPartResponseHeaderETag = "etag";

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
      AppLifecycle.notifyStateChanged,
      Auth2.notifyLoginChanged,
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
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Config(), Storage(), Auth2() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
    } else if (name == Auth2.notifyLoginChanged) {
      if (_contentItems == null && Auth2().isLoggedIn) {
        loadContentItemsFromNet().then((contentItems) {
          _contentItems = contentItems;
          _contentAttributes = ContentAttributes.fromJson(_contentAttributesJson);
        });
      }
    }
  }

  void _onAppLifecycleStateChanged(AppLifecycleState? state) {
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
    if (Config().contentUrl != null && Auth2().isLoggedIn) {
      Response? response = await Network().post("${Config().contentUrl}/content_items", body: JsonUtils.encode({'categories': categories}), auth: Auth2());
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
    //TMP:
    //return JsonUtils.decode(await rootBundle.loadString('assets/privacy.json'));
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
    debugPrint("Delete $url => ${response?.statusCode}");
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
      debugPrint("GET $url => ${response?.statusCode} ${(response?.succeeded == true) ? ('<' + (response?.bodyBytes.length.toString() ?? '') + ' bytes>') : response?.body}");
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
    debugPrint("Delete $url => ${response?.statusCode}");
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
      debugPrint("GET $url => ${response?.statusCode} ${(response?.succeeded == true) ? ('<' + (response?.bodyBytes.length.toString() ?? '') + ' bytes>') : response?.body}");
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

  Future<Map<String, Uint8List>> getFileContentItems(List<String> fileKeys, String category, {String? entityId}) async {
    Map<String, Uint8List> files = {};
    List<String> load = [];
    for (String fileKey in fileKeys) {
      String key = '${category}_${fileKey}';
      if (_fileContentCache[key] != null) {
        files[fileKey] = _fileContentCache[key]!;
      } else if (_fileContentFutures[key] == null) {
        load.add(fileKey);
      }
    }

    if (load.isNotEmpty) {
      List<FileContentItemReference>? fileRefs = await getFileContentDownloadUrls(fileKeys, category, entityId: entityId);

      if (StringUtils.isNotEmpty(Config().contentUrl)) {
        List<Future<Response?>> responseFutures = [];
        for (int i = 0; i < (fileRefs?.length ?? 0); i++) {
          String? url = fileRefs![i].url;
          if (url != null) {
            responseFutures.add(_fileContentFutures[url] = Network().get(url,));
          }
        }

        List<Response?> responses = await Future.wait(responseFutures);
        for (int i = 0; i < responses.length; i++) {
          Response? response = responses[i];
          FileContentItemReference? fileRef = fileRefs?[i];
          int responseCode = response?.statusCode ?? -1;

          // response code 2xx
          if (fileRef != null && responseCode ~/ 100 == 2) {
            String fileKey = fileRef.key ?? '';
            String? requestUrl = fileRef.url ?? '';
            _fileContentFutures[requestUrl] = null;
            // response code 2xx
            if (responseCode ~/ 100 == 2) {
              Uint8List? fileContent = response?.bodyBytes;
              if (fileContent != null) {
                files[fileKey] = _fileContentCache['${category}_${fileKey}'] = fileContent;
              }
            } else {
              debugPrint("Failed to download file key $fileKey from $requestUrl. Reason: $responseCode ${response?.body}");
            }
          }
        }
      }
    }
    return files;
  }

  Future<List<FileContentItemReference>?> getFileContentDownloadUrls(List<String> fileKeys, String category, {String? entityId}) async {
    if (StringUtils.isNotEmpty(Config().contentUrl)) {
      Map<String, String> queryParams = {
        'fileKeys': fileKeys.join(','),
        'category': category,
      };
      if (entityId != null) {
        queryParams['entityID'] = entityId;
      }
      String url = "${Config().contentUrl}/files/download";
      if (queryParams.isNotEmpty) {
        url = UrlUtils.addQueryParameters(url, queryParams);
      }
      Response? response = await Network().get(url, auth: Auth2());

      int? responseCode = response?.statusCode;
      if (responseCode == 200) {
        String? responseBody = response?.body;
        if (responseBody != null) {
          List<dynamic>? fileReferences = JsonUtils.decodeList(responseBody);
          return FileContentItemReference.listFromJson(fileReferences);
        }
      } else {
        String? responseString = response?.body;
        debugPrint("Failed to get references for file content downloads. Reason: $responseCode $responseString");
      }
    }
    return null;
  }

  Future<List<FileContentItemReference>?> uploadFileContentItems(Map<String, FutureOr<Uint8List?>> files, String category, {
    String? entityId,
    Function(FileContentItemReference)? preUpload,
    Function(FileContentItemReference, Response?)? postUpload,
  }) async {
    List<FileContentItemReference> uploaded = [];

    //TODO: implement number of files limit per upload
    if (StringUtils.isNotEmpty(Config().contentUrl) && files.isNotEmpty) {
      List<FileContentItemReference>? fileRefs = await getFileContentUploadUrls(files.keys.toList(), category, entityId: entityId);
      if ((fileRefs?.length ?? 0) == files.length) {
        List<Future<Response?>> responseFutures = [];
        for (int i = 0; i < (fileRefs?.length ?? 0); i++) {
          FileContentItemReference ref = fileRefs![i];
          ref.name = files.keys.elementAt(i);
          Uint8List? bytes = await files[ref.name];
          if (bytes != null) {
            responseFutures.add(_uploadFileContentItem(ref, bytes, preUpload: preUpload, postUpload: postUpload));
          }
        }

        List<Response?> responses = await Future.wait(responseFutures);
        for (int i = 0; i < responses.length; i++) {
          Response? response = responses[i];
          FileContentItemReference? fileRef = fileRefs?[i];
          int responseCode = response?.statusCode ?? -1;
          String? requestUrl = fileRef?.url ?? '';
          String fileName = fileRef?.name ?? '';

          // response code 2xx
          if (fileRef != null && responseCode ~/ 100 == 2) {
            uploaded.add(fileRef);
          } else {
            String? responseString = response?.body;
            debugPrint("Failed to upload $fileName to $requestUrl. Reason: $responseCode $responseString");
          }
        }
      }
    }
    return uploaded;
  }

  Future<List<FileContentItemReference>?> getFileContentUploadUrls(List<String> fileNames, String category, {String? entityId}) async {
    if (StringUtils.isNotEmpty(Config().contentUrl)) {
      Map<String, String> queryParams = {
        'fileNames': fileNames.join(','),
        'category': category,
      };
      if (entityId != null) {
        queryParams['entityID'] = entityId;
      }
      String url = "${Config().contentUrl}/files/upload";
      if (queryParams.isNotEmpty) {
        url = UrlUtils.addQueryParameters(url, queryParams);
      }
      Response? response = await Network().get(url, auth: Auth2());

      int? responseCode = response?.statusCode;
      if (responseCode == 200) {
        String? responseBody = response?.body;
        if (responseBody != null) {
          List<dynamic>? fileReferences = JsonUtils.decodeList(responseBody);
          return FileContentItemReference.listFromJson(fileReferences);
        }
      } else {
        String? responseString = response?.body;
        debugPrint("Failed to get references for file content uploads. Reason: $responseCode $responseString");
      }
    }
    return null;
  }

  Future<Response?> _uploadFileContentItem(FileContentItemReference ref, Uint8List bytes, {
    FutureOr<void> Function(FileContentItemReference)? preUpload,
    FutureOr<void> Function(FileContentItemReference, Response?)? postUpload
  }) async {
    await preUpload?.call(ref);

    Future<Response?> response = Network().put(ref.url, body: bytes);
    response.then((response) {
      postUpload?.call(ref, response);
    });

    return response;
  }

  // Multipart upload

  Future<MultipartFileUpload> multipartUploadFile(File file, {int? fileSize, required String category, String? entityId,
      Function(int, int, Response?)? onPartUploaded, Function()? onUploadCompleted, Function()? onUploadAborted}) async {
    fileSize ??= await file.length();
    if (fileSize > 0) {
      MultipartFileUpload? uploadData = await getMultipartUploadUrls(fileName: file.path, size: fileSize, category: category, entityId: entityId);
      if (uploadData?.isValid ?? false) {
        int totalParts = uploadData!.signedUrls!.length;
        int partSize = (fileSize ~/ totalParts) + 1;
        List<int> partStarts = List.generate(totalParts, (index) => index * partSize);
        uploadData.result = await _uploadFileParts(uploadData, totalParts, file, partStarts: partStarts,
            category: category, entityId: entityId, onPartUploaded: onPartUploaded, onUploadCompleted: onUploadCompleted, onUploadAborted: onUploadAborted);
        return uploadData;
      } else {
        debugPrint('Error uploading multipart file: invalid upload data');
      }
    } else {
      debugPrint('Error uploading multipart file: file is empty');
    }
    return MultipartFileUpload(
        result: MultipartUploadResult.failed
    );
  }

  Future<MultipartUploadResult> _uploadFileParts(MultipartFileUpload uploadData, int totalParts, File file, {required String category, String? entityId,
      required List<int> partStarts, Map<int, int>? retryCounts, List<String?>? eTags, Function(int, int, Response?)? onPartUploaded, Function()? onUploadCompleted, Function()? onUploadAborted}) async {
    List<Future<Response?>> responseFutures = [];

    for (int i in retryParts) {
      String? signedUrl = uploadData.signedUrls?[i];
      Uint8List partBytes = splitBytes[i];
      if (signedUrl == null) {
        debugPrint('Error uploading file part: missing signed urls $uploadData');
        return MultipartUploadResult.failed;
      }
      String? partNumberStr = Uri.tryParse(signedUrl)?.queryParameters[awsS3UploadPartQueryParamPartNumber] ?? '';
      int partNumber = int.tryParse(partNumberStr) ?? i + 1;
      responseFutures.add(_uploadFilePart(signedUrl, partBytes, partNumber: partNumber, totalParts: totalParts, onPartUploaded: onPartUploaded));
    }

    List<Response?> responses = await Future.wait(responseFutures);
    eTags ??= List.filled(totalParts, null);
    List<int> failedParts = [];
    for (int i = 0; i < responses.length; i++) {
      Response? response = responses[i];
      int responseCode = response?.statusCode ?? -1;
      if (responseCode ~/ 100 == 2) {
        String? eTag = response?.headers[awsS3UploadPartResponseHeaderETag]?.replaceAll(RegExp(r'\W'), ''); // get eTag from response header and remove non-alphanumeric characters
        eTags[i] = eTag;
      } else {
        // part upload failed
        failedParts.add(i);
        String? responseBody = response?.body;
        debugPrint('Error uploading file part: response $responseCode $responseBody');
      }
    }

    double failureRate = failedParts.length / totalParts;
    if (failureRate > Config().multipartPartUploadFailureCutoff) {
      debugPrint('Aborting multipart upload: max fraction of failed part uploads exceeded - ${failedParts.length}/$totalParts');
      MultipartUploadResult result = await abortMultipartUpload(uploadId: uploadData.uploadId!, category: category, entityId: entityId, fileKey: uploadData.fileKey);
      if (result == MultipartUploadResult.completed) {
        onUploadAborted?.call();
        return MultipartUploadResult.aborted;
      }
      return result;
    }
    if (retryCount >= Config().multipartPartUploadRetryLimit) {
      debugPrint('Aborting multipart upload: failed part upload retry limit reached - $retryCount');
      MultipartUploadResult result = await abortMultipartUpload(uploadId: uploadData.uploadId!, category: category, entityId: entityId, fileKey: uploadData.fileKey);
      if (result == MultipartUploadResult.completed) {
        onUploadAborted?.call();
        return MultipartUploadResult.aborted;
      }
      return result;
    }
    if (failureRate > 0) {
      MultipartUploadResult result = await _uploadFileParts(uploadData, splitBytes, category: category, entityId: entityId,
          retryCount: ++retryCount, retryParts: failedParts, onPartUploaded: onPartUploaded, onUploadCompleted: onUploadCompleted);
      return result;
    }
    if (eTags.contains(null)) {
      debugPrint('Aborting multipart upload: failed to get $awsS3UploadPartResponseHeaderETag for all parts');
      MultipartUploadResult result = await abortMultipartUpload(uploadId: uploadData.uploadId!, category: category, entityId: entityId, fileKey: uploadData.fileKey);
      if (result == MultipartUploadResult.completed) {
        onUploadAborted?.call();
        return MultipartUploadResult.aborted;
      }
      return result;
    }

    // complete the upload
    MultipartUploadResult result = await completeMultipartUpload(uploadId: uploadData.uploadId!, category: category, entityId: entityId, eTags: eTags, fileKey: uploadData.fileKey);
    //TODO: attempt abort if complete fails?
    onUploadCompleted?.call();
    return result;
  }

  Future<Response?> _uploadFilePart(String url, Uint8List bytes, {required int partNumber, required int totalParts, Function(int, int, Response?)? onPartUploaded}) async {
    Future<Response?> response = Network().put(url, body: bytes,);
    response.then((response) {
      onPartUploaded?.call(partNumber, totalParts, response);
    });

    return response;
  }

  Future<MultipartFileUpload?> getMultipartUploadUrls({required String fileName, required int size, required String category, String? entityId}) async {
    if (StringUtils.isNotEmpty(Config().contentUrl)) {
      fileName = fileName.split('/').last; // remove any path prefix
      try {
        String? body = JsonUtils.encode(<String, dynamic>{
          'fileName': fileName,
          'sizeInBytes': size,
          'category': category,
          'entityID': entityId,
        });
        Map<String, String> headers = {
          'Content-Type': 'application/json'
        };
        Response? response = await Network().post(
            '${Config().contentUrl}/files/upload/multipart/initiate',
            body: body,
            headers: headers,
            auth: Auth2()
        );
        int responseCode = response?.statusCode ?? -1;
        String? responseBody = response?.body;
        if (responseCode ~/ 100 == 2) {
          Map<String, dynamic>? responseJson = JsonUtils.decodeMap(responseBody);
          if (responseJson != null) {
            try {
              return MultipartFileUpload.fromJson(responseJson);
            } catch (e) {
              debugPrint('Error getting multipart upload urls: response parsing failed $e');
            }
          }
        } else {
          debugPrint('Error getting multipart upload urls: response $responseCode ${response?.body}');
        }
      } catch (e) {
        debugPrint('Error getting multipart upload urls: $e');
      }
    }
    return null;
  }

  Future<MultipartUploadResult> completeMultipartUpload({required String uploadId, required String category, String? entityId, List<String?>? eTags, int retryCount = 0, String? fileKey, bool abort = false}) async {
    if (StringUtils.isNotEmpty(Config().contentUrl) && (abort || !(eTags?.contains(null) ?? true))) {
      String errorAction = abort ? 'aborting' : 'completing';
      try {
        String? body = JsonUtils.encode(<String, dynamic>{
          'uploadID': uploadId,
          'eTags': eTags,
          'fileKey': fileKey,
          'category': category,
          'entityID': entityId,
          'abort': abort,
        });
        Map<String, String> headers = {
          'Content-Type': 'application/json'
        };
        Response? response = await Network().post(
          '${Config().contentUrl}/files/upload/multipart/complete',
          headers: headers,
          body: body,
          auth: Auth2()
        );
        int responseCode = response?.statusCode ?? -1;
        if (responseCode == 200) {
          return MultipartUploadResult.completed;
        } else {
          debugPrint('Error $errorAction multipart upload: response $responseCode ${response?.body}');
        }
      } catch (e) {
        debugPrint('Error $errorAction multipart upload: $e');
      }

      if (retryCount < Config().multipartCompleteUploadRetryLimit) {
        return await completeMultipartUpload(uploadId: uploadId, category: category, entityId: entityId, eTags: eTags, retryCount: ++retryCount, fileKey: fileKey, abort: abort);
      }
    }
    return MultipartUploadResult.failed;
  }

  Future<MultipartUploadResult> abortMultipartUpload({required String uploadId, required String category, String? entityId, String? fileKey}) {
    return completeMultipartUpload(uploadId: uploadId, category: category, entityId: entityId, fileKey: fileKey, abort: true);
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
  final String? audioFileExtension;

  AudioResult(this.resultType, { this.errorType, this.errorMessage, this.audioData, this.audioFileExtension});

  factory AudioResult.error(AudioErrorType? errorType, String? errorMessage) =>
    AudioResult(AudioResultType.error, errorType: errorType, errorMessage: errorMessage);

  factory AudioResult.cancel() =>
      AudioResult(AudioResultType.cancelled);

  factory AudioResult.succeed({ Uint8List? audioData, String? extension }) =>
    AudioResult(AudioResultType.succeeded, audioData: audioData, audioFileExtension: extension);

  bool get succeeded => (resultType == AudioResultType.succeeded);
}

extension FileExtention on FileSystemEntity{ //file.name
  String? get name {
    return this.path.split(Platform.pathSeparator).last;
  }
}

class FileContentItemReference {
  final String? key;
  final String? url;
  String? name;

  FileContentItemReference({this.key, this.url, this.name});

  factory FileContentItemReference.fromJson(Map<String, dynamic> json, {String? name}) {
    return FileContentItemReference(
      key: JsonUtils.stringValue(json['key']),
      url: JsonUtils.stringValue(json['url']),
      name: name,
    );
  }

  static List<FileContentItemReference>? listFromJson(List<dynamic>? jsonList) {
    List<FileContentItemReference>? items;
    if (jsonList != null) {
      items = <FileContentItemReference>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, FileContentItemReference.fromJson(jsonEntry));
      }
    }
    return items;
  }
}

class MultipartFileUpload {
  String? uploadId;
  String? fileKey;
  List<String>? signedUrls;
  MultipartUploadResult? result;

  MultipartFileUpload({this.uploadId, this.fileKey, this.signedUrls, this.result});

  factory MultipartFileUpload.fromJson(Map<String, dynamic> json) => MultipartFileUpload(
    uploadId: JsonUtils.stringValue(json['upload_id']),
    fileKey: JsonUtils.stringValue(json['key']),
    signedUrls: JsonUtils.listStringsValue(json['urls']),
  );

  bool get isValid => StringUtils.isNotEmpty(uploadId) && StringUtils.isNotEmpty(fileKey) && CollectionUtils.isNotEmpty(signedUrls);
}

enum MultipartUploadResult { completed, aborted, failed }