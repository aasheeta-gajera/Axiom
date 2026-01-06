import 'package:axiom/models/widget_model.dart';

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