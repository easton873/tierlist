import 'package:uuid/uuid.dart';

class VideoClip {
  final String id;
  final String path;
  final String name;
  final double sourceDuration;
  final double trimStart;
  final double trimEnd;
  final double fadeDuration;

  VideoClip({
    required this.id,
    required this.path,
    required this.name,
    required this.sourceDuration,
    this.trimStart = 0.0,
    double? trimEnd,
    this.fadeDuration = 0.5,
  }) : trimEnd = trimEnd ?? sourceDuration;

  static VideoClip create({
    required String path,
    required String name,
    required double sourceDuration,
  }) {
    return VideoClip(
      id: const Uuid().v4(),
      path: path,
      name: name,
      sourceDuration: sourceDuration,
    );
  }

  VideoClip copyWith({
    String? id,
    String? path,
    String? name,
    double? sourceDuration,
    double? trimStart,
    double? trimEnd,
    double? fadeDuration,
  }) {
    return VideoClip(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      sourceDuration: sourceDuration ?? this.sourceDuration,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      fadeDuration: fadeDuration ?? this.fadeDuration,
    );
  }

  double get trimmedDuration => trimEnd - trimStart;
}
