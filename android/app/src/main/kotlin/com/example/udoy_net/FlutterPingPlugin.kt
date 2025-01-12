package com.example.flutter_ping_plugin

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class FlutterPingPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_ping_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
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
