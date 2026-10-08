package com.thirty.app.thirty

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * THIRTY's one daily reminder — REMINDER-1.
 *
 * flutter_local_notifications' daily repeat (`DateTimeComponents.time`)
 * always restarts from the next matching time after *now*, so it cannot
 * begin on a later day: a reminder skipped because today's Circle is
 * already closed came straight back. This scheduler keeps one exact
 * alarm armed for the next eligible day and re-arms itself every time it
 * fires, so reminders continue daily without THIRTY being opened.
 *
 * Flutter stays the source of truth. It sends the whole schedule on every
 * change (`schedule`), and this persists only what an alarm must know
 * while Flutter is not running: the first date that may fire, the time,
 * and the notification's title and body. A new `schedule` or `cancel`
 * replaces that state completely.
 */
object DailyReminder {
    const val CHANNEL = "com.thirty.app/daily_reminder"

    // The id the reminder has always used — a new day's reminder replaces
    // an unread one instead of stacking under it.
    private const val NOTIFICATION_ID = 7301
    private const val CHANNEL_ID = "thirty_reminder"
    private const val CHANNEL_NAME = "Daily reminder"
    private const val CHANNEL_DESCRIPTION = "Your optional daily THIRTY reminder."

    private const val PREFS = "thirty_daily_reminder"
    private const val KEY_FIRST_DATE = "first_date"
    private const val KEY_HOUR = "hour"
    private const val KEY_MINUTE = "minute"
    private const val KEY_TITLE = "title"
    private const val KEY_BODY = "body"
    private const val KEY_ARMED_AT = "armed_at"
    private const val EXTRA_ARMED_AT = "armed_at"

    /** The earliest [hour]:[minute] on or after [firstDate] still ahead of [now]. */
    fun nextTrigger(firstDate: LocalDate, hour: Int, minute: Int, now: ZonedDateTime): ZonedDateTime {
        var date = maxOf(firstDate, now.toLocalDate())
        while (true) {
            val trigger = date.atTime(hour, minute).atZone(now.zone)
            if (trigger.isAfter(now)) return trigger
            date = date.plusDays(1)
        }
    }

    /** Replaces the schedule. Returns `scheduled` or `exactAlarmAccessDenied`. */
    fun schedule(
        context: Context,
        firstDate: LocalDate,
        hour: Int,
        minute: Int,
        title: String,
        body: String,
    ): String {
        prefs(context).edit()
            .putString(KEY_FIRST_DATE, firstDate.toString())
            .putInt(KEY_HOUR, hour)
            .putInt(KEY_MINUTE, minute)
            .putString(KEY_TITLE, title)
            .putString(KEY_BODY, body)
            .commit()
        return if (arm(context)) "scheduled" else "exactAlarmAccessDenied"
    }

    /** Removes the schedule and any pending alarm. */
    fun cancel(context: Context) {
        alarmManager(context).cancel(alarmIntent(context, 0L))
        prefs(context).edit().clear().commit()
    }

    /**
     * Arms the one alarm from the stored schedule — after a reboot, a clock
     * or timezone change, or regained exact-alarm access. Without exact
     * access nothing is armed: never an inexact fallback.
     */
    fun arm(context: Context): Boolean {
        val alarms = alarmManager(context)
        val stored = prefs(context)
        val firstDate = stored.getString(KEY_FIRST_DATE, null) ?: return false
        alarms.cancel(alarmIntent(context, 0L))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarms.canScheduleExactAlarms()) {
            stored.edit().remove(KEY_ARMED_AT).commit()
            return false
        }
        val trigger = nextTrigger(
            LocalDate.parse(firstDate),
            stored.getInt(KEY_HOUR, 0),
            stored.getInt(KEY_MINUTE, 0),
            ZonedDateTime.now(ZoneId.systemDefault()),
        ).toInstant().toEpochMilli()
        stored.edit().putLong(KEY_ARMED_AT, trigger).commit()
        alarms.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            trigger,
            alarmIntent(context, trigger),
        )
        return true
    }

    /** The armed alarm went off: show today's reminder, then arm tomorrow's. */
    fun onAlarm(context: Context, armedAt: Long) {
        val stored = prefs(context)
        if (stored.getString(KEY_FIRST_DATE, null) == null) return
        // Only the alarm armed last may notify — never one from a schedule
        // Flutter has since replaced.
        if (armedAt != stored.getLong(KEY_ARMED_AT, -1L)) {
            arm(context)
            return
        }
        val zone = ZoneId.systemDefault()
        val firedDate = Instant.ofEpochMilli(armedAt).atZone(zone).toLocalDate()
        // A reminder belongs to its own day — never delivered late into
        // another one.
        if (firedDate == LocalDate.now(zone)) {
            notify(
                context,
                stored.getString(KEY_TITLE, "") ?: "",
                stored.getString(KEY_BODY, "") ?: "",
            )
        }
        stored.edit().putString(KEY_FIRST_DATE, firedDate.plusDays(1).toString()).commit()
        arm(context)
    }

    private fun notify(context: Context, title: String, body: String) {
        val manager = context.getSystemService(NotificationManager::class.java)
        if (!manager.areNotificationsEnabled()) return
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_LOW)
                    .apply { description = CHANNEL_DESCRIPTION },
            )
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
        }
        val open = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val notification = builder
            .setSmallIcon(R.drawable.ic_stat_thirty)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .apply {
                if (open != null) {
                    setContentIntent(
                        PendingIntent.getActivity(
                            context,
                            0,
                            open,
                            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                        ),
                    )
                }
            }
            .build()
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun alarmIntent(context: Context, armedAt: Long): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            NOTIFICATION_ID,
            Intent(context, DailyReminderAlarmReceiver::class.java)
                .putExtra(EXTRA_ARMED_AT, armedAt),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

    private fun alarmManager(context: Context) =
        context.getSystemService(AlarmManager::class.java)

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    internal fun armedAtOf(intent: Intent) = intent.getLongExtra(EXTRA_ARMED_AT, 0L)
}

/** The exact alarm's target. */
class DailyReminderAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        DailyReminder.onAlarm(context, DailyReminder.armedAtOf(intent))
    }
}

/**
 * Alarms do not survive a reboot or an app update, and a changed clock or
 * timezone moves the local reminder time — each re-arms from the stored
 * schedule. So does regaining exact-alarm access.
 */
class DailyReminderRearmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        DailyReminder.arm(context)
    }
}
