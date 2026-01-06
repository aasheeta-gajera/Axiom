import 'ApiEndpointmodel.dart';
import 'DataModel.dart';
import 'ScreenModel.dart';
import 'ThemeModel.dart';

class ProjectModel {
  String id;
  String name;
  String description;
  List<ScreenModel> screens;
  ThemeModel theme;
  List<ApiEndpoint> apis;
  List<DataModel> dataModels; // Database models
  List<String> collections; // Available MongoDB collections

  ProjectModel({
    required this.id,
    required this.name,
    this.description = '',
    this.screens = const [],
    required this.theme,
    this.apis = const [],
    this.dataModels = const [],
    this.collections = const [],
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      screens: (json['screens'] as List?)
          ?.map((e) => ScreenModel.fromJson(e))
          .toList() ?? [],
      theme: ThemeModel.fromJson(json['theme'] ?? {}),
      apis: (json['apis'] as List?)
          ?.map((e) => ApiEndpoint.fromJson(e))
          .toList() ?? [],
      dataModels: (json['dataModels'] as List?)
          ?.map((e) => DataModel.fromJson(e))
          .toList() ?? [],
      collections: (json['collections'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'screens': screens.map((e) => e.toJson()).toList(),
      'theme': theme.toJson(),
      'apis': apis.map((e) => e.toJson()).toList(),
      'dataModels': dataModels.map((e) => e.toJson()).toList(),
      'collections': collections,
    };
  }
}
