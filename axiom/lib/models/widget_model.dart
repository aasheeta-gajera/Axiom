import 'package:flutter/material.dart';

// Enhanced Widget Model with complete event and data binding
class WidgetModel {
  String id;
  String type;
  Map<String, dynamic> properties;
  List<WidgetModel> children;
  Offset position;
  String? parent;

  // Data Binding
  String? bindToField; // MongoDB field name
  String? bindToCollection; // MongoDB collection
  String? dataSource; // API endpoint for data

  // API Binding Properties
  String? apiEndpointId;
  String? apiMethod;
  String? apiPath;
  bool requiresAuth;

  // Event Binding
  EventBinding? onClick;
  EventBinding? onChange;
  EventBinding? onSubmit;

  // For ListView items
  bool isListItem;
  Map<String, String>? dataMapping; // Maps widget properties to API response fields

  WidgetModel({
    required this.id,
    required this.type,
    this.properties = const {},
    this.children = const [],
    this.position = Offset.zero,
    this.parent,
    this.bindToField,
    this.bindToCollection,
    this.dataSource,
    this.apiEndpointId,
    this.apiMethod,
    this.apiPath,
    this.requiresAuth = false,
    this.onClick,
    this.onChange,
    this.onSubmit,
    this.isListItem = false,
    this.dataMapping,
  });

  factory WidgetModel.fromJson(Map<String, dynamic> json) {
    return WidgetModel(
      id: json['id'],
      type: json['type'],
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      children: (json['children'] as List?)
          ?.map((e) => WidgetModel.fromJson(e))
          .toList() ?? [],
      position: json['position'] != null
          ? Offset(
        (json['position']['x'] ?? 0).toDouble(),
        (json['position']['y'] ?? 0).toDouble(),
      )
          : Offset.zero,
      parent: json['parent'],
      bindToField: json['bindToField'],
      bindToCollection: json['bindToCollection'],
      dataSource: json['dataSource'],
      apiEndpointId: json['apiEndpointId'],
      apiMethod: json['apiMethod'],
      apiPath: json['apiPath'],
      requiresAuth: json['requiresAuth'] ?? false,
      onClick: json['onClick'] != null
          ? EventBinding.fromJson(json['onClick'])
          : null,
      onChange: json['onChange'] != null
          ? EventBinding.fromJson(json['onChange'])
          : null,
      onSubmit: json['onSubmit'] != null
          ? EventBinding.fromJson(json['onSubmit'])
          : null,
      isListItem: json['isListItem'] ?? false,
      dataMapping: json['dataMapping'] != null
          ? Map<String, String>.from(json['dataMapping'])
          : null,
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
      'bindToField': bindToField,
      'bindToCollection': bindToCollection,
      'dataSource': dataSource,
      'apiEndpointId': apiEndpointId,
      'apiMethod': apiMethod,
      'apiPath': apiPath,
      'requiresAuth': requiresAuth,
      'onClick': onClick?.toJson(),
      'onChange': onChange?.toJson(),
      'onSubmit': onSubmit?.toJson(),
      'isListItem': isListItem,
      'dataMapping': dataMapping,
    };
  }

  WidgetModel copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? properties,
    List<WidgetModel>? children,
    Offset? position,
    String? parent,
    String? bindToField,
    String? bindToCollection,
    String? dataSource,
    String? apiEndpointId,
    String? apiMethod,
    String? apiPath,
    bool? requiresAuth,
    EventBinding? onClick,
    EventBinding? onChange,
    EventBinding? onSubmit,
    bool? isListItem,
    Map<String, String>? dataMapping,
  }) {
    return WidgetModel(
      id: id ?? this.id,
      type: type ?? this.type,
      properties: properties ?? this.properties,
      children: children ?? this.children,
      position: position ?? this.position,
      parent: parent ?? this.parent,
      bindToField: bindToField ?? this.bindToField,
      bindToCollection: bindToCollection ?? this.bindToCollection,
      dataSource: dataSource ?? this.dataSource,
      apiEndpointId: apiEndpointId ?? this.apiEndpointId,
      apiMethod: apiMethod ?? this.apiMethod,
      apiPath: apiPath ?? this.apiPath,
      requiresAuth: requiresAuth ?? this.requiresAuth,
      onClick: onClick ?? this.onClick,
      onChange: onChange ?? this.onChange,
      onSubmit: onSubmit ?? this.onSubmit,
      isListItem: isListItem ?? this.isListItem,
      dataMapping: dataMapping ?? this.dataMapping,
    );
  }
}

// Event Binding Model
class EventBinding {
  String action; // 'callAPI', 'navigate', 'setState', 'validate'
  String? apiId;
  String? apiMethod;
  String? apiPath;
  Map<String, String>? fieldMapping; // Maps form fields to API body
  String? navigateTo;
  Map<String, dynamic>? parameters;

  EventBinding({
    required this.action,
    this.apiId,
    this.apiMethod,
    this.apiPath,
    this.fieldMapping,
    this.navigateTo,
    this.parameters,
  });

  factory EventBinding.fromJson(Map<String, dynamic> json) {
    return EventBinding(
      action: json['action'],
      apiId: json['apiId'],
      apiMethod: json['apiMethod'],
      apiPath: json['apiPath'],
      fieldMapping: json['fieldMapping'] != null
          ? Map<String, String>.from(json['fieldMapping'])
          : null,
      navigateTo: json['navigateTo'],
      parameters: json['parameters'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'apiId': apiId,
      'apiMethod': apiMethod,
      'apiPath': apiPath,
      'fieldMapping': fieldMapping,
      'navigateTo': navigateTo,
      'parameters': parameters,
    };
  }
}

// Enhanced API Endpoint Model
class ApiEndpoint {
  String id;
  String name;
  String method;
  String path;
  String description;
  String purpose; // 'login', 'register', 'create', 'read', 'update', 'delete', 'list'
  bool auth;

  // Database configuration
  String collection; // MongoDB collection name
  List<ApiField> fields;
  bool createCollection;

  // Request/Response examples
  Map<String, dynamic>? requestExample;
  Map<String, dynamic>? responseExample;

  ApiEndpoint({
    required this.id,
    required this.name,
    required this.method,
    required this.path,
    this.description = '',
    required this.purpose,
    this.auth = false,
    required this.collection,
    this.fields = const [],
    this.createCollection = false,
    this.requestExample,
    this.responseExample,
  });

  factory ApiEndpoint.fromJson(Map<String, dynamic> json) {
    return ApiEndpoint(
      id: json['id'],
      name: json['name'],
      method: json['method'],
      path: json['path'],
      description: json['description'] ?? '',
      purpose: json['purpose'] ?? 'create',
      auth: json['auth'] ?? false,
      collection: json['collection'] ?? '',
      fields: (json['fields'] as List?)
          ?.map((e) => ApiField.fromJson(e))
          .toList() ?? [],
      createCollection: json['createCollection'] ?? false,
      requestExample: json['requestExample'],
      responseExample: json['responseExample'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'method': method,
      'path': path,
      'description': description,
      'purpose': purpose,
      'auth': auth,
      'collection': collection,
      'fields': fields.map((e) => e.toJson()).toList(),
      'createCollection': createCollection,
      'requestExample': requestExample,
      'responseExample': responseExample,
    };
  }
}

// API Field Model
class ApiField {
  String name;
  String type; // 'String', 'Number', 'Boolean', 'Date', 'ObjectId', 'Array'
  bool required;
  bool unique;
  dynamic defaultValue;
  String? validation; // 'email', 'phone', 'url', etc.

  ApiField({
    required this.name,
    required this.type,
    this.required = false,
    this.unique = false,
    this.defaultValue,
    this.validation,
  });

  factory ApiField.fromJson(Map<String, dynamic> json) {
    return ApiField(
      name: json['name'],
      type: json['type'],
      required: json['required'] ?? false,
      unique: json['unique'] ?? false,
      defaultValue: json['defaultValue'],
      validation: json['validation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'required': required,
      'unique': unique,
      'defaultValue': defaultValue,
      'validation': validation,
    };
  }
}

// Data Model for database schemas
class DataModel {
  String name;
  List<ApiField> fields;
  String? collection; // MongoDB collection name
  String? description;

  DataModel({
    required this.name,
    this.fields = const [],
    this.collection,
    this.description,
  });

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      name: json['name'],
      fields: (json['fields'] as List?)
          ?.map((e) => ApiField.fromJson(e))
          .toList() ?? [],
      collection: json['collection'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fields': fields.map((e) => e.toJson()).toList(),
      'collection': collection,
      'description': description,
    };
  }
}

// Screen Model with Preview Support
class ScreenModel {
  String id;
  String name;
  String route;
  List<WidgetModel> widgets;
  String? thumbnail; // Base64 preview image
  DateTime lastModified;
  bool isPublished;

  ScreenModel({
    required this.id,
    required this.name,
    required this.route,
    this.widgets = const [],
    this.thumbnail,
    DateTime? lastModified,
    this.isPublished = false,
  }) : lastModified = lastModified ?? DateTime.now();

  factory ScreenModel.fromJson(Map<String, dynamic> json) {
    return ScreenModel(
      id: json['id'],
      name: json['name'],
      route: json['route'],
      widgets: (json['widgets'] as List?)
          ?.map((e) => WidgetModel.fromJson(e))
          .toList() ?? [],
      thumbnail: json['thumbnail'],
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'])
          : DateTime.now(),
      isPublished: json['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'route': route,
      'widgets': widgets.map((e) => e.toJson()).toList(),
      'thumbnail': thumbnail,
      'lastModified': lastModified.toIso8601String(),
      'isPublished': isPublished,
    };
  }
}

// Project Model
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