package com.taskmaster.task_master

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.taskmaster.llm/inference"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            // Stubs for compatibility if any old Dart code still calls this
            when (call.method) {
                "initialize" -> result.success(true)
                "generateResponse" -> result.success("Native LLM disabled. Use local Dart engine.")
                "startStream" -> result.error("DISABLED", "Native LLM disabled", null)
                else -> result.notImplemented()
            }
        }
    }
}
