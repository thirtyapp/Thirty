package com.thirty.app.thirty

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager

/**
 * Keeps a voiced Circle going while THIRTY is out of sight (V2 Phase D2,
 * ADR-023 §6): a media-playback foreground service, so Android neither
 * freezes THIRTY nor lets the device sleep between cues, and the
 * notification Android requires for it — "Circle running", the part on
 * show, Pause/Resume and Next.
 *
 * It keeps no time and plays nothing: Flutter decides what is said and
 * when, from the Circle's stored facts, and [GuidanceAudio] plays it. The
 * service exists only from the user's Start of a voiced Circle until the
 * Circle ends — it is never started on its own, collects nothing and does
 * no other work. Removing THIRTY from Recents ends it ([stopWithTask]).
 */
class GuidanceService : Service() {
    /** What the notification shows. */
    data class Status(
        val title: String,
        val part: String,
        val paused: Boolean,
        val keepAwakeMs: Long,
        val pauseLabel: String,
        val resumeLabel: String,
        val nextLabel: String,
        val channelName: String,
    )

    companion object {
        const val CHANNEL = "com.thirty.app/guidance_session"
        private const val NOTIFICATION_CHANNEL = "circle_guidance"
        private const val NOTIFICATION_ID = 3030
        private const val ACTION_SHOW = "com.thirty.app.guidance.SHOW"
        private const val ACTION_PAUSE = "com.thirty.app.guidance.PAUSE"
        private const val ACTION_RESUME = "com.thirty.app.guidance.RESUME"
        private const val ACTION_NEXT = "com.thirty.app.guidance.NEXT"

        /** The longest the service waits for the ending to be spoken. */
        private const val FINISH_LIMIT_MS = 30_000L

        /** Receives the notification's controls (MainActivity → Flutter). */
        var onAction: ((String) -> Unit)? = null

        private var pending: Status? = null
        private var endPending = false
        private var running: GuidanceService? = null

        /**
         * Shows or updates the session. Started only from THIRTY in front
         * (Start, Resume, Next); a later update reaches the running
         * service directly. Android refusing a start is never an error —
         * the voice then speaks only in front.
         */
        fun show(context: Context, status: Status) {
            val service = running
            if (service != null) {
                service.update(status)
                return
            }
            pending = status
            endPending = false
            val intent = Intent(context, GuidanceService::class.java).setAction(ACTION_SHOW)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (_: Exception) {
                pending = null
            }
        }

        /** Ends the session — at once, or once [GuidanceAudio] falls idle. */
        fun end(afterSpeech: Boolean, audio: GuidanceAudio?) {
            val service = running
            if (service == null) {
                // A start still on its way must still come to the
                // foreground first, as Android requires; it ends at once.
                if (pending != null) endPending = true
                return
            }
            if (afterSpeech && audio?.isPlaying == true) {
                service.finishAfterSpeech()
            } else {
                service.finish()
            }
        }

        /** The voice has finished what it was saying. */
        fun audioIdle() {
            running?.let { if (it.finishing) it.finish() }
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null
    private var status: Status? = null
    private var finishing = false
    private val finishLimit = Runnable { finish() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SHOW -> {
                running = this
                val status = pending ?: this.status
                val ending = endPending
                pending = null
                endPending = false
                if (status != null) update(status)
                if (status == null || ending) finish()
            }
            ACTION_PAUSE -> onAction?.invoke("pause")
            ACTION_RESUME -> onAction?.invoke("resume")
            ACTION_NEXT -> onAction?.invoke("next")
        }
        if (intent?.action != ACTION_SHOW && running == null) stopSelf()
        // Never restarted by Android on its own: a Circle is the user's.
        return START_NOT_STICKY
    }

    private fun update(status: Status) {
        this.status = status
        finishing = false
        handler.removeCallbacks(finishLimit)
        val notification = notificationFor(status)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        if (status.paused || status.keepAwakeMs <= 0) {
            releaseWakeLock()
        } else {
            keepAwake(status.keepAwakeMs)
        }
    }

    private fun finishAfterSpeech() {
        finishing = true
        handler.removeCallbacks(finishLimit)
        handler.postDelayed(finishLimit, FINISH_LIMIT_MS)
    }

    private fun finish() {
        finishing = false
        handler.removeCallbacks(finishLimit)
        if (running === this) running = null
        releaseWakeLock()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacks(finishLimit)
        if (running === this) running = null
        releaseWakeLock()
        super.onDestroy()
    }

    /** Partial: the screen may sleep, THIRTY's timing may not. */
    private fun keepAwake(ms: Long) {
        val lock = wakeLock ?: (getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "thirty:circle_guidance")
            .apply { setReferenceCounted(false) }
            .also { wakeLock = it }
        lock.acquire(ms)
    }

    private fun releaseWakeLock() {
        wakeLock?.let { if (it.isHeld) it.release() }
    }

    private fun notificationFor(status: Status): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    NOTIFICATION_CHANNEL,
                    status.channelName,
                    NotificationManager.IMPORTANCE_LOW,
                ).apply { setShowBadge(false) },
            )
            Notification.Builder(this, NOTIFICATION_CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this).setPriority(Notification.PRIORITY_LOW)
        }
        val toggle = if (status.paused) {
            action(status.resumeLabel, ACTION_RESUME, 1)
        } else {
            action(status.pauseLabel, ACTION_PAUSE, 2)
        }
        builder
            .setSmallIcon(R.drawable.ic_stat_thirty)
            .setContentTitle(status.title)
            .setContentText(status.part)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .addAction(toggle)
            .addAction(action(status.nextLabel, ACTION_NEXT, 3))
        packageManager.getLaunchIntentForPackage(packageName)?.let { launch ->
            launch.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            builder.setContentIntent(
                PendingIntent.getActivity(this, 0, launch, immutable()),
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        }
        return builder.build()
    }

    private fun action(label: String, action: String, code: Int): Notification.Action {
        val intent = Intent(this, GuidanceService::class.java).setAction(action)
        val pending = PendingIntent.getService(this, code, intent, immutable())
        @Suppress("DEPRECATION")
        return Notification.Action.Builder(0, label, pending).build()
    }

    private fun immutable(): Int = PendingIntent.FLAG_UPDATE_CURRENT or
        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
}
