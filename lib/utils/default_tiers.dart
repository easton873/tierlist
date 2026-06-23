import 'package:flutter/material.dart';
import '../models/tier_row.dart';

List<TierRow> defaultTiers() {
  return [
    TierRow(id: 'S', label: 'S', labelColor: const Color(0xFFE77584)),
    TierRow(id: 'A', label: 'A', labelColor: const Color(0xFFF7C48B)),
    TierRow(id: 'B', label: 'B', labelColor: const Color(0xFFF8FC8F)),
    TierRow(id: 'C', label: 'C', labelColor: const Color(0xFF92FF8B)),
    TierRow(id: 'D', label: 'D', labelColor: const Color(0xFF8CC6FA)),
    TierRow(id: 'F', label: 'F', labelColor: const Color(0xFFE86AEC)),
  ];
}
