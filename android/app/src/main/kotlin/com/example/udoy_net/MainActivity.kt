package com.example.udoy_net

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.udoy_net/ping"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "ping") {
                val ip = call.argument<String>("ip") ?: "8.8.8.8"
                ping(ip) { output ->
                    Handler(Looper.getMainLooper()).post {
                        result.success(output)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun ping(ip: String, callback: (String) -> Unit) {
        Thread {
            try {
                val process = Runtime.getRuntime().exec("ping -c 4 $ip")
                val reader = BufferedReader(InputStreamReader(process.inputStream))
                val output = StringBuilder()
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    output.append(line).append("\n")
                }
                reader.close()
                callback(output.toString())
            } catch (e: Exception) {
                callback("Error: ${e.message}")
            }
        }.start()
    }
}
