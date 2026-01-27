package com.taskmaster.task_master

import android.os.Bundle
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.taskmaster.llm/inference"
    private val STREAM_CHANNEL = "com.taskmaster.llm/stream"
    private var llmInference: LlmInference? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isGenerating = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup Event Channel for Streaming
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STREAM_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val modelPath = call.argument<String>("modelPath")
                    if (modelPath != null) {
                        try {
                            val options = LlmInference.LlmInferenceOptions.builder()
                                .setModelPath(modelPath)
                                .setMaxTokens(512)
                                .setTemperature(0.7f)
                                .setRandomSeed(101)
                                .setResultListener { partialResponse, done ->
                                    runOnUiThread {
                                        if (done) {
                                            isGenerating = false
                                        }
                                        if (eventSink != null) {
                                            if (done) {
                                                eventSink?.success(mapOf("done" to true))
                                            } else {
                                                eventSink?.success(mapOf("text" to partialResponse))
                                            }
                                        }
                                    }
                                }
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
                    // Legacy non-streaming method (kept for compatibility)
                    val prompt = call.argument<String>("prompt")
                    if (prompt != null) {
                        val inference = llmInference
                        if (inference != null) {
                            CoroutineScope(Dispatchers.IO).launch {
                                try {
                                    val formattedPrompt = "<start_of_turn>user\n$prompt\n<end_of_turn>model\n"
                                    val response = inference.generateResponse(formattedPrompt)
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
                "startStream" -> {
                    val prompt = call.argument<String>("prompt")
                    if (prompt != null) {
                        val inference = llmInference
                        if (inference != null) {
                            if (isGenerating) {
                                result.error("BUSY", "Previous response still generating", null)
                                return@setMethodCallHandler
                            }

                            val formattedPrompt = "<start_of_turn>user\n$prompt\n<end_of_turn>model\n"
                            
                            isGenerating = true
                            try {
                                inference.generateResponseAsync(formattedPrompt)
                                result.success(null) 
                            } catch (e: Exception) {
                                isGenerating = false
                                result.error("failed", e.message, null)
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
