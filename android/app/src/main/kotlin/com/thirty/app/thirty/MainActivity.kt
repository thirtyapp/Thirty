package com.thirty.app.thirty

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.LocalDate

class MainActivity : FlutterActivity() {
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
    }
}
