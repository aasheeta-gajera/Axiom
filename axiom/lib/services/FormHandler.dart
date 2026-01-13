
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/widget_model.dart';

class FormHandler {
  static final Map<String, TextEditingController> _controllers = {};
  static final Map<String, dynamic> _formData = {};

  // Initialize controllers for form fields
  static void initializeForm(List<WidgetModel> widgets) {
    _controllers.clear();
    _formData.clear();

    for (var widget in widgets) {
      if (widget.type == 'TextField') {
        final fieldKey = widget.properties['fieldKey'] ?? widget.id;
        _controllers[fieldKey] = TextEditingController();
      }
    }
  }

  // Get controller for a specific field
  static TextEditingController? getController(String key) {
    return _controllers[key];
  }

  // Collect all form data
  static Map<String, dynamic> collectFormData() {
    _formData.clear();

    _controllers.forEach((key, controller) {
      _formData[key] = controller.text;
    });

    return Map.from(_formData);
  }

  // Validate form fields
  static bool validateForm(List<WidgetModel> widgets) {
    bool isValid = true;

    for (var widget in widgets) {
      if (widget.type == 'TextField') {
        final fieldKey = widget.properties['fieldKey'] ?? widget.id;
        final isRequired = widget.properties['required'] ?? false;
        final controller = _controllers[fieldKey];

        if (isRequired && (controller == null || controller.text.isEmpty)) {
          isValid = false;
          break;
        }
      }
    }

    return isValid;
  }

  // Submit form to API
  static Future<Map<String, dynamic>> submitForm({
    required String apiUrl,
    required String method,
    Map<String, String>? headers,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final formData = collectFormData();

      // Merge with additional data
      final payload = {...formData, ...?additionalData};

      final uri = Uri.parse(apiUrl);
      http.Response response;

      final requestHeaders = {
        'Content-Type': 'application/json',
        ...?headers,
      };

      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(
            uri,
            headers: requestHeaders,
            body: json.encode(payload),
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: requestHeaders,
            body: json.encode(payload),
          );
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: requestHeaders,
            body: json.encode(payload),
          );
          break;
        case 'GET':
        default:
        // For GET, convert payload to query parameters
          final queryParams = payload.map((key, value) => MapEntry(key, value.toString()));
          final uriWithParams = uri.replace(queryParameters: queryParams);
          response = await http.get(uriWithParams, headers: requestHeaders);
          break;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Request failed with status ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Clear all form fields
  static void clearForm() {
    _controllers.forEach((key, controller) {
      controller.clear();
    });
    _formData.clear();
  }

  // Dispose all controllers
  static void dispose() {
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    _controllers.clear();
    _formData.clear();
  }
}

// Form Widget Builder
class FormBuilder extends StatefulWidget {
  final List<WidgetModel> formWidgets;
  final String? submitUrl;
  final String submitMethod;
  final VoidCallback? onSuccess;
  final Function(String)? onError;

  const FormBuilder({
    super.key,
    required this.formWidgets,
    this.submitUrl,
    this.submitMethod = 'POST',
    this.onSuccess,
    this.onError,
  });

  @override
  State<FormBuilder> createState() => _FormBuilderState();
}

class _FormBuilderState extends State<FormBuilder> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    FormHandler.initializeForm(widget.formWidgets);
  }

  @override
  void dispose() {
    FormHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.formWidgets.map((widget) => _buildFormWidget(widget)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Submit'),
          ),
        ),
      ],
    );
  }

  Widget _buildFormWidget(WidgetModel widget) {
    switch (widget.type) {
      case 'TextField':
        final fieldKey = widget.properties['fieldKey'] ?? widget.id;
        final controller = FormHandler.getController(fieldKey);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: widget.properties['label'] ?? '',
              hintText: widget.properties['hint'] ?? '',
              border: const OutlineInputBorder(),
            ),
            obscureText: widget.properties['obscureText'] ?? false,
          ),
        );

      case 'Text':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            widget.properties['text'] ?? '',
            style: TextStyle(
              fontSize: widget.properties['fontSize']?.toDouble() ?? 16,
              fontWeight: widget.properties['fontWeight'] == 'bold'
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleSubmit() async {
    if (!FormHandler.validateForm(widget.formWidgets)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (widget.submitUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No submit URL configured')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await FormHandler.submitForm(
      apiUrl: widget.submitUrl!,
      method: widget.submitMethod,
    );

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Form submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      FormHandler.clearForm();
    } else {
      final error = result['error'] ?? 'Unknown error';
      if (widget.onError != null) {
        widget.onError!(error);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// Form Preview Dialog
class FormPreviewDialog extends StatelessWidget {
  final List<WidgetModel> formWidgets;
  final String? submitUrl;
  final String submitMethod;

  const FormPreviewDialog({
    super.key,
    required this.formWidgets,
    this.submitUrl,
    this.submitMethod = 'POST',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Form Preview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: FormBuilder(
                  formWidgets: formWidgets,
                  submitUrl: submitUrl,
                  submitMethod: submitMethod,
                  onSuccess: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Form submitted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  onError: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}