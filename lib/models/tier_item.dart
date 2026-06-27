import 'dart:convert';
import 'dart:typed_data';
import 'text_overlay_config.dart';

enum TierItemType { image, text }

class TierItem {
  static TierItem fromJson(Map<String, dynamic> json) {
    return TierItem(
      id: json['id'] as String,
      type: TierItemType.values.byName(json['type'] as String),
      imageBytes: json['imageBytes'] != null
          ? base64Decode(json['imageBytes'] as String)
          : null,
      imageName: json['imageName'] as String?,
      text: json['text'] as String?,
      overlay: json['overlay'] != null
          ? TextOverlayConfig.fromJson(
              json['overlay'] as Map<String, dynamic>)
          : null,
      autoSize: json['autoSize'] as bool,
      customSize: json['customSize'] != null
          ? (json['customSize'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        if (imageBytes != null) 'imageBytes': base64Encode(imageBytes!),
        if (imageName != null) 'imageName': imageName,
        if (text != null) 'text': text,
        if (overlay != null) 'overlay': overlay!.toJson(),
        'autoSize': autoSize,
        if (customSize != null) 'customSize': customSize,
      };
  final String id;
  final TierItemType type;
  final Uint8List? imageBytes;
  final String? imageName;
  final String? text;
  final TextOverlayConfig? overlay;
  final bool autoSize;
  final double? customSize;

  const TierItem({
    required this.id,
    required this.type,
    this.imageBytes,
    this.imageName,
    this.text,
    this.overlay,
    this.autoSize = true,
    this.customSize,
  });

  TierItem copyWith({
    String? id,
    TierItemType? type,
    Uint8List? imageBytes,
    String? imageName,
    String? text,
    TextOverlayConfig? overlay,
    bool clearOverlay = false,
    bool? autoSize,
    double? customSize,
    bool clearCustomSize = false,
  }) {
    return TierItem(
      id: id ?? this.id,
      type: type ?? this.type,
      imageBytes: imageBytes ?? this.imageBytes,
      imageName: imageName ?? this.imageName,
      text: text ?? this.text,
      overlay: clearOverlay ? null : (overlay ?? this.overlay),
      autoSize: autoSize ?? this.autoSize,
      customSize: clearCustomSize ? null : (customSize ?? this.customSize),
    );
  }
}
