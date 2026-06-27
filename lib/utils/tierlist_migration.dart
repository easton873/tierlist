const int currentTierlistVersion = 1;

/// Migrates a raw decoded JSON map from any past version up to [currentTierlistVersion].
/// Add a new case here each time the file format changes.
Map<String, dynamic> migrateTierlistJson(Map<String, dynamic> json) {
  int version = (json['version'] as int?) ?? 0;

  // Each block upgrades from `version` to `version + 1`.
  // Currently only v1 exists, so there are no migrations yet.
  // Example future migration:
  //   if (version == 1) {
  //     // add new field with default
  //     json = Map<String, dynamic>.from(json);
  //     json['newField'] = defaultValue;
  //     version = 2;
  //   }

  if (version != currentTierlistVersion) {
    throw FormatException(
      'Unsupported .tierlist version: $version '
      '(current: $currentTierlistVersion)',
    );
  }

  return json;
}
