package com.taskmaster.task_master

import android.os.Bundle
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.taskmaster.llm/inference"
    private var llmInference: LlmInference? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val modelPath = call.argument<String>("modelPath")
                    if (modelPath != null) {
                        try {
                            val options = LlmInference.LlmInferenceOptions.builder()
                                .setModelPath(modelPath)
                                .setTemperature(0.7f)
                                .build()
                            llmInference = LlmInference.createFromOptions(this, options)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INIT_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARG", "Model path is required", null)
                    }
                }
                "generateResponse" -> {
                    val prompt = call.argument<String>("prompt")
                    if (prompt != null) {
                        val inference = llmInference
                        if (inference != null) {
                            CoroutineScope(Dispatchers.IO).launch {
                                try {
                                    val response = inference.generateResponse(prompt)
                                    withContext(Dispatchers.Main) {
                                        result.success(response)
                                    }
                                } catch (e: Exception) {
                                    withContext(Dispatchers.Main) {
                                        result.error("INFERENCE_FAILED", e.message, null)
                                    }
                                }
                            }
                        } else {
                            result.error("NOT_INITIALIZED", "LLM is not initialized", null)
                        }
                    } else {
                        result.error("INVALID_ARG", "Prompt is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        llmInference?.close()
    }
}
