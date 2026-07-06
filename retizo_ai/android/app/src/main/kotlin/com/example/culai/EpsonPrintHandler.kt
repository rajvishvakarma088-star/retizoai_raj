package com.example.culai

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import com.epson.epos2.printer.Printer
import com.epson.epos2.printer.LFCPrinter
import com.epson.epos2.printer.PrinterStatusInfo
import com.epson.epos2.printer.ReceiveListener
import com.epson.epos2.printer.LFCPrinterStatusInfo
import com.epson.epos2.printer.LFCSendCompleteListener
import com.epson.epos2.Epos2Exception
import com.epson.epos2.Epos2CallbackCode
import java.util.Locale

/**
 * EpsonPrintHandler - Manages all printing operations
 * 
 * Supports TWO types of printing:
 * 1. Regular Printer (Printer class) - For bills, receipts, invoices
 * 2. KDS Printer (LFCPrinter class) - For kitchen display system orders
 * 
 * Features:
 * - Multi-printer support (manage separate instances)
 * - Automatic disconnect after print
 * - Status callbacks to Flutter
 * - Error handling with detailed messages
 * - Safe connection/disconnection with retry logic
 * 
 * @param context Android context
 * @param channel Method channel for Flutter callbacks
 */
class EpsonPrintHandler(
    private val context: Context,
    private val channel: MethodChannel
) {
    private var regularPrinter: Printer? = null
    private var kdsPrinter: LFCPrinter? = null
    // Last known connection params — used for transparent auto-reconnect after
    // the printer firmware closes the TCP connection following each print job.
    private var lastRegularTarget: String? = null
    private var lastRegularSeries: String? = null
    private var lastRegularLang: String? = null
    // KDS connection params — same auto-reconnect mechanism as regular printer
    private var lastKDSTarget: String? = null
    private var lastKDSSeries: String? = null
    private var lastKDSLang: String? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    /** Serialises all operations on [regularPrinter] to prevent concurrent access. */
    private val printerLock = Any()
    
    companion object {
        private const val TAG = "EpsonPrintHandler"
        private const val DISCONNECT_INTERVAL = 500L // milliseconds
        private const val WIDTH = 48
        private const val INNER_WIDTH = 46
        private val LINE = " " + "-".repeat(INNER_WIDTH) + " "
        private val DOUBLE_LINE = " " + "=".repeat(INNER_WIDTH) + " "
    }

    private fun formatAmount(value: Double): String {
        val safeValue = if (value.isFinite()) value else 0.0
        return String.format(Locale.US, "%.2f", safeValue)
    }

    private fun amountLine(label: String, value: Double): String {
        return String.format(Locale.US, " %-32s SAR %9s \n", label, formatAmount(value))
    }

    /**
     * Connect to printer
     * 
     * @param target Printer address (e.g., "TCP:192.168.1.100" or "BT:XX:XX:XX:XX:XX:XX" or "USB:")
     * @param printerType "regular" for bills/receipts, "kds" for kitchen orders
     * @param series Printer series (e.g., "TM_M30", "TM_T88VII", "TM_L100")
     * @param lang Printer language model (e.g., "MODEL_ANK", "MODEL_JAPANESE")
     */
    fun connectPrinter(
        target: String,
        printerType: String,
        series: String,
        lang: String,
        result: MethodChannel.Result
    ) {
        Thread {
            // KDS uses a separate LFCPrinter object — no lock needed.
            // Regular printer operations are serialised via printerLock to prevent
            // concurrent connect / print / disconnect races across startup-restore,
            // fetchAndConnect, and auto-reconnect paths.
            if (printerType.lowercase() == "kds") {
                try {
                    connectKDSPrinter(target, series, lang, result)
                } catch (e: Exception) {
                    android.util.Log.e(TAG, "KDS connection failed", e)
                    mainHandler.post {
                        result.error("CONNECTION_ERROR", e.message, getErrorDetails(e))
                    }
                }
            } else {
                synchronized(printerLock) {
                    try {
                        connectRegularPrinter(target, series, lang, result)
                    } catch (e: Exception) {
                        android.util.Log.e(TAG, "Connection failed", e)
                        mainHandler.post {
                            result.error("CONNECTION_ERROR", e.message, getErrorDetails(e))
                        }
                    }
                }
            }
        }.start()
    }

    /**
     * Connect to regular printer for bills/receipts
     */
    private fun connectRegularPrinter(
        target: String,
        series: String,
        lang: String,
        result: MethodChannel.Result
    ) {
        try {
            android.util.Log.i(TAG, "starting regular printer connection: target=$target, series=$series, lang=$lang")
            
            // Cleanup existing connection
            regularPrinter?.let {
                android.util.Log.i(TAG, "existing printer connection found, disconnecting")
                disconnectRegularPrinterInternal()
                android.util.Log.i(TAG, "previous printer connection disconnected")
            }

            // Initialize printer with series and language model
            val printerSeries = getPrinterSeries(series)
            android.util.Log.i(TAG, "mapped series: $series to constant=$printerSeries")
            
            val langModel = getLanguageModel(lang)
            android.util.Log.i(TAG, "mapped language: $lang to constant=$langModel")
            
            val normalizedTarget = normalizeTarget(target)
            android.util.Log.i(TAG, "normalized target from $target to $normalizedTarget")

            // Persist connection params BEFORE connecting so auto-reconnect in
            // printReceipt / printKitchenTicket has a valid target even when
            // this initial connection attempt fails (e.g. printer offline at
            // app start).  Updated again below with actual connected target.
            lastRegularTarget = normalizedTarget
            lastRegularSeries = series
            lastRegularLang = lang
            
            regularPrinter = Printer(printerSeries, langModel, context)
            android.util.Log.i(TAG, "printer object created with series=$printerSeries, language=$langModel")
            
            regularPrinter?.setReceiveEventListener(receiveListener)
            android.util.Log.i(TAG, "receive event listener attached")
            
            // Connect to printer
            var connectedTarget = normalizedTarget
            try {
                android.util.Log.i(TAG, "attempting connection to $normalizedTarget with default parameters")
                regularPrinter?.connect(normalizedTarget, Printer.PARAM_DEFAULT)
                android.util.Log.i(TAG, "successfully connected to $normalizedTarget")
            } catch (e: Epos2Exception) {
                android.util.Log.w(TAG, "normalized target connection failed (${e.errorStatus}): ${e.message}, retrying with raw target: $target")
                if (normalizedTarget != target) {
                    try {
                        android.util.Log.i(TAG, "retrying connection with raw target: $target")
                        regularPrinter?.connect(target, Printer.PARAM_DEFAULT)
                        connectedTarget = target
                        android.util.Log.i(TAG, "successfully connected to raw target: $target")
                    } catch (e2: Exception) {
                        android.util.Log.e(TAG, "raw target connection also failed: ${e2.message}")
                        throw e2
                    }
                } else {
                    throw e
                }
            }
            
            // Update with the actual connected target (may differ from
            // normalized if the raw-target fallback was used)
            lastRegularTarget = connectedTarget

            mainHandler.post {
                android.util.Log.i(TAG, "regular printer connection established: target=$connectedTarget, series=$series")
                result.success(mapOf(
                    "status" to "connected",
                    "printerType" to "regular",
                    "target" to connectedTarget,
                    "series" to series
                ))
            }
            
            android.util.Log.d(TAG, "Regular printer connected: $connectedTarget")
            
        } catch (e: Exception) {
            regularPrinter = null
            // NOTE: lastRegularTarget / lastRegularSeries / lastRegularLang are
            // deliberately KEPT set — printReceipt / printKitchenTicket auto-
            // reconnect uses them even when the initial connect fails.
            val errorMsg = if (e is Epos2Exception) {
                "Epos2Exception(errorStatus=${e.errorStatus}, message=${e.message})"
            } else {
                "${e::class.simpleName}: ${e.message}"
            }
            android.util.Log.e(TAG, "regular printer connection failed: $errorMsg")
            android.util.Log.e(TAG, "stack trace for connection failure:", e)
            mainHandler.post {
                result.error("CONNECTION_ERROR", errorMsg, mapOf(
                    "exceptionType" to e::class.simpleName,
                    "message" to e.message,
                    "target" to target,
                    "series" to series
                ))
            }
        }
    }

    /**
     * Connect to KDS printer for kitchen orders
     */
    private fun connectKDSPrinter(
        target: String,
        series: String,
        lang: String,
        result: MethodChannel.Result
    ) {
        try {
            // Cleanup existing connection
            kdsPrinter?.let {
                disconnectKDSPrinterInternal()
            }

            // Initialize LFC printer
            val printerSeries = getLFCPrinterSeries(series)
            val langModel = getLanguageModel(lang)
            val normalizedTarget = normalizeTarget(target)
            
            kdsPrinter = LFCPrinter(printerSeries, langModel, context)
            kdsPrinter?.setSendCompleteEventListener(lfcSendCompleteListener)
            
            // Connect to KDS printer
            var connectedTarget = normalizedTarget
            try {
                kdsPrinter?.connect(normalizedTarget, LFCPrinter.PARAM_DEFAULT)
            } catch (e: Epos2Exception) {
                if (normalizedTarget != target) {
                    android.util.Log.w(TAG, "Normalized KDS target failed, retrying raw: $target", e)
                    kdsPrinter?.connect(target, LFCPrinter.PARAM_DEFAULT)
                    connectedTarget = target
                } else {
                    throw e
                }
            }
            
            // Persist KDS connection params for transparent auto-reconnect after each print.
            // Epson KDS firmware closes the TCP connection after every completed print job,
            // exactly like the regular printer. Without these stored params, subsequent
            // printKDS() calls fail with ERR_DISCONNECT.
            lastKDSTarget = connectedTarget
            lastKDSSeries = series
            lastKDSLang   = lang

            mainHandler.post {
                result.success(mapOf(
                    "status" to "connected",
                    "printerType" to "kds",
                    "target" to connectedTarget,
                    "series" to series
                ))
            }
            
            android.util.Log.d(TAG, "KDS printer connected: $connectedTarget")
            
        } catch (e: Exception) {
            kdsPrinter = null
            throw e
        }
    }

    /**
     * Disconnect from printer
     */
    fun disconnectPrinter(printerType: String, result: MethodChannel.Result) {
        Thread {
            try {
                when (printerType.lowercase()) {
                    "kds" -> {
                        disconnectKDSPrinterInternal()
                        mainHandler.post {
                            result.success(mapOf("status" to "disconnected", "printerType" to "kds"))
                        }
                    }
                    else -> {
                        // Must hold printerLock to avoid racing with an in-flight print job.
                        synchronized(printerLock) {
                            disconnectRegularPrinterInternal()
                        }
                        mainHandler.post {
                            result.success(mapOf("status" to "disconnected", "printerType" to "regular"))
                        }
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Disconnection failed", e)
                mainHandler.post {
                    result.error("DISCONNECT_ERROR", e.message, null)
                }
            }
        }.start()
    }

    /**
     * Print receipt/bill (Regular printer)
     */
    fun printReceipt(data: Map<String, Any>, result: MethodChannel.Result) {
        Thread {
            synchronized(printerLock) {
            try {
                // ── Bug 2 fix: auto-reconnect if printer was disconnected ─────────────────
                // Epson printer firmware closes the TCP connection after every print job.
                // If regularPrinter is null but we have previously connected, reconnect now
                // so the user never has to manually go back to Settings to reconnect.
                if (regularPrinter == null && lastRegularTarget != null) {
                    android.util.Log.i(TAG, "Regular printer not connected — auto-reconnecting to $lastRegularTarget")
                    try {
                        val printerSeries = getPrinterSeries(lastRegularSeries ?: "TM_M30")
                        val langModel    = getLanguageModel(lastRegularLang ?: "MODEL_ANK")
                        val normTarget   = normalizeTarget(lastRegularTarget!!)
                        regularPrinter = Printer(printerSeries, langModel, context)
                        regularPrinter?.setReceiveEventListener(receiveListener)
                        try {
                            regularPrinter?.connect(normTarget, Printer.PARAM_DEFAULT)
                            android.util.Log.i(TAG, "Auto-reconnected to $normTarget")
                        } catch (connEx: Epos2Exception) {
                            if (normTarget != lastRegularTarget) {
                                regularPrinter?.connect(lastRegularTarget!!, Printer.PARAM_DEFAULT)
                                android.util.Log.i(TAG, "Auto-reconnected to ${lastRegularTarget} (raw target)")
                            } else throw connEx
                        }
                    } catch (reconnectEx: Exception) {
                        android.util.Log.e(TAG, "Auto-reconnect failed: ${reconnectEx.message}")
                        // Clean up the partially-created Printer object to release SDK resources
                        try { regularPrinter?.setReceiveEventListener(null) } catch (_: Exception) {}
                        try { regularPrinter?.disconnect() } catch (_: Exception) {}
                        regularPrinter = null
                    }
                }
                // ─────────────────────────────────────────────────────────────────────────

                if (regularPrinter == null) {
                    mainHandler.post {
                        result.error("NOT_CONNECTED", "Regular printer not connected", null)
                    }
                    return@Thread
                }

                // Build print data (clearCommandBuffer already called inside buildReceiptData)
                buildReceiptData(data)

                // Send print job — with one auto-reconnect retry on ERR_DISCONNECT/ERR_PROCESSING
                try {
                    regularPrinter?.sendData(Printer.PARAM_DEFAULT)
                } catch (sendEx: Epos2Exception) {
                    val errStatus = sendEx.errorStatus
                    if ((errStatus == Epos2Exception.ERR_DISCONNECT
                                || errStatus == Epos2Exception.ERR_CONNECT
                                || errStatus == Epos2Exception.ERR_PROCESSING)
                        && lastRegularTarget != null) {
                        android.util.Log.w(TAG, "sendData failed (errStatus=$errStatus) — reconnecting to $lastRegularTarget and retrying")
                        disconnectRegularPrinterInternal()          // clean up stale object
                        Thread.sleep(300)
                        val printerSeries = getPrinterSeries(lastRegularSeries ?: "TM_M30")
                        val langModel    = getLanguageModel(lastRegularLang ?: "MODEL_ANK")
                        val normTarget   = normalizeTarget(lastRegularTarget!!)
                        regularPrinter = Printer(printerSeries, langModel, context)
                        regularPrinter?.setReceiveEventListener(receiveListener)
                        try {
                            regularPrinter?.connect(normTarget, Printer.PARAM_DEFAULT)
                        } catch (connEx: Epos2Exception) {
                            if (normTarget != lastRegularTarget) {
                                regularPrinter?.connect(lastRegularTarget!!, Printer.PARAM_DEFAULT)
                            } else throw connEx
                        }
                        android.util.Log.i(TAG, "Reconnected — retrying print")
                        buildReceiptData(data)                    // rebuild after clearCommandBuffer
                        regularPrinter?.sendData(Printer.PARAM_DEFAULT)
                    } else {
                        throw sendEx                               // non-recoverable — re-throw
                    }
                }

                android.util.Log.d(TAG, "Receipt sent — disconnecting (Epson recommended pattern)")

                // ── Epson-recommended: disconnect after every successful print ─────────
                // The printer completes the job from its internal buffer even after
                // TCP disconnect.  A fresh reconnect for the next job eliminates:
                //  • Stale TCP connections (firmware idle timeout)
                //  • ERR_PROCESSING (callback still pending from previous job)
                //  • receiveListener race conditions (listener is removed before disconnect)
                // The auto-reconnect block at the top of this method creates a new
                // Printer instance and reconnects transparently for the next print.
                // Uses retry loop for ERR_PROCESSING — simple disconnect() can fail
                // silently while printer is still processing, leaking the TCP connection.
                disconnectRegularPrinterInternal()

                // Manually notify Flutter of print success since receiveListener
                // won't fire after disconnect.  This keeps isPrinting / counters accurate.
                mainHandler.post {
                    channel.invokeMethod("onPrintComplete", mapOf(
                        "success" to true,
                        "printerType" to "regular",
                        "message" to "Print completed successfully"
                    ))
                }
                mainHandler.post { result.success(mapOf("status" to "printed")) }

            } catch (e: Exception) {
                android.util.Log.e(TAG, "Print receipt failed", e)
                regularPrinter?.clearCommandBuffer()
                mainHandler.post {
                    result.error("PRINT_ERROR", e.message, getErrorDetails(e))
                }
            }
            } // synchronized(printerLock)
        }.start()
    }

    /**
     * Print KDS order (Kitchen Display)
     *
     * Mirrors printReceipt() exactly for reliability:
     *  - Auto-reconnect if firmware closed TCP after previous job (same root cause as receipt Bug 2)
     *  - ERR_DISCONNECT retry with one reconnect attempt
     *  - result.success() called after sendLFCData to unblock Dart await (PRIMARY BUG FIX)
     *    Without result.success(), PrintQueueManager._isProcessing stays true forever
     *    and the entire KDS queue deadlocks after the first job.
     */
    fun printKDS(data: Map<String, Any>, jobNumber: Int, result: MethodChannel.Result) {
        Thread {
            try {
                // Auto-reconnect if KDS printer TCP was closed by firmware after previous print
                if (kdsPrinter == null && lastKDSTarget != null) {
                    android.util.Log.i(TAG, "KDS printer not connected — auto-reconnecting to $lastKDSTarget")
                    try {
                        val printerSeries = getLFCPrinterSeries(lastKDSSeries ?: "TM_L100")
                        val langModel     = getLanguageModel(lastKDSLang ?: "MODEL_ANK")
                        val normTarget    = normalizeTarget(lastKDSTarget!!)
                        kdsPrinter = LFCPrinter(printerSeries, langModel, context)
                        kdsPrinter?.setSendCompleteEventListener(lfcSendCompleteListener)
                        try {
                            kdsPrinter?.connect(normTarget, LFCPrinter.PARAM_DEFAULT)
                            android.util.Log.i(TAG, "KDS auto-reconnected to $normTarget")
                        } catch (connEx: Epos2Exception) {
                            if (normTarget != lastKDSTarget) {
                                kdsPrinter?.connect(lastKDSTarget!!, LFCPrinter.PARAM_DEFAULT)
                                android.util.Log.i(TAG, "KDS auto-reconnected to ${lastKDSTarget} (raw target)")
                            } else throw connEx
                        }
                    } catch (reconnectEx: Exception) {
                        android.util.Log.e(TAG, "KDS auto-reconnect failed: ${reconnectEx.message}")
                        try { kdsPrinter?.setSendCompleteEventListener(null) } catch (_: Exception) {}
                        try { kdsPrinter?.disconnect() } catch (_: Exception) {}
                        kdsPrinter = null
                    }
                }

                if (kdsPrinter == null) {
                    mainHandler.post {
                        result.error("NOT_CONNECTED", "KDS printer not connected", null)
                    }
                    return@Thread
                }

                // Build KDS data (clearCommandBuffer already called inside buildKDSData)
                buildKDSData(data)

                // Send with one auto-reconnect retry on ERR_DISCONNECT/ERR_PROCESSING
                try {
                    kdsPrinter?.sendLFCData(LFCPrinter.PARAM_DEFAULT, jobNumber)
                } catch (sendEx: Epos2Exception) {
                    val errStatus = sendEx.errorStatus
                    if ((errStatus == Epos2Exception.ERR_DISCONNECT
                                || errStatus == Epos2Exception.ERR_CONNECT
                                || errStatus == Epos2Exception.ERR_PROCESSING)
                        && lastKDSTarget != null) {
                        android.util.Log.w(TAG, "KDS sendLFCData failed (errStatus=$errStatus) — reconnecting to $lastKDSTarget and retrying")
                        disconnectKDSPrinterInternal()
                        Thread.sleep(300)
                        val printerSeries = getLFCPrinterSeries(lastKDSSeries ?: "TM_L100")
                        val langModel     = getLanguageModel(lastKDSLang ?: "MODEL_ANK")
                        val normTarget    = normalizeTarget(lastKDSTarget!!)
                        kdsPrinter = LFCPrinter(printerSeries, langModel, context)
                        kdsPrinter?.setSendCompleteEventListener(lfcSendCompleteListener)
                        try {
                            kdsPrinter?.connect(normTarget, LFCPrinter.PARAM_DEFAULT)
                        } catch (connEx: Epos2Exception) {
                            if (normTarget != lastKDSTarget) {
                                kdsPrinter?.connect(lastKDSTarget!!, LFCPrinter.PARAM_DEFAULT)
                            } else throw connEx
                        }
                        android.util.Log.i(TAG, "KDS reconnected — retrying print")
                        buildKDSData(data)
                        kdsPrinter?.sendLFCData(LFCPrinter.PARAM_DEFAULT, jobNumber)
                    } else {
                        throw sendEx
                    }
                }

                android.util.Log.d(TAG, "KDS order sent: Job #$jobNumber — disconnecting")
                disconnectKDSPrinterInternal()

                mainHandler.post {
                    channel.invokeMethod("onPrintComplete", mapOf(
                        "success" to true,
                        "printerType" to "kds",
                        "message" to "KDS order sent successfully",
                        "jobNumber" to jobNumber
                    ))
                }
                mainHandler.post { result.success(mapOf("status" to "printed")) }

            } catch (e: Exception) {
                android.util.Log.e(TAG, "Print KDS failed", e)
                kdsPrinter?.clearCommandBuffer()
                mainHandler.post {
                    result.error("PRINT_ERROR", e.message, getErrorDetails(e))
                }
            }
        }.start()
    }

    /**
     * Print kitchen ticket on regular thermal printer (ESC/POS, KDS-style format).
     *
     * Used as fallback when no dedicated LFC/KDS printer is configured.
     * Mirrors printReceipt() auto-reconnect logic exactly so the caller
     * gets the same reliability behaviour regardless of which path is taken.
     */
    fun printKitchenTicket(data: Map<String, Any>, result: MethodChannel.Result) {
        Thread {
            synchronized(printerLock) {
            try {
                // Auto-reconnect if TCP was closed by printer firmware
                if (regularPrinter == null && lastRegularTarget != null) {
                    android.util.Log.i(TAG, "[KitchenTicket] Regular printer not connected — auto-reconnecting to $lastRegularTarget")
                    try {
                        val printerSeries = getPrinterSeries(lastRegularSeries ?: "TM_M30")
                        val langModel    = getLanguageModel(lastRegularLang ?: "MODEL_ANK")
                        val normTarget   = normalizeTarget(lastRegularTarget!!)
                        regularPrinter = Printer(printerSeries, langModel, context)
                        regularPrinter?.setReceiveEventListener(receiveListener)
                        try {
                            regularPrinter?.connect(normTarget, Printer.PARAM_DEFAULT)
                        } catch (connEx: Epos2Exception) {
                            if (normTarget != lastRegularTarget) {
                                regularPrinter?.connect(lastRegularTarget!!, Printer.PARAM_DEFAULT)
                            } else throw connEx
                        }
                        android.util.Log.i(TAG, "[KitchenTicket] Auto-reconnected to $lastRegularTarget")
                    } catch (reconnectEx: Exception) {
                        android.util.Log.e(TAG, "[KitchenTicket] Auto-reconnect failed: ${reconnectEx.message}")
                        try { regularPrinter?.setReceiveEventListener(null) } catch (_: Exception) {}
                        try { regularPrinter?.disconnect() } catch (_: Exception) {}
                        regularPrinter = null
                    }
                }

                if (regularPrinter == null) {
                    mainHandler.post {
                        result.error("NOT_CONNECTED", "Printer not connected", null)
                    }
                    return@Thread
                }

                buildKitchenTicketData(data)

                try {
                    regularPrinter?.sendData(Printer.PARAM_DEFAULT)
                } catch (sendEx: Epos2Exception) {
                    val errStatus = sendEx.errorStatus
                    if ((errStatus == Epos2Exception.ERR_DISCONNECT
                                || errStatus == Epos2Exception.ERR_CONNECT
                                || errStatus == Epos2Exception.ERR_PROCESSING)
                        && lastRegularTarget != null) {
                        android.util.Log.w(TAG, "[KitchenTicket] sendData failed — reconnecting and retrying")
                        disconnectRegularPrinterInternal()
                        Thread.sleep(300)
                        val printerSeries = getPrinterSeries(lastRegularSeries ?: "TM_M30")
                        val langModel    = getLanguageModel(lastRegularLang ?: "MODEL_ANK")
                        val normTarget   = normalizeTarget(lastRegularTarget!!)
                        regularPrinter = Printer(printerSeries, langModel, context)
                        regularPrinter?.setReceiveEventListener(receiveListener)
                        try {
                            regularPrinter?.connect(normTarget, Printer.PARAM_DEFAULT)
                        } catch (connEx: Epos2Exception) {
                            if (normTarget != lastRegularTarget) {
                                regularPrinter?.connect(lastRegularTarget!!, Printer.PARAM_DEFAULT)
                            } else throw connEx
                        }
                        buildKitchenTicketData(data)
                        regularPrinter?.sendData(Printer.PARAM_DEFAULT)
                    } else {
                        throw sendEx
                    }
                }

                android.util.Log.d(TAG, "[KitchenTicket] Sent — disconnecting (Epson recommended pattern)")
                disconnectRegularPrinterInternal()

                mainHandler.post {
                    channel.invokeMethod("onPrintComplete", mapOf(
                        "success" to true,
                        "printerType" to "regular",
                        "message" to "Kitchen ticket printed successfully"
                    ))
                }
                mainHandler.post { result.success(mapOf("status" to "printed")) }

            } catch (e: Exception) {
                android.util.Log.e(TAG, "[KitchenTicket] Failed", e)
                regularPrinter?.clearCommandBuffer()
                mainHandler.post {
                    result.error("PRINT_ERROR", e.message, getErrorDetails(e))
                }
            }
            } // synchronized(printerLock)
        }.start()
    }

    /**
     * Build receipt print data from Flutter data map
     */
    private fun buildReceiptData(data: Map<String, Any>) {
        regularPrinter?.let { printer ->
            try {
                // Clear any stale commands from previous print job (Epson SDK requirement)
                // Without this, leftover data (e.g. from a test print) appends to the next job
                // and causes DOUBLE PRINTING (both receipts sent in one sendData() call).
                printer.clearCommandBuffer()
                // Add text language (CRITICAL - must be first!)
                printer.addTextLang(Printer.LANG_EN)

                // Logo image (org logo, printed centered before store name)
                val logoBase64 = data["logoBase64"] as? String
                if (logoBase64 != null && logoBase64.isNotEmpty()) {
                    try {
                        val bytes = android.util.Base64.decode(logoBase64, android.util.Base64.DEFAULT)
                        val bitmap = android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                        if (bitmap != null && bitmap.width > 0) {
                            // Scale logo to fit within 384×120 (matches web: aspect-ratio preserved, max 120px tall)
                            val maxLogoW = 384
                            val maxLogoH = 120
                            val logoScaleRatio = minOf(maxLogoW.toDouble() / bitmap.width, maxLogoH.toDouble() / bitmap.height)
                            val scaledLogoW = (bitmap.width * logoScaleRatio).toInt().coerceAtLeast(1)
                            val scaledLogoH = (bitmap.height * logoScaleRatio).toInt().coerceAtLeast(1)
                            val scaledBitmap = android.graphics.Bitmap.createScaledBitmap(
                                bitmap, scaledLogoW, scaledLogoH, true
                            )
                            printer.addTextAlign(Printer.ALIGN_CENTER)
                            printer.addImage(
                                scaledBitmap, 0, 0, scaledBitmap.width, scaledBitmap.height,
                                Printer.COLOR_1, Printer.MODE_MONO, Printer.HALFTONE_DITHER,
                                Printer.PARAM_DEFAULT.toDouble(), Printer.COMPRESS_AUTO
                            )
                            printer.addFeedLine(1)
                        }
                    } catch (logoEx: Exception) {
                        android.util.Log.w(TAG, "Logo printing skipped (non-critical): ${logoEx.message}")
                    }
                }

                // Center alignment for header
                printer.addTextAlign(Printer.ALIGN_CENTER)
                
                // Store/Brand Name
                val storeName = data["storeName"] as? String ?: "THE STORE"
                printer.addTextSize(2, 2)
                printer.addText("$storeName\n")
                printer.addTextSize(1, 1)
                printer.addText("$LINE\n")

                // 2. VAT, Branch, Address
                val vatNumber = data["vatNumber"] as? String
                val branchName = data["branchName"] as? String
                val storeAddress = data["storeAddress"] as? String
                
                printer.addTextAlign(Printer.ALIGN_LEFT)
                if (!vatNumber.isNullOrEmpty()) printer.addText(" VAT: $vatNumber\n")
                if (!branchName.isNullOrEmpty()) printer.addText(" BRANCH: $branchName\n")
                if (!storeAddress.isNullOrEmpty()) printer.addText(" ADDRESS: $storeAddress\n")

                printer.addText("$LINE\n")
                printer.addTextAlign(Printer.ALIGN_CENTER)
                printer.addText("SIMPLIFIED TAX INVOICE\n")
                printer.addText("$LINE\n")

                // 3. Order Info
                // ORDER #0005          INVOICE #0253 (Layout)
                printer.addTextAlign(Printer.ALIGN_LEFT)
                val orderNumber = data["orderNumber"] as? String ?: "N/A"
                val invoiceNumber = data["invoiceNumber"] as? String ?: ""
                
                // Use fixed width for left side to push Invoice # to right
                var orderLine = "ORDER #$orderNumber"
                if (invoiceNumber.isNotEmpty()) {
                    val spaces = INNER_WIDTH - orderLine.length - "INVOICE #$invoiceNumber".length
                    if (spaces > 0) {
                        orderLine += " ".repeat(spaces) + "INVOICE #$invoiceNumber"
                    } else {
                        orderLine += "  INVOICE #$invoiceNumber"
                    }
                }
                printer.addText(" $orderLine \n")

                val tableNumber = data["tableNumber"] as? String ?: "N/A"
                val orderType = data["orderType"] as? String ?: "DINE IN"
                printer.addText(" $orderType - TABLE: $tableNumber \n")
                
                val date = data["date"] as? String ?: ""
                val time = data["time"] as? String ?: ""
                printer.addText(" $date $time \n")
                
                val customerName = data["customerName"] as? String ?: "Guest Customer"
                printer.addText(" CUSTOMER: $customerName \n")
                printer.addText("$LINE\n")

                fun receiptMoney(value: Double): String {
                    val safeValue = if (value.isFinite()) value else 0.0
                    return String.format(Locale.US, "SAR %.2f", safeValue)
                }
                fun receiptSignedMoney(value: Double): String {
                    val safeValue = if (value.isFinite()) value else 0.0
                    return String.format(Locale.US, "%sSAR %.2f", if (safeValue < 0) "-" else "", kotlin.math.abs(safeValue))
                }
                fun receiptLine(label: String, amount: String): String {
                    val spaces = INNER_WIDTH - label.length - amount.length
                    return if (spaces >= 1) {
                        " $label${" ".repeat(spaces)}$amount \n"
                    } else {
                        " $label\n ${" ".repeat((INNER_WIDTH - amount.length).coerceAtLeast(0))}$amount \n"
                    }
                }
                fun receiptAmountLine(label: String, value: Double): String = receiptLine(label, receiptMoney(value))

                // 4. Items Header
                printer.addText(String.format(Locale.US, " %-22s %3s %9s %9s \n", "Item", "Qty", "Price", "Total"))
                printer.addText("$LINE\n")
                
                // 5. Items List
                val items = data["items"] as? List<Map<String, Any>>
                
                // Validate items list is not empty
                if (items.isNullOrEmpty()) {
                    printer.addTextAlign(Printer.ALIGN_CENTER)
                    printer.addText("ERROR: No items in order\n")
                    printer.addFeedLine(3)
                    printer.addCut(Printer.CUT_FEED)
                    throw IllegalArgumentException("Cannot print receipt: items list is empty")
                }
                
                // Group items: active first, then cancelled below
                val activeItems = items.filter { (it["status"] as? String)?.lowercase() != "cancelled" }
                val cancelledItems = items.filter { (it["status"] as? String)?.lowercase() == "cancelled" }
                val isFullyCancelled = activeItems.isEmpty() && cancelledItems.isNotEmpty()

                var subtotal = 0.0
                for (item in activeItems) {
                    val itemName = item["name"] as? String ?: ""
                    val quantity = (item["quantity"] as? Number)?.toInt() ?: 1
                    val price = (item["price"] as? Number)?.toDouble() ?: 0.0
                    val total = quantity * price
                    subtotal += total
                    
                    val nameLimit = 22
                    if (itemName.length > nameLimit) {
                        printer.addText(" $itemName\n")
                        printer.addText(String.format(Locale.US, " %-22s %3d %9s %9s \n", "", quantity, formatAmount(price), formatAmount(total)))
                    } else {
                        printer.addText(String.format(Locale.US, " %-22s %3d %9s %9s \n", itemName, quantity, formatAmount(price), formatAmount(total)))
                    }
                }

                // Print cancelled items grouped below active items
                if (cancelledItems.isNotEmpty()) {
                    printer.addText("$LINE\n")
                    printer.addTextAlign(Printer.ALIGN_CENTER)
                    printer.addText("Cancelled Items\n")
                    printer.addTextAlign(Printer.ALIGN_LEFT)
                    printer.addText("$LINE\n")
                    for (item in cancelledItems) {
                        val itemName = item["name"] as? String ?: ""
                        val quantity = (item["quantity"] as? Number)?.toInt() ?: 1
                        val price = (item["price"] as? Number)?.toDouble() ?: 0.0
                        val total = quantity * price
                        
                        val nameLimit = 22
                        if (itemName.length > nameLimit) {
                            printer.addText(" $itemName\n")
                            printer.addText(String.format(Locale.US, " %-22s %3d %9s %9s \n", "", quantity, formatAmount(price), formatAmount(total)))
                        } else {
                            printer.addText(String.format(Locale.US, " %-22s %3d %9s %9s \n", itemName, quantity, formatAmount(price), formatAmount(total)))
                        }
                    }
                }
                
                printer.addText("$LINE\n")
                
                // 6. Totals & Footer
                val netAmount = data["netAmount"] as? Double ?: 0.0
                val tax = data["tax"] as? Double ?: 0.0
                val total = data["total"] as? Double ?: 0.0
                val discount = (data["discount"] as? Number)?.toDouble() ?: 0.0
                val adjustmentAmount = (data["adjustmentAmount"] as? Number)?.toDouble() ?: 0.0
                val tableCharge = (data["tableCharge"] as? Number)?.toDouble() ?: 0.0
                // Use backend-provided total as the authoritative base so the receipt is
                // always correct regardless of whether item prices are stored as net
                // (pre-tax, as in Jan 1-9 orders) or tax-inclusive (newer orders).
                // total from Flutter = total_amt + tableCharge + adjustment, so subtract extras
                // here because the code below adds it back explicitly.
                var grandTotal = if (total > 0.0) {
                    total - adjustmentAmount - tableCharge
                } else {
                    // Fallback: sum items minus discount (should not be needed in practice)
                    var sum = 0.0
                    for (gItem in items) {
                        if ((gItem["status"] as? String)?.lowercase() != "cancelled") {
                            val gQty = (gItem["quantity"] as? Number)?.toDouble() ?: 1.0
                            val gPrice = (gItem["price"] as? Number)?.toDouble() ?: 0.0
                            sum += gQty * gPrice
                        }
                    }
                    maxOf(0.0, sum - discount)
                }

                if (!isFullyCancelled) {

                    
                    printer.addTextAlign(Printer.ALIGN_CENTER)
                    printer.addText("ORDER SUMMARY\n")
                    printer.addTextAlign(Printer.ALIGN_LEFT)

                    printer.addText(receiptAmountLine("Subtotal", subtotal))
                    
                    if (discount > 0.0) {
                        val discountPercent = if (subtotal > 0.0) (discount / subtotal) * 100.0 else 0.0
                        val discountLabel = if (discountPercent > 0.0) {
                            "Discount (${String.format(Locale.US, "%.0f", discountPercent)}%)"
                        } else {
                            "Discount"
                        }
                        printer.addText(receiptLine(discountLabel, receiptSignedMoney(-discount)))
                    }
                    printer.addText("$LINE\n")

                    printer.addText(receiptAmountLine("Net Amount", netAmount))
                    printer.addText(receiptAmountLine("Tax", tax))

                    @Suppress("UNCHECKED_CAST")
                    val taxBreakdown = data["taxBreakdown"] as? Map<String, Double>
                    if (taxBreakdown != null && taxBreakdown.isNotEmpty()) {
                        val entries = taxBreakdown.entries.sortedWith(
                            compareBy<Map.Entry<String, Double>> {
                                val upperName = it.key.uppercase(Locale.US)
                                if (upperName.contains("VAT") || upperName.contains("GST")) 0 else 1
                            }.thenBy { it.key.uppercase(Locale.US) }
                        )
                        entries.forEachIndexed { index, entry ->
                            val connector = if (index == entries.size - 1) "  └─ " else "  ├─ "
                            printer.addText(receiptAmountLine("$connector${entry.key}", entry.value))
                        }
                    } else {
                        printer.addText(receiptAmountLine("  └─ VAT", tax))
                    }
                    printer.addText("$LINE\n")
                    

                    // Total Amount BEFORE adjustment
                    val totalBeforeAdjustment = grandTotal
                    printer.addText(receiptAmountLine("Total Amount", totalBeforeAdjustment))
                    
                    if (tableCharge > 0.0) {
                        printer.addText(receiptAmountLine("Table Charges", tableCharge))
                        grandTotal += tableCharge
                    }

                    // Adjustment (if any)
                    if (adjustmentAmount != 0.0) {
                        printer.addText(receiptLine("Addition", receiptSignedMoney(adjustmentAmount)))
                        grandTotal += adjustmentAmount
                    }
                }

                if (isFullyCancelled) {
                    // Fully cancelled: show total paid amount then refund amount
                    val totalPaid = (data["totalPaidAmount"] as? Number)?.toDouble() ?: 0.0
                    val refundAmount = (data["refundAmount"] as? Number)?.toDouble() ?: totalPaid
                    printer.addText(receiptAmountLine("Total Paid", totalPaid))
                    printer.addText(receiptAmountLine("Refund Amount", refundAmount))
                    
                    val paymentMethod = (data["paymentMethod"] as? String)?.uppercase(Locale.US) ?: ""
                    if (paymentMethod.isNotEmpty()) {
                        printer.addText(receiptLine("Payment Method", paymentMethod))
                    }
                }

                // GRAND TOTAL: always the full product total (never reduced by payments)
                // For fully cancelled orders: 0.00 (nothing owed)
                printer.addText("$DOUBLE_LINE\n")
                printer.addText(receiptAmountLine("GRAND TOTAL", if (isFullyCancelled) 0.0 else grandTotal))
                printer.addText("$DOUBLE_LINE\n")
                
                if (!isFullyCancelled) {
                    val explicitPaidAmount = (data["paidAmount"] as? Number)?.toDouble() ?: 0.0
                    val totalPaid = (data["totalPaidAmount"] as? Number)?.toDouble() ?: 0.0
                    val paymentStatus = (data["paymentStatus"] as? String)?.uppercase(Locale.US) ?: ""
                    val paymentMethod = (data["paymentMethod"] as? String)?.uppercase(Locale.US) ?: ""
                    val paidAmount = when {
                        explicitPaidAmount > 0.0 -> explicitPaidAmount
                        totalPaid > 0.0 -> totalPaid
                        paymentStatus.equals("PAID", ignoreCase = true) -> grandTotal
                        else -> 0.0
                    }
                    val remaining = (grandTotal - paidAmount).coerceAtLeast(0.0)
                    
                    if (paidAmount > 0.0) {
                        printer.addText(receiptAmountLine("Paid", paidAmount))
                    }
                    if (remaining > 0.0) {
                        printer.addText(receiptAmountLine("Remaining", remaining))
                    }
                    if (paidAmount > 0.0 || remaining > 0.0) {
                        printer.addText("$LINE\n")
                    }
                    if (paymentStatus.isNotEmpty()) {
                        printer.addText(receiptLine("Payment Status", paymentStatus))
                    }
                    if (paymentMethod.isNotEmpty()) {
                        printer.addText(receiptLine("Payment Method", paymentMethod))
                    }
                    if (paymentStatus.isNotEmpty() || paymentMethod.isNotEmpty()) {
                        printer.addText("$LINE\n")
                    }
                    
                    @Suppress("UNCHECKED_CAST")
                    val paymentDistribution = data["paymentDistribution"] as? List<Map<String, Any>>
                    if (!paymentDistribution.isNullOrEmpty() && paymentDistribution.size > 1) {
                        printer.addText("Payment Distribution:\n")
                        for (dist in paymentDistribution) {
                            val method = (dist["method"] as? String)?.lowercase(Locale.US) ?: "Cash"
                            val distAmount = (dist["amount"] as? Number)?.toDouble() ?: 0.0
                            printer.addText(receiptAmountLine("  -> $method", distAmount))
                        }
                        printer.addText("$LINE\n")
                    }
                }

                if (!isFullyCancelled) {
                    // Refund info — informational only, does NOT change grand total
                    val refundAmount = (data["refundAmount"] as? Number)?.toDouble() ?: 0.0
                    if (refundAmount > 0.0) {
                        printer.addText(receiptAmountLine("Refund:", refundAmount))
                        printer.addText("$LINE\n")
                    }
                }

                // QR Code — printed above the footer text.
                printer.addFeedLine(1)
                printer.addTextAlign(Printer.ALIGN_CENTER)
                val qrCodeData = data["qrCodeData"] as? String
                if (qrCodeData != null && qrCodeData.isNotEmpty()) {
                    try {
                        val qrBytes = android.util.Base64.decode(qrCodeData, android.util.Base64.DEFAULT)
                        val qrBitmap = android.graphics.BitmapFactory.decodeByteArray(qrBytes, 0, qrBytes.size)
                        if (qrBitmap != null && qrBitmap.width > 0) {
                            // Scale to 120×120 matching web QR size
                            val qrSize = 120
                            val scaledQr = android.graphics.Bitmap.createScaledBitmap(qrBitmap, qrSize, qrSize, false)
                            printer.addTextAlign(Printer.ALIGN_CENTER)
                            printer.addImage(
                                scaledQr, 0, 0, scaledQr.width, scaledQr.height,
                                Printer.COLOR_1, Printer.MODE_MONO, Printer.HALFTONE_THRESHOLD,
                                Printer.PARAM_DEFAULT.toDouble(), Printer.COMPRESS_AUTO
                            )
                        }
                    } catch (qrEx: Exception) {
                        android.util.Log.w(TAG, "QR image printing skipped (non-critical): ${qrEx.message}")
                    }
                }

                // Footer text stays below the QR image.
                printer.addFeedLine(1)
                printer.addTextAlign(Printer.ALIGN_CENTER)
                printer.addText("THANK YOU\n")
                printer.addText("$time $date\n")
                
                // Barcode (optional, keep if it was there)
                val barcode = data["barcode"] as? String
                if (barcode != null) {
                    printer.addFeedLine(1)
                    printer.addBarcode(
                        barcode,
                        Printer.BARCODE_CODE39,
                        Printer.HRI_BELOW,
                        Printer.FONT_A,
                        2,
                        100
                    )
                }
                
                // Open drawer logic
                val openDrawer = data["openDrawer"] as? Boolean ?: false
                if (openDrawer) {
                    printer.addPulse(Printer.PARAM_DEFAULT, Printer.PARAM_DEFAULT)
                }
                
                // Cut paper
                printer.addCut(Printer.CUT_FEED)
                
            } catch (e: Exception) {
                printer.clearCommandBuffer()
                throw e
            }
        }
    }

    /**
     * Build KDS order data for kitchen display
     */
    private fun cleanItemString(s: String): String {
        var clean = s.lowercase()
        clean = clean.replace(Regex("^\\d+\\.\\s*"), "")
        if (clean.startsWith("+")) {
            clean = clean.substring(1)
        }
        return clean.trim()
    }

    private fun buildKDSData(data: Map<String, Any>) {
        kdsPrinter?.let { printer ->
            try {
                // Clear stale commands before building new KDS job (Epson SDK requirement)
                printer.clearCommandBuffer()
                // Add text language
                printer.addTextLang(LFCPrinter.LANG_EN)
                
                // Center alignment for header
                printer.addTextAlign(LFCPrinter.ALIGN_CENTER)

                // Store name at top — matches web kdsBridgePayload.js
                val storeName = data["storeName"] as? String ?: ""
                if (storeName.isNotEmpty()) {
                    printer.addTextSize(2, 2)
                    printer.addText("$storeName\n")
                    printer.addTextSize(1, 1)
                }

                // Header
                printer.addText("KITCHEN ORDER TICKET\n")

                // Pad order number to 4 digits (web: "ORDER #0001")
                val rawOrderNumber = data["orderNumber"] as? String ?: "N/A"
                val orderNumber = rawOrderNumber.toIntOrNull()
                    ?.toString()?.padStart(4, '0')
                    ?: rawOrderNumber
                printer.addText("ORDER #$orderNumber\n")

                printer.addText("${"=".repeat(48)}\n")

                // Left-align order info section — matches web format
                printer.addTextAlign(LFCPrinter.ALIGN_LEFT)
                // Date-Time
                val time = data["time"] as? String ?: ""
                val date = data["date"] as? String ?: "" 
                printer.addText("DATE-TIME: $date $time\n")
                
                printer.addText("${"=".repeat(48)}\n")

                val tableNumber = data["tableNumber"] as? String
                if (tableNumber != null && tableNumber != "—") {
                     printer.addText("TABLE: $tableNumber\n")
                }

                val orderNotes = data["orderNotes"] as? String
                if (!orderNotes.isNullOrBlank() && orderNotes != "N/A") {
                    printer.addText("ORDER NOTE: $orderNotes\n")
                }
                
                printer.addText("${"-".repeat(48)}\n")

                // Left alignment for items
                printer.addTextAlign(LFCPrinter.ALIGN_LEFT)

                // Items column header
                printer.addText(String.format("%-44s%4s\n", "ITEM", "QTY"))
                printer.addText("${"-".repeat(48)}\n")

                val items = data["items"] as? List<Map<String, Any>>
                if (items == null || items.isEmpty()) {
                   printer.addTextAlign(LFCPrinter.ALIGN_CENTER)
                   printer.addText("NO ITEMS\n")
                   printer.addTextAlign(LFCPrinter.ALIGN_LEFT)
                } else {
                    items.forEach { item ->
                        val quantity = item["quantity"] as? Int ?: 1
                        val itemName = item["name"] as? String ?: "Item"

                        if (itemName.startsWith("+")) {
                            // Modifier row — indented, with qty
                            printer.addText(String.format("  %-42s%4d\n", itemName, quantity))
                        } else {
                            // Main product row — truncate long names to prevent wrapping
                            val truncated = if (itemName.length > 44) itemName.substring(0, 43) + "~" else itemName
                            printer.addText(String.format("%-44s%4d\n", truncated, quantity))
                        }

                        val notes = item["notes"] as? String
                        if (notes != null && notes.isNotEmpty()) {
                            val cleanedItem = cleanItemString(itemName)
                            val cleanedNote = cleanItemString(notes)
                            if (cleanedItem != cleanedNote) {
                                printer.addText("*** $notes ***\n")
                            }
                        }
                    }
                }

                // Footer
                printer.addTextAlign(LFCPrinter.ALIGN_CENTER)
                printer.addText("${"-".repeat(48)}\n")
                
                printer.addText("PRINTED FROM KITCHEN DISPLAY SYSTEM\n")
                printer.addText("$time\n")
                
                // Priority indicator
                val priority = data["priority"] as? String
                if (priority != null && priority.equals("high", ignoreCase = true)) {
                    printer.addTextSize(2, 2)
                    printer.addText("*** URGENT ***\n")
                    printer.addTextSize(1, 1)
                }
                
                // Cut paper
                printer.addCut(LFCPrinter.CUT_FEED)
                
            } catch (e: Exception) {
                printer.clearCommandBuffer()
                throw e
            }
        }
    }

    /**
     * Build kitchen ticket data for regular ESC/POS thermal printer.
     *
     * Produces the same visual layout as buildKDSData() (KDS ticket format)
     * but using regularPrinter (Printer class) instead of kdsPrinter (LFCPrinter).
     * This allows any connected Epson thermal printer to print kitchen tickets.
     */
    private fun buildKitchenTicketData(data: Map<String, Any>) {
        regularPrinter?.let { printer ->
            try {
                printer.clearCommandBuffer()
                printer.addTextLang(Printer.LANG_EN)

                // --- Header ---
                printer.addTextAlign(Printer.ALIGN_CENTER)

                // Store name at top
                val storeName = data["storeName"] as? String ?: ""
                if (storeName.isNotEmpty()) {
                    printer.addTextSize(2, 2)
                    printer.addTextStyle(Printer.FALSE, Printer.FALSE, Printer.TRUE, Printer.COLOR_1)
                    printer.addText("$storeName\n")
                    printer.addTextSize(1, 1)
                    printer.addTextStyle(Printer.FALSE, Printer.FALSE, Printer.FALSE, Printer.COLOR_1)
                }

                printer.addText("KITCHEN ORDER TICKET\n")

                val rawOrderNumber = data["orderNumber"] as? String ?: "N/A"
                val orderNumber = rawOrderNumber.toIntOrNull()
                    ?.toString()?.padStart(4, '0')
                    ?: rawOrderNumber
                printer.addTextStyle(Printer.FALSE, Printer.FALSE, Printer.TRUE, Printer.COLOR_1)
                printer.addText("ORDER #$orderNumber\n")
                printer.addTextStyle(Printer.FALSE, Printer.FALSE, Printer.FALSE, Printer.COLOR_1)

                printer.addText("${"=".repeat(48)}\n")

                // Left-align order info section
                printer.addTextAlign(Printer.ALIGN_LEFT)
                val date = data["date"] as? String ?: ""
                val time = data["time"] as? String ?: ""
                printer.addTextStyle(Printer.FALSE, Printer.FALSE, Printer.TRUE, Printer.COLOR_1)
                printer.addText("DATE-TIME: $date $time\n")
                printer.addTextStyle(Printer.FALSE, Printer.FALSE, Printer.FALSE, Printer.COLOR_1)
                printer.addText("${"=".repeat(48)}\n")

                val tableNumber = data["tableNumber"] as? String
                if (!tableNumber.isNullOrEmpty() && tableNumber != "—") {
                    printer.addTextStyle(Printer.FALSE, Printer.FALSE, Printer.TRUE, Printer.COLOR_1)
                    printer.addText("TABLE: $tableNumber\n")
                    printer.addTextStyle(Printer.FALSE, Printer.FALSE, Printer.FALSE, Printer.COLOR_1)
                }

                val orderNotes = data["orderNotes"] as? String
                if (!orderNotes.isNullOrBlank() && orderNotes != "N/A") {
                    printer.addText("ORDER NOTE: $orderNotes\n")
                }

                // --- Items ---
                printer.addTextAlign(Printer.ALIGN_LEFT)
                printer.addText(String.format("%-44s%4s\n", "ITEM", "QTY"))
                printer.addText("${"-".repeat(48)}\n")

                val items = data["items"] as? List<Map<String, Any>>
                if (items.isNullOrEmpty()) {
                    printer.addTextAlign(Printer.ALIGN_CENTER)
                    printer.addText("NO ITEMS\n")
                    printer.addTextAlign(Printer.ALIGN_LEFT)
                } else {
                    items.forEach { item ->
                        val quantity = item["quantity"] as? Int ?: 1
                        val itemName = item["name"] as? String ?: "Item"
                        val notes    = item["notes"] as? String

                        if (itemName.startsWith("+")) {
                            // Modifier row — indented, with qty
                            printer.addText(String.format("  %-42s%4d\n", itemName, quantity))
                        } else {
                            // Main product row — bold, truncate long names
                            printer.addTextStyle(Printer.FALSE, Printer.FALSE, Printer.TRUE, Printer.COLOR_1)
                            val truncated = if (itemName.length > 44) itemName.substring(0, 43) + "~" else itemName
                            printer.addText(String.format("%-44s%4d\n", truncated, quantity))
                            printer.addTextStyle(Printer.FALSE, Printer.FALSE, Printer.FALSE, Printer.COLOR_1)
                        }

                        if (!notes.isNullOrEmpty()) {
                            val cleanedItem = cleanItemString(itemName)
                            val cleanedNote = cleanItemString(notes)
                            if (cleanedItem != cleanedNote) {
                                printer.addText("*** $notes ***\n")
                            }
                        }
                    }
                }

                // --- Footer ---
                printer.addTextAlign(Printer.ALIGN_CENTER)
                printer.addText("${"-".repeat(48)}\n")
                printer.addText("PRINTED FROM KITCHEN DISPLAY SYSTEM\n")
                printer.addText("$time\n")

                val priority = data["priority"] as? String
                if (priority != null && priority.equals("high", ignoreCase = true)) {
                    printer.addTextSize(2, 2)
                    printer.addText("*** URGENT ***\n")
                    printer.addTextSize(1, 1)
                }

                printer.addCut(Printer.CUT_FEED)

            } catch (e: Exception) {
                printer.clearCommandBuffer()
                throw e
            }
        }
    }

    /**
     * Get printer status
     */
    fun getPrinterStatus(printerType: String, result: MethodChannel.Result) {
        Thread {
            try {
                when (printerType.lowercase()) {
                    "kds" -> {
                        if (kdsPrinter == null) {
                            mainHandler.post {
                                result.error("NOT_CONNECTED", "KDS printer not connected", null)
                            }
                            return@Thread
                        }
                        
                        val status = kdsPrinter?.status
                        mainHandler.post {
                            result.success(mapOf(
                                "printerType" to "kds",
                                "connection" to status?.connection,
                                "online" to status?.online,
                                "coverOpen" to status?.coverOpen,
                                "paper" to status?.paper,
                                "paperFeed" to status?.paperFeed,
                                "errorStatus" to status?.errorStatus
                            ))
                        }
                    }
                    else -> {
                        if (regularPrinter == null) {
                            mainHandler.post {
                                result.error("NOT_CONNECTED", "Regular printer not connected", null)
                            }
                            return@Thread
                        }
                        
                        val status = regularPrinter?.status
                        mainHandler.post {
                            result.success(mapOf(
                                "printerType" to "regular",
                                "connection" to status?.connection,
                                "online" to status?.online,
                                "coverOpen" to status?.coverOpen,
                                "paper" to status?.paper,
                                "paperFeed" to status?.paperFeed,
                                "errorStatus" to status?.errorStatus,
                                "adapter" to status?.adapter,
                                "batteryLevel" to status?.batteryLevel
                            ))
                        }
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Get status failed", e)
                mainHandler.post {
                    result.error("STATUS_ERROR", e.message, null)
                }
            }
        }.start()
    }

    /**
     * Test print - Simple test page
     */
    fun testPrint(printerType: String, result: MethodChannel.Result) {
        Thread {
            try {
                when (printerType.lowercase()) {
                    "kds" -> testPrintKDS(result)
                    else -> testPrintRegular(result)
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Test print failed", e)
                mainHandler.post {
                    result.error("TEST_PRINT_ERROR", e.message, null)
                }
            }
        }.start()
    }

    /**
     * Test print for regular printer
     */
    private fun testPrintRegular(result: MethodChannel.Result) {
        if (regularPrinter == null) {
            mainHandler.post {
                result.error("NOT_CONNECTED", "Regular printer not connected", null)
            }
            return
        }

        try {
            regularPrinter?.clearCommandBuffer()
            regularPrinter?.addTextLang(Printer.LANG_EN)
            regularPrinter?.addTextAlign(Printer.ALIGN_CENTER)
            regularPrinter?.addTextSize(2, 2)
            regularPrinter?.addText("TEST PRINT\n")
            regularPrinter?.addTextSize(1, 1)
            regularPrinter?.addText("${"-".repeat(48)}\n")
            regularPrinter?.addText("Epson Printer\n")
            regularPrinter?.addText("Connection Successful\n")
            regularPrinter?.addText("${"-".repeat(48)}\n")
            regularPrinter?.addFeedLine(2)
            regularPrinter?.addText("${java.util.Date()}\n")
            regularPrinter?.addFeedLine(2)
            regularPrinter?.addCut(Printer.CUT_FEED)
            
            regularPrinter?.sendData(Printer.PARAM_DEFAULT)
            
            android.util.Log.d(TAG, "Test print sent (regular)")
            mainHandler.post { result.success(mapOf("status" to "queued")) }
            
        } catch (e: Exception) {
            regularPrinter?.clearCommandBuffer()
            throw e
        }
    }

    /**
     * Test print for KDS printer
     */
    private fun testPrintKDS(result: MethodChannel.Result) {
        if (kdsPrinter == null) {
            mainHandler.post {
                result.error("NOT_CONNECTED", "KDS printer not connected", null)
            }
            return
        }

        try {
            kdsPrinter?.clearCommandBuffer()
            kdsPrinter?.addTextLang(LFCPrinter.LANG_EN)
            kdsPrinter?.addTextAlign(LFCPrinter.ALIGN_CENTER)
            kdsPrinter?.addTextSize(2, 2)
            kdsPrinter?.addText("KDS TEST\n")
            kdsPrinter?.addTextSize(1, 1)
            kdsPrinter?.addText("${"-".repeat(30)}\n")
            kdsPrinter?.addText("Kitchen Display System\n")
            kdsPrinter?.addText("Connection Successful\n")
            kdsPrinter?.addText("${"-".repeat(30)}\n")
            kdsPrinter?.addFeedLine(2)
            kdsPrinter?.addText("${java.util.Date()}\n")
            kdsPrinter?.addFeedLine(2)
            kdsPrinter?.addCut(LFCPrinter.CUT_FEED)
            
            kdsPrinter?.sendLFCData(LFCPrinter.PARAM_DEFAULT, 9999)
            
            android.util.Log.d(TAG, "Test print sent (KDS)")
            mainHandler.post { result.success(mapOf("status" to "queued")) }
            
        } catch (e: Exception) {
            kdsPrinter?.clearCommandBuffer()
            throw e
        }
    }

    /**
     * Regular printer receive listener - callbacks for print completion
     */
    private val receiveListener = ReceiveListener { printerObj, code, status, printJobId ->
        android.util.Log.d(TAG, "Receive callback - code: $code, printJobId: $printJobId")
        
        mainHandler.post {
            try {
                when (code) {
                    Epos2CallbackCode.CODE_SUCCESS -> {
                        channel.invokeMethod("onPrintComplete", mapOf(
                            "success" to true,
                            "printerType" to "regular",
                            "message" to "Print completed successfully",
                            "printJobId" to printJobId
                        ))
                    }
                    else -> {
                        val errorMsg = getEpos2ErrorName(code)
                        channel.invokeMethod("onPrintComplete", mapOf(
                            "success" to false,
                            "printerType" to "regular",
                            "error" to errorMsg,
                            "errorCode" to code,
                            "status" to parseStatus(status)
                        ))
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Error in receive callback", e)
            }
            // REMOVED: clearCommandBuffer() that ran on the main thread without
            // holding printerLock.  It raced with the NEXT print job's
            // build*Data() on a background thread, silently wiping its commands
            // and causing empty / lost prints.  Each build*Data() already calls
            // clearCommandBuffer() as its first action, so this was redundant.
        }
    }

    /**
     * KDS printer send complete listener
     * Callback signature: onSendComplete(LFCPrinter, int jobNumber, int code, LFCPrinterStatusInfo status)
     */
    private val lfcSendCompleteListener = LFCSendCompleteListener { printerObj, jobNumber, code, status ->
        android.util.Log.d(TAG, "LFC send complete - code: $code, jobNumber: $jobNumber")
        
        mainHandler.post {
            try {
                when (code) {
                    Epos2CallbackCode.CODE_SUCCESS -> {
                        channel.invokeMethod("onPrintComplete", mapOf(
                            "success" to true,
                            "printerType" to "kds",
                            "message" to "KDS order sent successfully",
                            "jobNumber" to jobNumber
                        ))
                    }
                    else -> {
                        val errorMsg = getEpos2ErrorName(code)
                        channel.invokeMethod("onPrintComplete", mapOf(
                            "success" to false,
                            "printerType" to "kds",
                            "error" to errorMsg,
                            "errorCode" to code,
                            "jobNumber" to jobNumber,
                            "status" to if (status != null) parseLFCStatus(status) else null
                        ))
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Error in LFC send callback", e)
            }
        }
    }

    /**
     * Parse regular printer status info
     */
    private fun parseStatus(status: PrinterStatusInfo): Map<String, Any> {
        return mapOf(
            "connection" to status.connection,
            "online" to status.online,
            "coverOpen" to status.coverOpen,
            "paper" to status.paper,
            "paperFeed" to status.paperFeed,
            "errorStatus" to status.errorStatus
        )
    }

    /**
     * Parse LFC printer status info
     */
    private fun parseLFCStatus(status: LFCPrinterStatusInfo): Map<String, Any> {
        return mapOf(
            "connection" to status.connection,
            "online" to status.online,
            "coverOpen" to status.coverOpen,
            "paper" to status.paper,
            "paperFeed" to status.paperFeed,
            "errorStatus" to status.errorStatus
        )
    }

    /**
     * Internal disconnect for regular printer
     */
    /**
     * Disconnect regular printer with Epson-recommended retry loop.
     *
     * The Epson SDK returns ERR_PROCESSING if the printer is still executing a
     * job (paper feed, cut, etc.).  The official sample retries disconnect()
     * in a loop with a 500 ms sleep until it succeeds or a different error
     * occurs.  Caller should hold [printerLock] when this runs on a code-path
     * that could race with a print method.
     */
    private fun disconnectRegularPrinterInternal() {
        try {
            regularPrinter?.let { printer ->
                printer.setReceiveEventListener(null)
                // Epson-recommended: retry disconnect while ERR_PROCESSING
                while (true) {
                    try {
                        printer.disconnect()
                        break  // Success
                    } catch (e: Epos2Exception) {
                        if (e.errorStatus == Epos2Exception.ERR_PROCESSING) {
                            android.util.Log.d(TAG, "disconnect: ERR_PROCESSING — retrying in ${DISCONNECT_INTERVAL}ms")
                            Thread.sleep(DISCONNECT_INTERVAL)
                        } else {
                            android.util.Log.w(TAG, "disconnect: non-processing error (${e.errorStatus}), breaking")
                            break  // Different error — stop retrying
                        }
                    } catch (e: Exception) {
                        android.util.Log.w(TAG, "disconnect: unexpected error", e)
                        break
                    }
                }
                printer.clearCommandBuffer()
                android.util.Log.d(TAG, "Regular printer disconnected")
            }
        } catch (e: Exception) {
            android.util.Log.w(TAG, "Error during regular printer disconnect", e)
        } finally {
            regularPrinter = null
        }
    }

    /**
     * Internal disconnect for KDS printer
     */
    private fun disconnectKDSPrinterInternal() {
        try {
            kdsPrinter?.let { printer ->
                printer.setSendCompleteEventListener(null)
                // Epson-recommended: retry disconnect while ERR_PROCESSING
                while (true) {
                    try {
                        printer.disconnect()
                        break  // Success
                    } catch (e: Epos2Exception) {
                        if (e.errorStatus == Epos2Exception.ERR_PROCESSING) {
                            android.util.Log.d(TAG, "KDS disconnect: ERR_PROCESSING — retrying in ${DISCONNECT_INTERVAL}ms")
                            Thread.sleep(DISCONNECT_INTERVAL)
                        } else {
                            android.util.Log.w(TAG, "KDS disconnect: non-processing error (${e.errorStatus}), breaking")
                            break  // Different error — stop retrying
                        }
                    } catch (e: Exception) {
                        android.util.Log.w(TAG, "KDS disconnect: unexpected error", e)
                        break
                    }
                }
                printer.clearCommandBuffer()
                android.util.Log.d(TAG, "KDS printer disconnected")
            }
        } catch (e: Exception) {
            android.util.Log.w(TAG, "Error during KDS printer disconnect", e)
        } finally {
            kdsPrinter = null
        }
    }

    /**
     * Cleanup all resources
     */
    fun cleanup() {
        Thread {
            try {
                synchronized(printerLock) {
                    disconnectRegularPrinterInternal()
                }
                disconnectKDSPrinterInternal()
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Cleanup error", e)
            }
        }.start()
    }

    /**
     * Get printer series constant from string
     */
    private fun getPrinterSeries(series: String): Int {
        return when (series.uppercase()) {
            "TM_M10" -> Printer.TM_M10
            "TM_M30" -> Printer.TM_M30
            "TM_M30II" -> Printer.TM_M30II
            "TM_M30III" -> Printer.TM_M30III
            "TM_P20" -> Printer.TM_P20
            "TM_P60" -> Printer.TM_P60
            "TM_P60II" -> Printer.TM_P60II
            "TM_P80" -> Printer.TM_P80
            "TM_T20" -> Printer.TM_T20
            "TM_T60" -> Printer.TM_T60
            "TM_T70" -> Printer.TM_T70
            "TM_T81" -> Printer.TM_T81
            "TM_T82" -> Printer.TM_T82
            "TM_T83" -> Printer.TM_T83
            "TM_T88" -> Printer.TM_T88
            "TM_T88VII" -> Printer.TM_T88VII
            "TM_T90" -> Printer.TM_T90
            "TM_T90KP" -> Printer.TM_T90KP
            "TM_U220" -> Printer.TM_U220
            "TM_U330" -> Printer.TM_U330
            "TM_L90" -> Printer.TM_L90
            "TM_H6000" -> Printer.TM_H6000
            else -> Printer.TM_M30 // Default fallback
        }
    }

    /**
     * Get LFC printer series constant from string
     */
    private fun getLFCPrinterSeries(series: String): Int {
        return when (series.uppercase()) {
            "TM_L90LFC" -> LFCPrinter.TM_L90LFC
            "TM_L100" -> LFCPrinter.TM_L100
            else -> LFCPrinter.TM_L100 // Default KDS printer
        }
    }

    /**
     * Get language model constant from string
     */
    private fun getLanguageModel(lang: String): Int {
        return when (lang.uppercase()) {
            "MODEL_ANK" -> Printer.MODEL_ANK
            "MODEL_JAPANESE" -> Printer.MODEL_JAPANESE
            "MODEL_CHINESE" -> Printer.MODEL_CHINESE
            "MODEL_TAIWAN" -> Printer.MODEL_TAIWAN
            "MODEL_KOREAN" -> Printer.MODEL_KOREAN
            "MODEL_THAI" -> Printer.MODEL_THAI
            "MODEL_SOUTHASIA" -> Printer.MODEL_SOUTHASIA
            else -> Printer.MODEL_ANK // Default ANK (ASCII)
        }
    }

    /**
     * Normalize target strings from discovery/manual input:
     * - Trim whitespace and drop suffixes like "|local_printer|" or "[... ]"
     * - Keep explicit ports when provided, otherwise default to TCP prefix with host
     * - Preserve TCPS/BT/USB prefixes when valid
     */
    private fun normalizeTarget(raw: String): String {
        var target = raw.trim()
        android.util.Log.d(TAG, "  [normalizeTarget] INPUT: '$raw'")

        // Remove only "|" pipe which might have been accidentally passed from UI stringification
        if (target.contains("|")) {
            val before = target
            target = target.substringBefore("|").trim()
            android.util.Log.d(TAG, "  [normalizeTarget] removed pipe: '$before' to '$target'")
        }
        
        // NEVER remove "[" since Epson SDK discovery uses [local_printer] to identify devices

        val lower = target.lowercase()
        val prefix = when {
            lower.startsWith("tcps:") -> "TCPS:"
            lower.startsWith("tcp:") -> "TCP:"
            lower.startsWith("bt:") -> "BT:"
            lower.startsWith("usb:") -> "USB:"
            else -> "TCP:"
        }
        android.util.Log.d(TAG, "  [normalizeTarget] Detected prefix: '$prefix'")

        target = when {
            lower.startsWith("tcps:") -> target.substring(5)
            lower.startsWith("tcp:") -> target.substring(4)
            lower.startsWith("bt:") -> target.substring(3)
            lower.startsWith("usb:") -> target.substring(4)
            else -> target
        }
        android.util.Log.d(TAG, "  [normalizeTarget] After prefix strip: '$target'")

        target = target.trimStart(':', '/')
        android.util.Log.d(TAG, "  [normalizeTarget] After leading chars trim: '$target'")

        // For TCP/TCPS, remove any manually appended port string
        if (prefix == "TCP:" || prefix == "TCPS:") {
            val hostPort = target.split(":")
            if (hostPort.size > 1 && hostPort[1].toIntOrNull() != null) {
                android.util.Log.d(TAG, "  [normalizeTarget] Detected port in string: '${hostPort[1]}', removing")
                target = hostPort[0]
            }
        }

        val result = "$prefix$target"
        android.util.Log.d(TAG, "  [normalizeTarget] FINAL OUTPUT: '$result'")
        return result
    }

    /**
     * Map error code to human-readable name (handles both Exception and Callback codes)
     */
    private fun getEpos2ErrorName(code: Int): String {
        // Check Epos2CallbackCode first (used in print callbacks)
        return when (code) {
            Epos2CallbackCode.CODE_SUCCESS -> "SUCCESS"
            Epos2CallbackCode.CODE_PRINTING -> "PRINTING"
            Epos2CallbackCode.CODE_ERR_AUTORECOVER -> "ERR_AUTORECOVER - Auto recoverable error"
            Epos2CallbackCode.CODE_ERR_COVER_OPEN -> "ERR_COVER_OPEN - Cover is open"
            Epos2CallbackCode.CODE_ERR_CUTTER -> "ERR_CUTTER - Cutter error"
            Epos2CallbackCode.CODE_ERR_MECHANICAL -> "ERR_MECHANICAL - Mechanical error"
            Epos2CallbackCode.CODE_ERR_EMPTY -> "ERR_EMPTY - Paper empty"
            Epos2CallbackCode.CODE_ERR_UNRECOVERABLE -> "ERR_UNRECOVERABLE - Unrecoverable error"
            Epos2CallbackCode.CODE_ERR_FAILURE -> "ERR_FAILURE - Print failure"
            Epos2CallbackCode.CODE_ERR_NOT_FOUND -> "ERR_NOT_FOUND - Device not found"
            Epos2CallbackCode.CODE_ERR_SYSTEM -> "ERR_SYSTEM - System error"
            Epos2CallbackCode.CODE_ERR_PORT -> "ERR_PORT - Port error"
            Epos2CallbackCode.CODE_ERR_TIMEOUT -> "ERR_TIMEOUT - Timeout"
            Epos2CallbackCode.CODE_ERR_JOB_NOT_FOUND -> "ERR_JOB_NOT_FOUND - Job not found"
            Epos2CallbackCode.CODE_ERR_SPOOLER -> "ERR_SPOOLER - Spooler error"
            Epos2CallbackCode.CODE_ERR_BATTERY_LOW -> "ERR_BATTERY_LOW - Battery low"
            Epos2CallbackCode.CODE_CANCELED -> "CANCELED - Print canceled"
            // Check Epos2Exception codes (used in connection/setup)
            Epos2Exception.ERR_PARAM -> "ERR_PARAM - Invalid parameter"
            Epos2Exception.ERR_CONNECT -> "ERR_CONNECT - Connection failed"
            Epos2Exception.ERR_TIMEOUT -> "ERR_TIMEOUT - Timeout"
            Epos2Exception.ERR_MEMORY -> "ERR_MEMORY - Memory error"
            Epos2Exception.ERR_ILLEGAL -> "ERR_ILLEGAL - Illegal operation"
            Epos2Exception.ERR_PROCESSING -> "ERR_PROCESSING - Processing error"
            Epos2Exception.ERR_NOT_FOUND -> "ERR_NOT_FOUND - Device not found"
            Epos2Exception.ERR_IN_USE -> "ERR_IN_USE - Device in use"
            Epos2Exception.ERR_TYPE_INVALID -> "ERR_TYPE_INVALID - Invalid type"
            Epos2Exception.ERR_DISCONNECT -> "ERR_DISCONNECT - Disconnected"
            Epos2Exception.ERR_ALREADY_OPENED -> "ERR_ALREADY_OPENED - Already opened"
            Epos2Exception.ERR_ALREADY_USED -> "ERR_ALREADY_USED - Already used"
            Epos2Exception.ERR_BOX_COUNT_OVER -> "ERR_BOX_COUNT_OVER - Box count over"
            Epos2Exception.ERR_BOX_CLIENT_OVER -> "ERR_BOX_CLIENT_OVER - Box client over"
            Epos2Exception.ERR_UNSUPPORTED -> "ERR_UNSUPPORTED - Unsupported"
            Epos2Exception.ERR_FAILURE -> "ERR_FAILURE - General failure"
            else -> "UNKNOWN_ERROR_$code"
        }
    }

    /**
     * Get detailed error information
     */
    private fun getErrorDetails(e: Exception): Map<String, Any> {
        return when (e) {
            is Epos2Exception -> mapOf(
                "errorCode" to e.errorStatus,
                "errorName" to getEpos2ErrorName(e.errorStatus),
                "message" to (e.message ?: "Unknown Epson error")
            )
            else -> mapOf(
                "message" to (e.message ?: "Unknown error"),
                "type" to e.javaClass.simpleName
            )
        }
    }
}