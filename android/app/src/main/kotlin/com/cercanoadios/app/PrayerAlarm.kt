package com.cercanoadios.app

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.media.*
import android.net.Uri
import android.os.*
import org.json.JSONObject
import java.util.Calendar
import java.util.UUID

object AlarmStore {
    fun manager(c: Context) = c.getSystemService(AlarmManager::class.java)
    private fun prefs(c: Context) = c.getSharedPreferences("prayer_alarms", Context.MODE_PRIVATE)
    private fun intent(c: Context, id: Int, snooze: Boolean) = PendingIntent.getBroadcast(c, id*10 + if(snooze) 1 else 0,
        Intent(c, PrayerAlarmReceiver::class.java).setAction("RING").putExtra("id",id).putExtra("snooze",snooze),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    fun status(c: Context): String {
        if(!c.getSystemService(NotificationManager::class.java).areNotificationsEnabled()) return "notifications needed"
        if(Build.VERSION.SDK_INT >= 33 && c.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return "notifications needed"
        if(Build.VERSION.SDK_INT >= 31 && !manager(c).canScheduleExactAlarms()) return "exact alarm access needed"
        if(Build.VERSION.SDK_INT >= 26 && c.getSystemService(NotificationManager::class.java)
            .getNotificationChannel("prayer_alarm_v1")?.importance == NotificationManager.IMPORTANCE_NONE) return "alarm notifications disabled"
        return "ready"
    }
    fun save(c: Context, data: Map<String, Any?>) {
        val json = JSONObject(data)
        val id = json.getInt("id")
        prefs(c).edit().putString("alarm_$id",json.toString()).commit()
        next(c,id)
    }
    fun next(c: Context,id: Int) {
        val raw = prefs(c).getString("alarm_$id",null) ?: return
        val json = JSONObject(raw)
        val days = json.getJSONArray("weekdays")
        val weekdays = (0 until days.length()).map { days.getInt(it) }.toSet()
        val now = System.currentTimeMillis()
        for(offset in 0..7) {
            val candidate = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR,offset)
                set(Calendar.HOUR_OF_DAY,json.getInt("hour")); set(Calendar.MINUTE,json.getInt("minute"))
                set(Calendar.SECOND,0); set(Calendar.MILLISECOND,0)
            }
            val weekday = (candidate.get(Calendar.DAY_OF_WEEK)+5)%7+1
            if(candidate.timeInMillis > now+1000 && weekdays.contains(weekday)) {
                at(c,id,candidate.timeInMillis,false); return
            }
        }
    }
    fun at(c: Context,id: Int,time: Long,snooze: Boolean) {
        val show = PendingIntent.getActivity(c,id,Intent(c,MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        manager(c).setAlarmClock(AlarmManager.AlarmClockInfo(time,show),intent(c,id,snooze))
        if(snooze) prefs(c).edit().putLong("snooze_$id",time).commit()
    }
    fun cancelSnooze(c: Context,id: Int) {
        manager(c).cancel(intent(c,id,true)); prefs(c).edit().remove("snooze_$id").commit()
    }
    fun deferOverlap(c: Context,id: Int) {
        val time = System.currentTimeMillis()+600000
        // Retain the reminder even if exact-alarm permission changes mid-ring.
        prefs(c).edit().putLong("snooze_$id",time).commit()
        at(c,id,time,true)
    }
    fun cancel(c: Context,id: Int) {
        manager(c).cancel(intent(c,id,false)); manager(c).cancel(intent(c,id,true))
        prefs(c).edit().remove("alarm_$id").remove("snooze_$id").commit()
        if(PrayerAlarmService.activeId == id) c.stopService(Intent(c,PrayerAlarmService::class.java))
    }
    fun cancelAll(c: Context) {
        val keys = prefs(c).all.keys.toList()
        keys.filter { it.startsWith("alarm_") || it.startsWith("snooze_") }
            .map { it.substringAfter('_').toInt() }.toSet().forEach { cancel(c,it) }
        manager(c).cancel(intent(c,0,false))
        c.stopService(Intent(c,PrayerAlarmService::class.java))
        prefs(c).edit().clear().commit()
    }
    fun restore(c: Context) {
        if(status(c) != "ready") return
        prefs(c).all.keys.filter { it.startsWith("alarm_") }.forEach {
            try { next(c,it.substringAfter('_').toInt()) } catch(_: Exception) {}
        }
        prefs(c).all.keys.filter { it.startsWith("snooze_") }.forEach {
            val time = prefs(c).getLong(it,0)
            if(time > System.currentTimeMillis()) at(c,it.substringAfter('_').toInt(),time,true)
            else prefs(c).edit().remove(it).commit()
        }
    }
    fun fired(c: Context,id: Int,snooze: Boolean) {
        if(snooze) prefs(c).edit().remove("snooze_$id").commit() else next(c,id)
    }
}
class PrayerAlarmReceiver: BroadcastReceiver() {
    override fun onReceive(context: Context,intent: Intent) {
        if(intent.action != "RING") { AlarmStore.restore(context); return }
        if(AlarmStore.status(context) != "ready") return
        val id = intent.getIntExtra("id",0)
        try { AlarmStore.fired(context,id,intent.getBooleanExtra("snooze",false)) } catch(_: Exception) {}
        val service = Intent(context,PrayerAlarmService::class.java).putExtra("id",id)
        if(Build.VERSION.SDK_INT >= 26) context.startForegroundService(service) else context.startService(service)
    }
}
class PrayerAlarmService: Service() {
    companion object {
        var activeId: Int? = null
        private const val CHANNEL = "prayer_alarm_v1"
    }
    private var player: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var occurrence: String? = null
    private val handler = Handler(Looper.getMainLooper())
    private val spanish get() = resources.configuration.locales[0].language == "es"
    override fun onBind(intent: Intent?) = null
    override fun onStartCommand(intent: Intent?,flags: Int,startId: Int): Int {
        if(intent?.action == "STOP" || intent?.action == "SNOOZE") {
            // Old notification actions must never act on a newer occurrence.
            if(activeId == null || intent.getIntExtra("id", -1) != activeId ||
                intent.getStringExtra("occurrence") != occurrence) {
                if(activeId == null) stopSelf()
                return START_NOT_STICKY
            }
            if(intent.action == "SNOOZE") {
                try { AlarmStore.at(this,activeId!!,System.currentTimeMillis()+600000,true) }
                catch(_: Exception) { return START_NOT_STICKY }
            }
            stopSelf(); return START_NOT_STICKY
        }
        if(intent == null || !intent.hasExtra("id")) { stopSelf(); return START_NOT_STICKY }
        val id = intent.getIntExtra("id",0)
        if(activeId != null) {
            // First ringing reminder wins. Persist overlaps as ten-minute snoozes,
            // so opening prayer or stopping this service cannot discard them.
            if(activeId != id) {
                try { AlarmStore.deferOverlap(this,id) }
                catch(_: Exception) { /* Existing alarm remains actionable. */ }
            }
            return START_NOT_STICKY
        }
        activeId = id
        occurrence = UUID.randomUUID().toString()
        val nm = getSystemService(NotificationManager::class.java)
        if(Build.VERSION.SDK_INT >= 26) {
            nm.createNotificationChannel(NotificationChannel(CHANNEL,"Prayer alarms",NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Scheduled prayer alarms with Stop and Snooze"; setSound(null,null)
            })
        }
        val open = PendingIntent.getActivity(this,id,Intent(this,MainActivity::class.java)
            .setData(Uri.parse("cercano://alarm/$id/$occurrence/open"))
            .putExtra("openPrayer",true).putExtra("reminderID",id)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        fun action(name: String,code: Int) = PendingIntent.getService(this,code,
            Intent(this,PrayerAlarmService::class.java).setAction(name)
                .setData(Uri.parse("cercano://alarm/$id/$occurrence/$name"))
                .putExtra("id",id).putExtra("occurrence",occurrence),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        @Suppress("DEPRECATION")
        val notification = (if(Build.VERSION.SDK_INT >= 26) Notification.Builder(this,CHANNEL) else Notification.Builder(this))
            .setSmallIcon(R.drawable.ic_alarm)
            .setContentTitle(if (spanish) "Un momento para orar" else "A time for prayer")
            .setContentText(if (spanish) "Haz una pausa y da gracias con Cercano a Dios." else "Cercano a Dios · Pause and give thanks")
            .setCategory(Notification.CATEGORY_ALARM).setOngoing(true).setContentIntent(open)
            .addAction(Notification.Action.Builder(null,if (spanish) "Detener" else "Stop",action("STOP",2)).build())
            .addAction(Notification.Action.Builder(null,if (spanish) "Posponer 10 min" else "Snooze 10 min",action("SNOOZE",3)).build())
            .build()
        startForeground(2001,notification)
        player?.release(); handler.removeCallbacksAndMessages(null)
        if(wakeLock?.isHeld == true) wakeLock?.release()
        wakeLock = getSystemService(PowerManager::class.java).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,"Cercano:alarm").apply { acquire(130000) }
        try {
            player = MediaPlayer().apply {
                setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
                setDataSource(this@PrayerAlarmService, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
                isLooping = true; prepare(); start()
            }
        } catch(_: Exception) { /* System notification remains actionable if audio cannot play. */ }
        handler.postDelayed({ stopSelf() },120000)
        return START_NOT_STICKY
    }
    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null); player?.release(); player = null
        if(wakeLock?.isHeld == true) wakeLock?.release()
        activeId = null; occurrence = null; stopForeground(STOP_FOREGROUND_REMOVE); super.onDestroy()
    }
}
