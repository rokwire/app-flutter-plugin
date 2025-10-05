import 'package:flutter/material.dart';

import '../../model/content.dart';
import '../../service/content.dart';
import '../panels/modal_image_holder.dart';

class AccessibleImageHolder extends StatefulWidget implements ImageHolder{
  final ImageMetaData? metaData;
  final String? imageUrl;
  final Widget? child; //Image or ImageHolder

  final String? emptySemanticsLabel;
  final String? prefixSemanticsLabel;
  final String? suffixSemanticsLabel;

  @override
  Image? get image => child is Image ? child as Image :
                                        child is ImageHolder ? (child as ImageHolder).image : null;

  const AccessibleImageHolder({super.key, this.metaData, required this.child, this.imageUrl, this.emptySemanticsLabel, this.prefixSemanticsLabel, this.suffixSemanticsLabel});

  @override
  State<StatefulWidget> createState() =>
      _AccessibleImageHolderState();
}

class _AccessibleImageHolderState extends State<AccessibleImageHolder>{
  ImageMetaData? _metaData;

  @override
  void initState() {
    _metaData = widget.metaData;
    if(_metaData == null ){
      _loadMetaData();
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AccessibleImageHolder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if the image or metadata changes
    if (widget.image?.image != oldWidget.image?.image || widget.metaData != oldWidget.metaData) {
      _loadMetaData();
    }
  }

  @override
  Widget build(BuildContext context) =>
      Semantics(label: _imageAltText != null ? _semanticsLabel : widget.emptySemanticsLabel,
          image: true,
          excludeSemantics: true,
          child: widget.child
      );

  void _loadMetaData() {
    String? url = _imageUrl;
    if(url != null) {
      Content().loadImageMetaData(imageUrl: url).then((metaData) => {
          if(mounted){
              setState(() =>
          _metaData = metaData ?? _metaData
          )}
      });
    }
  }

  String? get _imageUrl =>  widget.image is NetworkImage ? (widget.image as NetworkImage).url : null;

  String? get _imageAltText => _metaData?.altText;

  String? get _semanticsLabel => "${widget.prefixSemanticsLabel ?? ""} $_imageAltText ${widget.suffixSemanticsLabel ?? ""}";
}