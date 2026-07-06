import Foundation
import Flutter
import libepos2

// MARK: - EpsonDiscoveryHandler
//
// iOS mirror of EpsonDiscoveryHandler.kt.
// Uses the Epos2Discovery API — same semantic interface as the Android Discovery class.
// Discovered printers are forwarded to Flutter via the channel's invokeMethod,
// exactly matching the Android implementation's structure.

class EpsonDiscoveryHandler: NSObject {

    // MARK: - Private state

    private weak var channel: FlutterMethodChannel?
    private var isDiscovering = false
    private var timeoutWorkItem: DispatchWorkItem?
    private let mainQueue = DispatchQueue.main
    private let TAG = "EpsonDiscoveryHandler"

    // MARK: - Init

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    // MARK: - Start Discovery

    func discoverPrinters(portType: String,
                          timeout: Int,
                          result: @escaping FlutterResult) {
        if isDiscovering {
            result(FlutterError(code: "ALREADY_DISCOVERING",
                               message: "Discovery already in progress",
                               details: nil))
            return
        }

        let filterOption = Epos2FilterOption()

        // Port type filter — matches Android portType string mapping
        switch portType.lowercased() {
        case "tcp":
            filterOption.portType = EPOS2_PORTTYPE_TCP.rawValue
        case "bluetooth":
            filterOption.portType = EPOS2_PORTTYPE_BLUETOOTH.rawValue
        case "usb":
            filterOption.portType = EPOS2_PORTTYPE_USB.rawValue
        default:
            filterOption.portType = EPOS2_PORTTYPE_ALL.rawValue
        }

        filterOption.deviceType    = EPOS2_TYPE_PRINTER.rawValue

        let startResult = Epos2Discovery.start(filterOption, delegate: self)
        if startResult != EPOS2_SUCCESS.rawValue {
            result(FlutterError(code: "DISCOVERY_ERROR",
                               message: "Failed to start discovery: \(errorName(startResult))",
                               details: nil))
            return
        }

        isDiscovering = true

        // Auto-stop after timeout (mirrors Android mainHandler.postDelayed)
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.isDiscovering {
                self.stopDiscoveryInternal()
                self.channel?.invokeMethod("onDiscoveryComplete",
                                           arguments: ["status": "completed"])
            }
        }
        timeoutWorkItem = workItem
        mainQueue.asyncAfter(deadline: .now() + .milliseconds(timeout), execute: workItem)

        NSLog("%@: discovery started — portType=%@, timeout=%dms", TAG, portType, timeout)
        result(["status": "started", "portType": portType, "timeout": timeout])
    }

    // MARK: - Stop Discovery

    func stopDiscovery(result: @escaping FlutterResult) {
        if !isDiscovering {
            result(["status": "already_stopped"])
            return
        }
        stopDiscoveryInternal()
        result(["status": "stopped"])
    }

    // MARK: - Internal Stop

    private func stopDiscoveryInternal() {
        let stopResult = Epos2Discovery.stop()
        // ERR_PROCESSING means already stopping — safe to ignore, matches Android behaviour
        if stopResult != EPOS2_SUCCESS.rawValue && stopResult != EPOS2_ERR_PROCESSING.rawValue {
            NSLog("%@: unexpected stop error: %@", TAG, errorName(stopResult))
        }
        isDiscovering = false
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
    }

    // MARK: - Cleanup

    func cleanup() {
        if isDiscovering {
            stopDiscoveryInternal()
        }
    }

    // MARK: - Helpers

    private func errorName(_ code: Int32) -> String {
        switch code {
        case EPOS2_SUCCESS.rawValue:        return "SUCCESS"
        case EPOS2_ERR_PARAM.rawValue:      return "ERR_PARAM"
        case EPOS2_ERR_CONNECT.rawValue:    return "ERR_CONNECT"
        case EPOS2_ERR_TIMEOUT.rawValue:    return "ERR_TIMEOUT"
        case EPOS2_ERR_MEMORY.rawValue:     return "ERR_MEMORY"
        case EPOS2_ERR_ILLEGAL.rawValue:    return "ERR_ILLEGAL"
        case EPOS2_ERR_PROCESSING.rawValue: return "ERR_PROCESSING"
        case EPOS2_ERR_NOT_FOUND.rawValue:  return "ERR_NOT_FOUND"
        case EPOS2_ERR_IN_USE.rawValue:     return "ERR_IN_USE"
        case EPOS2_ERR_FAILURE.rawValue:    return "ERR_FAILURE"
        default:                            return "UNKNOWN_\(code)"
        }
    }

    private func deviceTypeName(_ type: Int32) -> String {
        switch type {
        case EPOS2_TYPE_PRINTER.rawValue:        return "Printer"
        case EPOS2_TYPE_HYBRID_PRINTER.rawValue: return "Hybrid Printer"
        case EPOS2_TYPE_DISPLAY.rawValue:        return "Display"
        case EPOS2_TYPE_KEYBOARD.rawValue:       return "Keyboard"
        case EPOS2_TYPE_SCANNER.rawValue:        return "Scanner"
        case EPOS2_TYPE_SERIAL.rawValue:         return "Serial Device"
        default:                                 return "Unknown"
        }
    }
}

// MARK: - Epos2DiscoveryDelegate

extension EpsonDiscoveryHandler: Epos2DiscoveryDelegate {
    func onDiscovery(_ deviceInfo: Epos2DeviceInfo!) {
        guard let info = deviceInfo else { return }

        let printerData: [String: Any] = [
            "deviceName":    info.deviceName ?? "",
            "ipAddress":     info.ipAddress ?? "",
            "macAddress":    info.macAddress ?? "",
            "bdAddress":     info.bdAddress ?? "",
            "target":        info.target ?? "",
            "deviceType":    deviceTypeName(info.deviceType),
            "printerSeries": info.deviceName ?? "Unknown"
        ]

        NSLog("%@: discovered: %@ at %@", TAG, info.deviceName ?? "?", info.target ?? "?")

        mainQueue.async { [weak self] in
            self?.channel?.invokeMethod("onPrinterDiscovered", arguments: printerData)
        }
    }
}
