package com.example.udoy_net

import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import android.util.Log // Import Log class
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {

    private val CHANNEL_WIFI = "com.example.udoy_net/linkSpeed"
    private val CHANNEL_PING = "com.example.udoy_net/ping"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Channel for WiFi Details
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_WIFI)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "getLinkSpeed" -> {
                            val linkSpeed = getLinkSpeed()
                            if (linkSpeed != -1) {
                                result.success(linkSpeed)
                                // Log the link speed to the console
                                Log.d("WiFiDetails", "Link Speed: $linkSpeed Mbps")
                            } else {
                                result.error("UNAVAILABLE", "Link speed not available", null)
                            }
                        }
                        "getWifiDetails" -> {
                            val wifiDetails = getWifiDetails()
                            if (wifiDetails != null) {
                                result.success(wifiDetails)
                                // Log the Wi-Fi details to the console
                                Log.d("WiFiDetails", "Wi-Fi Details: $wifiDetails")
                            } else {
                                result.error("UNAVAILABLE", "WiFi details not available", null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                }

        // Channel for Ping
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_PING)
                .setMethodCallHandler { call, result ->
                    if (call.method == "ping") {
                        val ip = call.argument<String>("ip") ?: "8.8.8.8"
                        ping(ip) { output ->
                            Handler(Looper.getMainLooper()).post { result.success(output) }
                        }
                    } else {
                        result.notImplemented()
                    }
                }
    }

    // Get Wi-Fi Link Speed
    private fun getLinkSpeed(): Int {
        val wifiManager = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
        val wifiInfo: WifiInfo = wifiManager.connectionInfo
        return wifiInfo.linkSpeed // Link speed in Mbps
    }

    // Get Wi-Fi Details including Link Speed
    private fun getWifiDetails(): Map<String, Any>? {
        val wifiManager = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
        val wifiInfo: WifiInfo = wifiManager.connectionInfo
        return if (wifiInfo != null) {
            val wifiDetails =
                    mapOf(
                            "linkSpeed" to wifiInfo.linkSpeed, // Link speed in Mbps
                            "signalStrength" to
                                    WifiManager.calculateSignalLevel(
                                            wifiInfo.rssi,
                                            4
                                    ), // Signal strength level (1 to 4)
                            "frequency" to wifiInfo.frequency, // Frequency in MHz
                            "rssi" to wifiInfo.rssi, // RSSI (signal strength in dBm)
                            "linkSpeedMbps" to
                                    wifiInfo.linkSpeed // Added link speed in Mbps here as well
                    )
            // Log the details to the console
            Log.d("WiFiDetails", "Wi-Fi Details: $wifiDetails")
            wifiDetails
        } else {
            null
        }
    }

    // Ping Function
    private fun ping(ip: String, callback: (String) -> Unit) {
        Thread {
                    try {
                        val process =
                                Runtime.getRuntime().exec("ping -c 4 $ip") // Use -n for Windows
                        val reader = BufferedReader(InputStreamReader(process.inputStream))
                        val output = StringBuilder()
                        var line: String?
                        while (reader.readLine().also { line = it } != null) {
                            output.append(line).append("\n")
                        }
                        reader.close()
                        callback(output.toString()) // Callback with the ping result
                    } catch (e: Exception) {
                        callback("Error: ${e.message}") // Callback with the error message
                    }
                }
                .start()
    }
}
