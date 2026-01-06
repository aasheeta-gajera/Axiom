import 'ApiFieldModel.dart';

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