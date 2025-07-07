/*
 * Copyright 2025 Board of Trustees of the University of Illinois.
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

import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

class WebCacheImageService {
  static final String _imageCacheKey = 'web_network_image_cache';

  dynamic _box;

  // Singleton Factory

  static WebCacheImageService? _instance;

  static WebCacheImageService? get instance => _instance;

  @protected
  static set instance(WebCacheImageService? value) => _instance = value;

  factory WebCacheImageService() => _instance ?? (_instance = WebCacheImageService.internal());

  @protected
  WebCacheImageService.internal();

  // Implementation

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(_imageCacheKey);
    } catch (e) {
      debugPrint('Failed to init cache box. Reason: $e');
    }
  }

  Uint8List? getImage(String? imageUrl) {
    if (imageUrl == null) {
      return null;
    }
    try {
      if (_box.containsKey(imageUrl)) {
        return _box.get(imageUrl);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Failed to get image from the cache box. Reason: $e');
      return null;
    }
  }

  void saveImage({required String imageUrl, required Uint8List imageBytes}) {
    try {
      _box.put(imageUrl, imageBytes);
    } catch (e) {
      debugPrint('Failed to save image in the cache box. Reason: $e');
    }
  }
}
