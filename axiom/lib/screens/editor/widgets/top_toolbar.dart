import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/widget_provider.dart';
import '../../../models/widget_model.dart';

class TopToolbar extends StatelessWidget {
  const TopToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.crop_square, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Axiom',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),

          const VerticalDivider(width: 1),

          // Project Name
          Expanded(
            child: Consumer<ProjectProvider>(
              builder: (context, projectProvider, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    projectProvider.currentProject?.name ?? 'Untitled Project',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),

          // NEW: API Management Button
          _buildToolbarButton(
            icon: Icons.api,
            label: 'APIs',
            onPressed: () {
              final projectProvider = context.read<ProjectProvider>();
              if (projectProvider.currentProject != null) {
                Navigator.pushNamed(context, '/api-management');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please load a project first')),
                );
              }
            },
          ),

          const VerticalDivider(width: 1),

          _buildToolbarButton(
            icon: Icons.preview,
            label: 'Preview',
            onPressed: () => _showPreview(context),
          ),
          _buildToolbarButton(
            icon: Icons.save,
            label: 'Save',
            onPressed: () => _saveProject(context),
          ),
          _buildToolbarButton(
            icon: Icons.code,
            label: 'Export',
            onPressed: () => _showExportDialog(context),
          ),

          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: label,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey.shade700,
        ),
      ),
    );
  }

  void _saveProject(BuildContext context) async {
    final projectProvider = context.read<ProjectProvider>();
    final widgetProvider = context.read<WidgetProvider>();

    if (projectProvider.currentProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project loaded')),
      );
      return;
    }

    try {
      await projectProvider.saveWidgets(
        projectProvider.currentProject!.id,
        widgetProvider.currentScreenId ?? 'screen_1',
        widgetProvider.widgets,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Project saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          height: 700,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Preview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('Phone Preview Coming Soon'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone_android, color: Colors.blue),
              title: const Text('Export Flutter Code'),
              subtitle: const Text('Complete working app with API calls'),
              onTap: () {
                Navigator.pop(context);
                _exportFlutterCode(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.code, color: Colors.green),
              title: const Text('Export Backend Code'),
              subtitle: const Text('Node.js/Express API routes'),
              onTap: () {
                Navigator.pop(context);
                _exportBackendCode(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportFlutterCode(BuildContext context) {
    final widgetProvider = context.read<WidgetProvider>();
    final projectProvider = context.read<ProjectProvider>();
    final apis = projectProvider.currentProject?.apis ?? [];

    String flutterCode = _generateCompleteFlutterApp(widgetProvider.widgets, apis);
    _showCodeDialog(context, 'Flutter Code', flutterCode);
  }

  String _generateCompleteFlutterApp(List<WidgetModel> widgets, List<ApiEndpoint> apis) {
    return '''
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Generated App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GeneratedScreen(),
    );
  }
}

class GeneratedScreen extends StatefulWidget {
  const GeneratedScreen({Key? key}) : super(key: key);

  @override
  State<GeneratedScreen> createState() => _GeneratedScreenState();
}

class _GeneratedScreenState extends State<GeneratedScreen> {
  // Text controllers for TextFields
${_generateControllers(widgets)}

  @override
  void dispose() {
${_generateDisposeControllers(widgets)}
    super.dispose();
  }

${_generateAPIFunctions(widgets, apis)}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated App'),
        elevation: 2,
      ),
      body: Stack(
        children: [
${_generateWidgetCode(widgets, apis)}
        ],
      ),
    );
  }
}
''';
  }

  String _generateControllers(List<WidgetModel> widgets) {
    final textFields = widgets.where((w) => w.type == 'TextField').toList();
    if (textFields.isEmpty) return '';

    return textFields.map((widget) {
      final fieldKey = widget.properties['fieldKey'] ?? widget.id;
      return '  final _${fieldKey}Controller = TextEditingController();';
    }).join('\n');
  }

  String _generateDisposeControllers(List<WidgetModel> widgets) {
    final textFields = widgets.where((w) => w.type == 'TextField').toList();
    if (textFields.isEmpty) return '';

    return textFields.map((widget) {
      final fieldKey = widget.properties['fieldKey'] ?? widget.id;
      return '    _${fieldKey}Controller.dispose();';
    }).join('\n');
  }

  String _generateAPIFunctions(List<WidgetModel> widgets, List<ApiEndpoint> apis) {
    final buttonsWithAPI = widgets.where((w) => w.type == 'Button' && w.apiEndpointId != null).toList();
    if (buttonsWithAPI.isEmpty) return '';

    return buttonsWithAPI.map((widget) {
      final api = apis.firstWhere((a) => a.id == widget.apiEndpointId, orElse: () =>
          ApiEndpoint(id: '', method: 'GET', path: '/'));

      return '''
  Future<void> _handle${widget.id}ButtonPress() async {
    try {
      // Collect data from TextFields
      final data = {
${_generateDataCollection(widgets)}
      };

      final response = await http.${api.method.toLowerCase()}(
        Uri.parse('https://your-api.com${api.path}'),
        headers: {
          'Content-Type': 'application/json',
${api.auth ? "          'Authorization': 'Bearer YOUR_TOKEN_HERE'," : ''}
        },
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Success!'), backgroundColor: Colors.green),
          );
        }
        print('Response: \${response.body}');
      } else {
        throw Exception('Failed: \${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: \$e'), backgroundColor: Colors.red),
        );
      }
    }
  }
''';
    }).join('\n');
  }

  String _generateDataCollection(List<WidgetModel> widgets) {
    final textFields = widgets.where((w) => w.type == 'TextField').toList();
    if (textFields.isEmpty) return '';

    return textFields.map((widget) {
      final fieldKey = widget.properties['fieldKey'] ?? widget.id;
      return '        \'$fieldKey\': _${fieldKey}Controller.text,';
    }).join('\n');
  }

  String _generateWidgetCode(List<WidgetModel> widgets, List<ApiEndpoint> apis) {
    return widgets.map((widget) {
      final props = widget.properties;
      switch (widget.type) {
        case 'Text':
          return '''          Positioned(
            left: ${widget.position.dx},
            top: ${widget.position.dy},
            child: Text(
              '${props['text']}',
              style: TextStyle(
                fontSize: ${props['fontSize']},
                color: Color(0xFF${props['color']?.replaceAll('#', '')}),
                fontWeight: FontWeight.${props['fontWeight'] ?? 'normal'},
              ),
            ),
          ),''';

        case 'Button':
          final hasAPI = widget.apiEndpointId != null;
          return '''          Positioned(
            left: ${widget.position.dx},
            top: ${widget.position.dy},
            child: ElevatedButton(
              onPressed: ${hasAPI ? '_handle${widget.id}ButtonPress' : '() {}'},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF${props['backgroundColor']?.replaceAll('#', '')}),
                foregroundColor: Color(0xFF${props['color']?.replaceAll('#', '')}),
              ),
              child: Text('${props['text']}'),
            ),
          ),''';

        case 'TextField':
          final fieldKey = props['fieldKey'] ?? widget.id;
          return '''          Positioned(
            left: ${widget.position.dx},
            top: ${widget.position.dy},
            child: SizedBox(
              width: ${props['width']},
              child: TextField(
                controller: _${fieldKey}Controller,
                decoration: InputDecoration(
                  hintText: '${props['hint']}',
                  labelText: '${props['label']}',
                  border: const OutlineInputBorder(),
                ),
                obscureText: ${props['obscureText'] ?? false},
              ),
            ),
          ),''';

        case 'Container':
          return '''          Positioned(
            left: ${widget.position.dx},
            top: ${widget.position.dy},
            child: Container(
              width: ${props['width']},
              height: ${props['height']},
              decoration: BoxDecoration(
                color: Color(0xFF${props['backgroundColor']?.replaceAll('#', '')}),
                borderRadius: BorderRadius.circular(${props['borderRadius'] ?? 8}),
              ),
              child: const Center(child: Text('Container')),
            ),
          ),''';

        default:
          return '';
      }
    }).join('\n');
  }

  void _exportBackendCode(BuildContext context) {
    final projectProvider = context.read<ProjectProvider>();
    final apis = projectProvider.currentProject?.apis ?? [];
    final dataModels = projectProvider.currentProject?.dataModels ?? [];

    String backendCode = _generateBackendCode(apis, dataModels);
    _showCodeDialog(context, 'Backend Code', backendCode);
  }

  String _generateBackendCode(List<ApiEndpoint> apis, List<DataModel> dataModels) {
    return '''
// Generated Backend Code
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// Data Models
${_generateMongooseSchemas(dataModels)}

// API Routes
${_generateAPIRoutes(apis)}

module.exports = router;
''';
  }

  String _generateMongooseSchemas(List<DataModel> models) {
    return models.map((model) {
      final fields = model.fields.map((field) =>
      "  ${field.name}: { type: ${field.type}, required: ${field.required}, unique: ${field.unique} },"
      ).join('\n');

      return '''
const ${model.name}Schema = new mongoose.Schema({
$fields
}, { timestamps: true });

const ${model.name} = mongoose.model('${model.name}', ${model.name}Schema);
''';
    }).join('\n');
  }

  String _generateAPIRoutes(List<ApiEndpoint> apis) {
    return apis.map((api) {
      return '''
router.${api.method.toLowerCase()}('${api.path}', ${api.auth ? 'authMiddleware,' : ''} async (req, res) => {
  try {
    // ${api.description}
    // TODO: Implement ${api.method} ${api.path}
    res.json({ message: 'Endpoint working', data: req.body });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
''';
    }).join('\n');
  }

  void _showCodeDialog(BuildContext context, String title, String code) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 700,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Code copied to clipboard!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}