import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  // Retain the plugin for the app lifetime.
  // EpsonPrinterPlugin owns the MethodChannel — it must not be released.
  private var epsonPrinterPlugin: EpsonPrinterPlugin?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register Epson printer MethodChannel bridge.
    // This is the iOS equivalent of the EpsonPrinterHandler registered in MainActivity.kt.
    if let controller = window?.rootViewController as? FlutterViewController {
      epsonPrinterPlugin = EpsonPrinterPlugin(messenger: controller.binaryMessenger)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    epsonPrinterPlugin?.cleanup()
  }
}
