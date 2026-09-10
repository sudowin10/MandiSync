import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isBackendHealthy = false;
  String _healthStatusText = 'Checking API...';

  bool get isBackendHealthy => _isBackendHealthy;
  String get healthStatusText => _healthStatusText;

  Future<void> checkBackendHealth() async {
    final healthy = await _api.checkHealth();
    _isBackendHealthy = healthy;
    final hostPort = ApiConstants.rootBase.replaceFirst(RegExp(r'^https?:\/\/'), '');
    _healthStatusText = healthy ? 'API Online (v1.0)' : 'API Offline ($hostPort)';
    notifyListeners();
  }
}
