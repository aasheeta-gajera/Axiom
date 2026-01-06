class ApiField {
  final String name;
  final String type; // 'String', 'Number', 'Boolean', 'Date', 'ObjectId', 'Array', 'Object'
  final bool required;
  final bool unique;
  final String? validation;
  final dynamic defaultValue;
  final String? description;
  final List<dynamic>? arrayItems; // For predefined array options
  final Map<String, dynamic>? objectSchema; // For nested object structure

  const ApiField({
    required this.name,
    required this.type,
    this.required = false,
    this.unique = false,
    this.validation,
    this.defaultValue,
    this.description,
    this.arrayItems,
    this.objectSchema,
  });

  factory ApiField.fromJson(Map<String, dynamic> json) {
    return ApiField(
      name: json['name'] ?? '',
      type: json['type'] ?? 'String',
      required: json['required'] ?? false,
      unique: json['unique'] ?? false,
      validation: json['validation'],
      defaultValue: json['defaultValue'],
      description: json['description'],
      arrayItems: json['arrayItems'],
      objectSchema: json['objectSchema'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'required': required,
      'unique': unique,
      if (validation != null) 'validation': validation,
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (description != null) 'description': description,
      if (arrayItems != null) 'arrayItems': arrayItems,
      if (objectSchema != null) 'objectSchema': objectSchema,
    };
  }
}