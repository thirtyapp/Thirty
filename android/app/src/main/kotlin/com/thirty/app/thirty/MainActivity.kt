package com.thirty.app.thirty

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
                        guidance.play(call.argument<List<String>>("assets") ?: emptyList())
                        result.success(null)
                    }
                    "stop" -> {
                        guidance.stop()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        guidance?.stop()
        guidance = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
