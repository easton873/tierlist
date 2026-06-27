import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/tierlist_file.dart';

Future<bool> saveTierlistFile(
  BuildContext context,
  TierlistFile file,
) async {
  try {
    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Tierlist',
      fileName: 'tierlist.tierlist',
      type: FileType.custom,
      allowedExtensions: ['tierlist'],
    );
    if (outputFile == null) return false;

    final path =
        outputFile.endsWith('.tierlist') ? outputFile : '$outputFile.tierlist';
    final json = jsonEncode(file.toJson());
    await File(path).writeAsString(json, flush: true);
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
    return false;
  }
}

Future<TierlistFile?> loadTierlistFile(BuildContext context) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Open Tierlist',
      type: FileType.custom,
      allowedExtensions: ['tierlist'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final path = result.files.single.path;
    if (path == null) return null;

    final raw = await File(path).readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return TierlistFile.fromJson(json);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e')),
      );
    }
    return null;
  }
}
