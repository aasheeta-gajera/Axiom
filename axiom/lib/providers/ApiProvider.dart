
import 'package:flutter/material.dart';
import '../models/ApiEndpointmodel.dart';
import '../providers/ProjectProvider.dart';

class ApiProvider extends ChangeNotifier {
  final ProjectProvider _projectProvider;

  ApiProvider(this._projectProvider);

  // State
  List<ApiEndpoint> _endpoints = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ApiEndpoint> get endpoints => _endpoints;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load APIs from current project
  Future<void> loadAPIs() async {
    if (_projectProvider.currentProject != null) {
      _endpoints = _projectProvider.currentProject!.apis;
      notifyListeners();
    }
  }

  // Create new API
  Future<bool> createAPI(ApiEndpoint api) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _projectProvider.createOrUpdateAPI(api);
      await loadAPIs();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create API: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update existing API
  Future<bool> updateAPI(ApiEndpoint api) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _projectProvider.createOrUpdateAPI(api);
      await loadAPIs();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update API: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete API
  Future<bool> deleteAPI(ApiEndpoint endpoint) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Implement delete logic here
      // await _projectProvider.deleteAPI(endpoint);

      _endpoints.remove(endpoint);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete API: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Test API
  Future<Map<String, dynamic>?> testAPI(ApiEndpoint endpoint) async {
    try {
      // Implement test logic here
      // This should make an actual HTTP request to test the endpoint

      // Return test results
      return {
        'success': true,
        'statusCode': 200,
        'response': 'Test successful',
      };
    } catch (e) {
      _errorMessage = 'Failed to test API: $e';
      notifyListeners();
      return null;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}