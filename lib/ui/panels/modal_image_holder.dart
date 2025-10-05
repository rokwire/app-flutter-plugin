
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ModalImageHolder extends StatelessWidget{
  final String? imageUrl; //If we want to open different Url than the one child/image contains. Useful for thumb images that have url leading to larger image
  final String? imageKey;
  final ImageProvider? image; //If the child can't be Image. Useful when Image is wrapped within Decoration
  final Widget? child; //Preferably Image that will be directly passed to the ModalImagePanel. But can also contain image wrapped in Contained/Decoration/etc - then must use url/image
  final Map<String, String>? headers;

  const ModalImageHolder({Key? key,  this.child, this.imageUrl, this.imageKey, this.image, this.headers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showModalImage(context),
      child: child ?? Container(),
    );
  }

  //Modal Image Dialog
  void _showModalImage(BuildContext context){
    if (StringUtils.isNotEmpty(imageUrl)){
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (_, __, ___) => ModalPhotoImagePanel(imageUrl: imageUrl, networkImageHeaders: headers)));
      //Navigator.push(context, MaterialPageRoute( builder: (_) => ModalPhotoImagePanel(imageUrl: url)));
    }
    else if (StringUtils.isNotEmpty(imageKey)){
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (_, __, ___) => ModalPhotoImagePanel(imageKey: imageKey)));
      //Navigator.push(context, MaterialPageRoute( builder: (_) => ModalPhotoImagePanel(imageKey: imageKey)));
    }
    else if (image != null) {
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (_, __, ___) => ModalPhotoImagePanel(image: image)));
      //Navigator.push(context, MaterialPageRoute( builder: (_) => ModalPhotoImagePanel(image: image)));
    }
    else if (child is Image) {
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (_, __, ___) => ModalPhotoImagePanel(image: (child as Image).image)));
      //Navigator.push(context, MaterialPageRoute( builder: (_) => ModalPhotoImagePanel(image: (child as Image).image)));
    }
    else if(child is ImageHolder) {
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (_, __, ___) => ModalPhotoImagePanel(image: (child as ImageHolder).image?.image)));
    }
  }
}

abstract class ImageHolder {
  Image? get image;
}