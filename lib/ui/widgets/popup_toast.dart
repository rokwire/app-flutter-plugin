
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class PopupToast extends StatelessWidget {

  static const double defaultWidthRatio = 0.75;

  static const EdgeInsetsGeometry defaultPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  static BoxDecoration defaultDecoration = BoxDecoration(
      color: Styles.appColors.surface,
      border: Border.all(color: Styles.appColors.surfaceAccent, width: 1),
      borderRadius: const BorderRadius.all(const Radius.circular(8))
  );

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Decoration? decoration;
  final double widthRatio;

  PopupToast({ Key? key, required this.child,
    this.padding = defaultPadding,
    this.widthRatio = defaultWidthRatio,
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
    Container(width: MediaQuery.of(context).size.width * widthRatio,
      padding: padding, decoration: decoration ?? defaultDecoration,
      child: child,
    );
}