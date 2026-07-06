package com.example.culai

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import com.epson.epos2.discovery.Discovery
import com.epson.epos2.discovery.DiscoveryListener
import com.epson.epos2.discovery.FilterOption
import com.epson.epos2.discovery.DeviceInfo
import com.epson.epos2.Epos2Exception

/**
 * EpsonDiscoveryHandler - Manages printer discovery operations
 * 
 * Handles network/Bluetooth/USB printer discovery using Epson Discovery API
 * Provides callbacks to Flutter layer with discovered printer information
 * Supports filtering by port type and automatic timeout
 * 
 * Port Types:
 * - all: Discover all available printers
 * - tcp: Network/WiFi printers only
 * - bluetooth: Bluetooth printers only
 * - usb: USB-connected printers only
 * 
 * @param context Android context
 * @param channel Method channel for Flutter callbacks
 */
class EpsonDiscoveryHandler(
    private val context: Context,
    private val channel: MethodChannel
) {
    private var isDiscovering = false
    private val mainHandler = Handler(Looper.getMainLooper())
    private var timeoutRunnable: Runnable? = null
    
    companion object {
        private const val TAG = "EpsonDiscoveryHandler"
    }

    /**
     * Start printer discovery
     * 
     * @param portType Port filter: "all", "tcp", "bluetooth", "usb"
     * @param timeout Discovery timeout in milliseconds
     * @param result Method channel result callback
     */
    fun discoverPrinters(
        portType: String,
        timeout: Int,
        result: MethodChannel.Result
    ) {
        if (isDiscovering) {
            result.error("ALREADY_DISCOVERING", "Discovery already in progress", null)
            return
        }

        try {
            val filterOption = FilterOption()
            
            // Set port type filter
            when (portType.lowercase()) {
                "tcp" -> filterOption.portType = Discovery.PORTTYPE_TCP
                "bluetooth" -> filterOption.portType = Discovery.PORTTYPE_BLUETOOTH
                "usb" -> filterOption.portType = Discovery.PORTTYPE_USB
                else -> filterOption.portType = Discovery.PORTTYPE_ALL
            }
            
            // Set device type to printers only
            filterOption.deviceType = Discovery.TYPE_PRINTER
            
            // Use Epson name filter for better results
            filterOption.epsonFilter = Discovery.FILTER_NAME
            
            // Enable USB device name for better USB detection
            filterOption.usbDeviceName = Discovery.TRUE

            // Start discovery with listener
            Discovery.start(context, filterOption, discoveryListener)
            isDiscovering = true
            
            // Set timeout to auto-stop discovery
            timeoutRunnable = Runnable {
                if (isDiscovering) {
                    stopDiscoveryInternal()
                    notifyDiscoveryComplete()
                }
            }
            mainHandler.postDelayed(timeoutRunnable!!, timeout.toLong())
            
            result.success(mapOf(
                "status" to "started",
                "portType" to portType,
                "timeout" to timeout
            ))
            
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Failed to start discovery", e)
            isDiscovering = false
            result.error("DISCOVERY_ERROR", e.message, getErrorDetails(e))
        }
    }

    /**
     * Stop ongoing printer discovery
     */
    fun stopDiscovery(result: MethodChannel.Result) {
        try {
            if (!isDiscovering) {
                // Allow callers to stop safely even if a timeout already fired
                result.success(mapOf("status" to "already_stopped"))
            } else {
                stopDiscoveryInternal()
                result.success(mapOf("status" to "stopped"))
            }
            
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Failed to stop discovery", e)
            result.error("STOP_ERROR", e.message, getErrorDetails(e))
        }
    }

    /**
     * Internal method to stop discovery
     */
    private fun stopDiscoveryInternal() {
        try {
            Discovery.stop()
        } catch (e: Epos2Exception) {
            // Ignore ERR_PROCESSING - means discovery is already stopping
            if (e.errorStatus != Epos2Exception.ERR_PROCESSING) {
                android.util.Log.e(TAG, "Error stopping discovery", e)
            }
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Unexpected error stopping discovery", e)
        }
        
        isDiscovering = false
        timeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        timeoutRunnable = null
    }

    /**
     * Discovery listener - receives discovered printer information
     */
    private val discoveryListener = DiscoveryListener { deviceInfo ->
        try {
            // Extract printer information
            val printerData = mapOf(
                "deviceName" to deviceInfo.deviceName,
                "ipAddress" to (deviceInfo.ipAddress ?: ""),
                "macAddress" to (deviceInfo.macAddress ?: ""),
                "bdAddress" to (deviceInfo.bdAddress ?: ""),
                "target" to deviceInfo.target,
                "deviceType" to getDeviceTypeName(deviceInfo.deviceType),
                "printerSeries" to (deviceInfo.deviceName ?: "Unknown")
            )
            
            // Notify Flutter about discovered printer
            mainHandler.post {
                channel.invokeMethod("onPrinterDiscovered", printerData)
            }
            
            android.util.Log.d(TAG, "Discovered: ${deviceInfo.deviceName} at ${deviceInfo.target}")
            
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error processing discovered device", e)
        }
    }

    /**
     * Notify Flutter that discovery has completed
     */
    private fun notifyDiscoveryComplete() {
        mainHandler.post {
            channel.invokeMethod("onDiscoveryComplete", mapOf("status" to "completed"))
        }
    }

    /**
     * Get human-readable device type name
     */
    private fun getDeviceTypeName(deviceType: Int): String {
        return when (deviceType) {
            Discovery.TYPE_PRINTER -> "Printer"
            Discovery.TYPE_HYBRID_PRINTER -> "Hybrid Printer"
            Discovery.TYPE_DISPLAY -> "Display"
            Discovery.TYPE_KEYBOARD -> "Keyboard"
            Discovery.TYPE_SCANNER -> "Scanner"
            Discovery.TYPE_SERIAL -> "Serial Device"
            else -> "Unknown"
        }
    }

    /**
     * Get detailed error information for debugging
     */
    private fun getErrorDetails(e: Exception): Map<String, Any> {
        val details = mutableMapOf<String, Any>(
            "exception" to e.javaClass.simpleName,
            "message" to (e.message ?: "Unknown error")
        )
        
        if (e is Epos2Exception) {
            details["errorStatus"] = e.errorStatus
            details["errorCode"] = getEpos2ErrorName(e.errorStatus)
        }
        
        return details
    }

    /**
     * Get Epson error code name
     */
    private fun getEpos2ErrorName(errorStatus: Int): String {
        return when (errorStatus) {
            Epos2Exception.ERR_PARAM -> "ERR_PARAM"
            Epos2Exception.ERR_CONNECT -> "ERR_CONNECT"
            Epos2Exception.ERR_TIMEOUT -> "ERR_TIMEOUT"
            Epos2Exception.ERR_MEMORY -> "ERR_MEMORY"
            Epos2Exception.ERR_ILLEGAL -> "ERR_ILLEGAL"
            Epos2Exception.ERR_PROCESSING -> "ERR_PROCESSING"
            Epos2Exception.ERR_NOT_FOUND -> "ERR_NOT_FOUND"
            Epos2Exception.ERR_IN_USE -> "ERR_IN_USE"
            Epos2Exception.ERR_TYPE_INVALID -> "ERR_TYPE_INVALID"
            else -> "UNKNOWN_ERROR"
        }
    }

    /**
     * Cleanup resources
     */
    fun cleanup() {
        if (isDiscovering) {
            stopDiscoveryInternal()
        }
        timeoutRunnable?.let { mainHandler.removeCallbacks(it) }
    }
}
