import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/widget_model.dart';
import '../../services/auth_service.dart';
import '../../services/form_data_service.dart';
import '../editor/widgets/dynamic_list_view.dart';

class InteractivePreviewScreen extends StatefulWidget {
  final ScreenModel screen;

  const InteractivePreviewScreen({super.key, required this.screen});

  @override
  State<InteractivePreviewScreen> createState() => _InteractivePreviewScreenState();
}

class _InteractivePreviewScreenState extends State<InteractivePreviewScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var w in widget.screen.widgets) {
      if (w.type == 'TextField' || w.type == 'TextFormField') {
        _controllers[w.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.screen.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              for (var controller in _controllers.values) {
                controller.clear();
              }
              _formData.clear();
            }),
          ),
        ],
      ),
      body: Stack(
        children: widget.screen.widgets.map((w) => _buildInteractiveWidget(w)).toList(),
      ),
    );
  }

  // ✅ FIXED: Renamed parameter from 'widget' to 'widgetModel'
  Widget _buildInteractiveWidget(WidgetModel widgetModel) {
    return Positioned(
      left: widgetModel.position.dx,
      top: widgetModel.position.dy,
      child: _renderInteractiveWidget(widgetModel),
    );
  }

  // ✅ FIXED: Renamed parameter from 'widget' to 'widgetModel'
  Widget _renderInteractiveWidget(WidgetModel widgetModel) {
    final props = widgetModel.properties;

    switch (widgetModel.type) {
      case 'TextField':
      case 'TextFormField':
        return SizedBox(
          width: (props['width'] ?? 250).toDouble(),
          child: TextField(
            controller: _controllers[widgetModel.id],
            decoration: InputDecoration(
              hintText: props['hint'] ?? '',
              labelText: props['label'] ?? '',
              border: const OutlineInputBorder(),
            ),
            obscureText: props['obscureText'] ?? false,
            onChanged: (value) {
              // ✅ FIXED: Now using widgetModel instead of widget
              final fieldKey = props['fieldKey'] ?? widgetModel.id;
              _formData[fieldKey] = value;

              if (widgetModel.bindToField != null) {
                _formData[widgetModel.bindToField!] = value;
              }
            },
          ),
        );

      case 'Button':
        return ElevatedButton(
          onPressed: widgetModel.onClick != null
              ? () => _handleEvent(widgetModel.onClick!)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _parseColor(props['backgroundColor'] ?? '#2196F3'),
          ),
          child: Text(props['text'] ?? 'Button'),
        );

      case 'Text':
        return Text(
          props['text'] ?? 'Text',
          style: TextStyle(
            fontSize: (props['fontSize'] ?? 16).toDouble(),
            color: _parseColor(props['color'] ?? '#000000'),
          ),
        );

      case 'Container':
        return Container(
          width: (props['width'] ?? 200).toDouble(),
          height: (props['height'] ?? 100).toDouble(),
          decoration: BoxDecoration(
            color: _parseColor(props['backgroundColor'] ?? '#E3F2FD'),
            borderRadius: BorderRadius.circular((props['borderRadius'] ?? 8).toDouble()),
          ),
          child: Center(
            child: Text(
              'Container',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        );

      case 'Image':
        return Image.network(
          props['image'] ?? 'https://via.placeholder.com/200',
          width: (props['width'] ?? 200).toDouble(),
          height: (props['height'] ?? 200).toDouble(),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: (props['width'] ?? 200).toDouble(),
              height: (props['height'] ?? 200).toDouble(),
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image, size: 48),
            );
          },
        );

      case 'ListView':
        return Container(
          width: (props['width'] ?? 300).toDouble(),
          height: (props['height'] ?? 400).toDouble(),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DynamicListView(
            dataSource: props['dataSource'] ?? '',
            itemTemplate: props['itemTemplate'] ?? 'card',
            direction: props['direction'] ?? 'vertical',
            scroll: props['scroll'] ?? true,
            dataField: props['dataField'] ?? 'data',
            countField: props['countField'] ?? 'count',
          ),
        );

      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widgetModel.type,
            style: const TextStyle(fontSize: 12),
          ),
        );
    }
  }

  Future<void> _handleEvent(EventBinding event) async {
    switch (event.action) {
      case 'callAPI':
        await _callAPI(event);
        break;
      case 'navigate':
        _navigate(event);
        break;
      case 'validate':
        _validateForm();
        break;
    }
  }

  // ✅ COMPLETE API CALL HANDLER
  Future<void> _callAPI(EventBinding event) async {
    // Collect data using field mapping
    final requestData = <String, dynamic>{};

    if (event.fieldMapping != null && event.fieldMapping!.isNotEmpty) {
      // Use field mapping: API field name -> widget ID
      event.fieldMapping!.forEach((apiFieldName, widgetId) {
        final widgetModel = widget.screen.widgets.firstWhere(
              (w) => w.id == widgetId,
          orElse: () => widget.screen.widgets.first,
        );
        final fieldKey = widgetModel.properties['fieldKey'] ?? widgetId;

        // Get value from form data
        if (_formData.containsKey(fieldKey)) {
          requestData[apiFieldName] = _formData[fieldKey];
        } else if (_controllers.containsKey(widgetId)) {
          requestData[apiFieldName] = _controllers[widgetId]!.text;
        }
      });
    } else {
      // No mapping: use all form data
      requestData.addAll(_formData);
    }

    // Validate required fields
    if (requestData.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Please fill in the form'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('🔄 Calling API...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      // Load auth token for authenticated requests
      final authService = AuthService();
      await authService.loadToken();

      // Ensure path starts with /
      String apiPath = event.apiPath ?? '';
      if (!apiPath.startsWith('/')) {
        apiPath = '/$apiPath';
      }

      // Build correct URL
      final url = 'https://axiom-mmd4.onrender.com/api$apiPath';

      print('🚀 API Call Details:');
      print('   Method: ${event.apiMethod}');
      print('   URL: $url');
      print('   Data: $requestData');

      // Prepare headers with authentication
      Map<String, String> headers = {'Content-Type': 'application/json'};
      if (authService.token != null) {
        headers['Authorization'] = 'Bearer ${authService.token}';
      }

      http.Response response;

      switch (event.apiMethod?.toUpperCase()) {
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: json.encode(requestData),
          ).timeout(const Duration(seconds: 10));
          break;

        case 'GET':
          final uri = Uri.parse(url).replace(
            queryParameters: requestData.map((k, v) => MapEntry(k, v.toString())),
          );
          response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
          break;

        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: headers,
            body: json.encode(requestData),
          ).timeout(const Duration(seconds: 10));
          break;

        case 'DELETE':
          response = await http.delete(
            Uri.parse(url),
            headers: headers,
            body: json.encode(requestData),
          ).timeout(const Duration(seconds: 10));
          break;

        default:
          throw Exception('Unsupported HTTP method: ${event.apiMethod}');
      }

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (mounted) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Success
          final responseData = json.decode(response.body);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ Success!', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (responseData['message'] != null)
                    Text(responseData['message']),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Response Data'),
                      content: SingleChildScrollView(
                        child: Text(
                          const JsonEncoder.withIndent('  ').convert(responseData),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );

          // Save form data to database
          await FormDataService.saveFormData(
            screenId: widget.screen.id,
            screenName: widget.screen.name,
            formData: requestData,
          );

          // Clear form on success
          for (var controller in _controllers.values) {
            controller.clear();
          }
          _formData.clear();

        } else {
          // Error response
          String errorMessage = 'Error ${response.statusCode}';
          try {
            final errorData = json.decode(response.body);
            errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
          } catch (e) {
            errorMessage = response.body;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('❌ Failed (${response.statusCode})',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(errorMessage),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ API Call Error: $e');

      if (mounted) {
        String errorMessage = 'Network error';
        if (e.toString().contains('TimeoutException')) {
          errorMessage = 'Request timeout - server not responding';
        } else if (e.toString().contains('SocketException')) {
          errorMessage = 'No internet connection';
        } else {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('❌ Error', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(errorMessage),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _navigate(EventBinding event) {
    print('Navigate to: ${event.navigateTo}');
    // TODO: Implement screen navigation
  }

  void _validateForm() {
    bool isValid = _formData.isNotEmpty;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isValid ? '✅ Form is valid' : '❌ Please fill all fields'),
          backgroundColor: isValid ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}