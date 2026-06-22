import 'package:flutter/material.dart';
import '../models/tier_row.dart';

List<TierRow> defaultTiers() {
  return [
    TierRow(id: 'S', label: 'S', labelColor: const Color(0xFFFF7F7F)),
    TierRow(id: 'A', label: 'A', labelColor: const Color(0xFFFFBF7F)),
    TierRow(id: 'B', label: 'B', labelColor: const Color(0xFFFFDF7F)),
    TierRow(id: 'C', label: 'C', labelColor: const Color(0xFFBFFF7F)),
    TierRow(id: 'D', label: 'D', labelColor: const Color(0xFF7FBFFF)),
    TierRow(id: 'F', label: 'F', labelColor: const Color(0xFFBF7FFF)),
  ];
}
