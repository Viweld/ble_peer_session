package dev.viweld.ble_peer_session

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class BlePeerSessionPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        instance = this
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        if (instance === this) {
            instance = null
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                try {
                    startService(call)
                    result.success(null)
                } catch (error: Exception) {
                    val code =
                        if (error.javaClass.simpleName.contains("ForegroundServiceStartNotAllowed")) {
                            "foreground_start_not_allowed"
                        } else if (error is IllegalArgumentException) {
                            "invalid_small_icon"
                        } else {
                            "foreground_start_failed"
                        }
                    result.error(code, error.message, error.javaClass.simpleName)
                }
            }
            "stop" -> {
                try {
                    stopService()
                    result.success(null)
                } catch (error: Exception) {
                    result.error("foreground_stop_failed", error.message, error.javaClass.simpleName)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun startService(call: MethodCall) {
        val smallIcon = resolveSmallIcon(call.argument<String>("smallIcon"))
        val intent = Intent(appContext, BlePeerForegroundService::class.java).apply {
            putExtra(
                BlePeerForegroundService.EXTRA_TITLE,
                call.argument<String>("title") ?: "BLE peer session",
            )
            putExtra(
                BlePeerForegroundService.EXTRA_BODY,
                call.argument<String>("body") ?: "Bluetooth peer session is active",
            )
            putExtra(BlePeerForegroundService.EXTRA_SMALL_ICON_ID, smallIcon)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            appContext.startForegroundService(intent)
        } else {
            @Suppress("DEPRECATION")
            appContext.startService(intent)
        }
    }

    private fun stopService() {
        appContext.stopService(Intent(appContext, BlePeerForegroundService::class.java))
    }

    private fun resolveSmallIcon(resourceName: String?): Int {
        if (resourceName.isNullOrBlank()) {
            return R.drawable.ic_stat_ble_peer
        }
        val value = resourceName.removePrefix("@")
        val parts = value.split('/', limit = 2)
        val type = if (parts.size == 2) parts[0] else "drawable"
        val name = if (parts.size == 2) parts[1] else value
        val resolved = appContext.resources.getIdentifier(name, type, appContext.packageName)
        if (resolved == 0) {
            throw IllegalArgumentException("Unknown smallIcon resource: $resourceName")
        }
        return resolved
    }

    companion object {
        const val CHANNEL = "dev.viweld.ble_peer_session/foreground"

        @Volatile
        private var instance: BlePeerSessionPlugin? = null

        fun notifyTaskRemoved() {
            val plugin = instance ?: return
            Handler(Looper.getMainLooper()).post {
                plugin.channel.invokeMethod("onTaskRemoved", null)
            }
        }
    }
}
