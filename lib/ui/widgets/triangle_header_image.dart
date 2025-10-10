import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/accessible_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

class TriangleHeaderImage extends StatelessWidget {
  final Color?  flexBackColor;
  final String? flexImageUrl;
  final String? flexImageKey;
  final Color?  flexLeftToRightTriangleColor;
  final double? flexLeftToRightTriangleHeight;
  final Color?  flexRightToLeftTriangleColor;
  final double? flexRightToLeftTriangleHeight;
  const TriangleHeaderImage({super.key, this.flexBackColor, this.flexImageUrl, this.flexImageKey, this.flexLeftToRightTriangleColor,
    this.flexLeftToRightTriangleHeight, this.flexRightToLeftTriangleColor, this.flexRightToLeftTriangleHeight
  });

  @override
  Widget build(BuildContext context) {
    return Container(color: flexBackColor, child:
      Stack(alignment: Alignment.bottomCenter, children: <Widget>[
        buildFlexibleInterior(context),
        buildFlexibleLeftToRightTriangle(context),
        buildFlexibleLeftTriangle(context),
      ],),
    );
  }

  @protected
  Widget buildFlexibleInterior(BuildContext context) {
    Widget? image;
    if (flexImageUrl != null) {
      image = Image.network(Config().wrapWebProxyUrl(sourceUrl: flexImageUrl) ?? '', fit: BoxFit.cover, headers: kIsWeb ? Auth2Csrf().networkAuthHeaders : Config().networkAuthHeaders, excludeFromSemantics: true);
    } else if (flexImageKey != null) {
      image = Styles().images.getImage(flexImageKey, fit: BoxFit.cover, excludeFromSemantics: true);
    }
    return (image != null) ? Positioned.fill(child: ModalImageHolder(child: AccessibleImageHolder(child: image))) : Container();
  }

  @protected
  Widget buildFlexibleLeftToRightTriangle(BuildContext context) => CustomPaint(
    painter: TrianglePainter(painterColor: flexLeftToRightTriangleColor, horzDir: TriangleHorzDirection.leftToRight),
    child: Container(height: flexLeftToRightTriangleHeight,),
  );

  @protected
  Widget buildFlexibleLeftTriangle(BuildContext context) => CustomPaint(
    painter: TrianglePainter(painterColor: flexRightToLeftTriangleColor),
    child: Container(height: flexRightToLeftTriangleHeight,),
  );
}
