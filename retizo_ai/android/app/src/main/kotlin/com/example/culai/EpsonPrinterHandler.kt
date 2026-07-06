package com.example.culai

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.epson.epos2.Log

/**
 * EpsonPrinterHandler - Central manager for all Epson printer operations
 * 
 * Coordinates between Flutter and native Epson SDK functionality
 * Manages sub-handlers for discovery, printing, and status monitoring
 * 
 * Supported Methods:
 * - discoverPrinters: Find available Epson printers on network/bluetooth/USB
 * - connectPrinter: Connect to specific printer
 * - disconnectPrinter: Safely disconnect from printer
 * - printReceipt: Print standard receipt/bill
 * - printKDS: Print kitchen display order (KDS functionality)
 * - getPrinterStatus: Get current printer status
 * - testPrint: Test printer connection
 * 
 * @param context Android activity context
 * @param channel Method channel for Flutter communication
 */
class EpsonPrinterHandler(
    private val context: Context,
    private val channel: MethodChannel
) {
    private val discoveryHandler: EpsonDiscoveryHandler
    private val printHandler: EpsonPrintHandler
    
    companion object {
        private const val TAG = "EpsonPrinterHandler"
    }

    init {
        // Initialize Epson SDK logging
        try {
            Log.setLogSettings(
                context,
                Log.PERIOD_TEMPORARY,
                Log.OUTPUT_STORAGE,
                null,
                0,
                50,
                Log.LOGLEVEL_LOW
            )
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Failed to initialize Epson SDK logging", e)
        }

        // Initialize sub-handlers
        discoveryHandler = EpsonDiscoveryHandler(context, channel)
        printHandler = EpsonPrintHandler(context, channel)
    }

    /**
     * Handle method calls from Flutter
     * Routes calls to appropriate sub-handlers
     */
    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                // Discovery operations
                "discoverPrinters" -> {
                    val portType = call.argument<String>("portType") ?: "all"
                    val timeout = call.argument<Int>("timeout") ?: 10000
                    discoveryHandler.discoverPrinters(portType, timeout, result)
                }
                
                "stopDiscovery" -> {
                    discoveryHandler.stopDiscovery(result)
                }

                // Connection operations
                "connectPrinter" -> {
                    val target = call.argument<String>("target")
                    val printerType = call.argument<String>("printerType") ?: "regular"
                    val series = call.argument<String>("series") ?: "TM_M30III"
                    val lang = call.argument<String>("lang") ?: "MODEL_ANK"
                    
                    if (target == null) {
                        result.error("INVALID_ARGUMENT", "Target address is required", null)
                        return
                    }
                    
                    printHandler.connectPrinter(target, printerType, series, lang, result)
                }
                
                "disconnectPrinter" -> {
                    val printerType = call.argument<String>("printerType") ?: "regular"
                    printHandler.disconnectPrinter(printerType, result)
                }

                // Printing operations
                "printReceipt" -> {
                    val data = call.argument<Map<String, Any>>("data")
                    if (data == null) {
                        result.error("INVALID_ARGUMENT", "Print data is required", null)
                        return
                    }
                    printHandler.printReceipt(data, result)
                }
                
                "printKDS" -> {
                    val data = call.argument<Map<String, Any>>("data")
                    val jobNumber = call.argument<Int>("jobNumber") ?: 0
                    if (data == null) {
                        result.error("INVALID_ARGUMENT", "Print data is required", null)
                        return
                    }
                    printHandler.printKDS(data, jobNumber, result)
                }

                "printKitchenTicket" -> {
                    val data = call.argument<Map<String, Any>>("data")
                    if (data == null) {
                        result.error("INVALID_ARGUMENT", "Print data is required", null)
                        return
                    }
                    printHandler.printKitchenTicket(data, result)
                }
                
                "testPrint" -> {
                    val printerType = call.argument<String>("printerType") ?: "regular"
                    printHandler.testPrint(printerType, result)
                }

                // Status operations
                "getPrinterStatus" -> {
                    val printerType = call.argument<String>("printerType") ?: "regular"
                    printHandler.getPrinterStatus(printerType, result)
                }

                // Utility operations
                "getSupportedPrinters" -> {
                    getSupportedPrinters(result)
                }
                
                "getVersion" -> {
                    getSDKVersion(result)
                }

                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error handling method call: ${call.method}", e)
            result.error("EXCEPTION", e.message, e.stackTraceToString())
        }
    }

    /**
     * Get list of supported Epson printer models
     */
    private fun getSupportedPrinters(result: MethodChannel.Result) {
        val printers = listOf(
            mapOf("name" to "TM-M10", "series" to "TM_M10", "type" to "Mobile"),
            mapOf("name" to "TM-M30/M30II/M30III", "series" to "TM_M30", "type" to "Desktop"),
            mapOf("name" to "TM-P60/P60II", "series" to "TM_P60", "type" to "Mobile"),
            mapOf("name" to "TM-P80", "series" to "TM_P80", "type" to "Mobile"),
            mapOf("name" to "TM-T20", "series" to "TM_T20", "type" to "Desktop"),
            mapOf("name" to "TM-T82/T82III", "series" to "TM_T82", "type" to "Desktop"),
            mapOf("name" to "TM-T83/T83III", "series" to "TM_T83", "type" to "Desktop"),
            mapOf("name" to "TM-T88VI/T88VII", "series" to "TM_T88VII", "type" to "Desktop"),
            mapOf("name" to "TM-L90LFC (KDS)", "series" to "TM_L90LFC", "type" to "Kitchen"),
            mapOf("name" to "TM-L100 (KDS)", "series" to "TM_L100", "type" to "Kitchen"),
            mapOf("name" to "TM-U220", "series" to "TM_U220", "type" to "Impact")
        )
        result.success(printers)
    }

    /**
     * Get Epson SDK version info
     */
    private fun getSDKVersion(result: MethodChannel.Result) {
        result.success(mapOf(
            "version" to "2.36.0",
            "platform" to "Android",
            "sdk" to "ePOS SDK for Android"
        ))
    }

    /**
     * Cleanup resources when activity is destroyed
     */
    fun cleanup() {
        discoveryHandler.cleanup()
        printHandler.cleanup()
    }
}
