import 'package:flutter/material.dart';
import '../models/widget_model.dart';
import '../services/project_service.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectService _projectService = ProjectService();

  ProjectModel? _currentProject;
  List<ProjectModel> _projects = [];
  bool _isLoading = false;
  String? _error;

  ProjectModel? get currentProject => _currentProject;
  List<ProjectModel> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _projects = await _projectService.getProjects();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProject(String projectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentProject = await _projectService.getProject(projectId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createProject(String name, String description) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final project = await _projectService.createProject(name, description);
      _projects.add(project);
      _currentProject = project;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProject(ProjectModel project) async {
    try {
      await _projectService.updateProject(project);
      _currentProject = project;
      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _projects[index] = project;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await _projectService.deleteProject(projectId);
      _projects.removeWhere((p) => p.id == projectId);
      if (_currentProject?.id == projectId) {
        _currentProject = null;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> saveWidgets(String projectId, String screenId, List<WidgetModel> widgets) async {
    try {
      await _projectService.updateScreenWidgets(projectId, screenId, widgets);
      if (_currentProject != null) {
        final screenIndex = _currentProject!.screens.indexWhere((s) => s.id == screenId);
        if (screenIndex != -1) {
          _currentProject!.screens[screenIndex].widgets = widgets;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}