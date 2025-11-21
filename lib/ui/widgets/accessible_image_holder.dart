
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/content.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/image_meta_data.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AccessibleImageHolder extends StatefulWidget implements ImageHolder{
  final ImageMetaData? metaData;
  final Function(ImageMetaData? data)? onMetaDataLoaded;
  final String? imageUrl;
  final Widget? child; //Image or ImageHolder

  final String? emptySemanticsLabel;
  final String? prefixSemanticsLabel;
  final String? suffixSemanticsLabel;

  @override
  Image? get holderImage => child is Image ? child as Image :
                                     child is ImageHolder ? (child as ImageHolder).holderImage : null;

  @override
  String? get holderUrl => imageUrl ??
                                        (child is ImageHolder ? (child as ImageHolder).holderUrl : null);

  @override
  String? get holderKey => child is ImageHolder ? (child as ImageHolder).holderKey : null;

  static  String? getUrlFromImageProvider(ImageProvider? provider) => provider is NetworkImage ? provider.url : null;

  @override
  State<StatefulWidget> createState() => _AccessibleImageHolderState();

  const AccessibleImageHolder({super.key, this.metaData, required this.child, this.imageUrl, this.emptySemanticsLabel, this.prefixSemanticsLabel, this.suffixSemanticsLabel, this.onMetaDataLoaded});
}

class _AccessibleImageHolderState extends State<AccessibleImageHolder> with ImageMetaDataProviderMixin{

  @override
  ImageMetaData? get initialMetaData => widget.metaData;

  @override
  String? get metaDataKey => 
    widget.imageUrl   ??
    widget.holderKey ??
    AccessibleImageHolder.getUrlFromImageProvider(widget.holderImage?.image);

  @override
  void onMetaDataProvided() {
    if (mounted) {
      widget.onMetaDataLoaded?.call(metaData);
      setState((){}); // Update the metaData in the decorator
    }
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(excluding: _excludeSemantics, child:
      MergeSemantics(child:
        Semantics(label: _semanticsLabel,
          image: true, excludeSemantics: _excludeSemantics, explicitChildNodes: true, container: true,
          child: _metaDataDecorator?.copyWithMetaData(metaData) ?? widget.child
      )));

  bool get _excludeSemantics => StringUtils.isEmpty(_semanticsLabel);

  String? get _semanticsLabel =>  metaData?.decorative == true ? null :
    _imageAltText != null ?
      _semanticsText :
      widget.emptySemanticsLabel;

  String? get _semanticsText =>  "${widget.prefixSemanticsLabel ?? ""} $_imageAltText ${widget.suffixSemanticsLabel ?? ""}";

  String? get _imageAltText => metaData?.altText;

  ImageMetaDataDecorator? get _metaDataDecorator => widget.child is ImageMetaDataDecorator ? widget.child as ImageMetaDataDecorator : null;
}
