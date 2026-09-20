package dev.viweld.ble_peer_session

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class BlePeerForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        when (intent.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                val notification = buildNotification(intent)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
                    )
                } else {
                    @Suppress("DEPRECATION")
                    startForeground(NOTIFICATION_ID, notification)
                }
                return START_NOT_STICKY
            }
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        BlePeerSessionPlugin.notifyTaskRemoved()
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        clearForegroundNotification()
        super.onDestroy()
    }

    private fun clearForegroundNotification() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(NOTIFICATION_ID)
    }

    private fun buildNotification(intent: Intent): Notification {
        val channelId = ensureChannel()
        val title = intent.getStringExtra(EXTRA_TITLE) ?: DEFAULT_TITLE
        val body = intent.getStringExtra(EXTRA_BODY) ?: DEFAULT_BODY
        val smallIcon = intent.getIntExtra(EXTRA_SMALL_ICON_ID, R.drawable.ic_stat_ble_peer)
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent =
            PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(smallIcon)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun ensureChannel(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return CHANNEL_ID

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return CHANNEL_ID

        val channel =
            NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = CHANNEL_DESCRIPTION
                setShowBadge(false)
            }
        manager.createNotificationChannel(channel)
        return CHANNEL_ID
    }

    companion object {
        const val ACTION_STOP = "dev.viweld.ble_peer_session.action.FOREGROUND_STOP"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_SMALL_ICON_ID = "smallIconId"
        private const val CHANNEL_ID = "ble_peer_session"
        private const val CHANNEL_NAME = "BLE peer session"
        private const val CHANNEL_DESCRIPTION = "Keeps a Bluetooth peer session active"
        private const val DEFAULT_TITLE = "BLE peer session"
        private const val DEFAULT_BODY = "Bluetooth peer session is active"
        const val NOTIFICATION_ID = 41001
    }
}
