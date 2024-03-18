import 'package:flutter/widgets.dart';
import 'package:rokwire_plugin/service/styles.dart';

class UiImage extends StatelessWidget {
  final ImageSpec? spec;
  final Widget? defaultWidget;
  final bool excludeFromSemantics;
  final Animation<double>? opacity;
  final ImageRepeat? repeat;
  final Rect? centerSlice;
  final Map<String, String>? networkHeaders;
  final Widget Function(BuildContext, Widget, int?, bool)? frameBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  const UiImage({super.key, this.spec, this.defaultWidget, this.excludeFromSemantics = false,
    this.opacity, this.repeat, this.centerSlice, this.networkHeaders,
    this.frameBuilder, this.loadingBuilder, this.errorBuilder});

  UiImage apply({Key? key, Widget? defaultWidget, dynamic source, double? scale, double? size,
    double? width, double? height, String? weight, Color? color, String? semanticLabel, bool? excludeFromSemantics,
    double? fill, double? grade, double? opticalSize, String? fontFamily, String? fontPackage,
    bool? isAntiAlias, bool? matchTextDirection, bool? gaplessPlayback, AlignmentGeometry? alignment,
    Animation<double>? opacity, BlendMode? colorBlendMode, BoxFit? fit, FilterQuality? filterQuality, ImageRepeat? repeat,
    Rect? centerSlice, TextDirection? textDirection, Map<String, String>? networkHeaders,
    Widget Function(BuildContext, Widget, int?, bool)? frameBuilder,
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder}) {

    ImageSpec? imageSpec = spec;
    if (imageSpec == null) {
      return const UiImage();
    }

    imageSpec = ImageSpec.fromOther(imageSpec, source: source, scale: scale, size: size,
      width: width, height: height, weight: weight,
      fill: fill, grade: grade, opticalSize: opticalSize,
      fontFamily: fontFamily, fontPackage: fontPackage,
      color: color, semanticLabel: semanticLabel, isAntiAlias: isAntiAlias,
      matchTextDirection: matchTextDirection, gaplessPlayback: gaplessPlayback,
      alignment: alignment, colorBlendMode: colorBlendMode, fit: fit,
      filterQuality: filterQuality, repeat: repeat, textDirection: textDirection,
    );

    return UiImage(key: key ?? this.key, spec: imageSpec,
        defaultWidget: defaultWidget ?? this.defaultWidget,
        excludeFromSemantics: excludeFromSemantics ?? this.excludeFromSemantics,
        opacity: opacity ?? this.opacity, repeat: repeat ?? this.repeat,
        centerSlice: centerSlice ?? this.centerSlice, networkHeaders: networkHeaders ?? this.networkHeaders,
        frameBuilder: frameBuilder ?? this.frameBuilder, loadingBuilder: loadingBuilder ?? this.loadingBuilder,
        errorBuilder: errorBuilder ?? this.errorBuilder);
  }

  @override
  Widget build(BuildContext context) {
    Widget? image;
    ImageSpec? imageSpec = spec;
    if (imageSpec != null) {
      try {
        if (imageSpec is FlutterImageSpec) {
          image = UiImages.getFlutterImage(imageSpec);
        } else if (imageSpec is FontAwesomeImageSpec) {
          image = UiImages.getFaIcon(imageSpec);
        } else if (imageSpec is MaterialIconImageSpec) {
          image = UiImages.getMaterialIcon(imageSpec);
        }
      } catch(e) {
        debugPrint(e.toString());
      }
    }
    return image ?? defaultWidget ?? Container();
  }
}
