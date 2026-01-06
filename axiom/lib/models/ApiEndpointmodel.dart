import 'ApiFieldModel.dart';

class ApiEndpoint {
  String id;
  String name;
  String method;
  String path;
  String description;
  String purpose; // 'login', 'register', 'create', 'read', 'update', 'delete', 'list'
  bool auth;

  // Database configuration
  String collectionName; // MongoDB collection name
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
    required this.collectionName,
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
      collectionName: json['collectionName'] ?? json['collection'] ?? '',
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
      'collectionName': collectionName,
      'fields': fields.map((e) => e.toJson()).toList(),
      'createCollection': createCollection,
      'requestExample': requestExample,
      'responseExample': responseExample,
    };
  }
}