import 'dart:io';
import '../models/video_clip.dart';

class FfmpegUtil {
  static Future<double> probeDuration(String path) async {
    final result = await Process.run('ffprobe', [
      '-v', 'quiet',
      '-show_entries', 'format=duration',
      '-of', 'csv=p=0',
      path,
    ]);
    final output = (result.stdout as String).trim();
    return double.tryParse(output) ?? 0.0;
  }

  static Future<bool> hasAudioStream(String path) async {
    final result = await Process.run('ffprobe', [
      '-v', 'quiet',
      '-select_streams', 'a:0',
      '-show_entries', 'stream=codec_type',
      '-of', 'csv=p=0',
      path,
    ]);
    return (result.stdout as String).trim().isNotEmpty;
  }

  static Future<({int w, int h})> probeVideoSize(String path) async {
    final result = await Process.run('ffprobe', [
      '-v', 'quiet',
      '-select_streams', 'v:0',
      '-show_entries', 'stream=width,height',
      '-of', 'csv=p=0',
      path,
    ]);
    final parts = (result.stdout as String).trim().split(',');
    if (parts.length == 2) {
      final w = int.tryParse(parts[0]);
      final h = int.tryParse(parts[1]);
      if (w != null && h != null && w > 0 && h > 0) return (w: w, h: h);
    }
    return (w: 1920, h: 1080);
  }

  static Future<List<String>> buildArgs(
    List<VideoClip> clips,
    String outputPath,
  ) async {
    if (clips.isEmpty) return [];

    final hasAudio = <bool>[];
    for (final clip in clips) {
      hasAudio.add(await hasAudioStream(clip.path));
    }
    final allHaveAudio = hasAudio.every((a) => a);

    final args = <String>['-y'];

    // Single clip: input-level seeking + simple filtergraph (known to work)
    if (clips.length == 1) {
      final clip = clips[0];
      args.addAll([
        '-ss', clip.trimStart.toStringAsFixed(3),
        '-t', clip.trimmedDuration.toStringAsFixed(3),
        '-i', clip.path,
        '-vf', 'setpts=PTS-STARTPTS,format=yuv420p',
        '-c:v', 'libx264', '-preset', 'fast', '-crf', '18',
      ]);
      if (allHaveAudio) {
        args.addAll(['-af', 'aresample=44100', '-c:a', 'aac', '-b:a', '192k']);
      } else {
        args.add('-an');
      }
      args.add(outputPath);
      return args;
    }

    // Multi-clip: load FULL files without any input-level seeking.
    // Input-level -ss/-t interacts badly with filter_complex for multiple inputs.
    // Trimming is handled inside the filter graph with trim+setpts instead.
    for (final clip in clips) {
      args.addAll(['-i', clip.path]);
    }

    final targetSize = await probeVideoSize(clips[0].path);
    final w = targetSize.w;
    final h = targetSize.h;

    final filter = StringBuffer();

    for (int i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final dur = clip.trimmedDuration;
      final fade = clip.fadeDuration;

      // trim selects the time window, setpts resets pts to 0 immediately after
      // so downstream filters (scale, fps, fade, concat) see clean timestamps.
      final vChain = StringBuffer(
        '[$i:v]'
        'trim=start=${clip.trimStart.toStringAsFixed(3)}:end=${clip.trimEnd.toStringAsFixed(3)},'
        'setpts=PTS-STARTPTS,'
        'scale=$w:$h:force_original_aspect_ratio=decrease,'
        'pad=$w:$h:(ow-iw)/2:(oh-ih)/2,'
        'fps=fps=30,'
        'format=yuv420p',
      );
      if (i > 0) {
        vChain.write(',fade=t=in:st=0:d=${fade.toStringAsFixed(3)}');
      }
      if (i < clips.length - 1) {
        final fadeStart = (dur - fade).clamp(0.0, dur);
        vChain.write(
          ',fade=t=out:st=${fadeStart.toStringAsFixed(3)}:d=${fade.toStringAsFixed(3)}',
        );
      }
      vChain.write('[v$i];');
      filter.write(vChain);

      if (allHaveAudio) {
        final aChain = StringBuffer(
          '[$i:a]'
          'atrim=start=${clip.trimStart.toStringAsFixed(3)}:end=${clip.trimEnd.toStringAsFixed(3)},'
          'asetpts=PTS-STARTPTS,'
          'aresample=44100,'
          'aformat=channel_layouts=stereo',
        );
        if (i > 0) {
          aChain.write(',afade=t=in:st=0:d=${fade.toStringAsFixed(3)}');
        }
        if (i < clips.length - 1) {
          final fadeStart = (dur - fade).clamp(0.0, dur);
          aChain.write(
            ',afade=t=out:st=${fadeStart.toStringAsFixed(3)}:d=${fade.toStringAsFixed(3)}',
          );
        }
        aChain.write('[a$i];');
        filter.write(aChain);
      }
    }

    if (allHaveAudio) {
      for (int i = 0; i < clips.length; i++) {
        filter.write('[v$i][a$i]');
      }
      filter.write('concat=n=${clips.length}:v=1:a=1[vout][aout]');
    } else {
      for (int i = 0; i < clips.length; i++) {
        filter.write('[v$i]');
      }
      filter.write('concat=n=${clips.length}:v=1:a=0[vout]');
    }

    args.addAll(['-filter_complex', filter.toString()]);
    args.addAll(['-map', '[vout]']);
    if (allHaveAudio) {
      args.addAll(['-map', '[aout]', '-c:a', 'aac', '-b:a', '192k']);
    } else {
      args.add('-an');
    }
    args.addAll(['-c:v', 'libx264', '-preset', 'fast', '-crf', '18']);
    args.add(outputPath);

    return args;
  }

  /// Parses FFmpeg stderr "time=HH:MM:SS.ss" into total seconds.
  static double? parseProgressTime(String line) {
    final match = RegExp(r'time=(\d+):(\d+):([\d.]+)').firstMatch(line);
    if (match == null) return null;
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    final s = double.parse(match.group(3)!);
    return h * 3600 + m * 60 + s;
  }
}
