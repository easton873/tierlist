import 'package:flutter_riverpod/flutter_riverpod.dart';

class LayoutSettings {
  static LayoutSettings fromJson(Map<String, dynamic> json) {
    // Older save files only have a single 'poolPadding' value; fall back to
    // it for any per-side value that isn't present.
    final legacyPoolPadding = (json['poolPadding'] as num?)?.toDouble() ?? 16.0;
    return LayoutSettings(
      boardTopPad: (json['boardTopPad'] as num).toDouble(),
      boardBottomPad: (json['boardBottomPad'] as num).toDouble(),
      boardLeftPad: (json['boardLeftPad'] as num).toDouble(),
      rowGap: (json['rowGap'] as num).toDouble(),
      labelGap: (json['labelGap'] as num).toDouble(),
      poolPaddingLeft: (json['poolPaddingLeft'] as num?)?.toDouble() ?? 4.0,
      poolPaddingTop: (json['poolPaddingTop'] as num?)?.toDouble() ?? legacyPoolPadding,
      poolPaddingRight: (json['poolPaddingRight'] as num?)?.toDouble() ?? legacyPoolPadding,
      poolPaddingBottom: (json['poolPaddingBottom'] as num?)?.toDouble() ?? legacyPoolPadding,
      defaultRowHeight: json['defaultRowHeight'] != null
          ? (json['defaultRowHeight'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'boardTopPad': boardTopPad,
        'boardBottomPad': boardBottomPad,
        'boardLeftPad': boardLeftPad,
        'rowGap': rowGap,
        'labelGap': labelGap,
        'poolPaddingLeft': poolPaddingLeft,
        'poolPaddingTop': poolPaddingTop,
        'poolPaddingRight': poolPaddingRight,
        'poolPaddingBottom': poolPaddingBottom,
        if (defaultRowHeight != null) 'defaultRowHeight': defaultRowHeight,
      };
  final double boardTopPad;
  final double boardBottomPad;
  final double boardLeftPad;
  final double rowGap;
  final double labelGap;
  final double poolPaddingLeft;
  final double poolPaddingTop;
  final double poolPaddingRight;
  final double poolPaddingBottom;
  // null = auto (viewport / 6); non-null = fixed px for all non-custom rows
  final double? defaultRowHeight;

  const LayoutSettings({
    this.boardTopPad = 50.0,
    this.boardBottomPad = 50.0,
    this.boardLeftPad = 50.0,
    this.rowGap = 32.0,
    this.labelGap = 32.0,
    this.poolPaddingLeft = 4.0,
    this.poolPaddingTop = 16.0,
    this.poolPaddingRight = 16.0,
    this.poolPaddingBottom = 16.0,
    this.defaultRowHeight,
  });

  LayoutSettings copyWith({
    double? boardTopPad,
    double? boardBottomPad,
    double? boardLeftPad,
    double? rowGap,
    double? labelGap,
    double? poolPaddingLeft,
    double? poolPaddingTop,
    double? poolPaddingRight,
    double? poolPaddingBottom,
    double? defaultRowHeight,
    bool clearDefaultRowHeight = false,
  }) {
    return LayoutSettings(
      boardTopPad: boardTopPad ?? this.boardTopPad,
      boardBottomPad: boardBottomPad ?? this.boardBottomPad,
      boardLeftPad: boardLeftPad ?? this.boardLeftPad,
      rowGap: rowGap ?? this.rowGap,
      labelGap: labelGap ?? this.labelGap,
      poolPaddingLeft: poolPaddingLeft ?? this.poolPaddingLeft,
      poolPaddingTop: poolPaddingTop ?? this.poolPaddingTop,
      poolPaddingRight: poolPaddingRight ?? this.poolPaddingRight,
      poolPaddingBottom: poolPaddingBottom ?? this.poolPaddingBottom,
      defaultRowHeight:
          clearDefaultRowHeight ? null : (defaultRowHeight ?? this.defaultRowHeight),
    );
  }
}

class LayoutSettingsNotifier extends StateNotifier<LayoutSettings> {
  LayoutSettingsNotifier() : super(const LayoutSettings());

  void update(LayoutSettings Function(LayoutSettings) updater) {
    state = updater(state);
  }

  void resetToDefaults() {
    state = const LayoutSettings();
  }

  void loadFromFile(LayoutSettings settings) {
    state = settings;
  }
}

final layoutSettingsProvider =
    StateNotifierProvider<LayoutSettingsNotifier, LayoutSettings>(
      (ref) => LayoutSettingsNotifier(),
    );
