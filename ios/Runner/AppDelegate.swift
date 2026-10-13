import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  // The FlutterEngine is created lazily on first use so that the app's
  // `application(_:didFinishLaunchingWithOptions:)` entrypoint is fully
  // responsible for running it (Flutter 3.47+ no longer auto-runs the
  // engine, which broke cold start when the delegate subclass was used as
  // the app's `@main` entry point).
  private lazy var flutterEngine: FlutterEngine = {
    let engine = FlutterEngine.init(name: "io.flutter")
    engine.run(withEntrypoint: "io.flutter")
    return engine
  }()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register the plugins against the engine's registrar. This is required
    // by Flutter 3.47+ because the engine must be running before plugins
    // register themselves.
    GeneratedPluginRegistrant.register(with: flutterEngine.registrar)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
