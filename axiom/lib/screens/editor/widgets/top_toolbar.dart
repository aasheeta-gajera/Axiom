
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/widget_provider.dart';
import '../../../models/widget_model.dart';
import '../../preview/preview_screen_list.dart';

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

          IconButton(onPressed: (){
            Navigator.pop(context);
          }, icon: Icon(Icons.arrow_back_ios_new)),

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

          // NEW: Test Registration Screen Button
          _buildToolbarButton(
            icon: Icons.person_add,
            label: 'Test Form',
            onPressed: () {
              final widgetProvider = context.read<WidgetProvider>();
              widgetProvider.createRegistrationScreen();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Registration screen created! Click widgets to edit properties.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),

          const VerticalDivider(width: 1),

          _buildToolbarButton(
            icon: Icons.preview,
            label: 'Preview',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PreviewScreenList()),
            ),
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
          ApiEndpoint(id: '', name: 'Default', method: 'GET', path: '/', purpose: '', collection: ''));

      return '''
  Future<void> _handle${widget.id}ButtonPress() async {
    try {
      // Collect data from TextFields
      final data = {
${_generateDataCollection(widgets)}
      };

      final response = await http.${api.method.toLowerCase()}(
        Uri.parse('https://axiom-mmd4.onrender.com/api/dynamic/${api.collection}'),
        headers: {
          'Content-Type': 'application/json',
          ${api.auth ? "'Authorization': 'Bearer \${yourAuthToken}'," : ""}
        },
        body: json.encode({
          'method': '${api.method}',
          'purpose': '${api.purpose}',
          'data': data,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = json.decode(response.body);
        print('Success: \${result['message']}');
        // Handle success (navigate, show message, etc.)
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

// Connect to MongoDB
mongoose.connect('mongodb+srv://aasheeta:rtyfgho;@users.mdpvhwc.mongodb.net/axiom');

// Dynamic API Routes - No need to create collections manually!
router.post('/dynamic/:collection', async (req, res) => {
  try {
    const { collection } = req.params;
    const { method, data, purpose } = req.body;
    
    // Dynamic model creation - collection created automatically
    const DynamicModel = mongoose.models[collection] || 
      mongoose.model(collection, new mongoose.Schema({}, { 
        strict: false, 
        collection: collection,
        timestamps: true 
      }));
    
    const newItem = new DynamicModel({
      ...data,
      createdAt: new Date(),
      updatedAt: new Date()
    });
    
    await newItem.save();
    res.status(201).json({ 
      success: true, 
      message: 'Data saved successfully',
      data: newItem 
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

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