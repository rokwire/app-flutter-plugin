
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ModalImageHolder extends StatelessWidget{
  final String? url;
  final Widget? child;

  const ModalImageHolder({Key? key,  this.child, this.url, }) : super(key: key);
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
      AppToast.show("New Modal with Url");
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => ModalImagePanel(imageUrl: url)));
    }
    else if ((child is Image) && child != null) {
      AppToast.show("New Modal with Image");
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => ModalImagePanel(image: (child as Image).image)));    }
  }
}