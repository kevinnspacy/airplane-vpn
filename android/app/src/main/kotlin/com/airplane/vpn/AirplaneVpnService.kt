package com.airplane.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

class AirplaneVpnService : VpnService() {
    companion object {
        const val ACTION_CONNECT = "com.airplane.vpn.ACTION_CONNECT"
        const val ACTION_DISCONNECT = "com.airplane.vpn.ACTION_DISCONNECT"
        const val EXTRA_CONFIG_PATH = "config_path"
        const val EXTRA_SERVER_NAME = "server_name"
        
        private const val NOTIFICATION_CHANNEL_ID = "vpn_channel"
        private const val NOTIFICATION_ID = 1
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private val isRunning = AtomicBoolean(false)

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_CONNECT -> {
                val configPath = intent.getStringExtra(EXTRA_CONFIG_PATH)
                val serverName = intent.getStringExtra(EXTRA_SERVER_NAME) ?: "VPN Server"
                if (configPath != null) {
                    connect(configPath, serverName)
                }
            }
            ACTION_DISCONNECT -> {
                disconnect()
            }
        }
        return START_STICKY
    }

    private fun connect(configPath: String, serverName: String) {
        if (isRunning.get()) {
            return
        }

        VpnServiceManager.updateState("connecting")
        
        try {
            // Establish VPN Interface
            val builder = Builder()
                .setSession(serverName)
                .setMtu(1500)
                .addAddress("172.19.0.1", 30)
                .addDnsServer("1.1.1.1")
                .addRoute("0.0.0.0", 0)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                builder.setMetered(false)
            }

            vpnInterface = builder.establish()
            
            if (vpnInterface == null) {
                throw Exception("Failed to establish VPN interface")
            }

            // Read config file
            val configFile = File(configPath)
            if (!configFile.exists()) {
                throw Exception("Config file not found: $configPath")
            }
            
            val configContent = configFile.readText()
            android.util.Log.d("VPN", "Config loaded: ${configContent.take(100)}...")
            
            // TODO: Implement actual sing-box integration here
            // For now, we simulate a successful connection for UI testing
            // Real implementation requires:
            // 1. Adding sing-box AAR/library manually to jniLibs
            // 2. Using Libbox.newService(configContent) to create service
            // 3. Starting the service
            
            // Simulate connection delay
            Thread.sleep(500)
            
            isRunning.set(true)
            VpnServiceManager.updateState("connected")
            
            startForeground(NOTIFICATION_ID, createNotification(serverName, true))
            
            // Simulate traffic stats updates
            Thread {
                var bytesIn = 0L
                var bytesOut = 0L
                while (isRunning.get()) {
                    Thread.sleep(1000)
                    bytesIn += (1000..5000).random()
                    bytesOut += (500..2000).random()
                    VpnServiceManager.updateStats(bytesIn, bytesOut)
                }
            }.start()
            
        } catch (e: Exception) {
            android.util.Log.e("VPN", "Connection error: ${e.message}")
            VpnServiceManager.updateState("error")
            VpnServiceManager.sendError(e.message ?: "Unknown error")
            disconnect()
        }
    }

    private fun disconnect() {
        if (!isRunning.getAndSet(false)) {
            return
        }

        VpnServiceManager.updateState("disconnecting")

        try {
            vpnInterface?.close()
            vpnInterface = null
        } catch (e: Exception) {
            android.util.Log.e("VPN", "Error disconnecting: ${e.message}")
        }

        VpnServiceManager.updateState("disconnected")
        VpnServiceManager.resetStats()
        
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "VPN Status",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows VPN connection status"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(serverName: String, isConnected: Boolean): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val disconnectIntent = Intent(this, AirplaneVpnService::class.java).apply {
            action = ACTION_DISCONNECT
        }
        val disconnectPendingIntent = PendingIntent.getService(
            this, 0, disconnectIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = if (isConnected) "VPN Connected" else "VPN Connecting..."
        
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(serverName)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Disconnect",
                disconnectPendingIntent
            )
            .build()
    }

    override fun onDestroy() {
        disconnect()
        super.onDestroy()
    }

    override fun onRevoke() {
        disconnect()
        super.onRevoke()
    }
}
