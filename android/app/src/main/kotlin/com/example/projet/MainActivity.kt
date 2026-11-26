package com.example.projet

import android.app.ActivityManager
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Debug
import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val metricsChannel = "com.example.projet/device_metrics"
    private var previousCpuTimeMs: Long? = null
    private var previousElapsedTimeMs: Long? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, metricsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "read") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                try {
                    result.success(readDeviceMetrics())
                } catch (error: Exception) {
                    result.error("DEVICE_METRICS_FAILED", error.message, null)
                }
            }
    }

    private fun readDeviceMetrics(): Map<String, Any?> {
        val now = SystemClock.elapsedRealtime()
        val cpuTime = android.os.Process.getElapsedCpuTime()
        val cpuPercent = if (previousCpuTimeMs != null && previousElapsedTimeMs != null) {
            val elapsed = now - previousElapsedTimeMs!!
            val cpuDelta = cpuTime - previousCpuTimeMs!!
            if (elapsed in 1..10_000) {
                (cpuDelta.toDouble() / elapsed / Runtime.getRuntime().availableProcessors() * 100)
                    .coerceIn(0.0, 100.0)
            } else {
                null
            }
        } else {
            null
        }
        previousCpuTimeMs = cpuTime
        previousElapsedTimeMs = now

        val memoryInfo = ActivityManager.MemoryInfo()
        (getSystemService(ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(memoryInfo)
        val appMemoryInfo = Debug.MemoryInfo()
        Debug.getMemoryInfo(appMemoryInfo)
        val totalMemoryMb = memoryInfo.totalMem / (1024.0 * 1024.0)
        val memoryUsedPercent = if (memoryInfo.totalMem > 0) {
            ((memoryInfo.totalMem - memoryInfo.availMem).toDouble() /
                memoryInfo.totalMem * 100).coerceIn(0.0, 100.0)
        } else {
            null
        }

        val batteryIntent = registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED),
        )
        val batteryLevel = batteryIntent?.let { intent ->
            val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            if (level >= 0 && scale > 0) (level * 100 / scale) else null
        }
        val batteryState = when (
            batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        ) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "Charging"
            BatteryManager.BATTERY_STATUS_FULL -> "Full"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "Discharging"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "Not charging"
            else -> "Unknown"
        }

        return mapOf(
            "cpuPercent" to cpuPercent,
            "memoryUsedPercent" to memoryUsedPercent,
            "appMemoryMb" to (appMemoryInfo.totalPss / 1024.0),
            "totalMemoryMb" to totalMemoryMb,
            "batteryLevel" to batteryLevel,
            "batteryState" to batteryState,
        )
    }
}
