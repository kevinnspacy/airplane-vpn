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
import io.nekohasekai.libbox.CommandServer
import io.nekohasekai.libbox.CommandServerHandler
import io.nekohasekai.libbox.ConnectionOwner
import io.nekohasekai.libbox.InterfaceUpdateListener
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.LocalDNSTransport
import io.nekohasekai.libbox.NetworkInterfaceIterator
import io.nekohasekai.libbox.OverrideOptions
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.SetupOptions
import io.nekohasekai.libbox.StringIterator
import io.nekohasekai.libbox.SystemProxyStatus
import io.nekohasekai.libbox.TunOptions
import io.nekohasekai.libbox.WIFIState
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean
import io.nekohasekai.libbox.Notification as LibboxNotification

class AirplaneVpnService : VpnService(), PlatformInterface, CommandServerHandler {
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
    private var commandServer: CommandServer? = null
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

            // Setup Libbox paths
            val setupOptions = SetupOptions()
            setupOptions.setBasePath(filesDir.absolutePath)
            setupOptions.setWorkingPath(cacheDir.absolutePath)
            setupOptions.setTempPath(cacheDir.absolutePath)
            
            Libbox.setup(setupOptions)
            Log.d(TAG, "Libbox setup complete")

            // Create CommandServer
            commandServer = CommandServer(this, this)
            commandServer?.start()
            Log.d(TAG, "CommandServer started")
            
            // Start the service with config
            val overrideOptions = OverrideOptions()
            commandServer?.startOrReloadService(configContent, overrideOptions)
            
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
            commandServer?.closeService()
            commandServer?.close()
            commandServer = null
            
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

    // ==================== PlatformInterface implementation ====================
    
    override fun autoDetectInterfaceControl(fd: Int) {
        protect(fd)
    }

    override fun openTun(options: TunOptions): Int {
        Log.d(TAG, "Opening TUN interface")
        
        val builder = Builder()
            .setSession(serverName)
            .setMtu(options.mtu)
        
        // Add IPv4 address
        try {
            val inet4Address = options.inet4Address
            if (inet4Address != null && inet4Address.hasNext()) {
                val addr = inet4Address.next()
                builder.addAddress(addr.address(), addr.prefix())
            }
        } catch (e: Exception) {
            Log.w(TAG, "No IPv4 address: ${e.message}")
        }
        
        // Add IPv6 address  
        try {
            val inet6Address = options.inet6Address
            if (inet6Address != null && inet6Address.hasNext()) {
                val addr = inet6Address.next()
                builder.addAddress(addr.address(), addr.prefix())
            }
        } catch (e: Exception) {
            Log.w(TAG, "No IPv6 address: ${e.message}")
        }
        
        // Add DNS servers
        try {
            val dnsBox = options.dnsServerAddress
            val dnsServer = dnsBox?.value
            if (!dnsServer.isNullOrEmpty()) {
                builder.addDnsServer(dnsServer)
            } else {
                builder.addDnsServer("1.1.1.1")
                builder.addDnsServer("8.8.8.8")
            }
        } catch (e: Exception) {
            Log.w(TAG, "DNS error: ${e.message}")
            builder.addDnsServer("1.1.1.1")
            builder.addDnsServer("8.8.8.8")
        }
        
        // Add routes
        try {
            if (options.autoRoute) {
                builder.addRoute("0.0.0.0", 0)
                builder.addRoute("::", 0)
            }
        } catch (e: Exception) {
            builder.addRoute("0.0.0.0", 0)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false)
        }
        
        vpnInterface = builder.establish()
        
        return vpnInterface?.fd ?: throw Exception("Failed to establish VPN interface")
    }

    override fun usePlatformAutoDetectInterfaceControl(): Boolean = true
    
    override fun useProcFS(): Boolean = false
    
    override fun findConnectionOwner(
        ipProtocol: Int,
        sourceAddress: String?,
        sourcePort: Int,
        destinationAddress: String?,
        destinationPort: Int
    ): ConnectionOwner {
        // Return an empty ConnectionOwner instead of null to prevent Go panic
        return ConnectionOwner()
    }
    
    override fun getInterfaces(): NetworkInterfaceIterator? = null

    override fun underNetworkExtension(): Boolean = false
    
    override fun includeAllNetworks(): Boolean = false
    
    override fun clearDNSCache() {
        // No-op
    }
    
    override fun readWIFIState(): WIFIState? = null
    
    override fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener?) {
        // No-op
    }
    
    override fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener?) {
        // No-op
    }
    
    override fun localDNSTransport(): LocalDNSTransport? = null
    
    override fun sendNotification(notification: LibboxNotification?) {
        // Handle libbox notification if needed
    }
    
    override fun systemCertificates(): StringIterator? = null

    // ==================== CommandServerHandler implementation ====================
    
    override fun getSystemProxyStatus(): SystemProxyStatus? = null
    
    override fun serviceReload() {
        Log.d(TAG, "Service reload requested")
    }
    
    override fun serviceStop() {
        Log.d(TAG, "Service stop requested")
        disconnect()
    }
    
    override fun setSystemProxyEnabled(enabled: Boolean) {
        Log.d(TAG, "System proxy enabled: $enabled")
    }
    
    override fun writeDebugMessage(message: String?) {
        message?.let { Log.d(TAG, "Debug: $it") }
    }

    // ==================== Notification management ====================
    
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
