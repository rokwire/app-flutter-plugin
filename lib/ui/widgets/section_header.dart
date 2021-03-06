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
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class SectionSlantHeader extends StatelessWidget {
  final String? title;
  final Color? titleTextColor;
  final String? titleFontFamilly;
  final double titleFontSize;
  final TextStyle? titleTextStyle;
  final EdgeInsetsGeometry titlePadding;
  
  final String? subTitle;
  final Color? subTitleTextColor;
  final String? subTitleFontFamilly;
  final double subTitleFontSize;
  final TextStyle? subTitleTextStyle;
  final EdgeInsetsGeometry subTitlePadding;
  
  final Widget? titleIcon;
  final String? titleIconAsset;
  final EdgeInsetsGeometry titleIconPadding;

  final Color? backgroundColor;

  final Color? slantColor;
  final double slantPainterHeadingHeight;
  final double slantPainterHeight;

  final String? slantImageAsset;
  final double slantImageHeadingHeight;
  final double slantImageHeight;

  final Widget? rightIcon;
  final String? rightIconLabel;
  final String? rightIconAsset;
  final void Function()? rightIconAction;
  final EdgeInsetsGeometry rightIconPadding;

  final List<Widget>? children;
  final EdgeInsetsGeometry childrenPadding;

  const SectionSlantHeader({
    Key? key,

    this.title,
    this.titleTextColor,
    this.titleFontFamilly,
    this.titleFontSize = 20,
    this.titleTextStyle,
    this.titlePadding = const EdgeInsets.only(left: 16, top: 16),

    this.subTitle,
    this.subTitleTextColor,
    this.subTitleFontFamilly,
    this.subTitleFontSize = 16,
    this.subTitleTextStyle,
    this.subTitlePadding = const EdgeInsets.only(left: 50, right: 16),

    this.titleIcon,
    this.titleIconAsset,
    this.titleIconPadding = const EdgeInsets.only(right: 16),

    this.backgroundColor, 
    
    this.slantColor,
    this.slantPainterHeadingHeight = 85,
    this.slantPainterHeight = 67,
    
    this.slantImageAsset,
    this.slantImageHeadingHeight = 40,
    this.slantImageHeight = 112,
    
    this.rightIcon,
    this.rightIconLabel,
    this.rightIconAsset,
    this.rightIconAction,
    this.rightIconPadding = const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 2),
    
    this.children,
    this.childrenPadding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    // Build Stack layer 1
    List<Widget> layer1List = <Widget>[];
    if (StringUtils.isNotEmpty(slantImageAsset)) {
      layer1List.addAll([
        Container(color: _slantColor, height: slantImageHeadingHeight,),
        Row(children:[Expanded(child:
          SizedBox(height: slantImageHeight, child:
            Image.asset(slantImageAsset!, excludeFromSemantics: true, color: _slantColor, fit: BoxFit.fill),
          ),
        )]),
      ]);
    }
    else {
      layer1List.addAll([
        Container(color: _slantColor, height: slantPainterHeadingHeight,),
        Container(color: _slantColor, child:
          CustomPaint(painter: TrianglePainter(painterColor: backgroundColor ?? Styles().colors!.background, horzDir: TriangleHorzDirection.rightToLeft), child:
            Container(height: slantPainterHeight,),
          ),
        ),
      ]);
    }

    // Build Title Row
    List<Widget> titleList = <Widget>[];
    if ((titleIcon != null) || (titleIconAsset != null)) {
      titleList.add(
        Padding(padding: titleIconPadding, child:
          titleIcon ?? Image.asset(titleIconAsset!, excludeFromSemantics: true,),
        )
      );
    }
    
    titleList.add(
      Expanded(child:
        Semantics(label: title, header: true, excludeSemantics: true, child:
          Text(title ?? '', style: _titleTextStyle,)
        )
      ),
    );
    
    if ((rightIcon != null) || (rightIconAsset != null)) {
      titleList.add(
        Semantics(label: rightIconLabel, button: true, child:
          GestureDetector(onTap: rightIconAction, child:
            Container(padding: rightIconPadding, child:
              rightIcon ?? Image.asset(rightIconAsset!, excludeFromSemantics: true,),
            )
          )
        ),
      );
    }

    // Build Stack layer 2
    List<Widget> layer2List = <Widget>[
      Padding(padding: titlePadding, child:
        Row(children: titleList,),
      ),
    ];

    if (StringUtils.isNotEmpty(subTitle)) {
      layer2List.add(
        Semantics(label: subTitle, header: true, excludeSemantics: true, child:
          Padding(padding: subTitlePadding, child:
            Row(children: <Widget>[
              Expanded(child:
                Text(subTitle ?? '', style: _subTitleTextStyle,),
              ),
            ],),
          ),
        ),
      );
    }

    layer2List.add(
      Padding(padding: childrenPadding, child:
        Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: children ?? [],),
      )
    );

    return Stack(alignment: Alignment.topCenter, children: <Widget>[
      Column(children: layer1List,),
      Column(children: layer2List,),
    ],);

    
  }

  Color? get _slantColor => slantColor ?? Styles().colors?.fillColorPrimary;

  TextStyle get _titleTextStyle => titleTextStyle ?? TextStyle(
    color: titleTextColor ?? Styles().colors?.textColorPrimary,
    fontFamily: titleFontFamilly ?? Styles().fontFamilies?.extraBold,
    fontSize: titleFontSize
  );

  TextStyle get _subTitleTextStyle => subTitleTextStyle ?? TextStyle(
    color: subTitleTextColor ?? Styles().colors?.textColorPrimary,
    fontFamily: subTitleFontFamilly ?? Styles().fontFamilies?.regular,
    fontSize: subTitleFontSize
  );
}

class SectionRibbonHeader extends StatelessWidget {
  final String? title;
  final Color? titleTextColor;
  final String? titleFontFamilly;
  final double titleFontSize;
  final TextStyle? titleTextStyle;
  final EdgeInsetsGeometry titlePadding;

  final String? subTitle;
  final Color? subTitleTextColor;
  final String? subTitleFontFamilly;
  final double subTitleFontSize;
  final TextStyle? subTitleTextStyle;
  final EdgeInsetsGeometry subTitlePadding;

  final Widget? titleIcon;
  final String? titleIconAsset;
  final EdgeInsetsGeometry titleIconPadding;

  final Widget? rightIcon;
  final String? rightIconLabel;
  final String? rightIconAsset;
  final void Function()? rightIconAction;
  final EdgeInsetsGeometry rightIconPadding;

  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const SectionRibbonHeader({Key? key,
    this.title,
    this.titleTextColor,
    this.titleFontFamilly,
    this.titleFontSize = 20,
    this.titleTextStyle,
    this.titlePadding = EdgeInsets.zero,
    
    this.subTitle,
    this.subTitleTextColor,
    this.subTitleFontFamilly,
    this.subTitleFontSize = 16,
    this.subTitleTextStyle,
    this.subTitlePadding = EdgeInsets.zero,

    this.titleIcon,
    this.titleIconAsset,
    this.titleIconPadding = const EdgeInsets.only(right: 12),

    this.rightIcon,
    this.rightIconLabel,
    this.rightIconAsset,
    this.rightIconAction,
    this.rightIconPadding = const EdgeInsets.only(left: 12),

    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> titleList = <Widget>[];
    List<Widget>? subTitleList = StringUtils.isNotEmpty(subTitle) ? <Widget>[] : null;
    
    Widget? titleIconWidget = ((titleIcon != null) || (titleIconAsset != null)) ?
      Padding(padding: titleIconPadding, child:
        titleIcon ?? Image.asset(titleIconAsset!, excludeFromSemantics: true,),
      ) : null;
    if ((titleIconWidget != null)) {
      titleList.add(titleIconWidget);
      if (subTitleList != null) {
        subTitleList.add(Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true, child: titleIconWidget));
      }
    }

    titleList.add(
      Expanded(child:
        Padding(padding: titlePadding, child:
          Semantics(label: title, header: true, excludeSemantics: true, child:
            Text(title ?? '', style: _titleTextStyle,)
          ),
        ),
      ),
    );

    if (subTitleList != null) {
      subTitleList.add(
        Expanded(child:
          Padding(padding: subTitlePadding, child:
            Semantics(label: subTitle, header: true, excludeSemantics: true, child:
              Text(subTitle ?? '', style: _subTitleTextStyle,)
            ),
          ),
        ),
      );
    }

    Widget? rightIconWidget = ((rightIcon != null) || (rightIconAsset != null)) ?
      Padding(padding: rightIconPadding, child:
        rightIcon ?? Image.asset(rightIconAsset!, excludeFromSemantics: true,),
      ) : null;
    if (rightIconWidget != null) {
      titleList.add(rightIconWidget);
      if (subTitleList != null) {
        subTitleList.add(Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true, child: rightIconWidget));
      }
    }

    Widget contentWidget = Container(color: _backgroundColor, padding: padding, child: (subTitleList != null) ?
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: titleList,),
        Row(children: subTitleList,),
      ],) :
      Row(children: titleList,),
    );

    Widget? rightIconButton = ((rightIconWidget != null) && (rightIconAction != null)) ?
      Semantics(label: rightIconLabel, button: true, child:
        InkWell(onTap: rightIconAction, child:
          Padding(padding: padding, child:
            Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true, child:  rightIconWidget,),
          )
        )
      ) : null;

    return (rightIconButton != null) ?
      Stack(children: [
        contentWidget,
        Align(alignment: Alignment.topRight, child: rightIconButton),
      ],) :
      contentWidget;
  }

  Color? get _backgroundColor => backgroundColor ?? Styles().colors?.fillColorPrimary;

  TextStyle get _titleTextStyle => titleTextStyle ?? TextStyle(
    color: titleTextColor ?? Styles().colors?.white,
    fontFamily: titleFontFamilly ?? Styles().fontFamilies?.extraBold,
    fontSize: titleFontSize
  );

  TextStyle get _subTitleTextStyle => subTitleTextStyle ?? TextStyle(
    color: subTitleTextColor ?? Styles().colors?.white,
    fontFamily: subTitleFontFamilly ?? Styles().fontFamilies?.regular,
    fontSize: subTitleFontSize
  );
}

class ImageSlantHeader extends StatelessWidget {
  final String? imageUrl;
  final Widget? child;

  final String slantImageAsset;
  final Color? slantImageColor;
  final double slantImageHeadingHeight;
  final double slantImageHeight;

  const ImageSlantHeader({Key? key,
    this.imageUrl,
    this.child,

    required this.slantImageAsset,
    this.slantImageColor,
    this.slantImageHeadingHeight = 72,
    this.slantImageHeight = 112,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Image networkImage = Image.network(imageUrl!, headers: Config().networkAuthHeaders);
    Completer<ui.Image> networkImageCompleter = Completer<ui.Image>();
    networkImage.image.resolve(const ImageConfiguration()).addListener(ImageStreamListener((ImageInfo info, bool syncCall) => networkImageCompleter.complete(info.image)));

    return Stack(alignment: Alignment.topCenter, children: <Widget>[
      Image(image: networkImage.image, width: MediaQuery.of(context).size.width, fit: BoxFit.fitWidth, excludeFromSemantics: true,),
      FutureBuilder<ui.Image>(future: networkImageCompleter.future, builder: (BuildContext context, AsyncSnapshot<ui.Image> snapshot) {
        double displayHeight = (snapshot.data != null) ? (snapshot.data!.height * MediaQuery.of(context).size.width / snapshot.data!.width) : 240;
        return Padding(padding: EdgeInsets.only(top: displayHeight * 0.75), child:
          Stack(alignment: Alignment.topCenter, children: <Widget>[
            Column(children: <Widget>[
              Container(height: slantImageHeadingHeight, color: _slantImageColor,),
              SizedBox(height: slantImageHeight, width: MediaQuery.of(context).size.width, child:
                Image.asset(slantImageAsset, fit: BoxFit.fill, color: _slantImageColor, excludeFromSemantics: true,),
              ),
            ],),
            child ?? Container(),
          ])
        );
      }),
    ]);
  }

  Color? get _slantImageColor => slantImageColor ?? Styles().colors?.fillColorSecondary;
}