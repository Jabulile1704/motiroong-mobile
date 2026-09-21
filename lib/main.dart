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

/// Base URL of a self-hosted backend, e.g.
/// `--dart-define=BACKEND_URL=https://motiroong-backend.onrender.com`.
///
/// The backend's callables are `onCall` handlers, which Cloud Functions will
/// only run on the Blaze plan. `functions/src/server.ts` serves the very same
/// handlers over HTTP so they can live on a free Node host instead. Auth and
/// Firestore stay on the real Firebase project either way — both are free on
/// Spark — so this is the deployed setup, not a development shortcut.
///
/// Ignored when [kUseEmulators] is set, since that points everything local.
const String kBackendUrl = String.fromEnvironment('BACKEND_URL');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kUseEmulators) {
    await FunctionsClient.useEmulators(host: kEmulatorHost);
  } else if (kBackendUrl.isNotEmpty) {
    FunctionsClient.useHttpBackend(Uri.parse(kBackendUrl));
  }

  runApp(const MotirongApp());
}
