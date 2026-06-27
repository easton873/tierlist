import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/tier_item.dart';

const _clipboardChannel = MethodChannel('tierlist/clipboard');

const _uuid = Uuid();

Future<TierItem?> pickImageItem() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  if (file.bytes == null) return null;
  return TierItem(
    id: _uuid.v4(),
    type: TierItemType.image,
    imageBytes: file.bytes,
    imageName: file.name,
  );
}

Future<TierItem?> clipboardImageItem() async {
  final result = await _clipboardChannel.invokeMethod<Uint8List>('getImage');
  if (result == null) return null;
  return TierItem(
    id: _uuid.v4(),
    type: TierItemType.image,
    imageBytes: result,
    imageName: 'clipboard',
  );
}

Future<Uint8List?> pickImageBytes() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  return result.files.first.bytes;
}
