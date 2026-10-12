package com.thirty.app.thirty

import android.os.Build
import android.os.Bundle
import android.window.OnBackInvokedDispatcher
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.LocalDate

class MainActivity : FlutterActivity() {
    private var guidance: GuidanceAudio? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DailyReminder.CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> result.success(
                        DailyReminder.schedule(
                            applicationContext,
                            LocalDate.parse(call.argument<String>("firstDate")!!),
                            call.argument<Int>("hour")!!,
                            call.argument<Int>("minute")!!,
                            call.argument<String>("title")!!,
                            call.argument<String>("body")!!,
                        ),
                    )
                    "cancel" -> {
                        DailyReminder.cancel(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        val guidance = GuidanceAudio(applicationContext).also { this.guidance = it }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GuidanceAudio.CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        guidance.play(
                            call.argument<List<String>>("assets") ?: emptyList(),
                            call.argument<Boolean>("deferToScreenReader") ?: false,
                        )
                        result.success(null)
                    }
                    "stop" -> {
                        guidance.stop()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        guidance.onIdle = { GuidanceService.audioIdle() }
        val session = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GuidanceService.CHANNEL)
        session.setMethodCallHandler { call, result ->
            when (call.method) {
                "show" -> {
                    GuidanceService.show(
                        applicationContext,
                        GuidanceService.Status(
                            title = call.argument<String>("title") ?: "",
                            part = call.argument<String>("part") ?: "",
                            paused = call.argument<Boolean>("paused") ?: false,
                            keepAwakeMs = (call.argument<Number>("keepAwakeMs") ?: 0).toLong(),
                            pauseLabel = call.argument<String>("pauseLabel") ?: "",
                            resumeLabel = call.argument<String>("resumeLabel") ?: "",
                            nextLabel = call.argument<String>("nextLabel") ?: "",
                            channelName = call.argument<String>("channelName") ?: "",
                        ),
                    )
                    result.success(null)
                }
                "end" -> {
                    GuidanceService.end(call.argument<Boolean>("afterSpeech") ?: false, guidance)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        // The notification's controls reach the Circle through Flutter.
        GuidanceService.onAction = { action -> session.invokeMethod("action", action) }
    }

    /**
     * Back at THIRTY's first screen sends it to the background, as Android
     * 12+ does for a launcher app, instead of finishing the activity.
     * Finishing ended Flutter, and with it a voiced Circle under way: its
     * cues stopped until THIRTY was opened again (S25 finding, D2 final
     * hardening). On Android 13+ Flutter withdraws its back callback once
     * it has nothing to pop, and Android 16's default then finishes the
     * activity; this callback, registered before Flutter's own, is the one
     * left. Flutter's callback always sits above it while there is
     * anything to go back to. Older versions reach [popSystemNavigator].
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT,
            ) { moveTaskToBack(true) }
        }
        super.onCreate(savedInstanceState)
    }

    override fun popSystemNavigator(): Boolean {
        moveTaskToBack(true)
        return true
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // Without Flutter there is no Circle to keep going.
        GuidanceService.onAction = null
        GuidanceService.end(false, null)
        guidance?.onIdle = null
        guidance?.stop()
        guidance = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
