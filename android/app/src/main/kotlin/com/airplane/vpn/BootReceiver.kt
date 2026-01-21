package com.airplane.vpn

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            // Проверяем настройку автоподключения
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val autoConnect = prefs.getBoolean("flutter.autoConnect", false)
            
            if (autoConnect) {
                // Запускаем главную активность для автоподключения
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    putExtra("auto_connect", true)
                }
                context.startActivity(launchIntent)
            }
        }
    }
}
