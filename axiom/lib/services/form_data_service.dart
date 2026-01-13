import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class FormDataService {
  static const String baseUrl = 'https://axiom-mmd4.onrender.com/api';
  static const String _formDataKey = 'saved_form_data';

  // Save form data to backend database
  static Future<bool> saveFormData({
    required String screenId,
    required String screenName,
    required Map<String, dynamic> formData,
  }) async {
    try {
      final authService = AuthService();
      await authService.loadToken();

      final response = await http.post(
        Uri.parse('$baseUrl/form-data/save'),
        headers: {
          'Content-Type': 'application/json',
          if (authService.token != null) 'Authorization': 'Bearer ${authService.token}',
        },
        body: json.encode({
          'screenId': screenId,
          'screenName': screenName,
          'formData': formData,
        }),
      );

      if (response.statusCode == 201) {
        // Also save locally for offline access
        await _saveFormDataLocally(screenId, screenName, formData);
        return true;
      }
      return false;
    } catch (e) {
      print('Error saving form data: $e');
      // Save locally even if backend fails
      await _saveFormDataLocally(screenId, screenName, formData);
      return false;
    }
  }

  // Get all saved form data for a screen
  static Future<List<Map<String, dynamic>>> getFormDataForScreen(String screenId) async {
    try {
      final authService = AuthService();
      await authService.loadToken();

      final response = await http.get(
        Uri.parse('$baseUrl/form-data/screen/$screenId'),
        headers: {
          'Content-Type': 'application/json',
          if (authService.token != null) 'Authorization': 'Bearer ${authService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
    } catch (e) {
      print('Error fetching form data: $e');
    }

    // Fallback to local storage
    return await _getFormDataLocally(screenId);
  }

  // Get all saved forms (for PreviewList)
  static Future<List<Map<String, dynamic>>> getAllSavedForms() async {
    try {
      final authService = AuthService();
      await authService.loadToken();

      final response = await http.get(
        Uri.parse('$baseUrl/form-data/all'),
        headers: {
          'Content-Type': 'application/json',
          if (authService.token != null) 'Authorization': 'Bearer ${authService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
    } catch (e) {
      print('Error fetching all form data: $e');
    }

    // Fallback to local storage
    return await _getAllFormDataLocally();
  }

  // Delete saved form data
  static Future<bool> deleteFormData(String formId) async {
    try {
      final authService = AuthService();
      await authService.loadToken();

      final response = await http.delete(
        Uri.parse('$baseUrl/form-data/$formId'),
        headers: {
          'Content-Type': 'application/json',
          if (authService.token != null) 'Authorization': 'Bearer ${authService.token}',
        },
      );

      if (response.statusCode == 200) {
        await _deleteFormDataLocally(formId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting form data: $e');
      return false;
    }
  }

  // Local storage methods
  static Future<void> _saveFormDataLocally(String screenId, String screenName, Map<String, dynamic> formData) async {
    final prefs = await SharedPreferences.getInstance();
    final existingData = prefs.getString(_formDataKey) ?? '{}';
    final allData = json.decode(existingData);
    
    final formId = '${screenId}_${DateTime.now().millisecondsSinceEpoch}';
    allData[formId] = {
      'id': formId,
      'screenId': screenId,
      'screenName': screenName,
      'formData': formData,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_formDataKey, json.encode(allData));
  }

  static Future<List<Map<String, dynamic>>> _getFormDataLocally(String screenId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingData = prefs.getString(_formDataKey) ?? '{}';
    final allData = json.decode(existingData);
    
    return allData.values
        .where((form) => form['screenId'] == screenId)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  static Future<List<Map<String, dynamic>>> _getAllFormDataLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final existingData = prefs.getString(_formDataKey) ?? '{}';
    final allData = json.decode(existingData);
    
    return allData.values
        .cast<Map<String, dynamic>>()
        .toList();
  }

  static Future<void> _deleteFormDataLocally(String formId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingData = prefs.getString(_formDataKey) ?? '{}';
    final allData = json.decode(existingData);
    
    allData.remove(formId);
    await prefs.setString(_formDataKey, json.encode(allData));
  }
}
