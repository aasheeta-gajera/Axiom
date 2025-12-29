import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/widget_provider.dart';

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

          // Toolbar Actions
          _buildToolbarButton(
            icon: Icons.undo,
            label: 'Undo',
            onPressed: () {
              // TODO: Implement undo
            },
          ),
          _buildToolbarButton(
            icon: Icons.redo,
            label: 'Redo',
            onPressed: () {
              // TODO: Implement redo
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
            label: 'Export Code',
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
              leading: const Icon(Icons.phone_android),
              title: const Text('Export Flutter Code'),
              onTap: () {
                Navigator.pop(context);
                _exportFlutterCode(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Export Backend Code'),
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

    String flutterCode = '''
import 'package:flutter/material.dart';

class GeneratedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
${_generateWidgetCode(widgetProvider.widgets)}
        ],
      ),
    );
  }
}
''';

    _showCodeDialog(context, 'Flutter Code', flutterCode);
  }

  String _generateWidgetCode(List widgets) {
    return widgets.map((widget) {
      final props = widget.properties;
      switch (widget.type) {
        case 'Text':
          return '''          Positioned(
            left: ${widget.position.dx},
            top: ${widget.position.dy},
            child: Text('${props['text']}', style: TextStyle(fontSize: ${props['fontSize']})),
          ),''';
        case 'Button':
          return '''          Positioned(
            left: ${widget.position.dx},
            top: ${widget.position.dy},
            child: ElevatedButton(onPressed: () {}, child: Text('${props['text']}')),
          ),''';
        default:
          return '';
      }
    }).join('\n');
  }

  void _exportBackendCode(BuildContext context) {
    String backendCode = '''
const express = require('express');
const router = express.Router();

// Your generated API routes will appear here

module.exports = router;
''';

    _showCodeDialog(context, 'Backend Code', backendCode);
  }

  void _showCodeDialog(BuildContext context, String title, String code) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
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
                          // Copy to clipboard functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied!')),
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