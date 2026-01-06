import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ProjectModel.dart';
import '../models/widget_model.dart';
import 'auth_service.dart';

class ProjectService {
  static const String baseUrl = 'https://axiom-mmd4.onrender.com/api';
  final AuthService _authService = AuthService();

  Future<List<ProjectModel>> getProjects() async {
    await _authService.loadToken();

    final response = await http.get(
      Uri.parse('$baseUrl/projects?all=true'),
      headers: _authService.getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ProjectModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load projects');
  }

  Future<ProjectModel> getProject(String id) async {
    await _authService.loadToken();

    final response = await http.get(
      Uri.parse('$baseUrl/projects/$id'),
      headers: _authService.getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return ProjectModel.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load project');
  }

  Future<ProjectModel> createProject(String name, String description) async {
    await _authService.loadToken();

    final response = await http.post(
      Uri.parse('$baseUrl/projects'),
      headers: _authService.getAuthHeaders(),
      body: json.encode({
        'name': name,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      return ProjectModel.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create project');
  }

  Future<void> updateProject(ProjectModel project) async {
    await _authService.loadToken();

    final response = await http.put(
      Uri.parse('$baseUrl/projects/${project.id}'),
      headers: _authService.getAuthHeaders(),
      body: json.encode(project.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update project');
    }
  }

  Future<void> deleteProject(String id) async {
    await _authService.loadToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/projects/$id'),
      headers: _authService.getAuthHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete project');
    }
  }

  Future<void> updateScreenWidgets(
      String projectId,
      String screenId,
      List<WidgetModel> widgets,
      ) async {
    await _authService.loadToken();

    final response = await http.put(
      Uri.parse('$baseUrl/projects/$projectId/screens/$screenId/widgets'),
      headers: _authService.getAuthHeaders(),
      body: json.encode({
        'widgets': widgets.map((w) => w.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update widgets');
    }
  }

  Future<Map<String, dynamic>> generateUIFromDescription(String description) async {
    await _authService.loadToken();

    final response = await http.post(
      Uri.parse('$baseUrl/ai/generate-ui'),
      headers: _authService.getAuthHeaders(),
      body: json.encode({'description': description}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to generate UI');
  }
}