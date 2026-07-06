import Foundation
import Flutter
import libepos2

// MARK: - EpsonPrintHandler
//
// iOS mirror of the Android EpsonPrintHandler.kt.
// Architecture is identical: same MethodChannel methods, same receipt layout,
// same auto-reconnect-on-second-print logic, same clearCommandBuffer
// usage to prevent double printing.
//
// All heavy work runs on a background DispatchQueue so the main thread is
// never blocked. All MethodChannel.Result callbacks are dispatched back to
// DispatchQueue.main, which is the iOS equivalent of Android's mainHandler.post{}.

class EpsonPrintHandler: NSObject {

    // MARK: - Private state

    private var regularPrinter: Epos2Printer?
    private var kdsPrinter: Epos2LFCPrinter?

    // Persisted connection parameters for transparent auto-reconnect.
    // Epson printer firmware closes the TCP connection after every completed
    // print job — identical behaviour to Android.
    private var lastRegularTarget: String?
    private var lastRegularSeries: String?
    private var lastRegularLang: String?

    // KDS connection params — same auto-reconnect mechanism as regular printer
    private var lastKDSTarget: String?
    private var lastKDSSeries: String?
    private var lastKDSLang: String?

    private let channel: FlutterMethodChannel
    private let printQueue = DispatchQueue(label: "com.culai.epson.print", qos: .userInitiated)

    private let TAG = "EpsonPrintHandler"

    // MARK: - Init

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    // MARK: - Connect

    func connectPrinter(target: String,
                        printerType: String,
                        series: String,
                        lang: String,
                        result: @escaping FlutterResult) {
        printQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                if printerType.lowercased() == "kds" {
                    try self.connectKDSPrinter(target: target, series: series, lang: lang, result: result)
                } else {
                    try self.connectRegularPrinter(target: target, series: series, lang: lang, result: result)
                }
            } catch {
                NSLog("%@: connectPrinter failed: %@", self.TAG, error.localizedDescription)
                DispatchQueue.main.async {
                    result(FlutterError(code: "CONNECTION_ERROR",
                                       message: error.localizedDescription,
                                       details: nil))
                }
            }
        }
    }

    private func connectRegularPrinter(target: String,
                                       series: String,
                                       lang: String,
                                       result: @escaping FlutterResult) throws {
        NSLog("%@: starting regular printer connection: target=%@, series=%@, lang=%@", TAG, target, series, lang)

        // Clean up any existing connection
        if regularPrinter != nil {
            NSLog("%@: existing connection found, disconnecting", TAG)
            disconnectRegularPrinterInternal()
        }

        let printerSeries = getPrinterSeries(series)
        let langModel = getLanguageModel(lang)
        let printer = Epos2Printer(printerSeries: printerSeries, lang: langModel)
        printer?.setReceiveEventDelegate(self)

        let normalizedTarget = normalizeTarget(target)
        NSLog("%@: normalized target: %@ -> %@", TAG, target, normalizedTarget)

        // Persist connection params BEFORE connecting so auto-reconnect in
        // printReceipt / printKitchenTicket has a valid target even when this
        // initial connection attempt fails (e.g. printer offline at app start).
        // Updated again below with the actual connected target.
        self.lastRegularTarget = normalizedTarget
        self.lastRegularSeries = series
        self.lastRegularLang = lang

        var connectedTarget = normalizedTarget
        let connectResult = printer?.connect(normalizedTarget, timeout: Int(EPOS2_PARAM_DEFAULT))
        if connectResult != EPOS2_SUCCESS.rawValue {
            // Retry with raw target if normalization changed anything
            if normalizedTarget != target {
                NSLog("%@: normalized target failed (%d), retrying with raw: %@", TAG, connectResult ?? -1, target)
                let retryResult = printer?.connect(target, timeout: Int(EPOS2_PARAM_DEFAULT))
                if retryResult != EPOS2_SUCCESS.rawValue {
                    let errMsg = "Connection failed. Epson error: \(errorName(retryResult ?? -1)) (series=\(series))"
                    NSLog("%@: %@", TAG, errMsg)
                    DispatchQueue.main.async {
                        result(FlutterError(code: "CONNECTION_ERROR", message: errMsg, details: nil))
                    }
                    return
                }
                connectedTarget = target
            } else {
                let errMsg = "Connection failed. Epson error: \(errorName(connectResult ?? -1)) (series=\(series))"
                NSLog("%@: %@", TAG, errMsg)
                DispatchQueue.main.async {
                    result(FlutterError(code: "CONNECTION_ERROR", message: errMsg, details: nil))
                }
                return
            }
        }

        self.regularPrinter = printer
        // Update with actual connected target (may differ from normalized)
        self.lastRegularTarget = connectedTarget

        NSLog("%@: regular printer connected: %@", TAG, connectedTarget)
        DispatchQueue.main.async {
            result([
                "status": "connected",
                "printerType": "regular",
                "target": connectedTarget,
                "series": series
            ])
        }
    }

    private func connectKDSPrinter(target: String,
                                   series: String,
                                   lang: String,
                                   result: @escaping FlutterResult) throws {
        if kdsPrinter != nil {
            disconnectKDSPrinterInternal()
        }

        let printerSeries = getLFCPrinterSeries(series)
        let langModel = getLanguageModel(lang)
        let printer = Epos2LFCPrinter(printerSeries: printerSeries, lang: langModel)
        printer?.setSendCompleteEventDelegate(self)

        let normalizedTarget = normalizeTarget(target)
        var connectedTarget = normalizedTarget

        let connectResult = printer?.connect(normalizedTarget, timeout: Int(EPOS2_PARAM_DEFAULT))
        if connectResult != EPOS2_SUCCESS.rawValue {
            if normalizedTarget != target {
                NSLog("%@: KDS normalized target failed (%d), retrying raw: %@", TAG, connectResult ?? -1, target)
                let retryResult = printer?.connect(target, timeout: Int(EPOS2_PARAM_DEFAULT))
                if retryResult != EPOS2_SUCCESS.rawValue {
                    let errMsg = "KDS connection failed. Epson error: \(errorName(retryResult ?? -1))"
                    DispatchQueue.main.async {
                        result(FlutterError(code: "CONNECTION_ERROR", message: errMsg, details: nil))
                    }
                    return
                }
                connectedTarget = target
            } else {
                let errMsg = "KDS connection failed. Epson error: \(errorName(connectResult ?? -1))"
                DispatchQueue.main.async {
                    result(FlutterError(code: "CONNECTION_ERROR", message: errMsg, details: nil))
                }
                return
            }
        }

        self.kdsPrinter = printer
        self.lastKDSTarget = connectedTarget
        self.lastKDSSeries = series
        self.lastKDSLang = lang
        NSLog("%@: KDS printer connected: %@", TAG, connectedTarget)
        DispatchQueue.main.async {
            result([
                "status": "connected",
                "printerType": "kds",
                "target": connectedTarget,
                "series": series
            ])
        }
    }

    // MARK: - Disconnect

    func disconnectPrinter(printerType: String, result: @escaping FlutterResult) {
        printQueue.async { [weak self] in
            guard let self = self else { return }
            if printerType.lowercased() == "kds" {
                self.disconnectKDSPrinterInternal()
                DispatchQueue.main.async {
                    result(["status": "disconnected", "printerType": "kds"])
                }
            } else {
                self.disconnectRegularPrinterInternal()
                DispatchQueue.main.async {
                    result(["status": "disconnected", "printerType": "regular"])
                }
            }
        }
    }

    private func disconnectRegularPrinterInternal() {
        guard let printer = regularPrinter else { return }
        printer.setReceiveEventDelegate(nil)
        // Epson-recommended: retry disconnect while ERR_PROCESSING
        while true {
            let disconnectResult = printer.disconnect()
            if disconnectResult == EPOS2_SUCCESS.rawValue {
                break
            } else if disconnectResult == EPOS2_ERR_PROCESSING.rawValue {
                NSLog("%@: disconnect ERR_PROCESSING — retrying in 500ms", TAG)
                Thread.sleep(forTimeInterval: 0.5)
            } else {
                NSLog("%@: disconnect error %d, breaking", TAG, disconnectResult)
                break
            }
        }
        printer.clearCommandBuffer()
        regularPrinter = nil
        NSLog("%@: regular printer disconnected", TAG)
    }

    private func disconnectKDSPrinterInternal() {
        guard let printer = kdsPrinter else { return }
        printer.setSendCompleteEventDelegate(nil)
        // Epson-recommended: retry disconnect while ERR_PROCESSING
        while true {
            let disconnectResult = printer.disconnect()
            if disconnectResult == EPOS2_SUCCESS.rawValue {
                break
            } else if disconnectResult == EPOS2_ERR_PROCESSING.rawValue {
                NSLog("%@: KDS disconnect ERR_PROCESSING — retrying in 500ms", TAG)
                Thread.sleep(forTimeInterval: 0.5)
            } else {
                NSLog("%@: KDS disconnect error %d, breaking", TAG, disconnectResult)
                break
            }
        }
        printer.clearCommandBuffer()
        kdsPrinter = nil
        NSLog("%@: KDS printer disconnected", TAG)
    }

    // MARK: - Print Receipt

    func printReceipt(data: [String: Any], result: @escaping FlutterResult) {
        printQueue.async { [weak self] in
            guard let self = self else { return }

            // ── Bug 2 equivalent (iOS): auto-reconnect if printer TCP was closed ──
            if self.regularPrinter == nil, let lastTarget = self.lastRegularTarget {
                NSLog("%@: auto-reconnecting to %@", self.TAG, lastTarget)
                let printerSeries = self.getPrinterSeries(self.lastRegularSeries ?? "TM_M30")
                let langModel = self.getLanguageModel(self.lastRegularLang ?? "MODEL_ANK")
                let printer = Epos2Printer(printerSeries: printerSeries, lang: langModel)
                printer?.setReceiveEventDelegate(self)
                let normTarget = self.normalizeTarget(lastTarget)
                var reconnected = false
                if printer?.connect(normTarget, timeout: Int(EPOS2_PARAM_DEFAULT)) == EPOS2_SUCCESS.rawValue {
                    reconnected = true
                } else if normTarget != lastTarget,
                          printer?.connect(lastTarget, timeout: Int(EPOS2_PARAM_DEFAULT)) == EPOS2_SUCCESS.rawValue {
                    reconnected = true
                }
                if reconnected {
                    self.regularPrinter = printer
                    NSLog("%@: auto-reconnect succeeded", self.TAG)
                } else {
                    NSLog("%@: auto-reconnect failed", self.TAG)
                }
            }

            guard self.regularPrinter != nil else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "NOT_CONNECTED",
                                       message: "Regular printer not connected",
                                       details: nil))
                }
                return
            }

            // Bug 1 fix: clearCommandBuffer is called inside buildReceiptData
            do {
                try self.buildReceiptData(data: data)
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "PRINT_ERROR",
                                       message: "Build receipt failed: \(error.localizedDescription)",
                                       details: nil))
                }
                return
            }

            // Send with one auto-reconnect retry on ERR_DISCONNECT/ERR_CONNECT/ERR_PROCESSING
            var sendResult = self.regularPrinter?.sendData(Int(EPOS2_PARAM_DEFAULT))
            if (sendResult == EPOS2_ERR_DISCONNECT.rawValue || sendResult == EPOS2_ERR_CONNECT.rawValue || sendResult == EPOS2_ERR_PROCESSING.rawValue),
               let lastTarget = self.lastRegularTarget {
                NSLog("%@: sendData failed (%d) — reconnecting and retrying", self.TAG, sendResult ?? -1)
                self.disconnectRegularPrinterInternal()
                Thread.sleep(forTimeInterval: 0.3)
                let printerSeries = self.getPrinterSeries(self.lastRegularSeries ?? "TM_M30")
                let langModel = self.getLanguageModel(self.lastRegularLang ?? "MODEL_ANK")
                let printer = Epos2Printer(printerSeries: printerSeries, lang: langModel)
                printer?.setReceiveEventDelegate(self)
                let normTarget = self.normalizeTarget(lastTarget)
                var reconnectResult: Int32 = Int32(printer?.connect(normTarget, timeout: Int(EPOS2_PARAM_DEFAULT)) ?? EPOS2_ERR_CONNECT.rawValue)
                if reconnectResult != Int32(EPOS2_SUCCESS.rawValue), normTarget != lastTarget {
                    reconnectResult = Int32(printer?.connect(lastTarget, timeout: Int(EPOS2_PARAM_DEFAULT)) ?? EPOS2_ERR_CONNECT.rawValue)
                }
                if reconnectResult == Int32(EPOS2_SUCCESS.rawValue) {
                    self.regularPrinter = printer
                    // Rebuild after buffer was cleared in disconnect
                    do {
                        try self.buildReceiptData(data: data)
                    } catch {
                        DispatchQueue.main.async {
                            result(FlutterError(code: "PRINT_ERROR",
                                               message: "Rebuild after reconnect failed: \(error.localizedDescription)",
                                               details: nil))
                        }
                        return
                    }
                    sendResult = self.regularPrinter?.sendData(Int(EPOS2_PARAM_DEFAULT))
                } else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "PRINT_ERROR",
                                           message: "Reconnect retry failed after ERR_DISCONNECT",
                                           details: nil))
                    }
                    return
                }
            }

            if sendResult != EPOS2_SUCCESS.rawValue {
                self.regularPrinter?.clearCommandBuffer()
                DispatchQueue.main.async {
                    result(FlutterError(code: "PRINT_ERROR",
                                       message: "sendData failed: \(self.errorName(sendResult ?? -1))",
                                       details: nil))
                }
                return
            }

            NSLog("%@: receipt sent — disconnecting (Epson recommended pattern)", self.TAG)

            // Disconnect after every successful print (matching Android pattern).
            // The printer completes the job from its internal buffer even after
            // TCP disconnect.  A fresh reconnect for the next job eliminates
            // stale TCP connections and ERR_PROCESSING carry-over.
            self.regularPrinter?.setReceiveEventDelegate(nil)
            self.disconnectRegularPrinterInternal()

            // Manually notify Flutter of print success since the delegate
            // won't fire after disconnect.
            DispatchQueue.main.async {
                self.channel.invokeMethod("onPrintComplete", arguments: [
                    "success": true,
                    "printerType": "regular",
                    "message": "Print completed successfully"
                ])
            }
            DispatchQueue.main.async {
                result(["status": "printed"])
            }
        }
    }

    // MARK: - Print KDS

    func printKDS(data: [String: Any], jobNumber: Int, result: @escaping FlutterResult) {
        printQueue.async { [weak self] in
            guard let self = self else { return }

            // Auto-reconnect if KDS printer TCP was closed by firmware after previous print
            if self.kdsPrinter == nil, let lastTarget = self.lastKDSTarget {
                NSLog("%@: KDS auto-reconnecting to %@", self.TAG, lastTarget)
                let printerSeries = self.getLFCPrinterSeries(self.lastKDSSeries ?? "TM_L100")
                let langModel = self.getLanguageModel(self.lastKDSLang ?? "MODEL_ANK")
                let printer = Epos2LFCPrinter(printerSeries: printerSeries, lang: langModel)
                printer?.setSendCompleteEventDelegate(self)
                let normTarget = self.normalizeTarget(lastTarget)
                var reconnected = false
                if printer?.connect(normTarget, timeout: Int(EPOS2_PARAM_DEFAULT)) == EPOS2_SUCCESS.rawValue {
                    reconnected = true
                } else if normTarget != lastTarget,
                          printer?.connect(lastTarget, timeout: Int(EPOS2_PARAM_DEFAULT)) == EPOS2_SUCCESS.rawValue {
                    reconnected = true
                }
                if reconnected {
                    self.kdsPrinter = printer
                    NSLog("%@: KDS auto-reconnect succeeded", self.TAG)
                } else {
                    NSLog("%@: KDS auto-reconnect failed", self.TAG)
                }
            }

            guard self.kdsPrinter != nil else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "NOT_CONNECTED",
                                       message: "KDS printer not connected",
                                       details: nil))
                }
                return
            }

            do {
                try self.buildKDSData(data: data)
            } catch {
                self.kdsPrinter?.clearCommandBuffer()
                DispatchQueue.main.async {
                    result(FlutterError(code: "PRINT_ERROR",
                                       message: "Build KDS failed: \(error.localizedDescription)",
                                       details: nil))
                }
                return
            }

            // Send with one auto-reconnect retry on ERR_DISCONNECT/ERR_CONNECT/ERR_PROCESSING
            var sendResult = self.kdsPrinter?.sendLFCData(Int(EPOS2_PARAM_DEFAULT), jobNumber: jobNumber)
            if (sendResult == EPOS2_ERR_DISCONNECT.rawValue || sendResult == EPOS2_ERR_CONNECT.rawValue || sendResult == EPOS2_ERR_PROCESSING.rawValue),
               let lastTarget = self.lastKDSTarget {
                NSLog("%@: KDS sendLFCData failed (%d) — reconnecting and retrying", self.TAG, sendResult ?? -1)
                self.disconnectKDSPrinterInternal()
                Thread.sleep(forTimeInterval: 0.3)
                let printerSeries = self.getLFCPrinterSeries(self.lastKDSSeries ?? "TM_L100")
                let langModel = self.getLanguageModel(self.lastKDSLang ?? "MODEL_ANK")
                let printer = Epos2LFCPrinter(printerSeries: printerSeries, lang: langModel)
                printer?.setSendCompleteEventDelegate(self)
                let normTarget = self.normalizeTarget(lastTarget)
                var reconnectResult: Int32 = Int32(printer?.connect(normTarget, timeout: Int(EPOS2_PARAM_DEFAULT)) ?? EPOS2_ERR_CONNECT.rawValue)
                if reconnectResult != Int32(EPOS2_SUCCESS.rawValue), normTarget != lastTarget {
                    reconnectResult = Int32(printer?.connect(lastTarget, timeout: Int(EPOS2_PARAM_DEFAULT)) ?? EPOS2_ERR_CONNECT.rawValue)
                }
                if reconnectResult == Int32(EPOS2_SUCCESS.rawValue) {
                    self.kdsPrinter = printer
                    do {
                        try self.buildKDSData(data: data)
                    } catch {
                        DispatchQueue.main.async {
                            result(FlutterError(code: "PRINT_ERROR",
                                               message: "Rebuild KDS after reconnect failed: \(error.localizedDescription)",
                                               details: nil))
                        }
                        return
                    }
                    sendResult = self.kdsPrinter?.sendLFCData(Int(EPOS2_PARAM_DEFAULT), jobNumber: jobNumber)
                } else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "PRINT_ERROR",
                                           message: "KDS reconnect retry failed after ERR_DISCONNECT",
                                           details: nil))
                    }
                    return
                }
            }

            if sendResult != EPOS2_SUCCESS.rawValue {
                self.kdsPrinter?.clearCommandBuffer()
                DispatchQueue.main.async {
                    result(FlutterError(code: "PRINT_ERROR",
                                       message: "KDS sendData failed: \(self.errorName(sendResult ?? -1))",
                                       details: nil))
                }
                return
            }

            NSLog("%@: KDS order sent: Job #%d — disconnecting (Epson recommended pattern)", self.TAG, jobNumber)

            // Disconnect after every successful print (matching Android pattern).
            self.kdsPrinter?.setSendCompleteEventDelegate(nil)
            self.disconnectKDSPrinterInternal()

            DispatchQueue.main.async {
                self.channel.invokeMethod("onPrintComplete", arguments: [
                    "success": true,
                    "printerType": "kds",
                    "message": "KDS order sent successfully",
                    "jobNumber": jobNumber
                ])
            }
            DispatchQueue.main.async {
                result(["status": "printed"])
            }
        }
    }

    // MARK: - Test Print

    func testPrint(printerType: String, result: @escaping FlutterResult) {
        printQueue.async { [weak self] in
            guard let self = self else { return }
            if printerType.lowercased() == "kds" {
                self.testPrintKDS(result: result)
            } else {
                self.testPrintRegular(result: result)
            }
        }
    }

    private func testPrintRegular(result: @escaping FlutterResult) {
        guard let printer = regularPrinter else {
            DispatchQueue.main.async {
                result(FlutterError(code: "NOT_CONNECTED", message: "Regular printer not connected", details: nil))
            }
            return
        }
        // Bug 1 fix: clear buffer before building test job
        printer.clearCommandBuffer()
        printer.addTextLang(EPOS2_LANG_EN.rawValue)
        printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
        printer.addTextSize(2, height: 2)
        printer.addText("TEST PRINT\n")
        printer.addTextSize(1, height: 1)
        printer.addText("\(String(repeating: "-", count: 42))\n")
        printer.addText("Epson Printer\n")
        printer.addText("Connection Successful\n")
        printer.addText("\(String(repeating: "-", count: 42))\n")
        printer.addFeedLine(2)
        printer.addText("\(Date())\n")
        printer.addFeedLine(2)
        printer.addCut(EPOS2_CUT_FEED.rawValue)

        let sendResult = printer.sendData(Int(EPOS2_PARAM_DEFAULT))
        if sendResult != EPOS2_SUCCESS.rawValue {
            printer.clearCommandBuffer()
            DispatchQueue.main.async {
                result(FlutterError(code: "TEST_PRINT_ERROR",
                                   message: "Test print failed: \(self.errorName(sendResult))",
                                   details: nil))
            }
            return
        }
        NSLog("%@: Test print sent (regular)", TAG)
        DispatchQueue.main.async { result(["status": "queued"]) }
    }

    private func testPrintKDS(result: @escaping FlutterResult) {
        guard let printer = kdsPrinter else {
            DispatchQueue.main.async {
                result(FlutterError(code: "NOT_CONNECTED", message: "KDS printer not connected", details: nil))
            }
            return
        }
        // Bug 1 fix: clear buffer before test job
        printer.clearCommandBuffer()
        printer.addTextLang(EPOS2_LANG_EN.rawValue)
        printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
        printer.addTextSize(2, height: 2)
        printer.addText("KDS TEST\n")
        printer.addTextSize(1, height: 1)
        printer.addText("\(String(repeating: "-", count: 30))\n")
        printer.addText("Kitchen Display System\n")
        printer.addText("Connection Successful\n")
        printer.addText("\(String(repeating: "-", count: 30))\n")
        printer.addFeedLine(2)
        printer.addText("\(Date())\n")
        printer.addFeedLine(2)
        printer.addCut(EPOS2_CUT_FEED.rawValue)

        let sendResult = printer.sendLFCData(Int(EPOS2_PARAM_DEFAULT), jobNumber: 9999)
        if sendResult != EPOS2_SUCCESS.rawValue {
            printer.clearCommandBuffer()
            DispatchQueue.main.async {
                result(FlutterError(code: "TEST_PRINT_ERROR",
                                   message: "KDS test print failed: \(self.errorName(sendResult))",
                                   details: nil))
            }
            return
        }
        NSLog("%@: Test print sent (KDS)", TAG)
        DispatchQueue.main.async { result(["status": "queued"]) }
    }

    // MARK: - Printer Status

    func getPrinterStatus(printerType: String, result: @escaping FlutterResult) {
        printQueue.async { [weak self] in
            guard let self = self else { return }
            if printerType.lowercased() == "kds" {
                guard let printer = self.kdsPrinter else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "NOT_CONNECTED", message: "KDS printer not connected", details: nil))
                    }
                    return
                }
                let status = printer.getStatus()
                DispatchQueue.main.async {
                    result([
                        "printerType": "kds",
                        "connection": status?.connection ?? -1,
                        "online": status?.online ?? -1,
                        "coverOpen": status?.coverOpen ?? -1,
                        "paper": status?.paper ?? -1,
                        "paperFeed": status?.paperFeed ?? -1,
                        "errorStatus": status?.errorStatus ?? -1
                    ])
                }
            } else {
                guard let printer = self.regularPrinter else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "NOT_CONNECTED", message: "Regular printer not connected", details: nil))
                    }
                    return
                }
                let status = printer.getStatus()
                DispatchQueue.main.async {
                    result([
                        "printerType": "regular",
                        "connection": status?.connection ?? -1,
                        "online": status?.online ?? -1,
                        "coverOpen": status?.coverOpen ?? -1,
                        "paper": status?.paper ?? -1,
                        "paperFeed": status?.paperFeed ?? -1,
                        "errorStatus": status?.errorStatus ?? -1
                    ])
                }
            }
        }
    }

    // MARK: - Build Receipt Data
    //
    // Mirrors buildReceiptData() in EpsonPrintHandler.kt exactly.
    // clearCommandBuffer() is called FIRST to prevent double-printing (Bug 1 fix).

    private func buildReceiptData(data: [String: Any]) throws {
        guard let printer = regularPrinter else { return }

        // Bug 1 fix: clear stale commands before building new job
        printer.clearCommandBuffer()
        printer.addTextLang(EPOS2_LANG_EN.rawValue)

        let INNER_WIDTH = 46
        let LINE = " " + String(repeating: "-", count: INNER_WIDTH) + " "
        let DOUBLE_LINE = " " + String(repeating: "=", count: INNER_WIDTH) + " "

        let formatAmount = { (value: Double) -> String in
            let safeValue = value.isFinite ? value : 0.0
            return String(format: "%.2f", safeValue)
        }

        let receiptMoney = { (value: Double) -> String in
            let safeValue = value.isFinite ? value : 0.0
            return String(format: "SAR %.2f", safeValue)
        }

        let receiptSignedMoney = { (value: Double) -> String in
            let safeValue = value.isFinite ? value : 0.0
            return String(format: "%@SAR %.2f", safeValue < 0 ? "-" : "", abs(safeValue))
        }

        let receiptLine = { (label: String, amount: String) -> String in
            let spaces = INNER_WIDTH - label.count - amount.count
            if spaces >= 1 {
                return " \(label)\(String(repeating: " ", count: spaces))\(amount) \n"
            } else {
                return " \(label)\n \(String(repeating: " ", count: max(0, INNER_WIDTH - amount.count)))\(amount) \n"
            }
        }

        let receiptAmountLine = { (label: String, value: Double) -> String in
            return receiptLine(label, receiptMoney(value))
        }

        // Logo image (org logo, printed centered before store name)
        if let logoBase64 = data["logoBase64"] as? String, !logoBase64.isEmpty,
           let logoData = Data(base64Encoded: logoBase64),
           let logoImage = UIImage(data: logoData),
           logoImage.size.width > 0 {
            // Scale logo to fit within 384×120 (matches web: aspect-ratio preserved, max 120px tall)
            let maxLogoW: CGFloat = 384
            let maxLogoH: CGFloat = 120
            let logoScaleRatio = min(maxLogoW / logoImage.size.width, maxLogoH / logoImage.size.height)
            let scaledLogoW = max(1.0, logoImage.size.width * logoScaleRatio)
            let scaledLogoH = max(1.0, logoImage.size.height * logoScaleRatio)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: scaledLogoW, height: scaledLogoH))
            let scaledImage = renderer.image { _ in
                logoImage.draw(in: CGRect(x: 0, y: 0, width: scaledLogoW, height: scaledLogoH))
            }
            printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
            printer.add(
                scaledImage,
                x: 0, y: 0,
                width: Int(scaledLogoW), height: Int(scaledLogoH),
                color: EPOS2_COLOR_1.rawValue,
                mode: EPOS2_MODE_MONO.rawValue,
                halftone: EPOS2_HALFTONE_DITHER.rawValue,
                brightness: Double(EPOS2_PARAM_DEFAULT),
                compress: EPOS2_COMPRESS_AUTO.rawValue
            )
            printer.addFeedLine(1)
        }

        // Store/Brand name
        let storeName = data["storeName"] as? String ?? "THE STORE"
        printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
        printer.addTextSize(2, height: 2)
        printer.addText("\(storeName)\n")
        printer.addTextSize(1, height: 1)
        printer.addText("\(LINE)\n")

        // VAT, branch, address
        let vatNumber = data["vatNumber"] as? String
        let branchName = data["branchName"] as? String
        let storeAddress = data["storeAddress"] as? String

        printer.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
        if let vat = vatNumber, !vat.isEmpty { printer.addText(" VAT: \(vat)\n") }
        if let branch = branchName, !branch.isEmpty { printer.addText(" BRANCH: \(branch)\n") }
        if let address = storeAddress, !address.isEmpty { printer.addText(" ADDRESS: \(address)\n") }

        printer.addText("\(LINE)\n")
        printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
        printer.addText("SIMPLIFIED TAX INVOICE\n")
        printer.addText("\(LINE)\n")

        // Order info
        printer.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
        let orderNumber = data["orderNumber"] as? String ?? "N/A"
        let invoiceNumber = data["invoiceNumber"] as? String ?? ""

        var orderLine = "ORDER #\(orderNumber)"
        if !invoiceNumber.isEmpty {
            let spaces = INNER_WIDTH - orderLine.count - "INVOICE #\(invoiceNumber)".count
            if spaces > 0 {
                orderLine += String(repeating: " ", count: spaces) + "INVOICE #\(invoiceNumber)"
            } else {
                orderLine += "  INVOICE #\(invoiceNumber)"
            }
        }
        printer.addText(" \(orderLine) \n")

        let tableNumber = data["tableNumber"] as? String ?? "N/A"
        let orderType = data["orderType"] as? String ?? "DINE IN"
        printer.addText(" \(orderType) - TABLE: \(tableNumber) \n")

        let date = data["date"] as? String ?? ""
        let time = data["time"] as? String ?? ""
        printer.addText(" \(date) \(time) \n")

        let customerName = data["customerName"] as? String ?? "Guest Customer"
        printer.addText(" CUSTOMER: \(customerName) \n")
        printer.addText("\(LINE)\n")

        // Items header
        printer.addText(" \(rpad("Item", 22)) \(lpad("Qty", 3)) \(lpad("Price", 9)) \(lpad("Total", 9)) \n")
        printer.addText("\(LINE)\n")

        // Items list
        let items = data["items"] as? [[String: Any]]
        guard let items = items, !items.isEmpty else {
            printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
            printer.addText("ERROR: No items in order\n")
            printer.addFeedLine(3)
            printer.addCut(EPOS2_CUT_FEED.rawValue)
            printer.clearCommandBuffer()
            throw PrintHandlerError.emptyItems
        }

        // group items: active first, then cancelled below
        let activeItems = items.filter { (($0["status"] as? String)?.lowercased() ?? "") != "cancelled" }
        let cancelledItems = items.filter { ($0["status"] as? String)?.lowercased() == "cancelled" }
        let isFullyCancelled = activeItems.isEmpty && !cancelledItems.isEmpty

        var subtotal = 0.0
        for item in activeItems {
            let itemName = item["name"] as? String ?? ""
            let quantity = (item["quantity"] as? NSNumber)?.intValue ?? (item["quantity"] as? Int ?? 1)
            let price = (item["price"] as? NSNumber)?.doubleValue ?? (item["price"] as? Double ?? 0.0)
            let total = Double(quantity) * price
            subtotal += total

            let nameLimit = 22
            if itemName.count > nameLimit {
                printer.addText(" \(itemName)\n")
                printer.addText(" \(rpad("", 22)) \(lpad(String(quantity), 3)) \(lpad(formatAmount(price), 9)) \(lpad(formatAmount(total), 9)) \n")
            } else {
                printer.addText(" \(rpad(itemName, 22)) \(lpad(String(quantity), 3)) \(lpad(formatAmount(price), 9)) \(lpad(formatAmount(total), 9)) \n")
            }
        }

        // print cancelled items grouped below active items
        if !cancelledItems.isEmpty {
            printer.addText("\(LINE)\n")
            printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
            printer.addText("Cancelled Items\n")
            printer.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
            printer.addText("\(LINE)\n")
            for item in cancelledItems {
                let itemName = item["name"] as? String ?? ""
                let quantity = (item["quantity"] as? NSNumber)?.intValue ?? (item["quantity"] as? Int ?? 1)
                let price = (item["price"] as? NSNumber)?.doubleValue ?? (item["price"] as? Double ?? 0.0)
                let total = Double(quantity) * price

                let nameLimit = 22
                if itemName.count > nameLimit {
                    printer.addText(" \(itemName)\n")
                    printer.addText(" \(rpad("", 22)) \(lpad(String(quantity), 3)) \(lpad(formatAmount(price), 9)) \(lpad(formatAmount(total), 9)) \n")
                } else {
                    printer.addText(" \(rpad(itemName, 22)) \(lpad(String(quantity), 3)) \(lpad(formatAmount(price), 9)) \(lpad(formatAmount(total), 9)) \n")
                }
            }
        }

        printer.addText("\(LINE)\n")

        // Totals
        let netAmount = (data["netAmount"] as? NSNumber)?.doubleValue ?? (data["netAmount"] as? Double ?? 0.0)
        let tax = (data["tax"] as? NSNumber)?.doubleValue ?? (data["tax"] as? Double ?? 0.0)
        let total = (data["total"] as? NSNumber)?.doubleValue ?? (data["total"] as? Double ?? 0.0)
        let discount = (data["discount"] as? NSNumber)?.doubleValue ?? (data["discount"] as? Double ?? 0.0)
        let adjustmentAmount = (data["adjustmentAmount"] as? NSNumber)?.doubleValue ?? (data["adjustmentAmount"] as? Double ?? 0.0)
        let tableCharge = (data["tableCharge"] as? NSNumber)?.doubleValue ?? (data["tableCharge"] as? Double ?? 0.0)

        var grandTotal: Double
        if total > 0.0 {
            grandTotal = total - adjustmentAmount - tableCharge
        } else {
            grandTotal = 0.0
            for gItem in items {
                if ((gItem["status"] as? String)?.lowercased() ?? "") != "cancelled" {
                    let gQty = Double((gItem["quantity"] as? NSNumber)?.intValue ?? (gItem["quantity"] as? Int ?? 1))
                    let gPrice = (gItem["price"] as? NSNumber)?.doubleValue ?? (gItem["price"] as? Double ?? 0.0)
                    grandTotal += gQty * gPrice
                }
            }
            grandTotal = max(0.0, grandTotal - discount)
        }

        if !isFullyCancelled {
            printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
            printer.addText("ORDER SUMMARY\n")
            printer.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)

            printer.addText(receiptAmountLine("Subtotal", subtotal))
            
            if discount > 0.0 {
                let discountPercent = subtotal > 0.0 ? (discount / subtotal) * 100.0 : 0.0
                let discountLabel: String
                if discountPercent > 0.0 {
                    discountLabel = String(format: "Discount (%.0f%%)", discountPercent)
                } else {
                    discountLabel = "Discount"
                }
                printer.addText(receiptLine(discountLabel, receiptSignedMoney(-discount)))
            }
            printer.addText("\(LINE)\n")

            printer.addText(receiptAmountLine("Net Amount", netAmount))
            printer.addText(receiptAmountLine("Tax", tax))

            if let taxBreakdown = data["taxBreakdown"] as? [String: Any], !taxBreakdown.isEmpty {
                // sort tax breakdown
                let sortedKeys = taxBreakdown.keys.sorted { (k1, k2) -> Bool in
                    let u1 = k1.uppercased()
                    let u2 = k2.uppercased()
                    let score1 = (u1.contains("VAT") || u1.contains("GST")) ? 0 : 1
                    let score2 = (u2.contains("VAT") || u2.contains("GST")) ? 0 : 1
                    if score1 != score2 {
                        return score1 < score2
                    }
                    return u1 < u2
                }
                for (index, key) in sortedKeys.enumerated() {
                    let rawVal = taxBreakdown[key]
                    let value = (rawVal as? NSNumber)?.doubleValue ?? (rawVal as? Double ?? 0.0)
                    let connector = index == sortedKeys.count - 1 ? "  └─ " : "  ├─ "
                    printer.addText(receiptAmountLine("\(connector)\(key)", value))
                }
            } else {
                printer.addText(receiptAmountLine("  └─ VAT", tax))
            }
            printer.addText("\(LINE)\n")

            // Total Amount BEFORE adjustment
            let totalBeforeAdjustment = grandTotal
            printer.addText(receiptAmountLine("Total Amount", totalBeforeAdjustment))

            if tableCharge > 0.0 {
                printer.addText(receiptAmountLine("Table Charges", tableCharge))
                grandTotal += tableCharge
            }

            // Adjustment (if any)
            if adjustmentAmount != 0.0 {
                printer.addText(receiptLine("Addition", receiptSignedMoney(adjustmentAmount)))
                grandTotal += adjustmentAmount
            }
        }

        if isFullyCancelled {
            // Fully cancelled: show total paid amount then refund amount
            let totalPaid = (data["totalPaidAmount"] as? NSNumber)?.doubleValue ?? (data["totalPaidAmount"] as? Double ?? 0.0)
            let refundAmount = (data["refundAmount"] as? NSNumber)?.doubleValue ?? (data["refundAmount"] as? Double ?? totalPaid)
            printer.addText(receiptAmountLine("Total Paid", totalPaid))
            printer.addText(receiptAmountLine("Refund Amount", refundAmount))
            
            let paymentMethod = (data["paymentMethod"] as? String)?.uppercased() ?? ""
            if !paymentMethod.isEmpty {
                printer.addText(receiptLine("Payment Method", paymentMethod))
            }
        }

        // GRAND TOTAL: always the full product total (never reduced by payments)
        // For fully cancelled orders: 0.00 (nothing owed)
        printer.addText("\(DOUBLE_LINE)\n")
        printer.addText(receiptAmountLine("GRAND TOTAL", isFullyCancelled ? 0.0 : grandTotal))
        printer.addText("\(DOUBLE_LINE)\n")

        if !isFullyCancelled {
            let explicitPaidAmount = (data["paidAmount"] as? NSNumber)?.doubleValue ?? (data["paidAmount"] as? Double ?? 0.0)
            let totalPaid = (data["totalPaidAmount"] as? NSNumber)?.doubleValue ?? (data["totalPaidAmount"] as? Double ?? 0.0)
            let paymentStatus = (data["paymentStatus"] as? String)?.uppercased() ?? ""
            let paymentMethod = (data["paymentMethod"] as? String)?.uppercased() ?? ""

            let paidAmount: Double
            if explicitPaidAmount > 0.0 {
                paidAmount = explicitPaidAmount
            } else if totalPaid > 0.0 {
                paidAmount = totalPaid
            } else if paymentStatus == "PAID" {
                paidAmount = grandTotal
            } else {
                paidAmount = 0.0
            }
            let remaining = max(0.0, grandTotal - paidAmount)

            if paidAmount > 0.0 {
                printer.addText(receiptAmountLine("Paid", paidAmount))
            }
            if remaining > 0.0 {
                printer.addText(receiptAmountLine("Remaining", remaining))
            }
            if paidAmount > 0.0 || remaining > 0.0 {
                printer.addText("\(LINE)\n")
            }
            if !paymentStatus.isEmpty {
                printer.addText(receiptLine("Payment Status", paymentStatus))
            }
            if !paymentMethod.isEmpty {
                printer.addText(receiptLine("Payment Method", paymentMethod))
            }
            if !paymentStatus.isEmpty || !paymentMethod.isEmpty {
                printer.addText("\(LINE)\n")
            }

            if let paymentDistribution = data["paymentDistribution"] as? [[String: Any]], paymentDistribution.count > 1 {
                printer.addText("Payment Distribution:\n")
                for dist in paymentDistribution {
                    let method = (dist["method"] as? String)?.uppercased() ?? "CASH"
                    let distAmount = (dist["amount"] as? NSNumber)?.doubleValue ?? (dist["amount"] as? Double ?? 0.0)
                    printer.addText(receiptAmountLine("  -> \(method)", distAmount))
                }
                printer.addText("\(LINE)\n")
            }
        }

        if !isFullyCancelled {
            // Refund info — informational only, does NOT change grand total
            let refundAmount = (data["refundAmount"] as? NSNumber)?.doubleValue ?? (data["refundAmount"] as? Double ?? 0.0)
            if refundAmount > 0.0 {
                printer.addText(receiptAmountLine("Refund:", refundAmount))
                printer.addText("\(LINE)\n")
            }
        }

        // QR Code — printed above the footer text.
        printer.addFeedLine(1)
        printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
        if let qrCodeData = data["qrCodeData"] as? String, !qrCodeData.isEmpty,
           let qrBytes = Data(base64Encoded: qrCodeData),
           let qrImage = UIImage(data: qrBytes),
           qrImage.size.width > 0 {
            let qrSize: CGFloat = 120
            let qrRenderer = UIGraphicsImageRenderer(size: CGSize(width: qrSize, height: qrSize))
            let scaledQr = qrRenderer.image { _ in
                qrImage.draw(in: CGRect(x: 0, y: 0, width: qrSize, height: qrSize))
            }
            printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
            printer.add(
                scaledQr,
                x: 0, y: 0,
                width: Int(qrSize), height: Int(qrSize),
                color: EPOS2_COLOR_1.rawValue,
                mode: EPOS2_MODE_MONO.rawValue,
                halftone: EPOS2_HALFTONE_THRESHOLD.rawValue,
                brightness: Double(EPOS2_PARAM_DEFAULT),
                compress: EPOS2_COMPRESS_AUTO.rawValue
            )
        }

        // Footer text stays below the QR image.
        printer.addFeedLine(1)
        printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
        printer.addText("THANK YOU\n")
        printer.addText("\(time) \(date)\n")

        // Barcode
        if let barcode = data["barcode"] as? String {
            printer.addFeedLine(1)
            printer.addBarcode(barcode,
                               type: EPOS2_BARCODE_CODE39.rawValue,
                               hri: EPOS2_HRI_BELOW.rawValue,
                               font: EPOS2_FONT_A.rawValue,
                               width: 2,
                               height: 100)
        }

        // Cash drawer
        if let openDrawer = data["openDrawer"] as? Bool, openDrawer {
            printer.addPulse(Int32(EPOS2_PARAM_DEFAULT), time: Int32(EPOS2_PARAM_DEFAULT))
        }

        printer.addCut(EPOS2_CUT_FEED.rawValue)
    }

    // MARK: - Build KDS Data
    //
    // Mirrors buildKDSData() in EpsonPrintHandler.kt exactly.

    private func cleanItemString(_ s: String) -> String {
        var clean = s.lowercased()
        if let range = clean.range(of: "^\\d+\\.\\s*", options: .regularExpression) {
            clean.removeSubrange(range)
        }
        if clean.hasPrefix("+") {
            clean = String(clean.dropFirst())
        }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildKDSData(data: [String: Any]) throws {
        guard let printer = kdsPrinter else { return }

        // Bug 1 fix: clear stale commands
        printer.clearCommandBuffer()
        printer.addTextLang(EPOS2_LANG_EN.rawValue)
        printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)

        // Store name at top — matches web kdsBridgePayload.js
        let storeName = data["storeName"] as? String ?? ""
        if !storeName.isEmpty {
            printer.addTextSize(2, height: 2)
            printer.addText("\(storeName)\n")
            printer.addTextSize(1, height: 1)
        }

        printer.addText("KITCHEN ORDER TICKET\n")

        // Pad order number to 4 digits (web: "ORDER #0001")
        let rawOrderNumber = data["orderNumber"] as? String ?? "N/A"
        let orderNumber: String
        if let num = Int(rawOrderNumber) {
            orderNumber = String(format: "%04d", num)
        } else {
            orderNumber = rawOrderNumber
        }
        printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_TRUE, color: EPOS2_COLOR_1.rawValue)
        printer.addText("ORDER #\(orderNumber)\n")
        printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_FALSE, color: EPOS2_COLOR_1.rawValue)

        printer.addText("\(String(repeating: "=", count: 42))\n")

        // Left-align order info section
        printer.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
        let time = data["time"] as? String ?? ""
        let date = data["date"] as? String ?? ""
        printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_TRUE, color: EPOS2_COLOR_1.rawValue)
        printer.addText("DATE-TIME: \(date) \(time)\n")
        printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_FALSE, color: EPOS2_COLOR_1.rawValue)

        printer.addText("\(String(repeating: "=", count: 42))\n")

        if let tableNumber = data["tableNumber"] as? String, tableNumber != "—" {
            printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_TRUE, color: EPOS2_COLOR_1.rawValue)
            printer.addText("TABLE: \(tableNumber)\n")
            printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_FALSE, color: EPOS2_COLOR_1.rawValue)
        }

        // Order-level note (whole-order special instructions from order_des field)
        let orderNotes = data["orderNotes"] as? String ?? ""
        if !orderNotes.isEmpty && orderNotes != "N/A" {
            printer.addText("ORDER NOTE: \(orderNotes)\n")
        }

        printer.addText("\(String(repeating: "-", count: 42))\n")

        // Items column header — rpad/lpad for correct iOS column alignment
        printer.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
        printer.addText("\(rpad("ITEM", 38))\(lpad("QTY", 4))\n")
        printer.addText("\(String(repeating: "-", count: 42))\n")

        let items = data["items"] as? [[String: Any]]
        if items == nil || items!.isEmpty {
            printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
            printer.addText("NO ITEMS\n")
            printer.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
        } else {
            for item in items! {
                let quantity = item["quantity"] as? Int ?? 1
                let itemName = item["name"] as? String ?? "Item"

                if itemName.hasPrefix("+") {
                    // Modifier row — indented, with qty
                    printer.addText("  \(rpad(itemName, 36))\(String(format: "%4d", quantity))\n")
                } else {
                    // Main product row — bold, truncate long names
                    printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_TRUE, color: EPOS2_COLOR_1.rawValue)
                    let truncated = itemName.count > 38
                        ? String(itemName.prefix(37)) + "~"
                        : itemName
                    printer.addText("\(rpad(truncated, 38))\(String(format: "%4d", quantity))\n")
                    printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_FALSE, color: EPOS2_COLOR_1.rawValue)
                }

                if let notes = item["notes"] as? String, !notes.isEmpty {
                    let cleanedItem = cleanItemString(itemName)
                    let cleanedNote = cleanItemString(notes)
                    if cleanedItem != cleanedNote {
                        printer.addText("*** \(notes) ***\n")
                    }
                }
            }
        }

        // Footer
        printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
        printer.addText("\(String(repeating: "-", count: 42))\n")
        printer.addText("PRINTED FROM KITCHEN DISPLAY SYSTEM\n")
        printer.addText("\(time)\n")

        if let priority = data["priority"] as? String, priority.lowercased() == "high" {
            printer.addTextSize(2, height: 2)
            printer.addText("*** URGENT ***\n")
            printer.addTextSize(1, height: 1)
        }

        printer.addCut(EPOS2_CUT_FEED.rawValue)
    }

    // MARK: - Print Kitchen Ticket (ESC/POS KDS-format fallback on regular thermal printer)
    //
    // Mirrors printKitchenTicket() in EpsonPrintHandler.kt exactly.
    // Used when no dedicated KDS printer is configured — sends a kitchen-format
    // ticket to the regular thermal printer with the same reliability logic.

    func printKitchenTicket(data: [String: Any], result: @escaping FlutterResult) {
        printQueue.async { [weak self] in
            guard let self = self else { return }

            // Auto-reconnect if TCP was closed by printer firmware
            if self.regularPrinter == nil, let lastTarget = self.lastRegularTarget {
                NSLog("%@: [KitchenTicket] auto-reconnecting to %@", self.TAG, lastTarget)
                let printerSeries = self.getPrinterSeries(self.lastRegularSeries ?? "TM_M30")
                let langModel = self.getLanguageModel(self.lastRegularLang ?? "MODEL_ANK")
                let printer = Epos2Printer(printerSeries: printerSeries, lang: langModel)
                printer?.setReceiveEventDelegate(self)
                let normTarget = self.normalizeTarget(lastTarget)
                var reconnected = false
                if printer?.connect(normTarget, timeout: Int(EPOS2_PARAM_DEFAULT)) == EPOS2_SUCCESS.rawValue {
                    reconnected = true
                } else if normTarget != lastTarget,
                          printer?.connect(lastTarget, timeout: Int(EPOS2_PARAM_DEFAULT)) == EPOS2_SUCCESS.rawValue {
                    reconnected = true
                }
                if reconnected {
                    self.regularPrinter = printer
                    NSLog("%@: [KitchenTicket] auto-reconnect succeeded", self.TAG)
                } else {
                    NSLog("%@: [KitchenTicket] auto-reconnect failed", self.TAG)
                }
            }

            guard self.regularPrinter != nil else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "NOT_CONNECTED",
                                       message: "Printer not connected",
                                       details: nil))
                }
                return
            }

            do {
                try self.buildKitchenTicketData(data: data)
            } catch {
                self.regularPrinter?.clearCommandBuffer()
                DispatchQueue.main.async {
                    result(FlutterError(code: "PRINT_ERROR",
                                       message: "Build kitchen ticket failed: \(error.localizedDescription)",
                                       details: nil))
                }
                return
            }

            var sendResult = self.regularPrinter?.sendData(Int(EPOS2_PARAM_DEFAULT))
            if (sendResult == EPOS2_ERR_DISCONNECT.rawValue || sendResult == EPOS2_ERR_CONNECT.rawValue || sendResult == EPOS2_ERR_PROCESSING.rawValue),
               let lastTarget = self.lastRegularTarget {
                NSLog("%@: [KitchenTicket] sendData failed — reconnecting and retrying", self.TAG)
                self.disconnectRegularPrinterInternal()
                Thread.sleep(forTimeInterval: 0.3)
                let printerSeries = self.getPrinterSeries(self.lastRegularSeries ?? "TM_M30")
                let langModel = self.getLanguageModel(self.lastRegularLang ?? "MODEL_ANK")
                let printer = Epos2Printer(printerSeries: printerSeries, lang: langModel)
                printer?.setReceiveEventDelegate(self)
                let normTarget = self.normalizeTarget(lastTarget)
                var reconnectResult: Int32 = Int32(printer?.connect(normTarget, timeout: Int(EPOS2_PARAM_DEFAULT)) ?? EPOS2_ERR_CONNECT.rawValue)
                if reconnectResult != Int32(EPOS2_SUCCESS.rawValue), normTarget != lastTarget {
                    reconnectResult = Int32(printer?.connect(lastTarget, timeout: Int(EPOS2_PARAM_DEFAULT)) ?? EPOS2_ERR_CONNECT.rawValue)
                }
                if reconnectResult == Int32(EPOS2_SUCCESS.rawValue) {
                    self.regularPrinter = printer
                    do {
                        try self.buildKitchenTicketData(data: data)
                    } catch {
                        DispatchQueue.main.async {
                            result(FlutterError(code: "PRINT_ERROR",
                                               message: "Rebuild kitchen ticket after reconnect failed: \(error.localizedDescription)",
                                               details: nil))
                        }
                        return
                    }
                    sendResult = self.regularPrinter?.sendData(Int(EPOS2_PARAM_DEFAULT))
                } else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "PRINT_ERROR",
                                           message: "[KitchenTicket] reconnect retry failed after ERR_DISCONNECT",
                                           details: nil))
                    }
                    return
                }
            }

            if sendResult != EPOS2_SUCCESS.rawValue {
                self.regularPrinter?.clearCommandBuffer()
                DispatchQueue.main.async {
                    result(FlutterError(code: "PRINT_ERROR",
                                       message: "[KitchenTicket] sendData failed: \(self.errorName(sendResult ?? -1))",
                                       details: nil))
                }
                return
            }

            NSLog("%@: Kitchen ticket sent — disconnecting (Epson recommended pattern)", self.TAG)

            // Disconnect after every successful print (matching Android pattern).
            self.regularPrinter?.setReceiveEventDelegate(nil)
            self.disconnectRegularPrinterInternal()

            DispatchQueue.main.async {
                self.channel.invokeMethod("onPrintComplete", arguments: [
                    "success": true,
                    "printerType": "regular",
                    "message": "Kitchen ticket printed successfully"
                ])
            }
            DispatchQueue.main.async {
                result(["status": "printed"])
            }
        }
    }

    private func buildKitchenTicketData(data: [String: Any]) throws {
        guard let printer = regularPrinter else { return }

        printer.clearCommandBuffer()
        printer.addTextLang(EPOS2_LANG_EN.rawValue)

        // Header
        printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)

        // Store name at top
        let storeName = data["storeName"] as? String ?? ""
        if !storeName.isEmpty {
            printer.addTextSize(2, height: 2)
            printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_TRUE, color: EPOS2_COLOR_1.rawValue)
            printer.addText("\(storeName)\n")
            printer.addTextSize(1, height: 1)
            printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_FALSE, color: EPOS2_COLOR_1.rawValue)
        }

        printer.addText("KITCHEN ORDER TICKET\n")

        let rawOrderNumber = data["orderNumber"] as? String ?? "N/A"
        let orderNumber: String
        if let num = Int(rawOrderNumber) {
            orderNumber = String(format: "%04d", num)
        } else {
            orderNumber = rawOrderNumber
        }
        printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_TRUE, color: EPOS2_COLOR_1.rawValue)
        printer.addText("ORDER #\(orderNumber)\n")
        printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_FALSE, color: EPOS2_COLOR_1.rawValue)

        printer.addText("\(String(repeating: "=", count: 42))\n")

        // Left-align order info section
        printer.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
        let date = data["date"] as? String ?? ""
        let time = data["time"] as? String ?? ""
        printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_TRUE, color: EPOS2_COLOR_1.rawValue)
        printer.addText("DATE-TIME: \(date) \(time)\n")
        printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_FALSE, color: EPOS2_COLOR_1.rawValue)
        printer.addText("\(String(repeating: "=", count: 42))\n")

        let tableNumber = data["tableNumber"] as? String
        if let table = tableNumber, !table.isEmpty, table != "—" {
            printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_TRUE, color: EPOS2_COLOR_1.rawValue)
            printer.addText("TABLE: \(table)\n")
            printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_FALSE, color: EPOS2_COLOR_1.rawValue)
        }

        // Order-level note (whole-order special instructions from order_des field)
        let kitchenOrderNotes = data["orderNotes"] as? String ?? ""
        if !kitchenOrderNotes.isEmpty && kitchenOrderNotes != "N/A" {
            printer.addText("ORDER NOTE: \(kitchenOrderNotes)\n")
        }

        // Items — alignment already set to LEFT above
        printer.addText("\(rpad("ITEM", 38))\(lpad("QTY", 4))\n")
        printer.addText("\(String(repeating: "-", count: 42))\n")

        let items = data["items"] as? [[String: Any]]
        if items == nil || items!.isEmpty {
            printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
            printer.addText("NO ITEMS\n")
            printer.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
        } else {
            for item in items! {
                let quantity = item["quantity"] as? Int ?? 1
                let itemName = item["name"] as? String ?? "Item"
                let notes = item["notes"] as? String

                if itemName.hasPrefix("+") {
                    // Modifier row — indented, with qty
                    printer.addText("  \(rpad(itemName, 36))\(String(format: "%4d", quantity))\n")
                } else {
                    // Main product row — bold, truncate long names
                    printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_TRUE, color: EPOS2_COLOR_1.rawValue)
                    let truncated = itemName.count > 38
                        ? String(itemName.prefix(37)) + "~"
                        : itemName
                    printer.addText("\(rpad(truncated, 38))\(String(format: "%4d", quantity))\n")
                    printer.addTextStyle(EPOS2_FALSE, ul: EPOS2_FALSE, em: EPOS2_FALSE, color: EPOS2_COLOR_1.rawValue)
                }

                if let n = notes, !n.isEmpty {
                    let cleanedItem = cleanItemString(itemName)
                    let cleanedNote = cleanItemString(n)
                    if cleanedItem != cleanedNote {
                        printer.addText("*** \(n) ***\n")
                    }
                }
            }
        }

        // Footer
        printer.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
        printer.addText("\(String(repeating: "-", count: 42))\n")
        printer.addText("PRINTED FROM KITCHEN DISPLAY SYSTEM\n")
        printer.addText("\(time)\n")

        if let priority = data["priority"] as? String, priority.lowercased() == "high" {
            printer.addTextSize(2, height: 2)
            printer.addText("*** URGENT ***\n")
            printer.addTextSize(1, height: 1)
        }

        printer.addCut(EPOS2_CUT_FEED.rawValue)
    }

    // MARK: - Cleanup

    func cleanup() {
        printQueue.async { [weak self] in
            self?.disconnectRegularPrinterInternal()
            self?.disconnectKDSPrinterInternal()
        }
    }

    // MARK: - Helpers: Printer Series / Language / Target

    private func getPrinterSeries(_ series: String) -> Int32 {
        switch series.uppercased() {
        case "TM_M10":       return EPOS2_TM_M10.rawValue
        case "TM_M30":       return EPOS2_TM_M30.rawValue
        case "TM_M30II":     return EPOS2_TM_M30II.rawValue
        case "TM_M30III":    return EPOS2_TM_M30III.rawValue
        case "TM_P20":       return EPOS2_TM_P20.rawValue
        case "TM_P60":       return EPOS2_TM_P60.rawValue
        case "TM_P60II":     return EPOS2_TM_P60II.rawValue
        case "TM_P80":       return EPOS2_TM_P80.rawValue
        case "TM_T20":       return EPOS2_TM_T20.rawValue
        case "TM_T60":       return EPOS2_TM_T60.rawValue
        case "TM_T70":       return EPOS2_TM_T70.rawValue
        case "TM_T81":       return EPOS2_TM_T81.rawValue
        case "TM_T82":       return EPOS2_TM_T82.rawValue
        case "TM_T83":       return EPOS2_TM_T83.rawValue
        case "TM_T88":       return EPOS2_TM_T88.rawValue
        case "TM_T88VII":    return EPOS2_TM_T88VII.rawValue
        case "TM_T90":       return EPOS2_TM_T90.rawValue
        case "TM_T90KP":     return EPOS2_TM_T90KP.rawValue
        case "TM_U220":      return EPOS2_TM_U220.rawValue
        case "TM_U330":      return EPOS2_TM_U330.rawValue
        case "TM_L90":       return EPOS2_TM_L90.rawValue
        case "TM_H6000":     return EPOS2_TM_H6000.rawValue
        default:             return EPOS2_TM_M30.rawValue
        }
    }

    private func getLFCPrinterSeries(_ series: String) -> Int32 {
        switch series.uppercased() {
        case "TM_L90LFC":   return EPOS2_TM_L90LFC.rawValue
        case "TM_L100":     return EPOS2_TM_L100.rawValue
        default:            return EPOS2_TM_L100.rawValue
        }
    }

    private func getLanguageModel(_ lang: String) -> Int32 {
        switch lang.uppercased() {
        case "MODEL_ANK":        return EPOS2_MODEL_ANK.rawValue
        case "MODEL_JAPANESE":   return EPOS2_MODEL_JAPANESE.rawValue
        case "MODEL_CHINESE":    return EPOS2_MODEL_CHINESE.rawValue
        case "MODEL_TAIWAN":     return EPOS2_MODEL_TAIWAN.rawValue
        case "MODEL_KOREAN":     return EPOS2_MODEL_KOREAN.rawValue
        case "MODEL_THAI":       return EPOS2_MODEL_THAI.rawValue
        case "MODEL_SOUTHASIA":  return EPOS2_MODEL_SOUTHASIA.rawValue
        default:                 return EPOS2_MODEL_ANK.rawValue
        }
    }

    /// Identical normalization logic to the Android normalizeTarget()
    private func normalizeTarget(_ raw: String) -> String {
        var target = raw.trimmingCharacters(in: .whitespaces)
        NSLog("%@: [normalizeTarget] INPUT: %@", TAG, raw)

        // Strip pipe suffixes
        if let pipeIdx = target.firstIndex(of: "|") {
            target = String(target[target.startIndex..<pipeIdx]).trimmingCharacters(in: .whitespaces)
        }

        let lower = target.lowercased()
        let prefix: String
        let body: String

        if lower.hasPrefix("tcps:") {
            prefix = "TCPS:"
            body = String(target.dropFirst(5))
        } else if lower.hasPrefix("tcp:") {
            prefix = "TCP:"
            body = String(target.dropFirst(4))
        } else if lower.hasPrefix("bt:") {
            prefix = "BT:"
            body = String(target.dropFirst(3))
        } else if lower.hasPrefix("usb:") {
            prefix = "USB:"
            body = String(target.dropFirst(4))
        } else {
            prefix = "TCP:"
            body = target
        }

        var stripped = body.drop(while: { $0 == ":" || $0 == "/" })
        // Remove port from TCP targets (Epson SDK appends port internally)
        if prefix == "TCP:" || prefix == "TCPS:" {
            let parts = stripped.split(separator: ":")
            if parts.count > 1, Int(parts[1]) != nil {
                stripped = parts[0]
            }
        }

        let result = "\(prefix)\(stripped)"
        NSLog("%@: [normalizeTarget] OUTPUT: %@", TAG, result)
        return result
    }

    // MARK: - String column-formatting helpers
    //
    // iOS String(format:) silently ignores field-width modifiers for %@.
    // These helpers replicate Java's %-Ns (left-align/pad) and %Ns (right-align/pad)
    // so receipt column layout matches Android output identically.

    /// Left-align: extend `s` with trailing spaces to exactly `n` chars.
    /// Truncates to `n` if longer (equivalent to Java %-Ns).
    private func rpad(_ s: String, _ n: Int) -> String {
        guard s.count < n else { return String(s.prefix(n)) }
        return s + String(repeating: " ", count: n - s.count)
    }

    /// Right-align: prefix `s` with leading spaces to exactly `n` chars.
    /// Truncates to `n` if longer (equivalent to Java %Ns).
    private func lpad(_ s: String, _ n: Int) -> String {
        guard s.count < n else { return String(s.prefix(n)) }
        return String(repeating: " ", count: n - s.count) + s
    }

    private func errorName(_ code: Int32) -> String {
        switch code {
        case EPOS2_SUCCESS.rawValue:           return "SUCCESS"
        case EPOS2_ERR_PARAM.rawValue:         return "ERR_PARAM"
        case EPOS2_ERR_CONNECT.rawValue:       return "ERR_CONNECT"
        case EPOS2_ERR_TIMEOUT.rawValue:       return "ERR_TIMEOUT"
        case EPOS2_ERR_MEMORY.rawValue:        return "ERR_MEMORY"
        case EPOS2_ERR_ILLEGAL.rawValue:       return "ERR_ILLEGAL"
        case EPOS2_ERR_PROCESSING.rawValue:    return "ERR_PROCESSING"
        case EPOS2_ERR_NOT_FOUND.rawValue:     return "ERR_NOT_FOUND"
        case EPOS2_ERR_IN_USE.rawValue:        return "ERR_IN_USE"
        case EPOS2_ERR_DISCONNECT.rawValue:    return "ERR_DISCONNECT"
        case EPOS2_ERR_ALREADY_OPENED.rawValue: return "ERR_ALREADY_OPENED"
        case EPOS2_ERR_FAILURE.rawValue:       return "ERR_FAILURE"
        default:                               return "UNKNOWN_\(code)"
        }
    }
}

// MARK: - Epos2PtrReceiveDelegate (Regular printer callbacks)

extension EpsonPrintHandler: Epos2PtrReceiveDelegate {
    func onPtrReceive(_ printerObj: Epos2Printer!,
                      code: Int32,
                      status: Epos2PrinterStatusInfo!,
                      printJobId: String!) {
        // With disconnect-after-print pattern, this delegate fires only if the
        // printer somehow stays connected (e.g. disconnect failed).  Log only —
        // do NOT touch regularPrinter or clearCommandBuffer here because those
        // race with the printQueue.  Completion is already signalled manually
        // in printReceipt / printKitchenTicket after disconnect.
        NSLog("%@: receive callback code=%d (delegate — no-op with disconnect-after-print)", TAG, code)
    }

    private func callbackErrorName(_ code: Int32) -> String {
        switch code {
        case EPOS2_CODE_SUCCESS.rawValue:           return "SUCCESS"
        case EPOS2_CODE_ERR_AUTORECOVER.rawValue:   return "ERR_AUTORECOVER"
        case EPOS2_CODE_ERR_COVER_OPEN.rawValue:    return "ERR_COVER_OPEN"
        case EPOS2_CODE_ERR_CUTTER.rawValue:        return "ERR_CUTTER"
        case EPOS2_CODE_ERR_MECHANICAL.rawValue:    return "ERR_MECHANICAL"
        case EPOS2_CODE_ERR_EMPTY.rawValue:         return "ERR_EMPTY"
        case EPOS2_CODE_ERR_UNRECOVERABLE.rawValue: return "ERR_UNRECOVERABLE"
        case EPOS2_CODE_ERR_FAILURE.rawValue:       return "ERR_FAILURE"
        case EPOS2_CODE_ERR_NOT_FOUND.rawValue:     return "ERR_NOT_FOUND"
        case EPOS2_CODE_ERR_SYSTEM.rawValue:        return "ERR_SYSTEM"
        case EPOS2_CODE_ERR_PORT.rawValue:          return "ERR_PORT"
        case EPOS2_CODE_ERR_TIMEOUT.rawValue:       return "ERR_TIMEOUT"
        case EPOS2_CODE_CANCELED.rawValue:          return "CANCELED"
        default:                                    return "UNKNOWN_\(code)"
        }
    }
}

// MARK: - Epos2LFCSendCompleteDelegate (KDS callbacks)

extension EpsonPrintHandler: Epos2LFCSendCompleteDelegate {
    func onSendComplete(_ lfcPrinterObj: Epos2LFCPrinter!,
                        jobNumber: Int,
                        code: Int32,
                        status: Epos2LFCPrinterStatusInfo!) {
        // With disconnect-after-print pattern, this delegate should rarely fire.
        // Completion is signalled manually in printKDS after disconnect.
        NSLog("%@: LFC send complete code=%d jobNumber=%d (delegate — no-op with disconnect-after-print)", TAG, code, Int32(jobNumber))
    }
}

// MARK: - Internal error type

private enum PrintHandlerError: Error {
    case emptyItems
}
