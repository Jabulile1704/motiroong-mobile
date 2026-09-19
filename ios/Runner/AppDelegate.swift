import Flutter
import UIKit

#if DEBUG
  import FirebaseCore
  import FirebaseFunctions
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    #if DEBUG
      registerEmulatorChannel(engineBridge.pluginRegistry)
    #endif
  }

  #if DEBUG
    /// Lets a *debug* build on a physical iPhone reach the Functions emulator
    /// on the Mac's LAN address.
    ///
    /// The Firebase SDK refuses to attach the signed-in user's token to a
    /// plain-HTTP request unless the host is loopback, and a phone's loopback
    /// is the phone. `allowInsecureTokenAttachment` is the SDK's escape hatch
    /// for exactly this case; it exists only in DEBUG builds, so this whole
    /// channel compiles out of release builds and can never weaken one.
    private func registerEmulatorChannel(_ registry: FlutterPluginRegistry) {
      guard let registrar = registry.registrar(forPlugin: "MotiroongEmulator") else { return }
      let channel = FlutterMethodChannel(
        name: "motiroong/emulator",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "allowInsecureFunctionsTokens",
              let region = call.arguments as? String,
              let app = FirebaseApp.app()
        else {
          result(FlutterMethodNotImplemented)
          return
        }
        Functions.functions(app: app, region: region).allowInsecureTokenAttachment = true
        result(true)
      }
    }
  #endif
}
