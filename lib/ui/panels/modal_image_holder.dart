
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ModalImageHolder extends StatelessWidget{
  final String? url; //If we want to open different Url than the one child/image contains. Useful for thumb images that have url leading to larger image
  final ImageProvider? image; //If the child can't be Image. Useful when Image is wrapped within Decoration
  final Widget? child; //Preferably Image that will be directly passed to the ModalImagePanel. But can also contain image wrapped in Contained/Decoration/etc - then must use url/image

  const ModalImageHolder({Key? key,  this.child, this.url, this.image, }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        _showModalImage(context);
      },
      child: child?? Container(),
    );
  }

  //Modal Image Dialog
  void _showModalImage(BuildContext context){
    if(StringUtils.isNotEmpty(url)){
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => ModalImagePanel(imageKey: url)));
    }
    else if(image != null){
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => ModalImagePanel(image: image)));
    }
    else if ((child is Image) && child != null) {
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => ModalImagePanel(image: (child as Image).image)));
    }
  }
}