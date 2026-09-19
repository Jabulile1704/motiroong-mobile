package com.jabulile.motiroong

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth's fingerprint prompt is an AndroidX BiometricPrompt, which needs
// a FragmentActivity host; a plain FlutterActivity fails at the prompt.
class MainActivity : FlutterFragmentActivity()
