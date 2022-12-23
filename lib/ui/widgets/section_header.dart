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
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
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
  final String? titleIconKey;
  final EdgeInsetsGeometry titleIconPadding;

  final Color? backgroundColor;

  final Color? slantColor;
  final double slantPainterHeadingHeight;
  final double slantPainterHeight;

  final String? slantImageKey;
  final double slantImageHeadingHeight;
  final double slantImageHeight;

  final Widget? rightIcon;
  final String? rightIconLabel;
  final String? rightIconKey;
  final void Function()? rightIconAction;
  final EdgeInsetsGeometry rightIconPadding;

  final Widget? headerWidget;
  final List<Widget>? children;
  final EdgeInsetsGeometry childrenPadding;
  final CrossAxisAlignment childrenAlignment;

  final bool allowOverlap;

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
    this.titleIconKey,
    this.titleIconPadding = const EdgeInsets.only(right: 16),

    this.backgroundColor, 
    
    this.slantColor,
    this.slantPainterHeadingHeight = 47,
    this.slantPainterHeight = 67,
    
    this.slantImageKey,
    this.slantImageHeadingHeight = 40,
    this.slantImageHeight = 112,
    
    this.rightIcon,
    this.rightIconLabel,
    this.rightIconKey,
    this.rightIconAction,
    this.rightIconPadding = const EdgeInsets.only(left: 16, right: 16),
    
    this.headerWidget,
    this.children,
    this.childrenPadding = const EdgeInsets.all(16),
    this.childrenAlignment = CrossAxisAlignment.center,

    this.allowOverlap = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    // Title
    List<Widget> contentList = [
      headerWidget ?? _buildTitle()
    ];

    if (StringUtils.isNotEmpty(subTitle)) {
      contentList.add(_buildSubTitle());
    }

    // Slant
    List<Widget> slantList = <Widget>[];
    if (StringUtils.isNotEmpty(slantImageKey)) {
      slantList.addAll([
        Container(color: _slantColor, height: slantImageHeadingHeight,),
        Row(children:[Expanded(child:
          SizedBox(height: slantImageHeight, child:
            Styles().images?.getImage(slantImageKey, excludeFromSemantics: true, color: _slantColor, fit: BoxFit.fill),
          ),
        )]),
      ]);
    }
    else {
      slantList.addAll([
        Container(color: _slantColor, height: slantPainterHeadingHeight,),
        Container(color: _slantColor, child:
          CustomPaint(painter: TrianglePainter(painterColor: backgroundColor ?? Styles().colors!.background, horzDir: TriangleHorzDirection.rightToLeft), child:
            Container(height: slantPainterHeight,),
          ),
        ),
      ]);
    }

    contentList.add(allowOverlap ?
      Stack(children: [
        Column(children: slantList,),
        Padding(padding: childrenPadding, child:
          Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: childrenAlignment, children: children ?? [],),
        )
      ]) :
      Column(children: [
        ...slantList,
        Padding(padding: childrenPadding, child:
          Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: childrenAlignment, children: children ?? [],),
        )
      ])
    );
    
    return Column(children: contentList,);
  }

  Widget _buildTitle() { 
    List<Widget> titleList = <Widget>[];
    if ((titleIcon != null) || (titleIconKey != null)) {
      titleList.add(
        Padding(padding: titleIconPadding, child:
          titleIcon ?? Styles().images?.getImage(titleIconKey, excludeFromSemantics: true),
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
    
    if ((rightIcon != null) || (rightIconKey != null)) {
      titleList.add(
        Semantics(label: rightIconLabel, button: true, child:
          GestureDetector(onTap: rightIconAction, child:
            Container(padding: rightIconPadding, color: _slantColor, child:
              rightIcon ?? Styles().images?.getImage(rightIconKey, excludeFromSemantics: true,),
            )
          )
        ),
      );
    }

    return Container(color: _slantColor, child: Padding(padding: titlePadding, child: Row(children: titleList,),));
  }

  Widget _buildSubTitle() {
    return Semantics(label: subTitle, header: true, excludeSemantics: true, child:
      Padding(padding: subTitlePadding, child:
        Row(children: <Widget>[
          Expanded(child:
            Text(subTitle ?? '', style: _subTitleTextStyle,),
          ),
        ],),
      ),
    );
  }

  Color? get _slantColor => slantColor ?? Styles().colors?.fillColorPrimary;

  TextStyle get _titleTextStyle => titleTextStyle ?? TextStyle(
    color: titleTextColor ?? Styles().colors?.textPrimary,
    fontFamily: titleFontFamilly ?? Styles().fontFamilies?.extraBold,
    fontSize: titleFontSize
  );

  TextStyle get _subTitleTextStyle => subTitleTextStyle ?? TextStyle(
    color: subTitleTextColor ?? Styles().colors?.textPrimary,
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
  final String? titleIconKey;
  final EdgeInsetsGeometry titleIconPadding;

  final Widget? rightIcon;
  final String? rightIconLabel;
  final String? rightIconKey;
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
    this.titleIconKey,
    this.titleIconPadding = const EdgeInsets.only(right: 12),

    this.rightIcon,
    this.rightIconLabel,
    this.rightIconKey,
    this.rightIconAction,
    this.rightIconPadding = const EdgeInsets.only(left: 12),

    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> titleList = <Widget>[];
    List<Widget>? subTitleList = StringUtils.isNotEmpty(subTitle) ? <Widget>[] : null;
    
    Widget? titleIconWidget = ((titleIcon != null) || (titleIconKey != null)) ?
      Padding(padding: titleIconPadding, child:
        titleIcon ?? Styles().images?.getImage(titleIconKey, excludeFromSemantics: true),
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

    Widget? rightIconWidget = ((rightIcon != null) || (rightIconKey != null)) ?
      Padding(padding: rightIconPadding, child:
        rightIcon ?? Styles().images?.getImage(rightIconKey, excludeFromSemantics: true),
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
    color: titleTextColor ?? Styles().colors?.textLight,
    fontFamily: titleFontFamilly ?? Styles().fontFamilies?.extraBold,
    fontSize: titleFontSize
  );

  TextStyle get _subTitleTextStyle => subTitleTextStyle ?? TextStyle(
    color: subTitleTextColor ?? Styles().colors?.textLight,
    fontFamily: subTitleFontFamilly ?? Styles().fontFamilies?.regular,
    fontSize: subTitleFontSize
  );
}

class ImageSlantHeader extends StatelessWidget {
  final String? imageUrl;
  final String? imageKey;
  final Widget? child;

  final String slantImageKey;
  final Color? slantImageColor;
  final double slantImageHeadingHeight;
  final double slantImageHeight;

  final Widget? progressWidget;
  final Size progressSize;
  final double progressWidth;
  final Color? progressColor;

  const ImageSlantHeader({Key? key,
    this.imageUrl,
    this.imageKey,
    this.child,

    required this.slantImageKey,
    this.slantImageColor,
    this.slantImageHeadingHeight = 72,
    this.slantImageHeight = 112,

    this.progressWidget,
    this.progressSize = const Size(24, 24),
    this.progressWidth = 2,
    this.progressColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget? image;
    if (StringUtils.isNotEmpty(imageKey)) {
      image = Styles().images?.getImage(imageKey!, source: imageUrl, width: MediaQuery.of(context).size.width, fit: BoxFit.fitWidth, excludeFromSemantics: true, 
        networkHeaders: Config().networkAuthHeaders, loadingBuilder: _imageLoadingWidget);
    } else if (StringUtils.isNotEmpty(imageUrl)) {
      image = Image.network(imageUrl!, width: MediaQuery.of(context).size.width, fit: BoxFit.fitWidth, excludeFromSemantics: true, 
        headers: Config().networkAuthHeaders, loadingBuilder: _imageLoadingWidget);
    }

    double displayHeight = (image as Image?)?.height ?? 240;
    return Stack(alignment: Alignment.topCenter, children: <Widget>[
      image!=null ?
          ModalImageHolder(child: image,)
        :Container(),
      Padding(padding: EdgeInsets.only(top: displayHeight * 0.75), child:
        Stack(alignment: Alignment.topCenter, children: <Widget>[
          Column(children: <Widget>[
            Container(height: slantImageHeadingHeight, color: _slantImageColor,),
            SizedBox(height: slantImageHeight, width: MediaQuery.of(context).size.width, child:
              Styles().images?.getImage(slantImageKey, fit: BoxFit.fill, color: _slantImageColor, excludeFromSemantics: true,),
            ),
          ],),
          child ?? Container(),
        ])
      ),
    ]);
  }

  Widget _imageLoadingWidget(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) {
      return child;
    }
    return Center(child: _buildProgressWidget(context, loadingProgress));
  }

  Widget _buildProgressWidget(BuildContext context, ImageChunkEvent progress) {
    return progressWidget ?? SizedBox(height: progressSize.width, width: 24, child:
      CircularProgressIndicator(strokeWidth: progressWidth, valueColor: AlwaysStoppedAnimation<Color?>(progressColor ?? Styles().colors?.surface ?? Colors.white),
        value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null),
    );
  }

  Color? get _slantImageColor => slantImageColor ?? Styles().colors?.fillColorSecondary;
}