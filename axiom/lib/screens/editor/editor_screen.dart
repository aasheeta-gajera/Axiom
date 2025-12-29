import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/widget_provider.dart';
import '../../providers/project_provider.dart';
import 'widgets/widget_palette.dart';
import 'widgets/canvas_area.dart';
import 'widgets/properties_panel.dart';
import 'widgets/top_toolbar.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectId = ModalRoute.of(context)?.settings.arguments as String?;
      if (projectId != null) {
        context.read<ProjectProvider>().loadProject(projectId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const TopToolbar(),
          Expanded(
            child: Row(
              children: [
                // Left sidebar - Widget Palette
                Container(
                  width: 280,
                  color: Colors.white,
                  child: const WidgetPalette(),
                ),

                // Center - Canvas Area
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.grey[200],
                    child: const CanvasArea(),
                  ),
                ),

                // Right sidebar - Properties Panel
                Container(
                  width: 320,
                  color: Colors.white,
                  child: const PropertiesPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}