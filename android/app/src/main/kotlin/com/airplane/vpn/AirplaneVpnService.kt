package com.airplane.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import io.nekohasekai.libbox.BoxService
import io.nekohasekai.libbox.CommandServer
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.TunOptions
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

class AirplaneVpnService : VpnService(), PlatformInterface {
    companion object {
        private const val TAG = "AirplaneVPN"
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
    private var serverName: String = "VPN Server"

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d(TAG, "VPN Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_CONNECT -> {
                val configPath = intent.getStringExtra(EXTRA_CONFIG_PATH)
                serverName = intent.getStringExtra(EXTRA_SERVER_NAME) ?: "VPN Server"
                if (configPath != null) {
                    connect(configPath)
                }
            }
            ACTION_DISCONNECT -> {
                disconnect()
            }
        }
        return START_STICKY
    }

    private fun connect(configPath: String) {
        if (isRunning.get()) {
            Log.w(TAG, "VPN already running")
            return
        }

        VpnServiceManager.updateState("connecting")
        
        try {
            // Read config content
            val configFile = File(configPath)
            if (!configFile.exists()) {
                throw Exception("Config file not found: $configPath")
            }
            val configContent = configFile.readText()
            Log.d(TAG, "Config loaded, length: ${configContent.length}")

            // Initialize Libbox
            val options = Libbox.newSetupOptions().apply {
                basePath = filesDir.absolutePath
                workingPath = cacheDir.absolutePath
                tempPath = cacheDir.absolutePath
            }
            
            Libbox.setup(options)
            Log.d(TAG, "Libbox setup complete")

            // Create and start BoxService
            boxService = Libbox.newService(configContent, this)
            boxService?.start()
            
            isRunning.set(true)
            VpnServiceManager.updateState("connected")
            
            startForeground(NOTIFICATION_ID, createNotification(serverName, true))
            Log.i(TAG, "VPN connected to $serverName")

        } catch (e: Exception) {
            Log.e(TAG, "Connection error: ${e.message}", e)
            VpnServiceManager.updateState("error")
            VpnServiceManager.sendError(e.message ?: "Unknown error")
            disconnect()
        }
    }

    private fun disconnect() {
        if (!isRunning.getAndSet(false)) {
            return
        }

        Log.d(TAG, "Disconnecting VPN")
        VpnServiceManager.updateState("disconnecting")

        try {
            boxService?.close()
            boxService = null
            
            vpnInterface?.close()
            vpnInterface = null
        } catch (e: Exception) {
            Log.e(TAG, "Error disconnecting: ${e.message}", e)
        }

        VpnServiceManager.updateState("disconnected")
        VpnServiceManager.resetStats()
        
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.i(TAG, "VPN disconnected")
    }

    // PlatformInterface implementation
    
    override fun autoDetectInterfaceControl(fd: Int) {
        protect(fd)
    }

    override fun openTun(options: TunOptions): Int {
        Log.d(TAG, "Opening TUN interface")
        
        val builder = Builder()
            .setSession(serverName)
            .setMtu(options.mtu)
        
        // Add addresses
        val inet4Address = options.inet4Address
        if (inet4Address != null && inet4Address.hasNext()) {
            val addr = inet4Address.next()
            builder.addAddress(addr.address, addr.prefix)
        }
        
        val inet6Address = options.inet6Address
        if (inet6Address != null && inet6Address.hasNext()) {
            val addr = inet6Address.next()
            builder.addAddress(addr.address, addr.prefix)
        }
        
        // Add DNS servers
        val dnsServers = options.dnsServerAddress
        if (dnsServers != null) {
            while (dnsServers.hasNext()) {
                builder.addDnsServer(dnsServers.next())
            }
        }
        
        // Add routes
        if (options.isAutoRoute) {
            builder.addRoute("0.0.0.0", 0)
            builder.addRoute("::", 0)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false)
        }
        
        vpnInterface = builder.establish()
        
        return vpnInterface?.fd ?: throw Exception("Failed to establish VPN interface")
    }

    override fun closeTun() {
        Log.d(TAG, "Closing TUN interface")
        vpnInterface?.close()
        vpnInterface = null
    }

    override fun usePlatformAutoDetectInterfaceControl(): Boolean = true
    
    override fun usePlatformDefaultInterfaceMonitor(): Boolean = false
    
    override fun usePlatformInterfaceGetter(): Boolean = false
    
    override fun useProcFS(): Boolean = false
    
    override fun findConnectionOwner(
        ipProtocol: Int,
        sourceAddress: String,
        sourcePort: Int,
        destinationAddress: String,
        destinationPort: Int
    ): Int = 0
    
    override fun packageNameByUid(uid: Int): String = ""
    
    override fun uidByPackageName(packageName: String): Int = 0
    
    override fun writeLog(message: String) {
        Log.d(TAG, message)
    }
    
    override fun getInterfaces(): String = ""
    
    override fun underNetworkExtension(): Boolean = false

    // Notification management
    
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
