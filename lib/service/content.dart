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
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

// Content service does rely on Service initialization API so it does not override service interfaces and is not registered in Services.
class Content with Service implements NotificationsListener {

  static const String notifyContentAttributesChanged      = "edu.illinois.rokwire.group.content_attributes.changed";
  static const String notifyUserProfilePictureChanged     = "edu.illinois.rokwire.content.user.picture.profile.changed";

  static const String _contentAttributesCategory = "attributes";
  static const String _contentAttributesCacheFileName = "contentAttributes.json";

  Directory? _appDocDir;
  DateTime?  _pausedDateTime;
  
  ContentAttributes? _contentAttributes;
  final Map<String, ContentAttributes> _contentAttributesByScope = <String, ContentAttributes>{};

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
    _appDocDir = await _getAppDocumentsDirectory();
    _contentAttributes = await _loadContentAttributesFromCache();
    if (_contentAttributes == null) {
      Map<String, dynamic>? contentAttributesJson = await _loadContentAttributesJsonFromNet();
      ContentAttributes? contentAttributes = ContentAttributes.fromJson(contentAttributesJson);
      if (contentAttributes != null) {
        _contentAttributes = contentAttributes;
        _saveContentAttributesStringToCache(JsonUtils.encode(contentAttributesJson));
      }
    }
    else {
      _updateContentAttributes();
    }

    await super.initService();
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
          _updateContentAttributes();
        }
      }
    }
  }

  // Caching

  Future<Directory?> _getAppDocumentsDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    }
    catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  // Content Attributes

  ContentAttributes? contentAttributes(String scope) => (_contentAttributes != null) ?
      (_contentAttributesByScope[scope] ??= (ContentAttributes.fromOther(_contentAttributes, scope: scope) ?? ContentAttributes())) : null;

  File? _getContentAttributesCacheFile() =>
    (_appDocDir != null) ? File(join(_appDocDir!.path, _contentAttributesCacheFileName)) : null;

  Future<String?> _loadContentAttributesStringFromCache() async {
    try {
      File? cacheFile = _getContentAttributesCacheFile();
      return (await cacheFile?.exists() == true) ? await cacheFile?.readAsString() : null;
    }
    catch(e) { 
      debugPrint(e.toString()); 
    }
    return null;
  }

  Future<void> _saveContentAttributesStringToCache(String? value) async {
    try {
      File? cacheFile = _getContentAttributesCacheFile();
      if (cacheFile != null) {
        if (value != null) {
          await cacheFile.writeAsString(value, flush: true);
        }
        else if (await cacheFile.exists()){
          await cacheFile.delete();
        }
      }
    }
    catch(e) { 
      debugPrint(e.toString());
    }
  }

  Future<ContentAttributes?> _loadContentAttributesFromCache() async {
    return ContentAttributes.fromJson(JsonUtils.decodeMap(await _loadContentAttributesStringFromCache()));
  }

  Future<Map<String, dynamic>?> _loadContentAttributesJsonFromNet() async {
    //TMP: return await AppBundle.loadString('assets/content.attributes.json');
    Response? response = await Network().get("${Config().contentUrl}/content_items", auth: Auth2(), body: JsonUtils.encode({"categories":[_contentAttributesCategory]}));
    List<dynamic>? resonseJsonList = (response?.statusCode == 200) ? JsonUtils.decodeList(response?.body) : null;
    Map<String, dynamic>? resonseJson = ((resonseJsonList != null) && resonseJsonList.isNotEmpty) ? JsonUtils.mapValue(resonseJsonList.first) : null;
    return (resonseJson != null) ? JsonUtils.mapValue(resonseJson['data']) : null;
  }

  Future<void> _updateContentAttributes() async {
    Map<String, dynamic>? contentAttributesJson = await _loadContentAttributesJsonFromNet();
    ContentAttributes? contentAttributes = ContentAttributes.fromJson(contentAttributesJson);
    if ((contentAttributes != null) && (contentAttributes != _contentAttributes)) {
      _contentAttributes = contentAttributes;
      _contentAttributesByScope.clear();
      _saveContentAttributesStringToCache(JsonUtils.encode(contentAttributesJson));
      NotificationService().notify(notifyContentAttributesChanged);
    }
  }

  // Implementation

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
      Map<String, dynamic>? json = JsonUtils.decode(responseString);
      String? imageUrl = (json != null) ? json['url'] : null;
      if (isUserPic == true) {
        NotificationService().notify(notifyUserProfilePictureChanged, null);
      }
      return ImagesResult.succeed(imageUrl);
    } else {
      debugPrint("Failed to upload image. Reason: $responseCode $responseString");
      return ImagesResult.error(ImagesErrorType.uploadFailed, "Failed to upload image.", response);
    }
  }

  Future<ImagesResult> deleteCurrentUserProfileImage() async {
    String? serviceUrl = Config().contentUrl;
    if (StringUtils.isEmpty(serviceUrl)) {
      return ImagesResult.error(ImagesErrorType.serviceNotAvailable, 'Missing content BB url.');
    }
    String url = '$serviceUrl/profile_photo';
    Response? response = await Network().delete(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    if (responseCode == 200) {
      NotificationService().notify(notifyUserProfilePictureChanged, null);
      return ImagesResult.succeed('User profile image deleted.');
    } else {
      String? responseString = response?.body;
      debugPrint("Failed to delete user's profile image. Reason: $responseCode $responseString");
      return ImagesResult.error(ImagesErrorType.deleteFailed, "Failed to delete user's profile image.", responseString);
    }
  }

  Future<Uint8List?> loadDefaultUserProfileImage({String? accountId}) async {
    return loadUserProfileImage(UserProfileImageType.defaultType, accountId: accountId);
  }

  Future<Uint8List?> loadSmallUserProfileImage({String? accountId}) async {
    return loadUserProfileImage(UserProfileImageType.small, accountId: accountId);
  }

  Future<Uint8List?> loadUserProfileImage(UserProfileImageType type, {String? accountId}) async {
    String? url = getUserProfileImage(accountId: accountId, type: type);
    if (StringUtils.isEmpty(url)) {
      debugPrint('Failed to construct user profile image url.');
      return null;
    }
    Response? response = await Network().get(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    if (responseCode == 200) {
      return response!.bodyBytes;
    } else {
      debugPrint('Failed to retrieve user profile picture for user {$accountId} and image type {${_profileImageTypeToKeyString(type)}}}. \nReason: $responseCode: ${response?.body}');
      return null;
    }
  }

  String? getUserProfileImage({String? accountId, UserProfileImageType? type = UserProfileImageType.small}) {
    String? serviceUrl = Config().contentUrl;
    if (StringUtils.isEmpty(serviceUrl)) {
      debugPrint('Missing content service url.');
      return null;
    }

    String? userAccountId = accountId ?? Auth2().accountId;
    if (StringUtils.isEmpty(userAccountId)) {
      debugPrint('Missing account id.');
      return null;
    }
    String typeToString = _profileImageTypeToKeyString(type!);
    String imageUrl = '$serviceUrl/profile_photo/$userAccountId?size=$typeToString';
    return imageUrl;
  }

  Future<Uint8List?> _rotateImage(String filePath) async {
    if (StringUtils.isEmpty(filePath)) {
      return null;
    }
    File rotatedImage = await FlutterExifRotation.rotateImage(path: filePath);
    return await rotatedImage.readAsBytes();
  }

  bool _isValidImage(String? contentType) {
    if (contentType == null) return false;
    return contentType.startsWith("image/");
  }

  static String _profileImageTypeToKeyString(UserProfileImageType type) {
    switch (type) {
      case UserProfileImageType.defaultType:
        return 'default';
      case UserProfileImageType.medium:
        return 'medium';
      case UserProfileImageType.small:
        return 'small';
    }
  }

  // Content Items

  Future<List<dynamic>?> loadContentItems({List<String>? categories, List<String>? ids}) async {
    String? serviceUrl = Config().contentUrl;
    if (StringUtils.isEmpty(serviceUrl)) {
      debugPrint('Missing content service url.');
      return null;
    }
    if (CollectionUtils.isEmpty(categories) && CollectionUtils.isEmpty(ids)) {
      debugPrint('Missing content item category');
      return null;
    }

    Map<String, dynamic> json = {};
    if(CollectionUtils.isNotEmpty(categories)){
      json["categories"] = categories;
    }

    if(CollectionUtils.isNotEmpty(ids)){
      json["ids"] = ids;
    }
    String? body = JsonUtils.encode(json);

    String url = "$serviceUrl/content_items";
    Response? response = await Network().get(url, body: body, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      String? responseBody = response?.body;
      return (responseBody != null) ? JsonUtils.decodeList(responseBody) : null;
    } else {
      debugPrint('Failed to load content itemReason: ');
      debugPrint(responseBody);
      return null;
    }
  }
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
}

class ImagesResult {
  ImagesResultType? resultType;
  ImagesErrorType? errorType;
  String? errorMessage;
  dynamic data;

  ImagesResult.error(this.errorType, this.errorMessage, [this.data]) :
    resultType = ImagesResultType.error;

  ImagesResult.cancel() :
    resultType = ImagesResultType.cancelled;

  ImagesResult.succeed(this.data) :
    resultType = ImagesResultType.succeeded;
}

enum UserProfileImageType { defaultType, medium, small }
