import Foundation
import Flutter
import libepos2

// MARK: - EpsonPrinterPlugin
//
// iOS mirror of EpsonPrinterHandler.kt.
// Registers on the same MethodChannel ("com.culai.epson_printer") and routes
// all method calls identically.  Sub-handlers (discovery, print) are exact
// Swift transliterations of their Kotlin counterparts.

class EpsonPrinterPlugin: NSObject {

    // MARK: - Properties

    private let channel: FlutterMethodChannel
    private let discoveryHandler: EpsonDiscoveryHandler
    private let printHandler: EpsonPrintHandler

    private let TAG = "EpsonPrinterPlugin"

    // Supported printer list — identical to the Android implementation
    private let supportedPrinters: [[String: String]] = [
        ["name": "TM-M10",              "series": "TM_M10",      "type": "Mobile"],
        ["name": "TM-M30/M30II/M30III", "series": "TM_M30",      "type": "Desktop"],
        ["name": "TM-P60/P60II",        "series": "TM_P60",      "type": "Mobile"],
        ["name": "TM-P80",              "series": "TM_P80",       "type": "Mobile"],
        ["name": "TM-T20",              "series": "TM_T20",       "type": "Desktop"],
        ["name": "TM-T82/T82III",       "series": "TM_T82",       "type": "Desktop"],
        ["name": "TM-T83/T83III",       "series": "TM_T83",       "type": "Desktop"],
        ["name": "TM-T88VI/T88VII",     "series": "TM_T88VII",    "type": "Desktop"],
        ["name": "TM-L90LFC (KDS)",     "series": "TM_L90LFC",    "type": "Kitchen"],
        ["name": "TM-L100 (KDS)",       "series": "TM_L100",      "type": "Kitchen"],
        ["name": "TM-U220",             "series": "TM_U220",      "type": "Impact"],
    ]

    // MARK: - Init

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "com.culai.epson_printer",
                                       binaryMessenger: messenger)
        discoveryHandler = EpsonDiscoveryHandler(channel: channel)
        printHandler     = EpsonPrintHandler(channel: channel)
        super.init()

        // Enable Epson SDK logging (matches Android SDK log init in EpsonPrinterHandler.kt)
        Epos2Log.setLogSettings(
            EPOS2_PERIOD_TEMPORARY.rawValue,
            output: EPOS2_OUTPUT_STORAGE.rawValue,
            ipAddress: nil,
            port: 0,
            logSize: 50,
            logLevel: EPOS2_LOGLEVEL_LOW.rawValue
        )

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call, result: result)
        }
    }

    // MARK: - Method Call Router
    //
    // Mirrors EpsonPrinterHandler.kt handleMethodCall() — same method names,
    // same argument keys, same error codes.

    private func handleMethodCall(_ call: FlutterMethodCall,
                                  result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            // Some calls (getVersion, getSupportedPrinters) have no args — handle below
            handleNoArgCall(call, result: result)
            return
        }

        switch call.method {

        // ── Discovery ──────────────────────────────────────────────────────────
        case "discoverPrinters":
            let portType = args["portType"] as? String ?? "all"
            let timeout  = args["timeout"]  as? Int    ?? 10000
            discoveryHandler.discoverPrinters(portType: portType,
                                               timeout: timeout,
                                               result: result)

        case "stopDiscovery":
            discoveryHandler.stopDiscovery(result: result)

        // ── Connection ─────────────────────────────────────────────────────────
        case "connectPrinter":
            guard let target = args["target"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT",
                                    message: "Target address is required",
                                    details: nil))
                return
            }
            let printerType = args["printerType"] as? String ?? "regular"
            let series      = args["series"]      as? String ?? "TM_M30III"
            let lang        = args["lang"]        as? String ?? "MODEL_ANK"
            printHandler.connectPrinter(target: target,
                                        printerType: printerType,
                                        series: series,
                                        lang: lang,
                                        result: result)

        case "disconnectPrinter":
            let printerType = args["printerType"] as? String ?? "regular"
            printHandler.disconnectPrinter(printerType: printerType, result: result)

        // ── Printing ───────────────────────────────────────────────────────────
        case "printReceipt":
            guard let data = args["data"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT",
                                    message: "Print data is required",
                                    details: nil))
                return
            }
            printHandler.printReceipt(data: data, result: result)

        case "printKDS":
            guard let data = args["data"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT",
                                    message: "Print data is required",
                                    details: nil))
                return
            }
            let jobNumber = args["jobNumber"] as? Int ?? 0
            printHandler.printKDS(data: data, jobNumber: jobNumber, result: result)

        case "printKitchenTicket":
            guard let data = args["data"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT",
                                    message: "Print data is required",
                                    details: nil))
                return
            }
            printHandler.printKitchenTicket(data: data, result: result)

        case "testPrint":
            let printerType = args["printerType"] as? String ?? "regular"
            printHandler.testPrint(printerType: printerType, result: result)

        // ── Status ─────────────────────────────────────────────────────────────
        case "getPrinterStatus":
            let printerType = args["printerType"] as? String ?? "regular"
            printHandler.getPrinterStatus(printerType: printerType, result: result)

        // ── Utility ────────────────────────────────────────────────────────────
        case "getSupportedPrinters":
            result(supportedPrinters)

        case "getVersion":
            result([
                "version":  "2.36.0",
                "platform": "iOS",
                "sdk":      "ePOS SDK for iOS"
            ])

        // Android-only (no-op on iOS — Bluetooth permissions are handled via Info.plist)
        case "requestPermissions":
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Handles calls that arrive without an arguments dictionary
    private func handleNoArgCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getSupportedPrinters":
            result(supportedPrinters)
        case "getVersion":
            result([
                "version":  "2.36.0",
                "platform": "iOS",
                "sdk":      "ePOS SDK for iOS"
            ])
        case "requestPermissions":
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        discoveryHandler.cleanup()
        printHandler.cleanup()
        channel.setMethodCallHandler(nil)
    }
}
