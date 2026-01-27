import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

enum ServerStatus { online, offline, waking, checking }

class ServerService extends ChangeNotifier {
  ServerStatus _status = ServerStatus.checking;
  ServerStatus get status => _status;

  Timer? _warmingTimer;

  ServerService() {
    startWarming();
  }

  Future<void> checkHealth() async {
    final baseUrl =
        AppConstants.dataCollectionServerUrl.replaceFirst('/collect', '');
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        _status = ServerStatus.online;
      } else {
        _status = ServerStatus.waking;
      }
    } catch (e) {
      _status = ServerStatus.offline;
    }
    notifyListeners();
  }

  void startWarming() {
    // Initial check
    checkHealth();

    // Ping every 5 minutes to keep Render alive
    _warmingTimer?.cancel();
    _warmingTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      checkHealth();
    });
  }

  @override
  void dispose() {
    _warmingTimer?.cancel();
    super.dispose();
  }
}

final serverServiceProvider = ChangeNotifierProvider<ServerService>((ref) {
  return ServerService();
});
