import 'dart:typed_data';
import 'text_overlay_config.dart';

enum TierItemType { image, text }

class TierItem {
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
