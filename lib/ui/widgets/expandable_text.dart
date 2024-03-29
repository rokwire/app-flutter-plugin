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
import 'package:rokwire_plugin/service/styles.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;

  final int trimLinesCount;

  final Color? splitterColor;
  final double splitterHeight;
  final EdgeInsetsGeometry splitterMargin;

  final TextStyle? readMoreStyle;

  final Widget? readMoreIcon;
  final String? readMoreIconKey;
  final EdgeInsetsGeometry readMoreIconPadding;

  final Widget? footerWidget;

  const ExpandableText(this.text, {
    Key? key,
    this.textStyle,

    this.trimLinesCount = 3,

    this.splitterColor,
    this.splitterHeight = 1,
    this.splitterMargin = const EdgeInsets.symmetric(vertical: 5),

    this.readMoreStyle,

    this.readMoreIcon,
    this.readMoreIconKey,
    this.readMoreIconPadding = const EdgeInsets.only(left: 7),

    this.footerWidget,
  })  : super(key: key);

  TextStyle get _textStyle => textStyle ?? TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground,);
  
  String get trimSuffix => '...';

  Color? get _splitterColor => splitterColor ?? Styles().colors.fillColorSecondary;
  
  String get readMoreText => 'Read more';
  String? get readMoreHint => null;
  TextStyle get _readMoreStyle => readMoreStyle ?? TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary);

  Widget? get _readMoreIcon => readMoreIcon ?? (readMoreIconKey != null ? Styles().images.getImage(readMoreIconKey!, excludeFromSemantics: true) : null);

  @override
  _ExpandableTextState createState() => _ExpandableTextState();

}

class _ExpandableTextState extends State<ExpandableText> {

  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      
      List<Widget> contentList = <Widget>[];
      
      TextPainter textPainter = TextPainter(
        textScaler: MediaQuery.of(context).textScaler,
        textDirection: TextDirection.rtl,
      );
      
      textPainter.text = TextSpan(text: widget.trimSuffix, style: widget._textStyle,);
      textPainter.layout(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
      Size elipsisSize = textPainter.size;
      
      textPainter.text = TextSpan(text: widget.text, style: widget._textStyle);
      textPainter.maxLines = widget.trimLinesCount;
      textPainter.layout(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
      Size textSize = textPainter.size;

      TextPosition pos = textPainter.getPositionForOffset(Offset(textSize.width - elipsisSize.width, textSize.height,));
      int? endIndex = textPainter.getOffsetBefore(pos.offset);
      if (textPainter.didExceedMaxLines) {
        
        String displayText = _collapsed ? widget.text.substring(0, endIndex) + widget.trimSuffix : widget.text;
        contentList.add(RichText(textScaler: MediaQuery.of(context).textScaler, softWrap: true, overflow: TextOverflow.clip,
          text: TextSpan(text: displayText, style: widget._textStyle,),
        ),);

        if (_collapsed) {
          List<Widget> readMoreList = <Widget>[
            Text(widget.readMoreText, style: widget._readMoreStyle,),
          ];
          
          Widget? readMoreIcon = widget._readMoreIcon;
          if (readMoreIcon != null) {
            readMoreList.add(Padding(padding: widget.readMoreIconPadding, child: readMoreIcon));
          }

          contentList.add(Semantics(button: true, label: widget.readMoreText, hint: widget.readMoreHint, child:
            InkWell(onTap: _onTapLink, child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(color: widget._splitterColor, height: widget.splitterHeight, margin: widget.splitterMargin,),
                Center(child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: readMoreList,),
                ),
              ],)
            )
          ));
        }
        else if (widget.footerWidget != null) {
          contentList.add(widget.footerWidget!);
        }
      }
      else {
        contentList.add(Text(widget.text, style: widget._textStyle,));

        if (widget.footerWidget != null) {
          contentList.add(widget.footerWidget!);
        }
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
    },);
  }

  void _onTapLink() {
    setState(() => _collapsed = !_collapsed);
  }
}