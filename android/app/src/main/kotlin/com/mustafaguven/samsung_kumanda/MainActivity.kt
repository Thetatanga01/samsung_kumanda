package com.mustafaguven.samsung_kumanda

import android.content.Context
import android.net.wifi.WifiManager
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.net.NetworkInterface

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mustafaguven.samsung_kumanda/multicast"
    private val VOLUME_CHANNEL = "com.mustafaguven.samsung_kumanda/volume_keys"
    private var multicastLock: WifiManager.MulticastLock? = null
    private var volumeEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    volumeEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    volumeEventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "acquireMulticastLock" -> {
                    try {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        multicastLock = wifiManager.createMulticastLock("SamsungRemoteLock")
                        multicastLock?.setReferenceCounted(true)
                        multicastLock?.acquire()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LOCK_FAILED", e.message, null)
                    }
                }
                "releaseMulticastLock" -> {
                    try {
                        multicastLock?.release()
                        multicastLock = null
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("RELEASE_FAILED", e.message, null)
                    }
                }
                // Gerçek WiFi IP'sini WifiManager'dan al
                "getWifiIp" -> {
                    try {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        @Suppress("DEPRECATION")
                        val ipInt = wifiManager.connectionInfo.ipAddress
                        if (ipInt != 0) {
                            val ip = String.format(
                                "%d.%d.%d.%d",
                                ipInt and 0xff,
                                ipInt shr 8 and 0xff,
                                ipInt shr 16 and 0xff,
                                ipInt shr 24 and 0xff
                            )
                            result.success(ip)
                        } else {
                            // WifiManager sonuç vermezse tüm arayüzleri tara
                            result.success(getWifiIpFromInterfaces())
                        }
                    } catch (e: Exception) {
                        result.success(getWifiIpFromInterfaces())
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN) {
            when (event.keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    volumeEventSink?.success("KEY_VOLUP")
                    return true
                }
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    volumeEventSink?.success("KEY_VOLDOWN")
                    return true
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }

    private fun getWifiIpFromInterfaces(): String? {
        return try {
            NetworkInterface.getNetworkInterfaces()?.toList()
                ?.filter { it.name.startsWith("wlan") && it.isUp && !it.isLoopback }
                ?.flatMap { it.inetAddresses.toList() }
                ?.filter { !it.isLoopbackAddress && it.address.size == 4 }
                ?.map { it.hostAddress }
                ?.firstOrNull()
        } catch (e: Exception) {
            null
        }
    }
}
