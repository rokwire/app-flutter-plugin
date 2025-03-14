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
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_header_image.dart';

// HeaderBar

class HeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final SemanticsSortKey? sortKey;
  
  final Widget? leadingWidget;
  final String? leadingLabel;
  final String? leadingHint;
  final String? leadingIconKey;
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
    this.leadingIconKey,
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
    Widget? image = leadingIcon;
    return (image != null) ? Semantics(label: leadingLabel, hint: leadingHint, button: true, excludeSemantics: true, child:
      IconButton(icon: image, onPressed: () => onTapLeading(context))
    ) : null;
  }

  @protected
  Widget? get leadingIcon => (leadingIconKey != null) ? Styles().images.getImage(leadingIconKey, excludeFromSemantics: true) : null;

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
  final double toolbarHeight;
  final double? expandedHeight;
  final Color? backgroundColor;

  final Widget? flexWidget;
  final String? flexImageKey;
  final String? flexImageUrl;
  final Color?  flexBackColor;
  final Color?  flexRightToLeftTriangleColor;
  final double? flexRightToLeftTriangleHeight;
  final Color?  flexLeftToRightTriangleColor;
  final double? flexLeftToRightTriangleHeight;

  final Widget? leadingWidget;
  final double? leadingWidth;
  final String? leadingLabel;
  final String? leadingHint;
  final EdgeInsetsGeometry leadingPadding;
  final Size? leadingOvalSize;
  final Color? leadingOvalColor;
  final String? leadingIconKey;
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

  const SliverToutHeaderBar({Key? key,
    this.pinned = false,
    this.floating = false,
    this.toolbarHeight = kToolbarHeight,
    this.expandedHeight,
    this.backgroundColor,

    this.flexWidget,
    this.flexImageKey,
    this.flexImageUrl,
    this.flexBackColor,
    this.flexRightToLeftTriangleColor,
    this.flexRightToLeftTriangleHeight,
    this.flexLeftToRightTriangleColor,
    this.flexLeftToRightTriangleHeight,

    this.leadingWidget,
    this.leadingWidth,
    this.leadingLabel,
    this.leadingHint,
    this.leadingPadding = const EdgeInsets.all(8),
    this.leadingOvalSize,
    this.leadingOvalColor,
    this.leadingIconKey,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: pinned,
      floating: floating,
      toolbarHeight: toolbarHeight,
      expandedHeight: expandedHeight,
      backgroundColor: backgroundColor,
      leading: leadingWidget ?? buildLeadingWidget(context),
      leadingWidth: leadingWidth,
      title: titleWidget ?? buildTitleWidget(context),
      flexibleSpace: flexWidget ?? buildFlexibleSpace(context),
    );
  }

  // Flexible Space
  @protected
  Widget? buildFlexibleSpace(BuildContext context) =>
    Semantics(container: true, excludeSemantics: true, child:
      FlexibleSpaceBar(background:
        TriangleHeaderImage(key: key, flexBackColor: flexBackColor, flexImageKey: flexImageKey, flexImageUrl: flexImageUrl,
          flexLeftToRightTriangleColor: flexLeftToRightTriangleColor, flexLeftToRightTriangleHeight: flexLeftToRightTriangleHeight,
          flexRightToLeftTriangleColor: flexRightToLeftTriangleColor, flexRightToLeftTriangleHeight: flexRightToLeftTriangleHeight,
        ),
      ),
    );

  //Leading
  @protected
  Widget? buildLeadingWidget(BuildContext context) => (leadingIconKey != null) ?
    Semantics(label: leadingLabel, hint: leadingHint, button: true, child:
      GestureDetector(onTap: () => onTapLeading(context), child:
        Padding(padding: leadingPadding, child:
          ClipOval(child:
            Container(color: leadingOvalColor, width: leadingOvalSize?.width ?? 0, height: leadingOvalSize?.height ?? 0, child:
              Styles().images.getImage(leadingIconKey, excludeFromSemantics: true)
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

  // Title
  @protected
  Widget? buildTitleWidget(BuildContext context) => (title != null) ? Text(title ?? '', style: textStyle ?? titleTextStyle, textAlign: textAlign, maxLines: maxLines) : null;

  @protected
  TextStyle? get titleTextStyle => TextStyle(color: textColor, fontFamily: fontFamily, fontSize: fontSize, letterSpacing: letterSpacing,);

}

// SliverHeaderBar

class SliverHeaderBar extends StatelessWidget {
  
  final bool pinned;
  final bool floating;
  final double? elevation;
  final double toolbarHeight;
  final Color? backgroundColor;

  final Widget? leadingWidget;
  final double? leadingWidth;
  final String? leadingLabel;
  final String? leadingHint;
  final String? leadingIconKey;
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
    this.toolbarHeight = kToolbarHeight,
    this.backgroundColor,

    this.leadingWidget,
    this.leadingWidth,
    this.leadingLabel,
    this.leadingHint,
    this.leadingIconKey,
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
      toolbarHeight: toolbarHeight,
      backgroundColor: backgroundColor,
      elevation: 0,
      leading : leadingWidget ?? buildLeadingWidget(context),
      leadingWidth: leadingWidth,
      title: titleWidget ?? buildTitleWidget(context),
      centerTitle: centerTitle,
      actions: actions
    );
  }

  // Leading
  @protected
  Widget? buildLeadingWidget(BuildContext context) {
    Widget? image = leadingImage;
    return (image != null) ? Semantics(label: leadingLabel, hint: leadingHint, button: true, excludeSemantics: true, child:
      IconButton(icon: image, onPressed: () => onTapLeading(context))
    ) : null;
  }

  
  @protected
  Widget? get leadingImage => (leadingIconKey != null) ? Styles().images.getImage(leadingIconKey, excludeFromSemantics: true) : null;

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
