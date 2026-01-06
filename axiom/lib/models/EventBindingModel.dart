
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