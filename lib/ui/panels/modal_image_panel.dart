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
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ModalImagePanel extends StatelessWidget {
  final String imageUrl;
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

  final void Function()? onDismiss;

  const ModalImagePanel({Key? key,
    required this.imageUrl,
    this.imageKey,
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
    Widget? image;
    if (StringUtils.isNotEmpty(imageKey)) {
      image = Styles().uiImages?.getImage(imageKey!, source: imageUrl, excludeFromSemantics: true, fit: BoxFit.fitWidth, 
        networkHeaders: (networkImageHeaders ?? Config().networkAuthHeaders), loadingBuilder: _imageLoadingWidget);
    } else {
      image = Image.network(imageUrl, excludeFromSemantics: true, fit: BoxFit.fitWidth, 
        headers: (networkImageHeaders ?? Config().networkAuthHeaders), loadingBuilder: _imageLoadingWidget);
    }
    
    return Scaffold(backgroundColor: Colors.black.withOpacity(0.3), body:
      SafeArea(child:
        InkWell(onTap: () => _onDismiss(context), child:
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child:
              Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: image != null ?
                  Padding(padding: imagePadding, child: InkWell(onTap: (){ /* ignore taps on image*/ }, child: image),) : Container()
                ),
              ],)
            ),
          ],),
        ),
      ),
    );
  }

  Widget _imageLoadingWidget(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) {
      return Stack(children:[
        child,
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _buildCloseWidget(context),
        ],)
      ]);
    }
    return Center(child: _buildProgressWidget(context, loadingProgress));
  }

  Widget _buildCloseWidget(BuildContext context) {
    return closeWidget ?? Semantics(label: closeLabel ?? "Close Button", hint: closeHint, button: true, focusable: true, focused: true, child:
      GestureDetector(onTap: () => _onClose(context), child:
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child:
          Text('\u00D7', style: TextStyle(color: Styles().colors?.white ?? Colors.white, fontFamily: Styles().fontFamilies?.medium, fontSize: 50),),
        ),
      )
    );
  }

  Widget _buildProgressWidget(BuildContext context, ImageChunkEvent progress) {
    return progressWidget ?? SizedBox(height: progressSize.width, width: 24, child:
      CircularProgressIndicator(strokeWidth: progressWidth, valueColor: AlwaysStoppedAnimation<Color?>(progressColor ?? Styles().colors?.white ?? Colors.white), 
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

