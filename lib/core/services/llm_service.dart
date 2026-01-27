import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:async';

class LlmService {
  static const MethodChannel _channel =
      MethodChannel('com.taskmaster.llm/inference');
  static const EventChannel _streamChannel =
      EventChannel('com.taskmaster.llm/stream');

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize(String modelPath) async {
    if (kIsWeb) {
      print('LLM Service is not supported on Web');
      return false;
    }

    try {
      // Basic check for file existence if it's a readable path
      if (!modelPath.startsWith('/data/local/tmp/')) {
        // Common Android tmp path might not be readable directly by File()
        if (!await File(modelPath).exists()) {
          print('LLM model file not found at $modelPath');
          return false;
        }
      }

      final bool success =
          await _channel.invokeMethod('initialize', {'modelPath': modelPath});
      _isInitialized = success;

      // Initialize stream listener early to be ready
      _streamChannel.receiveBroadcastStream().listen((event) {
        // This global listener is just to keep the channel active if needed
      });

      return success;
    } on PlatformException catch (e) {
      print('Failed to initialize LLM: ${e.message}');
      return false;
    }
  }

  Future<String?> generateResponse(String prompt) async {
    if (kIsWeb || !_isInitialized) return null;

    try {
      final String? response =
          await _channel.invokeMethod('generateResponse', {'prompt': prompt});
      return response;
    } on PlatformException catch (e) {
      print('Inference failed: ${e.message}');
      return null;
    }
  }

  Stream<String> generateResponseStream(String prompt) async* {
    if (kIsWeb || !_isInitialized) {
      yield "LLM not initialized or not supported on Web.";
      return;
    }

    StreamController<String> controller = StreamController();

    // temporary subscription to the event channel
    final subscription = _streamChannel.receiveBroadcastStream().listen(
      (event) {
        final Map<dynamic, dynamic> map = event;
        if (map['done'] == true) {
          controller.close();
        } else if (map['text'] != null) {
          controller.add(map['text'] as String);
        }
      },
      onError: (error) {
        controller.addError(error);
        controller.close();
      },
    );

    try {
      // Trigger native generation
      await _channel.invokeMethod('startStream', {'prompt': prompt});

      // Yield chunks as they arrive from the controller
      await for (final chunk in controller.stream) {
        yield chunk;
      }
    } catch (e) {
      yield "Error: $e";
    } finally {
      await subscription.cancel();
      await controller.close();
    }
  }
}
