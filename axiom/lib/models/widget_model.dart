import 'package:flutter/material.dart';

class WidgetModel {
  String id;
  String type;
  Map<String, dynamic> properties;
  List<WidgetModel> children;
  Offset position;
  String? parent;

  // NEW: API Integration properties
  String? apiEndpointId;
  String? apiMethod;
  String? apiPath;
  Map<String, String>? apiHeaders;
  bool requiresAuth;

  WidgetModel({
    required this.id,
    required this.type,
    this.properties = const {},
    this.children = const [],
    this.position = Offset.zero,
    this.parent,
    this.apiEndpointId,
    this.apiMethod,
    this.apiPath,
    this.apiHeaders,
    this.requiresAuth = false,
  });

  factory WidgetModel.fromJson(Map<String, dynamic> json) {
    return WidgetModel(
      id: json['id'],
      type: json['type'],
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      children: (json['children'] as List?)
          ?.map((e) => WidgetModel.fromJson(e))
          .toList() ??
          [],
      position: json['position'] != null
          ? Offset(
        (json['position']['x'] ?? 0).toDouble(),
        (json['position']['y'] ?? 0).toDouble(),
      )
          : Offset.zero,
      parent: json['parent'],
      apiEndpointId: json['apiEndpointId'],
      apiMethod: json['apiMethod'],
      apiPath: json['apiPath'],
      apiHeaders: json['apiHeaders'] != null
          ? Map<String, String>.from(json['apiHeaders'])
          : null,
      requiresAuth: json['requiresAuth'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'properties': properties,
      'children': children.map((e) => e.toJson()).toList(),
      'position': {'x': position.dx, 'y': position.dy},
      'parent': parent,
      'apiEndpointId': apiEndpointId,
      'apiMethod': apiMethod,
      'apiPath': apiPath,
      'apiHeaders': apiHeaders,
      'requiresAuth': requiresAuth,
    };
  }

  WidgetModel copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? properties,
    List<WidgetModel>? children,
    Offset? position,
    String? parent,
    String? apiEndpointId,
    String? apiMethod,
    String? apiPath,
    Map<String, String>? apiHeaders,
    bool? requiresAuth,
  }) {
    return WidgetModel(
      id: id ?? this.id,
      type: type ?? this.type,
      properties: properties ?? this.properties,
      children: children ?? this.children,
      position: position ?? this.position,
      parent: parent ?? this.parent,
      apiEndpointId: apiEndpointId ?? this.apiEndpointId,
      apiMethod: apiMethod ?? this.apiMethod,
      apiPath: apiPath ?? this.apiPath,
      apiHeaders: apiHeaders ?? this.apiHeaders,
      requiresAuth: requiresAuth ?? this.requiresAuth,
    );
  }
}

// Keep all other model classes (ProjectModel, ScreenModel, etc.) the same as in your original file
class ProjectModel {
  String id;
  String name;
  String description;
  List<ScreenModel> screens;
  ThemeModel theme;
  List<ApiEndpoint> apis;
  List<DataModel> dataModels;

  ProjectModel({
    required this.id,
    required this.name,
    this.description = '',
    this.screens = const [],
    required this.theme,
    this.apis = const [],
    this.dataModels = const [],
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      screens: (json['screens'] as List?)
          ?.map((e) => ScreenModel.fromJson(e))
          .toList() ??
          [],
      theme: ThemeModel.fromJson(json['theme'] ?? {}),
      apis: (json['apis'] as List?)
          ?.map((e) => ApiEndpoint.fromJson(e))
          .toList() ??
          [],
      dataModels: (json['dataModels'] as List?)
          ?.map((e) => DataModel.fromJson(e))
          .toList() ??
          [],
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
    };
  }
}

class ScreenModel {
  String id;
  String name;
  String route;
  List<WidgetModel> widgets;

  ScreenModel({
    required this.id,
    required this.name,
    required this.route,
    this.widgets = const [],
  });

  factory ScreenModel.fromJson(Map<String, dynamic> json) {
    return ScreenModel(
      id: json['id'],
      name: json['name'],
      route: json['route'],
      widgets: (json['widgets'] as List?)
          ?.map((e) => WidgetModel.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'route': route,
      'widgets': widgets.map((e) => e.toJson()).toList(),
    };
  }
}

class ThemeModel {
  String primaryColor;
  String accentColor;
  String fontFamily;
  bool darkMode;

  ThemeModel({
    this.primaryColor = '#2196F3',
    this.accentColor = '#FF5722',
    this.fontFamily = 'Roboto',
    this.darkMode = false,
  });

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      primaryColor: json['primaryColor'] ?? '#2196F3',
      accentColor: json['accentColor'] ?? '#FF5722',
      fontFamily: json['fontFamily'] ?? 'Roboto',
      darkMode: json['darkMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor,
      'accentColor': accentColor,
      'fontFamily': fontFamily,
      'darkMode': darkMode,
    };
  }
}

class ApiEndpoint {
  String id;
  String method;
  String path;
  String description;
  bool auth;

  ApiEndpoint({
    required this.id,
    required this.method,
    required this.path,
    this.description = '',
    this.auth = false,
  });

  factory ApiEndpoint.fromJson(Map<String, dynamic> json) {
    return ApiEndpoint(
      id: json['id'],
      method: json['method'],
      path: json['path'],
      description: json['description'] ?? '',
      auth: json['auth'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'path': path,
      'description': description,
      'auth': auth,
    };
  }
}

class DataModel {
  String id;
  String name;
  List<ModelField> fields;

  DataModel({
    required this.id,
    required this.name,
    this.fields = const [],
  });

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      id: json['id'],
      name: json['name'],
      fields: (json['fields'] as List?)
          ?.map((e) => ModelField.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fields': fields.map((e) => e.toJson()).toList(),
    };
  }
}

class ModelField {
  String name;
  String type;
  bool required;
  bool unique;

  ModelField({
    required this.name,
    required this.type,
    this.required = false,
    this.unique = false,
  });

  factory ModelField.fromJson(Map<String, dynamic> json) {
    return ModelField(
      name: json['name'],
      type: json['type'],
      required: json['required'] ?? false,
      unique: json['unique'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'required': required,
      'unique': unique,
    };
  }
}