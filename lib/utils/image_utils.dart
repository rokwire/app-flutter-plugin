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
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:path_provider/path_provider.dart';

class ImageUtils {

  ///
  /// imageBytes - the content of the image
  ///
  /// fileName - the name of the file without file extension
  ///
  /// returns true if save operation succeed and false otherwise
  ///
  static Future<bool?> saveToFs(Uint8List? imageBytes, String fileName) async {
    if ((imageBytes == null) || StringUtils.isEmpty(fileName)) {
      return false;
    }
    final String dir = (await getApplicationDocumentsDirectory()).path;
    final String fullPath = '$dir/$fileName.png';
    File capturedFile = File(fullPath);
    await capturedFile.writeAsBytes(imageBytes);
    bool? saveResult = false;
    try {
      saveResult = await GallerySaver.saveImage(capturedFile.path);
    } catch (e) {
      debugPrint('Failed to save image to fs. \nException: ${e.toString()}');
    }
    return saveResult;
  }

  ///
  /// imageBytes - the bytes of the original image
  ///
  /// label - the string that would be displayed over the image
  ///
  /// width - the width of the original image
  ///
  /// height - the height of the original image
  ///
  /// returns the bytes of the updated image
  ///
  static Future<Uint8List?> applyLabelOverImage(Uint8List? imageBytes, String? label, {
    double width = 1024,
    double height = 1024,
    TextStyle? textStyle,
    TextAlign textAlign = TextAlign.center,
    ui.TextDirection textDirection = ui.TextDirection.ltr,
  }) async {
    if (imageBytes != null) {

      try {
        double textGutterX = width / 16;
        double textGutterY = height / 32;

        final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
            ui.ParagraphStyle(textDirection: textDirection, textAlign: textAlign, fontSize: textStyle?.fontSize, fontFamily: textStyle?.fontFamily))
          ..pushStyle(ui.TextStyle(color: textStyle?.color))
          ..addText(label ?? '');
        final ui.Paragraph paragraph = paragraphBuilder.build()..layout(ui.ParagraphConstraints(width: width - 2 * textGutterX));
        final double textHeight = paragraph.height + 2 * textGutterY;
        final double outputHeight = (height + textHeight);

        final recorder = ui.PictureRecorder();
        Canvas canvas = Canvas(recorder, Rect.fromPoints(const Offset(0.0, 0.0), Offset(width, outputHeight)));
        final fillPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawRect(Rect.fromLTWH(0.0, 0.0, width, outputHeight), fillPaint);

        ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
        ui.FrameInfo frameInfo = await codec.getNextFrame();
        canvas.drawImage(frameInfo.image, Offset(0.0, 0.0), fillPaint);
        canvas.drawParagraph(paragraph, Offset(textGutterX, height + textGutterY));

        final picture = recorder.endRecording();
        final img = await picture.toImage(width.toInt(), outputHeight.toInt());
        ByteData pngBytes = await img.toByteData(format: ui.ImageByteFormat.png) ?? ByteData(0);
        Uint8List newQrBytes = Uint8List(pngBytes.lengthInBytes);
        for (int i = 0; i < pngBytes.lengthInBytes; i++) {
          newQrBytes[i] = pngBytes.getUint8(i);
        }
        return newQrBytes;
      } catch (e) {
        debugPrint('Failed to apply label to image. \nException: ${e.toString()}');
      }
    }
    return null;
  }

  static Future<Uint8List?> mapGroupMarkerImage({
    Color? backColor,
    
    Color? strokeColor,
    double strokeWidth = 1,
    
    String? text,
    TextStyle? textStyle,
    
    required double imageSize }) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder, Rect.fromLTRB(0, 0, imageSize, imageSize));
    Offset center = Offset(imageSize / 2, imageSize / 2);

    if (backColor != null) {
      canvas.drawCircle(center, center.dx, Paint()
        ..color = backColor
        ..style = PaintingStyle.fill
      );
    }

    if (strokeColor != null) {
      canvas.drawCircle(center, center.dx, Paint()
        ..color = strokeColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
      );
    }

    if ((text != null) && (textStyle != null)) {
      ui.Paragraph paragraph = _paragraphThatFitsText(text, size: Size(imageSize, imageSize), textStyle: textStyle);
      canvas.drawParagraph(paragraph, Offset((imageSize - paragraph.width) / 2, (imageSize - paragraph.height) / 2));
    }

    ui.Picture picture = recorder.endRecording();
    ui.Image image = await picture.toImage(imageSize.toInt(), imageSize.toInt());
    ByteData? imageBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return imageBytes?.buffer.asUint8List();
  }

  static ui.Paragraph _paragraphThatFitsText(String text, {required Size size, required TextStyle textStyle, ui.TextDirection textDirection = ui.TextDirection.ltr, TextAlign textAlign = TextAlign.center, int? maxLines = 1}) {
    
    double textScaleFactor = 1.0;
    while (0.0 < textScaleFactor) {
      TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: textDirection,
        textScaler: TextScaler.linear(textScaleFactor),
        maxLines: maxLines,
      )..layout();
      if ((textPainter.width <= size.width) && (textPainter.height <= size.height)) {
        break;
      }
      else {
        textScaleFactor -= 0.1;
      }
    }

    ui.ParagraphStyle paragraphStyle = textStyle.getParagraphStyle(textScaler: (0 < textScaleFactor) ? TextScaler.linear(textScaleFactor) : TextScaler.noScaling, textDirection: textDirection, textAlign: textAlign, maxLines: maxLines);
    ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)..addText(text);
    return paragraphBuilder.build()..layout(ui.ParagraphConstraints(width: size.width));

    /* ui.Paragraph? paragraph;
    double textScaleFactor = 1.0;
    while (0.0 < textScaleFactor) {
      ui.ParagraphStyle paragraphStyle = textStyle.getParagraphStyle(textScaleFactor: textScaleFactor, textDirection: textDirection, textAlign: textAlign, maxLines: maxLines);
      ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)..addText(text);
      paragraph = paragraphBuilder.build();
      paragraph.layout(ui.ParagraphConstraints(width: size.width));
      if ((paragraph.width <= size.width) && (paragraph.height <= size.hashCode)) {
        break;
      }
      else {
        textScaleFactor -= 0.1;
      }
    }
    return paragraph ?? (ui.ParagraphBuilder(textStyle.getParagraphStyle())..addText(text)).build()..layout(ui.ParagraphConstraints(width: size.width)); */
  }
}