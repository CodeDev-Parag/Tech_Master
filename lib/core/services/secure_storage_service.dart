import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _keyGeminiApiKey = 'gemini_api_key';

  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _keyGeminiApiKey, value: apiKey);
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: _keyGeminiApiKey);
  }

  Future<void> deleteApiKey() async {
    await _storage.delete(key: _keyGeminiApiKey);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }
}
