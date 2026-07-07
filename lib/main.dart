import 'package:flutter/material.dart';

import 'app.dart';

/// App entry point — kept intentionally thin. All app-level setup
/// (MaterialApp, theme, routing) lives in `app.dart` so main.dart doesn't
/// balloon as the project grows.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: initialize anything that must be ready before the first frame:
  // - secure storage (flutter_secure_storage) for the refresh token
  // - local offline-queue database (Drift/Hive)
  // - crash/analytics reporting
  // These belong in core/services and should be awaited here once built,
  // e.g.: await OfflineQueueService.init();

  runApp(const MoTirong());
}
