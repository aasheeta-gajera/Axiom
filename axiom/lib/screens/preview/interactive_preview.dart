
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/widget_model.dart';

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
    for (var widget in widget.screen.widgets) {
      if (widget.type == 'TextField' || widget.type == 'TextFormField') {
        _controllers[widget.id] = TextEditingController();
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
            }),
          ),
        ],
      ),
      body: Stack(
        children: widget.screen.widgets.map((w) => _buildInteractiveWidget(w)).toList(),
      ),
    );
  }

  Widget _buildInteractiveWidget(WidgetModel widget) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: _renderInteractiveWidget(widget),
    );
  }

  Widget _renderInteractiveWidget(WidgetModel widget) {
    final props = widget.properties;

    switch (widget.type) {
      case 'TextField':
      case 'TextFormField':
        return SizedBox(
          width: (props['width'] ?? 250).toDouble(),
          child: TextField(
            controller: _controllers[widget.id],
            decoration: InputDecoration(
              hintText: props['hint'] ?? '',
              labelText: props['label'] ?? '',
              border: const OutlineInputBorder(),
            ),
            obscureText: props['obscureText'] ?? false,
            onChanged: (value) {
              if (widget.bindToField != null) {
                _formData[widget.bindToField!] = value;
              }
            },
          ),
        );

      case 'Button':
        return ElevatedButton(
          onPressed: widget.onClick != null
              ? () => _handleEvent(widget.onClick!)
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

      default:
        return Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade300,
          child: Text(widget.type),
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
    }
  }

  Future<void> _callAPI(EventBinding event) async {
    // Collect data from mapped fields
    final requestData = <String, dynamic>{};
    event.fieldMapping?.forEach((apiField, widgetId) {
      final controller = _controllers[widgetId];
      if (controller != null) {
        requestData[apiField] = controller.text;
      }
    });

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔄 Calling API...')),
      );
    }

    try {
      final url = 'https://axiom-mmd4.onrender.com/api${event.apiPath}';

      http.Response response;
      switch (event.apiMethod?.toUpperCase()) {
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          );
          break;
        case 'GET':
          response = await http.get(Uri.parse(url));
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          );
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url));
          break;
        default:
          throw Exception('Unsupported method');
      }

      if (mounted) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Success!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigate(EventBinding event) {
    // Implement navigation
    print('Navigate to: ${event.navigateTo}');
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}