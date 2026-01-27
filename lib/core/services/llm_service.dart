import 'package:flutter/services.dart';
import 'dart:io';

class LlmService {
  static const MethodChannel _channel =
      MethodChannel('com.taskmaster.llm/inference');

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize(String modelPath) async {
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
      return success;
    } on PlatformException catch (e) {
      print('Failed to initialize LLM: ${e.message}');
      return false;
    }
  }

  Future<String?> generateResponse(String prompt) async {
    if (!_isInitialized) return null;

    try {
      final String? response =
          await _channel.invokeMethod('generateResponse', {'prompt': prompt});
      return response;
    } on PlatformException catch (e) {
      print('Inference failed: ${e.message}');
      return null;
    }
  }
}
