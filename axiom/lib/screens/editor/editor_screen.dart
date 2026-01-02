
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../services/websocket_service.dart';
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
  final bool _showPalette = true;
  final bool _showProperties = true;

  @override
  void initState() {
    super.initState();

    // ✅ ADD THIS
    final wsService = context.read<WebSocketService>();
    wsService.connect();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectId = ModalRoute.of(context)?.settings.arguments as String?;
      if (projectId != null) {
        context.read<ProjectProvider>().loadProject(projectId);
        wsService.joinProject(projectId); // ✅ Join project room
      }
    });
  }

  @override
  void dispose() {
    context.read<WebSocketService>().disconnect(); // ✅ Clean up
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const TopToolbar(),
          Expanded(
            child: isMobile
                ? _buildMobileLayout()
                : isSmallScreen
                ? _buildDesktopLayout() : _buildDesktopLayout()
          ),
        ],
      ),
      // Mobile FABs for toggling panels
      floatingActionButton: isMobile
          ? Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'palette',
            onPressed: () => _showBottomSheet(context, isWidget: true),
            child: const Icon(Icons.widgets),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'properties',
            onPressed: () => _showBottomSheet(context, isWidget: false),
            child: const Icon(Icons.settings),
          ),
        ],
      )
          : null,
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left sidebar - Widget Palette
        if (_showPalette)
          Container(
            width: 280,
            color: Colors.white,
            child: const WidgetPalette(),
          ),

        // Center - Canvas Area
        Expanded(
          child: Container(
            color: Colors.grey[200],
            child: const CanvasArea(),
          ),
        ),

        // Right sidebar - Properties Panel
        if (_showProperties)
          Container(
            width: 320,
            color: Colors.white,
            child: const PropertiesPanel(),
          ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    // Mobile: Canvas only, panels in bottom sheets
    return Container(
      color: Colors.grey[200],
      child: const CanvasArea(),
    );
  }

  void _showBottomSheet(BuildContext context, {required bool isWidget}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isWidget ? 'Widget Palette' : 'Properties',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: isWidget
                    ? const WidgetPalette()
                    : const PropertiesPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}