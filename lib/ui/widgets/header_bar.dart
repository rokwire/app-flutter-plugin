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
import 'package:flutter/semantics.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

// HeaderBar

class HeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final SemanticsSortKey? sortKey;
  
  final Widget? leadingWidget;
  final String? leadingLabel;
  final String? leadingHint;
  final String? leadingAsset;
  final void Function()? onLeading;
    
  final Widget? titleWidget;
  final String? title;
  final TextStyle? textStyle;
  final Color? textColor;
  final String? fontFamily;
  final double? fontSize;
  final double? letterSpacing;
  final int? maxLines;
  final TextAlign? textAlign;
  final bool? centerTitle;

  final List<Widget>? actions;

  const HeaderBar({Key? key,
    this.sortKey,

    this.leadingWidget,
    this.leadingLabel,
    this.leadingHint,
    this.leadingAsset,
    this.onLeading,
    
    this.titleWidget,
    this.title,
    this.textStyle,
    this.textColor,
    this.fontFamily,
    this.fontSize,
    this.letterSpacing,
    this.maxLines,
    this.textAlign,
    this.centerTitle,

    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return (sortKey != null)
      ? Semantics(sortKey:sortKey, child: buildAppBar(context))
      : buildAppBar(context);
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      leading : leadingWidget ?? buildLeadingWidget(context),
      title: titleWidget ?? buildTitleWidget(context),
      centerTitle: centerTitle,
      actions: actions,
    );
  }

  // Leading
  @protected
  Widget? buildLeadingWidget(BuildContext context) {
    Image? image = leadingImage;
    return (image != null) ? Semantics(label: leadingLabel, hint: leadingHint, button: true, excludeSemantics: true, child:
      IconButton(icon: image, onPressed: () => onTapLeading(context))
    ) : null;
  }

  @protected
  Image? get leadingImage => (leadingAsset != null) ? Styles().uiImages?.getImage(leadingAsset!, excludeFromSemantics: true) as Image? : null;

  @protected
  void onTapLeading(BuildContext context) {
    if (onLeading != null) {
      onLeading!();
    }
    else {
      leadingHandler(context);
    }
  }

  @protected
  void leadingHandler(BuildContext context) {}

  // Title
  @protected
  Widget? buildTitleWidget(BuildContext context) => Text(title ?? '', style: textStyle ?? titleTextStyle, textAlign: textAlign, maxLines: maxLines);

  @protected
  TextStyle? get titleTextStyle => TextStyle(color: textColor, fontFamily: fontFamily, fontSize: fontSize, letterSpacing: letterSpacing,);

  // PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// SliverToutHeaderBar

class SliverToutHeaderBar extends StatelessWidget {

  final bool pinned;
  final bool floating;
  final double? expandedHeight;
  final Color? backgroundColor;

  final Widget? flexWidget;
  final String? flexImageUrl;
  final Color?  flexBackColor;
  final Color?  flexRightToLeftTriangleColor;
  final double? flexRightToLeftTriangleHeight;
  final Color?  flexLeftToRightTriangleColor;
  final double? flexLeftToRightTriangleHeight;

  final Widget? leadingWidget;
  final String? leadingLabel;
  final String? leadingHint;
  final EdgeInsetsGeometry? leadingPadding;
  final Size? leadingOvalSize;
  final Color? leadingOvalColor;
  final String? leadingAsset;
  final void Function()? onLeading;

  const SliverToutHeaderBar({Key? key,
    this.pinned = false,
    this.floating = false,
    this.expandedHeight,
    this.backgroundColor,

    this.flexWidget,
    this.flexImageUrl,
    this.flexBackColor,
    this.flexRightToLeftTriangleColor,
    this.flexRightToLeftTriangleHeight,
    this.flexLeftToRightTriangleColor,
    this.flexLeftToRightTriangleHeight,

    this.leadingWidget,
    this.leadingLabel,
    this.leadingHint,
    this.leadingPadding,
    this.leadingOvalSize,
    this.leadingOvalColor,
    this.leadingAsset,
    this.onLeading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: pinned,
      floating: floating,
      expandedHeight: expandedHeight,
      backgroundColor: backgroundColor,
      flexibleSpace: flexWidget ?? buildFlexibleSpace(context),
      leading: leadingWidget ?? buildLeadingWidget(context),
    );
  }

  // Flexible Space
  @protected
  Widget? buildFlexibleSpace(BuildContext context) =>
    Semantics(container: true, excludeSemantics: true, child:
      FlexibleSpaceBar(background:
        Container(color: flexBackColor, child:
          Stack(alignment: Alignment.bottomCenter, children: <Widget>[
                buildFlexibleInterior(context),
                buildFlexibleLeftToRightTriangle(context),
                buildFlexibleLeftTriangle(context),
              ],
            ),
          ))
      );

  @protected
  Widget buildFlexibleInterior(BuildContext context) {
    Widget? image = Styles().uiImages?.getImage(flexImageUrl!, fit: BoxFit.cover, networkHeaders: Config().networkAuthHeaders, excludeFromSemantics: true);
    return (flexImageUrl != null && image != null) ? Positioned.fill(child: image) : Container();
  }

  @protected
  Widget buildFlexibleLeftToRightTriangle(BuildContext context) => CustomPaint(
    painter: TrianglePainter(painterColor: flexLeftToRightTriangleColor, horzDir: TriangleHorzDirection.leftToRight),
    child: Container(height: flexLeftToRightTriangleHeight,),
  );

  @protected
  Widget buildFlexibleLeftTriangle(BuildContext context) => CustomPaint(
    painter: TrianglePainter(painterColor: flexRightToLeftTriangleColor),
    child: Container(height: flexRightToLeftTriangleHeight,),
  );

  //Leading
  @protected
  Widget? buildLeadingWidget(BuildContext context) => (leadingAsset != null) ?
    Semantics(label: leadingLabel, hint: leadingHint, button: true, child:
      Padding(padding: leadingPadding ?? const EdgeInsets.all(0), child:
        GestureDetector(onTap: () => onTapLeading(context), child:
          ClipOval(child:
            Container(color: leadingOvalColor, width: leadingOvalSize?.width ?? 0, height: leadingOvalSize?.height ?? 0, child:
              Styles().uiImages?.getImage(leadingAsset!, excludeFromSemantics: true)
            ),
          ),
        ),
      )
    ) : null;

  @protected
  void onTapLeading(BuildContext context) {
    if (onLeading != null) {
      onLeading!();
    }
    else {
      leadingHandler(context);
    }
  }

  @protected
  void leadingHandler(BuildContext context) {}
}

// SliverHeaderBar

class SliverHeaderBar extends StatelessWidget {
  
  final bool pinned;
  final bool floating;
  final double? elevation;
  final Color? backgroundColor;

  final Widget? leadingWidget;
  final String? leadingLabel;
  final String? leadingHint;
  final String? leadingAsset;
  final void Function()? onLeading;
    
  final Widget? titleWidget;
  final String? title;
  final TextStyle? textStyle;
  final Color? textColor;
  final String? fontFamily;
  final double? fontSize;
  final double? letterSpacing;
  final int? maxLines;
  final TextAlign? textAlign;
  final bool? centerTitle;

  final List<Widget>? actions;

  const SliverHeaderBar({Key? key,
    this.pinned = false,
    this.floating = false,
    this.elevation,
    this.backgroundColor,

    this.leadingWidget,
    this.leadingLabel,
    this.leadingHint,
    this.leadingAsset,
    this.onLeading,
    
    this.titleWidget,
    this.title,
    this.textStyle,
    this.textColor,
    this.fontFamily,
    this.fontSize,
    this.letterSpacing,
    this.maxLines,
    this.textAlign,
    this.centerTitle,

    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildAppBar(context);
  }

  SliverAppBar buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: pinned,
      floating: floating,
      backgroundColor: backgroundColor,
      elevation: 0,
      leading : leadingWidget ?? buildLeadingWidget(context),
      title: titleWidget ?? buildTitleWidget(context),
      centerTitle: centerTitle,
      actions: actions,
    );
  }

  // Leading
  @protected
  Widget? buildLeadingWidget(BuildContext context) {
    Image? image = leadingImage;
    return (image != null) ? Semantics(label: leadingLabel, hint: leadingHint, button: true, excludeSemantics: true, child:
      IconButton(icon: image, onPressed: () => onTapLeading(context))
    ) : null;
  }

  
  @protected
  Image? get leadingImage => (leadingAsset != null) ? Styles().uiImages?.getImage(leadingAsset!, excludeFromSemantics: true) as Image? : null;

  @protected
  void onTapLeading(BuildContext context) {
    if (onLeading != null) {
      onLeading!();
    }
    else {
      leadingHandler(context);
    }
  }

  @protected
  void leadingHandler(BuildContext context) {}

  // Title
  @protected
  Widget? buildTitleWidget(BuildContext context) => Text(title ?? '', style: textStyle ?? titleTextStyle, textAlign: textAlign, maxLines: maxLines);

  @protected
  TextStyle? get titleTextStyle => TextStyle(color: textColor, fontFamily: fontFamily, fontSize: fontSize, letterSpacing: letterSpacing,);
}
