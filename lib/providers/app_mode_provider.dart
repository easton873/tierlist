import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_mode.dart';

final appModeProvider = StateProvider<AppMode>((ref) => AppMode.edit);
