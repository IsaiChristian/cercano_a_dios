package com.cercanoadios.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.math.log10

class MainActivity : FlutterActivity() {
    private lateinit var channel: MethodChannel
    private var recorder: MediaRecorder? = null
    private var player: MediaPlayer? = null
    private var pendingRecord: Pair<String, MethodChannel.Result>? = null
    private var pendingNotifications: MethodChannel.Result? = null
    private var openPrayer: Int? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        openPrayer = if(intent.getBooleanExtra("openPrayer", false)) intent.getIntExtra("reminderID",0) else null
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cercano/device")
        AlarmStore.restore(this)
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "directory" -> result.success(File(noBackupFilesDir, "prayers").apply { mkdirs() }.absolutePath)
                    "alarmCapability" -> result.success("alarm")
                    "alarmStatus" -> result.success(AlarmStore.status(this))
                    "consumeOpenPrayer" -> { result.success(openPrayer); openPrayer = null }
                    "settings" -> {
                        val destination = if(Build.VERSION.SDK_INT >= 31 && !AlarmStore.manager(this).canScheduleExactAlarms())
                            Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM else Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                        startActivity(Intent(destination, Uri.parse("package:$packageName"))); result.success(null)
                    }
                    "schedule" -> {
                        if(Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            pendingNotifications = result
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 42)
                        } else {
                            check(AlarmStore.status(this) == "ready") { "Allow Alarms & reminders in device settings, then tap Edit to retry." }
                            @Suppress("UNCHECKED_CAST")
                            AlarmStore.save(this, call.arguments as Map<String, Any?>); result.success(null)
                        }
                    }
                    "cancel" -> { AlarmStore.cancel(this, call.argument<Int>("id")!!); result.success(null) }
                    "cancelSnooze" -> { AlarmStore.cancelSnooze(this, call.argument<Int>("id")!!); result.success(null) }
                    "cancelAll" -> { AlarmStore.cancelAll(this); result.success(null) }
                    "stopAlarm" -> { stopService(Intent(this, PrayerAlarmService::class.java)); result.success(null) }
                    "testAlarm" -> {
                        check(AlarmStore.status(this) == "ready") { "Enable notification and exact alarm access, then save a prayer time before testing." }
                        AlarmStore.at(this, 0, System.currentTimeMillis()+10000, false); result.success(null)
                    }
                    "record" -> {
                        val path = call.argument<String>("path")!!
                        if(checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                            check(pendingRecord == null) { "A microphone request is already open." }
                            pendingRecord = path to result; requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 41)
                        } else { startRecording(path); result.success(null) }
                    }
                    "finishRecording" -> { finishRecording(); result.success(null) }
                    "amplitude" -> {
                        val peak = recorder?.maxAmplitude ?: 0
                        result.success(if(peak == 0) 0.0 else ((20*log10(peak.toDouble()/32767)+60)/60).coerceIn(0.0,1.0))
                    }
                    "play" -> {
                        player?.release()
                        player = MediaPlayer().apply {
                            setDataSource(call.argument<String>("path")!!); prepare(); start()
                            setOnCompletionListener { it.release(); player = null }
                        }; result.success(null)
                    }
                    "stopPlayback" -> { player?.release(); player = null; result.success(null) }
                    else -> result.notImplemented()
                }
            } catch(e: Exception) { result.error("device", e.message ?: "Device operation failed. Please retry.", null) }
        }
    }
    private fun startRecording(path: String) {
        finishRecording(); player?.release(); player = null
        stopService(Intent(this, PrayerAlarmService::class.java))
        @Suppress("DEPRECATION")
        val active = MediaRecorder()
        try {
            active.setAudioSource(MediaRecorder.AudioSource.MIC)
            active.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            active.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            active.setAudioChannels(1); active.setAudioSamplingRate(16000); active.setAudioEncodingBitRate(32000)
            active.setOutputFile(path); active.setMaxDuration(120000)
            active.prepare(); active.start(); recorder = active
        } catch(e: Exception) { active.release(); throw e }
    }
    private fun finishRecording() {
        val active = recorder ?: return
        recorder = null
        try { active.stop() } catch(_: RuntimeException) {} finally { active.release() }
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if(requestCode == 41) {
            val pending = pendingRecord; pendingRecord = null
            if(pending != null) {
                if(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
                    try { startRecording(pending.first); pending.second.success(null) }
                    catch(e: Exception) { pending.second.error("microphone", e.message, null) }
                } else pending.second.error("microphone", "Microphone access was not granted. You can reflect silently or enable it in Settings.", null)
            }
        }
        if(requestCode == 42) {
            // Require an explicit retry; no false scheduling success after a permission prompt.
            pendingNotifications?.error("permission", "Notification access updated. Tap Edit and Save to finish setting your alarm.", null)
            pendingNotifications = null
        }
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if(intent.getBooleanExtra("openPrayer", false)) channel.invokeMethod("openPrayer", intent.getIntExtra("reminderID",0))
    }
    override fun onPause() { if(recorder != null) channel.invokeMethod("recordingInterrupted", null); finishRecording(); player?.release(); player = null; super.onPause() }
    override fun onDestroy() { finishRecording(); player?.release(); super.onDestroy() }
}
