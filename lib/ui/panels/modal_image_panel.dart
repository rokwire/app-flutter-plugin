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
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ModalImagePanel extends StatelessWidget {
  final String imageUrl;
  final EdgeInsetsGeometry imagePadding;

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
    this.imagePadding = const EdgeInsets.symmetric(vertical: 64, horizontal: 32),


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
    Image networkImage = Image.network(imageUrl, headers: Config().networkAuthHeaders);
    Completer<ui.Image> networkImageCompleter = Completer<ui.Image>();
    networkImage.image.resolve(const ImageConfiguration()).addListener(ImageStreamListener((ImageInfo info, bool syncCall) => networkImageCompleter.complete(info.image)));
    
    return Scaffold(backgroundColor: Colors.black.withOpacity(0.3), body:
      SafeArea(child:
        InkWell(onTap: () => _onDismiss(context), child:
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child:
              Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child:
                  FutureBuilder<ui.Image>(future: networkImageCompleter.future, builder: (BuildContext context, AsyncSnapshot<ui.Image> snapshot) {
                    return snapshot.hasData ?
                      Padding(padding: imagePadding, child:
                        InkWell(onTap: (){ /* ignore taps on image*/ }, child:
                          Stack(children:[
                            Image.network(imageUrl, excludeFromSemantics: true, fit: BoxFit.fitWidth, headers: Config().networkAuthHeaders),
                            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                              _buildCloseWidget(context),
                            ],)
                          ]),
                        ),
                      ) :
                      Center(child:
                        _buildProgressWidget(context)
                      );
                  }),
                ),
              ],)
            ),
          ],),
        ),
      ),
    );
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

  Widget _buildProgressWidget(BuildContext context) {
    return progressWidget ?? SizedBox(height: progressSize.width, width: 24, child:
      CircularProgressIndicator(strokeWidth: progressWidth, valueColor: AlwaysStoppedAnimation<Color?>(progressColor ?? Styles().colors?.white ?? Colors.white),),
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

