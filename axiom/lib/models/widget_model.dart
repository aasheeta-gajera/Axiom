import 'package:flutter/material.dart';

import 'EventBindingModel.dart';

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