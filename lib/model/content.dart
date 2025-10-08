import 'package:rokwire_plugin/utils/utils.dart';

class ImageMetaData {
  final String? altText;
  final bool? decorative;

  ImageMetaData( {this.altText, this.decorative});

  static ImageMetaData? fromJson(Map<String, dynamic>? json) => json != null ? ImageMetaData(
    altText: JsonUtils.stringValue("alt_text"),
    decorative: JsonUtils.boolValue("decorative")
  ) : null;

  Map<String, dynamic> toJson() =>
      {
        "alt_text": this.altText,
        "decorative": this.decorative
      };

  @override
  bool operator==(Object other) =>
      (other is ImageMetaData) &&
          (altText == other.altText) &&
          (decorative == other.decorative);

  @override
  int get hashCode =>
      (altText?.hashCode ?? 0) ^
      (decorative?.hashCode ?? 0);
}