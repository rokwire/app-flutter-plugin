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
import 'package:rokwire_plugin/gen/styles.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class PopupMessage extends StatelessWidget {
  final String? title;
  final TextStyle? titleTextStyle;
  final Color? titleTextColor;
  final String? titleFontFamily;
  final double titleFontSize;
  final TextAlign? titleTextAlign;
  final EdgeInsetsGeometry titlePadding;
  final Color? titleBarColor;
  
  final String? message;
  final TextStyle? messageTextStyle;
  final Color? messageTextColor;
  final String? messageFontFamily;
  final double messageFontSize;
  final TextAlign? messageTextAlign;
  final EdgeInsetsGeometry messagePadding;
  
  final Widget? button;
  final String? buttonTitle;
  final EdgeInsetsGeometry buttonPadding;
  final void Function(BuildContext context)? onTapButton;

  final ShapeBorder? border;
  final BorderRadius? borderRadius;

  const PopupMessage({Key? key,
    this.title,
    this.titleTextStyle,
    this.titleTextColor,
    this.titleFontFamily,
    this.titleFontSize = 20.0,
    this.titleTextAlign,
    this.titlePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.titleBarColor,
    
    this.message,
    this.messageTextStyle,
    this.messageTextColor,
    this.messageFontFamily,
    this.messageFontSize = 16.0,
    this.messageTextAlign,
    this.messagePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    
    this.button,
    this.buttonTitle,
    this.buttonPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    this.onTapButton,

    this.border,
    this.borderRadius,
  }) : super(key: key);

  @protected Color? get defautTitleBarColor => AppColors.fillColorPrimary;
  @protected Color? get displayTitleBarColor => titleBarColor ?? defautTitleBarColor;

  @protected Color? get defautTitleTextColor => AppColors.textLight;
  @protected Color? get displayTitleTextColor => titleTextColor ?? defautTitleTextColor;
  
  @protected String? get defaultTitleFontFamily => AppFontFamilies.bold;
  @protected String? get displayTitleFontFamily => titleFontFamily ?? defaultTitleFontFamily;
  
  @protected TextStyle get defaultTitleTextStyle => TextStyle(fontFamily: displayTitleFontFamily, fontSize: titleFontSize, color: displayTitleTextColor);
  @protected TextStyle get displayTitleTextStyle => titleTextStyle ?? defaultTitleTextStyle;

  @protected Color? get defautMessageTextColor => AppColors.fillColorPrimary;
  @protected Color? get displayMessageTextColor => messageTextColor ?? defautMessageTextColor;
  
  @protected String? get defaultMessageFontFamily => AppFontFamilies.bold;
  @protected String? get displayMessageFontFamily => messageFontFamily ?? defaultMessageFontFamily;
  
  @protected TextStyle get defaultMessageTextStyle => TextStyle(fontFamily: displayMessageFontFamily, fontSize: messageFontSize, color: displayMessageTextColor);
  @protected TextStyle get displayMessageTextStyle => messageTextStyle ?? defaultMessageTextStyle;

  @protected Widget getDefaultButton(BuildContext context) => RoundedButton(label: buttonTitle ?? '', contentWeight: 0.75, onTap: () => _onTapButton(context),);
  @protected Widget getDisplayButton(BuildContext context) => button ?? getDefaultButton(context);

  @protected BorderRadius get defautBorderRadius => const BorderRadius.all(Radius.circular(8));
  @protected BorderRadius get displayBorderRadius => borderRadius ?? defautBorderRadius;

  @protected ShapeBorder get defautBorder => RoundedRectangleBorder(borderRadius: displayBorderRadius,);
  @protected ShapeBorder get displayBorder => border ?? defautBorder;

  static Future<void> show({
    String? title,
    TextStyle? titleTextStyle,
    Color? titleTextColor,
    String? titleFontFamily,
    double titleFontSize = 20,
    TextAlign? titleTextAlign,
    EdgeInsetsGeometry titlePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    Color? titleBarColor,
    
    String? message,
    TextStyle? messageTextStyle,
    Color? messageTextColor,
    String? messageFontFamily,
    double messageFontSize = 16.0,
    TextAlign? messageTextAlign,
    EdgeInsetsGeometry messagePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    
    Widget? button,
    String? buttonTitle,
    EdgeInsetsGeometry buttonPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    void Function(BuildContext context)? onTapButton,

    ShapeBorder? border,
    BorderRadius? borderRadius,

    required BuildContext context,
    bool barrierDismissible = true,
  }) => showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) => PopupMessage(
      title: title,
      titleTextStyle: titleTextStyle,
      titleTextColor: titleTextColor,
      titleFontFamily: titleFontFamily,
      titleFontSize: titleFontSize,
      titleTextAlign: titleTextAlign,
      titlePadding: titlePadding,
      titleBarColor: titleBarColor,
  
      message: message,
      messageTextStyle: messageTextStyle,
      messageTextColor: messageTextColor,
      messageFontFamily: messageFontFamily,
      messageFontSize: messageFontSize,
      messageTextAlign: messageTextAlign,
      messagePadding: messagePadding,
  
      button: button,
      buttonTitle: buttonTitle,
      buttonPadding: buttonPadding,
      onTapButton: onTapButton,

      border: border,
      borderRadius: borderRadius,
    )
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: displayBorderRadius, child:
      Dialog(shape: displayBorder, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
          Row(children: <Widget>[
            Expanded(child:
              Container(color: displayTitleBarColor, child:
                Padding(padding: titlePadding, child:
                  Text(title ?? '', style: displayTitleTextStyle, textAlign: titleTextAlign,),
                ),
              ),
            ),
          ],),
          Padding(padding: messagePadding, child:
            Text(message ?? '', textAlign: messageTextAlign, style: displayMessageTextStyle,),
          ),
          Padding(padding: buttonPadding, child:
            getDisplayButton(context),
          ),
        ],),
      ),
    );
  }

  void _onTapButton(BuildContext context) {
    if (onTapButton != null) {
      onTapButton!(context);
    }
    else {
      Navigator.of(context).pop(true);
    }
  }
}

class ActionsMessage extends StatelessWidget {
  final String? title;
  final TextStyle? titleTextStyle;
  final Color? titleTextColor;
  final String? titleFontFamily;
  final double titleFontSize;
  final TextAlign? titleTextAlign;
  final EdgeInsetsGeometry titlePadding;
  final Color? titleBarColor;
  final Widget? closeButtonIcon;
  
  final String? message;
  final TextStyle? messageTextStyle;
  final Color? messageTextColor;
  final String? messageFontFamily;
  final double messageFontSize;
  final TextAlign? messageTextAlign;
  final EdgeInsetsGeometry messagePadding;
  
  final List<Widget> buttons;
  final EdgeInsetsGeometry buttonsPadding;
  final Axis buttonAxis;

  final Widget? bodyWidget;

  final ShapeBorder? border;
  final BorderRadius? borderRadius;

  const ActionsMessage({Key? key,
    this.title,
    this.titleTextStyle,
    this.titleTextColor,
    this.titleFontFamily,
    this.titleFontSize = 20.0,
    this.titleTextAlign,
    this.titlePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.titleBarColor,
    this.closeButtonIcon,
    
    this.message,
    this.messageTextStyle,
    this.messageTextColor,
    this.messageFontFamily,
    this.messageFontSize = 16.0,
    this.messageTextAlign,
    this.messagePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    
    this.buttons = const [],
    this.buttonsPadding = const EdgeInsets.only(left: 16, right: 16, bottom: 16),
    this.buttonAxis = Axis.horizontal,

    this.bodyWidget,

    this.border,
    this.borderRadius,
  }) : super(key: key);

  @protected Color? get defautTitleBarColor => AppColors.fillColorPrimary;
  @protected Color? get displayTitleBarColor => titleBarColor ?? defautTitleBarColor;

  @protected Color? get defautTitleTextColor => AppColors.textLight;
  @protected Color? get displayTitleTextColor => titleTextColor ?? defautTitleTextColor;
  
  @protected String? get defaultTitleFontFamily => AppFontFamilies.bold;
  @protected String? get displayTitleFontFamily => titleFontFamily ?? defaultTitleFontFamily;
  
  @protected TextStyle get defaultTitleTextStyle => TextStyle(fontFamily: displayTitleFontFamily, fontSize: titleFontSize, color: displayTitleTextColor);
  @protected TextStyle get displayTitleTextStyle => titleTextStyle ?? defaultTitleTextStyle;

  @protected Color? get defautMessageTextColor => AppColors.fillColorPrimary;
  @protected Color? get displayMessageTextColor => messageTextColor ?? defautMessageTextColor;
  
  @protected String? get defaultMessageFontFamily => AppFontFamilies.bold;
  @protected String? get displayMessageFontFamily => messageFontFamily ?? defaultMessageFontFamily;
  
  @protected TextStyle get defaultMessageTextStyle => TextStyle(fontFamily: displayMessageFontFamily, fontSize: messageFontSize, color: displayMessageTextColor);
  @protected TextStyle get displayMessageTextStyle => messageTextStyle ?? defaultMessageTextStyle;

  @protected BorderRadius get defautBorderRadius => const BorderRadius.all(Radius.circular(8));
  @protected BorderRadius get displayBorderRadius => borderRadius ?? defautBorderRadius;

  @protected ShapeBorder get defautBorder => RoundedRectangleBorder(borderRadius: displayBorderRadius,);
  @protected ShapeBorder get displayBorder => border ?? defautBorder;

  @protected Widget? get defaultCloseButtonIcon => Styles().images?.getImage('close-circle-light', defaultSpec: FontAwesomeImageSpec(type: 'fa.icon', source: '0xf057', size: 18.0, color: AppColors.surface));
  @protected Widget? get displayCloseButtonIcon => closeButtonIcon ?? defaultCloseButtonIcon;

  static Future<T?> show<T>({
    String? title,
    TextStyle? titleTextStyle,
    Color? titleTextColor,
    String? titleFontFamily,
    double titleFontSize = 20,
    TextAlign? titleTextAlign,
    EdgeInsetsGeometry titlePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    Color? titleBarColor,
    Widget? closeButtonIcon,
    
    String? message,
    TextStyle? messageTextStyle,
    Color? messageTextColor,
    String? messageFontFamily,
    double messageFontSize = 16.0,
    TextAlign? messageTextAlign,
    EdgeInsetsGeometry messagePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    
    List<Widget> buttons = const [],
    EdgeInsetsGeometry buttonsPadding = const EdgeInsets.only(left: 16, right: 16, bottom: 16),
    Axis buttonAxis = Axis.horizontal,

    ShapeBorder? border,
    BorderRadius? borderRadius,

    required BuildContext context,
    bool barrierDismissible = true,
  }) => showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) => ActionsMessage(
      title: title,
      titleTextStyle: titleTextStyle,
      titleTextColor: titleTextColor,
      titleFontFamily: titleFontFamily,
      titleFontSize: titleFontSize,
      titleTextAlign: titleTextAlign,
      titlePadding: titlePadding,
      titleBarColor: titleBarColor,
      closeButtonIcon: closeButtonIcon,
  
      message: message,
      messageTextStyle: messageTextStyle,
      messageTextColor: messageTextColor,
      messageFontFamily: messageFontFamily,
      messageFontSize: messageFontSize,
      messageTextAlign: messageTextAlign,
      messagePadding: messagePadding,
  
      buttons: buttons,
      buttonAxis: buttonAxis,
      buttonsPadding: buttonsPadding,

      border: border,
      borderRadius: borderRadius,
    )
  );

  @override
  Widget build(BuildContext context) {
    List<Widget> flexibleButtons = [];
    for (Widget button in buttons) {
      flexibleButtons.add(button);
    }
    Widget? closeButton = displayCloseButtonIcon;
    return Dialog(shape: displayBorder, clipBehavior: Clip.antiAlias, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
        Material(
          color: displayTitleBarColor,
          child: Row(children: [
            Expanded(child:
              Padding(padding: titlePadding, child:
                Text(title ?? '', style: displayTitleTextStyle, textAlign: titleTextAlign,),
              ),
            ),
            closeButton != null ? IconButton(icon: closeButton, onPressed: () { Navigator.pop(context); }) : Container(),
          ]),
        ),
        bodyWidget ?? Column(children: <Widget>[
          Padding(padding: messagePadding, child:
            Text(message ?? '', textAlign: messageTextAlign, style: displayMessageTextStyle,),
          ),
          buttonAxis == Axis.vertical ?
              Padding(padding: buttonsPadding, child: Column(children: buttons),)
                : Padding(padding: buttonsPadding,
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min, children: flexibleButtons,),
                ),
        ])
      ],),
    );
  }
}