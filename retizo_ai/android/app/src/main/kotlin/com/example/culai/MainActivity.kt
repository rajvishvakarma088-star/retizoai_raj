package com.example.culai

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity - Entry point for Epson Printer Integration
 * 
 * Implements Method Channel bridge between Flutter and Epson ePOS SDK
 * Handles runtime permissions for Bluetooth/USB/Location
 * Manages printer discovery, connection, and printing operations
 * 
 * Channel: "com.culai.epson_printer"
 * 
 * @author CulAI Development Team
 * @version 1.0.0
 */
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.culai.epson_printer"
    private val REQUEST_PERMISSION = 100
    
    private var methodChannel: MethodChannel? = null
    private var printerHandler: EpsonPrinterHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize Method Channel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        // Initialize Printer Handler
        printerHandler = EpsonPrinterHandler(this, methodChannel!!)
        
        // Register Method Channel call handler
        methodChannel?.setMethodCallHandler { call, result ->
            printerHandler?.handleMethodCall(call, result)
        }
        
        // Request runtime permissions
        requestRuntimePermissions()
    }

    /**
     * Request runtime permissions required for Epson printer operations
     * - Bluetooth: For wireless printer discovery and connection
     * - Location: Required for Bluetooth discovery on Android 10+
     */
    private fun requestRuntimePermissions() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return
        }

        val requestPermissions = ArrayList<String>()

        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
                // Android 12+ (API 31+) - New Bluetooth permissions
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) 
                    == PackageManager.PERMISSION_DENIED) {
                    requestPermissions.add(Manifest.permission.BLUETOOTH_SCAN)
                }
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) 
                    == PackageManager.PERMISSION_DENIED) {
                    requestPermissions.add(Manifest.permission.BLUETOOTH_CONNECT)
                }
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                // Android 10-11 (API 29-30) - Location required for Bluetooth
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) 
                    == PackageManager.PERMISSION_DENIED) {
                    requestPermissions.add(Manifest.permission.ACCESS_FINE_LOCATION)
                }
            }
            else -> {
                // Android 9 and below (API 28-) - Coarse location sufficient
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) 
                    == PackageManager.PERMISSION_DENIED) {
                    requestPermissions.add(Manifest.permission.ACCESS_COARSE_LOCATION)
                }
            }
        }

        if (requestPermissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this, 
                requestPermissions.toTypedArray(), 
                REQUEST_PERMISSION
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == REQUEST_PERMISSION) {
            // Notify Flutter layer about permission results
            val permissionResults = mutableMapOf<String, Boolean>()
            for (i in permissions.indices) {
                permissionResults[permissions[i]] = 
                    grantResults[i] == PackageManager.PERMISSION_GRANTED
            }
            
            methodChannel?.invokeMethod("onPermissionsResult", permissionResults)
        }
    }

    override fun onDestroy() {
        // Clean up printer resources
        printerHandler?.cleanup()
        printerHandler = null
        methodChannel = null
        super.onDestroy()
    }
}
