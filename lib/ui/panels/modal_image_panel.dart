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

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:pinch_zoom/pinch_zoom.dart';

///////////////////////////////////////
// ModalPinchZoomImagePanel

class ModalPinchZoomImagePanel extends StatelessWidget {
  final String? imageUrl;
  final String? imageKey;
  final EdgeInsetsGeometry imagePadding;

  final Map<String, String>? networkImageHeaders;

  final Widget? closeWidget;
  final String? closeLabel;
  final String? closeHint;
  final void Function()? onClose;
  final void Function()? onCloseAnalytics;

  final Widget? progressWidget;
  final Size progressSize;
  final double progressWidth;
  final Color? progressColor;

  final ImageProvider? image;

  final void Function()? onDismiss;

  const ModalPinchZoomImagePanel({Key? key,
    this.imageUrl,
    this.imageKey,
    this.image,
    this.imagePadding = const EdgeInsets.symmetric(vertical: 64, horizontal: 32),

    this.networkImageHeaders,

    this.closeWidget,
    this.closeLabel = 'Close Button',
    this.closeHint,
    this.onClose,
    this.onCloseAnalytics,

    this.progressWidget,
    this.progressSize = const Size(24, 24),
    this.progressWidth = 2,
    this.progressColor,

    this.onDismiss,

  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black.withValues(alpha: 0.3), body:
      Center(child:
      InkWell(onTap: () => _onDismiss(context), child:
        PinchZoom(
          //resetDuration: const Duration(milliseconds: 100),
          maxScale: 4,
          onZoomStart: (){print('Start zooming');},
          onZoomEnd: (){print('Stop zooming');},
          child: Padding(padding: imagePadding, child: _imageWidget),
          /*Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child:
              Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Padding(padding: imagePadding, child: _imageWidget)),
            ],)
          ),
          ],)*/
        ),
      ),
      ),
    );
  }

  Widget? get _imageWidget {
    if(image != null){
      return Image(image: image!, loadingBuilder: _imageLoadingWidget,  frameBuilder: _imageFrameBuilder);
    }
    else if (StringUtils.isNotEmpty(imageKey)) {
      return Styles().images.getImage(imageKey!, excludeFromSemantics: true, fit: BoxFit.fitWidth,
        networkHeaders: (networkImageHeaders ?? Config().networkAuthHeaders), loadingBuilder: _imageLoadingWidget, frameBuilder: _imageFrameBuilder);
    }
    else if (StringUtils.isNotEmpty(imageUrl)) {
      return Image.network(imageUrl!, excludeFromSemantics: true, fit: BoxFit.fitWidth,
        headers: (networkImageHeaders ?? Config().networkAuthHeaders), loadingBuilder: _imageLoadingWidget,  frameBuilder: _imageFrameBuilder);
    }
    else {
      return null;
    }
  }

  Widget _imageLoadingWidget(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) {
      return child;
    }
    return Center(child: _buildProgressWidget(context, loadingProgress));
  }

  Widget _imageFrameBuilder(BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded,){ //Some images do not show X button //Do not call loadingBuilder so fix with frameBuilder
    return Stack(
      children:[
          child,
          Visibility(
            visible: frame != null, //It will be null before the first image frame is ready, and zero  for the first image frame. Show Close button when ready to draw - leave the progress indicator till then
            child:Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _buildCloseWidget(context),
            ],))
        ]);
  }

  Widget _buildCloseWidget(BuildContext context) {
    return closeWidget ?? Semantics(label: closeLabel ?? "Close Button", hint: closeHint, button: true, focusable: true, focused: true, child:
      // Do not use InkWell inside PinchZoom, this raises "No Material widget found" exception on attempts to zoom.
      GestureDetector(onTap: () => _onClose(context), child:
        Container(color: Colors.transparent, padding: const EdgeInsets.symmetric(horizontal: 16), child:
          Text('\u00D7', style: TextStyle(color: Styles().colors.surface, fontFamily: Styles().fontFamilies.medium, fontSize: 50),),
        ),
      )
    );
  }

  Widget _buildProgressWidget(BuildContext context, ImageChunkEvent progress) {
    return progressWidget ?? SizedBox(height: progressSize.width, width: 24, child:
      CircularProgressIndicator(strokeWidth: progressWidth, valueColor: AlwaysStoppedAnimation<Color?>(progressColor ?? Styles().colors.surface),
        value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null),
    );
  }

  void _onClose(BuildContext context) {
    if (onClose != null) {
      onClose!();
    }
    else {
      if (onCloseAnalytics != null) {
        onCloseAnalytics!();
      }
      Navigator.of(context).pop();
    }
  }

  void _onDismiss(BuildContext context) {
    if (onDismiss != null) {
      onDismiss!();
    }
    else {
      _onClose(context);
    }
  }
}

///////////////////////////////////////
// ModalPhotoImagePanel

class ModalPhotoImagePanel extends StatelessWidget {
  final String? imageUrl;
  final String? imageKey;
  final EdgeInsetsGeometry imagePadding;

  final Map<String, String>? networkImageHeaders;

  final Widget? closeWidget;
  final String? closeLabel;
  final String? closeHint;
  final void Function()? onClose;
  final void Function()? onCloseAnalytics;

  final Widget? progressWidget;
  final Size progressSize;
  final double progressWidth;
  final Color? progressColor;

  final ImageProvider? image;

  final void Function()? onDismiss;

  const ModalPhotoImagePanel({Key? key,
    this.imageUrl,
    this.imageKey,
    this.image,
    this.imagePadding = const EdgeInsets.symmetric(vertical: 64, horizontal: 32),

    this.networkImageHeaders,

    this.closeWidget,
    this.closeLabel = 'Close Button',
    this.closeHint,
    this.onClose,
    this.onCloseAnalytics,

    this.progressWidget,
    this.progressSize = const Size(24, 24),
    this.progressWidth = 2,
    this.progressColor,

    this.onDismiss,

  }) : super(key: key);

  Widget build(BuildContext context) =>
    Scaffold(backgroundColor: Colors.black.withValues(alpha: 0.7), body:
      Stack(children: [
        Container(
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
            //width: MediaQuery.of(context).size.width,
          ),
          child: PhotoView(
            imageProvider: _imageProvider,
            loadingBuilder: _buildImageLoading,
            backgroundDecoration: BoxDecoration(color: Colors.transparent),
            //minScale: minScale,
            //maxScale: maxScale,
            //initialScale: initialScale,
            //basePosition: basePosition,
            //filterQuality: filterQuality,
            //disableGestures: disableGestures,
            errorBuilder: _buildImageError,
          ),
        ),
        Positioned.fill(child:
          SafeArea(child:
            Align(alignment: Alignment.topRight, child:
              _buildCloseWidget(context),
           )
          )
        ),
      ],)
    );

  ImageProvider? get _imageProvider {
    if (image != null) {
      return image;
    }
    else if (imageUrl != null) {
      return NetworkImage(imageUrl!);
    }
    else if (imageKey != null) {
      Widget? imageWidget = Styles().images.getImage(imageKey);
      return (imageWidget is Image) ? imageWidget.image : null;
    }
    else {
      return null;
    }
  }

  Widget _buildImageLoading(BuildContext context, ImageChunkEvent? loadingProgress) =>
    (loadingProgress != null) ? Center(child: _buildImageProgress(context, loadingProgress)) : Container();

  Widget _buildImageProgress(BuildContext context, ImageChunkEvent progress) {
    return progressWidget ?? SizedBox(height: progressSize.width, width: 24, child:
      CircularProgressIndicator(strokeWidth: progressWidth, valueColor: AlwaysStoppedAnimation<Color?>(progressColor ?? Styles().colors.white),
        value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null),
    );
  }

  Widget _buildImageError(BuildContext context, Object error, StackTrace? stackTrace) {
    return Container();
  }

  Widget _buildCloseWidget(BuildContext context) =>
    closeWidget ?? Semantics(label: closeLabel ?? "Close Button", hint: closeHint, button: true, focusable: true, focused: true, child:
      // Do not use InkWell inside PinchZoom, this raises "No Material widget found" exception on attempts to zoom.
      GestureDetector(onTap: () => _onClose(context), child:
        Container(color: Colors.transparent, padding: const EdgeInsets.symmetric(horizontal: 16), child:
          Text('\u00D7', style: TextStyle(color: Styles().colors.white, fontFamily: Styles().fontFamilies.medium, fontSize: 50),),
        ),
      )
    );

  void _onClose(BuildContext context) {
    if (onClose != null) {
      onClose?.call();
    }
    else {
      if (onCloseAnalytics != null) {
        onCloseAnalytics?.call();
      }
      Navigator.of(context).pop();
    }
  }

}