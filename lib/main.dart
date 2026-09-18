import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/network/functions_client.dart';
import 'firebase_options.dart';

/// Set with `--dart-define=USE_EMULATORS=true` to run against the local
/// Firebase Emulator Suite instead of the deployed project.
///
/// This is not a convenience flag. Cloud Functions require the Blaze plan,
/// so on a no-cost account the emulator is the *only* place the backend runs
/// — see the setup guide. Develop here, deploy later.
const bool kUseEmulators = bool.fromEnvironment('USE_EMULATORS');

/// The LAN address of the machine running the emulators. `localhost` is
/// correct for the iOS simulator and Flutter web; a physical phone needs your
/// computer's IP (its own localhost is itself), and the Android emulator
/// needs 10.0.2.2.
const String kEmulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: 'localhost',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kUseEmulators) {
    FunctionsClient.useEmulators(host: kEmulatorHost);
  }

  runApp(const MotirongApp());
}
