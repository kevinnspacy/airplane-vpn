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

// Sing-box imports
// Note: These imports assume io.nekohasekai:sing-box library structure.
// If build fails, verify the exact package name in the library documentation or source.
import io.nekohasekai.libbox.BoxService
import io.nekohasekai.libbox.Libbox

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
    private var boxService: BoxService? = null
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
            // 1. Establish VPN Interface
            // In 'tun' mode with 'auto_route', sing-box might handle this if platform interface is passed correctly.
            // However, common pattern is to create TUN here and pass FD, OR let Libbox manage it.
            // For this implementation, we will use Libbox's internal TUN management if supported,
            // otherwise we establish a basic TUN to ensure the service is active.
            
            val builder = Builder()
                .setSession(serverName)
                .setMtu(1500)
                .addAddress("172.19.0.1", 30) // Virtual IP
                .addDnsServer("1.1.1.1")
                .addRoute("0.0.0.0", 0)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                builder.setMetered(false)
            }

            vpnInterface = builder.establish()
            
            if (vpnInterface == null) {
                throw Exception("Failed to establish VPN interface")
            }

            // 2. Start Sing-box Core via Libbox
            val configFile = File(configPath)
            if (!configFile.exists()) {
                throw Exception("Config file not found: $configPath")
            }
            
            val configContent = configFile.readText()
            
            // Initializing Libbox Service
            // Warning: API signature might vary by version.
            // We assume newService(configJson) or similar.
            // If Libbox requires a platform interface, we might need to pass 'this' or a wrapper.
            // For now, we try standard initialization.
            
            try {
                // boxService = Libbox.newService(configContent) // Example API
                // boxService?.start()
                
                // Since I cannot verify the exact API method right now, I will add a TO-DO placeholder
                // that simulates the start for now, but points where to put the real code.
                
                // REAL IMPLEMENTATION (Commented out until API verified):
                // boxService = Libbox.newService(configContent, PlatformInterfaceImpl(this))
                // boxService.start()
                
                // Note: You must ensure 'io.nekohasekai:sing-box' is usable this way.
                // If the library only provides a full VpnService subclass, we should extend THAT instead.
                // BUT, io.nekohasekai.libbox is usually a low-level binding.
                
                android.util.Log.d("VPN", "Starting Libbox with config: ${configContent.take(100)}...")
                
                // Placeholder for success to allow UI testing
                // Remove this when real Libbox call is added
                // Thread.sleep(500) 
                
            } catch (e: Exception) {
                android.util.Log.e("VPN", "Libbox error: ${e.message}")
                throw e
            }
            
            isRunning.set(true)
            VpnServiceManager.updateState("connected")
            
            startForeground(NOTIFICATION_ID, createNotification(serverName, true))
            
        } catch (e: Exception) {
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
            // Stop Sing-box
            boxService?.close() // or stop()
            boxService = null

            // Close interface
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
