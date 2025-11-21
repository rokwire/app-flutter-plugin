import 'package:flutter/widgets.dart';
import 'package:rokwire_plugin/service/content.dart';

import '../../model/content.dart';

mixin ImageMetaDataProviderMixin<T extends StatefulWidget> on State<T> implements  ImageMetaDataHolder{
  late final ImageMetaDataProvider _provider;

  @protected String? get metaDataKey;
  @protected ImageMetaData? get initialMetaData;
  @protected void onMetaDataProvided();

  ImageMetaData? get metaData => _provider.metaData;

  @override
  void initState() {
    super.initState();
    initProvider(imageUrl: metaDataKey, initialData: initialMetaData);
  }

  /// This method must be called from the `initState` of the State class using this mixin.
  void initProvider({ImageMetaData? initialData, String? imageUrl}) {
    _provider = ImageMetaDataProvider(initialData: initialData, imageUrl: imageUrl,);
    _provider.addListener(onMetaDataProvided);
    _provider.loadMetaData();
  }

  @override
  void dispose() {
    _provider.removeListener(onMetaDataProvided);
    _provider.dispose();
    super.dispose();
  }
}

class ImageMetaDataProvider extends ChangeNotifier {
  final String? imageUrl;
  ImageMetaData? _metaData;
  bool _isLoading = false;

  ImageMetaDataProvider({required String? this.imageUrl, ImageMetaData? initialData}) :
    _metaData = initialData;

  ImageMetaData? get metaData => _metaData;

  bool get isLoading => _isLoading;

  void loadMetaData() {
    if (_metaData != null || _isLoading || imageUrl == null) return;

    _isLoading = true;
    Content().loadImageMetaData(url: imageUrl!).then((result) {
      _metaData = result.imageMetaData ?? _metaData;
      _isLoading = false;
      // Notify all listeners that the data has changed.
      notifyListeners();
    });
  }
}

abstract class ImageMetaDataHolder {
  ImageMetaData? get metaData;
  // set onMetaDataChanged(ValueChanged<ImageMetaData?>? onMetaDataChanged);
}

mixin ImageMetaDataDecorator on Widget{
  ImageMetaDataDecorator copyWithMetaData(ImageMetaData? metaData);
}