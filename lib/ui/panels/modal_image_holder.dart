
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/content.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/ui/widgets/image_meta_data.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ModalImageHolder extends StatelessWidget implements ImageHolder, ImageMetaDataDecorator{
  final String? imageUrl; //If we want to open different Url than the one child/image contains. Useful for thumb images that have url leading to larger image
  final String? imageKey;
  final Image? image; //If the child can't be Image. Useful when Image is wrapped within Decoration
  final Widget? child; //Preferably Image that will be directly passed to the ModalImagePanel. But can also contain image wrapped in Contained/Decoration/etc - then must use url or image
  final Map<String, String>? headers;
  final ImageMetaData? metaData; //Decorator field.

  const ModalImageHolder({super.key, this.image, this.child, this.imageUrl, this.imageKey, this.headers, this.metaData});

  @override //Used to pass the metaData fut in the same time keep the metaData final. Fixing warning.
  ImageMetaDataDecorator copyWithMetaData(ImageMetaData? metaData) =>
      ModalImageHolder(key: super.key, image: this.image,  imageUrl: this.imageUrl, child: this.child, imageKey: this.imageKey, headers: this.headers, metaData: metaData ?? this.metaData);

  @override String? get holderUrl => imageUrl;
  @override String? get holderKey => imageKey;
  @override Image? get holderImage => image ?? (
      child is Image ? child as Image :
      child is ImageHolder ? (child as ImageHolder).holderImage :
      null );

  @override
  Widget build(BuildContext context) {
    return Semantics(hint: "double tap to Zoom", button: true, child:
      InkWell(
        onTap: () => _showModalImage(context),
        child: child ?? Container(),
      ));
  }

  //Modal Image Dialog
  void _showModalImage(BuildContext context) =>
    StringUtils.isNotEmpty(imageUrl) ||
    StringUtils.isNotEmpty(imageKey) ||
    holderImage?.image != null ?
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (_, __, ___) =>
          ModalPhotoImagePanel(image: holderImage?.image, imageUrl: imageUrl, imageKey: imageKey, imageMetadata: metaData, networkImageHeaders: headers))
      ) : null;
}

abstract class ImageHolder {
  Image? get holderImage;
  String? get holderUrl => null;
  String? get holderKey => null;
}