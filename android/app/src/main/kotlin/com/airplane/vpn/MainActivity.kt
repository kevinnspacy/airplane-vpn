package com.airplane.vpn

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val VPN_CHANNEL = "com.airplane.vpn/vpn"
        private const val VPN_EVENTS_CHANNEL = "com.airplane.vpn/vpn_events"
        private const val VPN_PERMISSION_REQUEST = 1001
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var pendingConfig: String? = null
    private var pendingServerName: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method Channel для команд
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "connect" -> {
                    val config = call.argument<String>("config")
                    val serverName = call.argument<String>("serverName")
                    if (config != null) {
                        startVpn(config, serverName ?: "VPN Server", result)
                    } else {
                        result.error("INVALID_CONFIG", "Configuration is null", null)
                    }
                }
                "disconnect" -> {
                    stopVpn(result)
                }
                "getStatus" -> {
                    getVpnStatus(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Event Channel для событий VPN
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_EVENTS_CHANNEL)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                // Регистрируем слушатель событий VPN
                VpnServiceManager.setEventListener { event ->
                    runOnUiThread {
                        eventSink?.success(event)
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                VpnServiceManager.setEventListener(null)
            }
        })
    }

    private fun startVpn(config: String, serverName: String, result: MethodChannel.Result) {
        // Проверяем разрешение VPN
        val intent = VpnService.prepare(this)
        if (intent != null) {
            // Нужно запросить разрешение
            pendingConfig = config
            pendingServerName = serverName
            startActivityForResult(intent, VPN_PERMISSION_REQUEST)
            result.success(true)
        } else {
            // Разрешение уже есть, запускаем VPN
            doStartVpn(config, serverName)
            result.success(true)
        }
    }

    private fun doStartVpn(config: String, serverName: String) {
        // Сохраняем конфигурацию во временный файл
        val configFile = File(filesDir, "config.json")
        configFile.writeText(config)

        // Запускаем VPN сервис
        val serviceIntent = Intent(this, AirplaneVpnService::class.java).apply {
            action = AirplaneVpnService.ACTION_CONNECT
            putExtra(AirplaneVpnService.EXTRA_CONFIG_PATH, configFile.absolutePath)
            putExtra(AirplaneVpnService.EXTRA_SERVER_NAME, serverName)
        }
        startService(serviceIntent)
    }

    private fun stopVpn(result: MethodChannel.Result) {
        val serviceIntent = Intent(this, AirplaneVpnService::class.java).apply {
            action = AirplaneVpnService.ACTION_DISCONNECT
        }
        startService(serviceIntent)
        result.success(true)
    }

    private fun getVpnStatus(result: MethodChannel.Result) {
        val status = mapOf(
            "state" to VpnServiceManager.getCurrentState(),
            "bytesIn" to VpnServiceManager.getBytesIn(),
            "bytesOut" to VpnServiceManager.getBytesOut()
        )
        result.success(status)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == VPN_PERMISSION_REQUEST) {
            if (resultCode == Activity.RESULT_OK) {
                // Разрешение получено, запускаем VPN
                pendingConfig?.let { config ->
                    doStartVpn(config, pendingServerName ?: "VPN Server")
                }
            } else {
                // Пользователь отклонил запрос
                eventSink?.success(mapOf(
                    "type" to "error",
                    "message" to "VPN permission denied"
                ))
            }
            pendingConfig = null
            pendingServerName = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
    }
}
