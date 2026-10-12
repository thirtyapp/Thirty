package com.thirty.app.thirty

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.view.accessibility.AccessibilityManager
import io.flutter.FlutterInjector

/**
 * Spoken guidance for a composed Circle (V2 Phase D2, ADR-023 §6).
 *
 * Plays bundled recordings — Flutter assets — one after another, offline.
 * While it speaks it asks for transient, duckable audio focus, so music
 * the user put on for their Circle only dips under the voice and comes
 * back. A clip that can't be opened is skipped; nothing here ever throws
 * back into Flutter. Flutter decides what to say and when.
 */
class GuidanceAudio(private val context: Context) {
    companion object {
        const val CHANNEL = "com.thirty.app/guidance_audio"
    }

    private val audioManager =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val accessibilityManager =
        context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()
    private val focusRequest: AudioFocusRequest? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(attributes)
                .build()
        } else {
            null
        }

    private var player: MediaPlayer? = null
    private var queue: List<String> = emptyList()

    /** Called whenever the voice falls silent after playing. */
    var onIdle: (() -> Unit)? = null

    /** Whether a clip is playing or still queued. */
    val isPlaying: Boolean
        get() = player != null || queue.isNotEmpty()

    /**
     * Plays [assets] in order, replacing anything still playing. With
     * [deferToScreenReader], nothing plays while a screen reader (touch
     * exploration — TalkBack) is on: it announces the part itself. Other
     * accessibility services don't count.
     */
    fun play(assets: List<String>, deferToScreenReader: Boolean) {
        stop()
        if (deferToScreenReader && accessibilityManager.isTouchExplorationEnabled) return
        queue = assets
        if (queue.isEmpty()) return
        requestFocus()
        playNext()
    }

    /** Stops at once and gives focus back. */
    fun stop() {
        queue = emptyList()
        player?.release()
        player = null
        abandonFocus()
    }

    private fun playNext() {
        player?.release()
        player = null
        while (queue.isNotEmpty()) {
            val asset = queue.first()
            queue = queue.drop(1)
            val next = open(asset) ?: continue
            player = next
            next.setOnCompletionListener { playNext() }
            next.start()
            return
        }
        abandonFocus()
        onIdle?.invoke()
    }

    private fun open(asset: String): MediaPlayer? {
        val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
        return try {
            context.assets.openFd(key).use { fd ->
                MediaPlayer().apply {
                    setAudioAttributes(attributes)
                    setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
                    prepare()
                }
            }
        } catch (_: Exception) {
            null
        }
    }

    @Suppress("DEPRECATION")
    private fun requestFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioManager.requestAudioFocus(focusRequest!!)
        } else {
            audioManager.requestAudioFocus(
                null,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK,
            )
        }
    }

    @Suppress("DEPRECATION")
    private fun abandonFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioManager.abandonAudioFocusRequest(focusRequest!!)
        } else {
            audioManager.abandonAudioFocus(null)
        }
    }
}
