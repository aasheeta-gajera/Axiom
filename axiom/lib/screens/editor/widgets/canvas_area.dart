import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/widget_provider.dart';
import '../../../models/widget_model.dart';
import 'package:uuid/uuid.dart';

class CanvasArea extends StatefulWidget {
  const CanvasArea({super.key});

  @override
  State<CanvasArea> createState() => _CanvasAreaState();
}

class _CanvasAreaState extends State<CanvasArea> {
  @override
  Widget build(BuildContext context) {
    return Consumer<WidgetProvider>(
      builder: (context, provider, child) {
        return DragTarget<String>(
          onAcceptWithDetails: (details) {
            final widgetType = details.data;
            _addWidgetToCanvas(context, widgetType, details.offset);
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: candidateData.isNotEmpty
                      ? Colors.blue.withOpacity(0.5)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Grid background
                  CustomPaint(
                    size: Size.infinite,
                    painter: GridPainter(),
                  ),

                  // Empty state
                  if (provider.widgets.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.gesture,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Drag widgets here to start building',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Render widgets
                  ...provider.widgets.map((widget) {
                    return _buildDraggableWidget(context, widget, provider);
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDraggableWidget(
      BuildContext context,
      WidgetModel widget,
      WidgetProvider provider,
      ) {
    final isSelected = provider.selectedWidget?.id == widget.id;

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: GestureDetector(
        onTap: () => provider.selectWidget(widget),
        child: Draggable<WidgetModel>(
          data: widget,
          feedback: Material(
            elevation: 8,
            child: _renderWidget(widget, true),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _renderWidget(widget, false),
          ),
          onDragEnd: (details) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localOffset = renderBox.globalToLocal(details.offset);
            provider.updateWidgetPosition(widget.id, localOffset);
          },
          child: Container(
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
            ),
            child: _renderWidget(widget, false),
          ),
        ),
      ),
    );
  }

  Widget _renderWidget(WidgetModel widget, bool isFeedback) {
    final props = widget.properties;

    switch (widget.type) {
      case 'Text':
        return Text(
          props['text'] ?? 'Text',
          style: TextStyle(
            fontSize: (props['fontSize'] ?? 16.0).toDouble(),
            color: _parseColor(props['color'] ?? '#000000'),
            fontWeight: props['fontWeight'] == 'bold'
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        );

      case 'Button':
        return ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: _parseColor(props['backgroundColor'] ?? '#2196F3'),
            foregroundColor: _parseColor(props['color'] ?? '#FFFFFF'),
          ),
          child: Text(
            props['text'] ?? 'Button',
            style: TextStyle(fontSize: (props['fontSize'] ?? 16.0).toDouble()),
          ),
        );

      case 'Container':
        return Container(
          width: (props['width'] ?? 200.0).toDouble(),
          height: (props['height'] ?? 100.0).toDouble(),
          decoration: BoxDecoration(
            color: _parseColor(props['backgroundColor'] ?? '#E3F2FD'),
            borderRadius: BorderRadius.circular(
              (props['borderRadius'] ?? 8.0).toDouble(),
            ),
          ),
        );

      case 'Image':
        return Image.network(
          props['image'] ?? 'https://via.placeholder.com/200',
          width: (props['width'] ?? 200.0).toDouble(),
          height: (props['height'] ?? 200.0).toDouble(),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: (props['width'] ?? 200.0).toDouble(),
              height: (props['height'] ?? 200.0).toDouble(),
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image, size: 48),
            );
          },
        );

      case 'Card':
        return Card(
          elevation: 4,
          child: Container(
            width: (props['width'] ?? 250.0).toDouble(),
            height: (props['height'] ?? 150.0).toDouble(),
            padding: const EdgeInsets.all(16),
            child: const Text('Card Content'),
          ),
        );

      case 'TextField':
        return SizedBox(
          width: (props['width'] ?? 250.0).toDouble(),
          child: TextField(
            decoration: InputDecoration(
              hintText: props['hint'] ?? 'Enter text',
              border: const OutlineInputBorder(),
            ),
          ),
        );

      case 'Row':
        return Container(
          width: (props['width'] ?? 300.0).toDouble(),
          height: (props['height'] ?? 100.0).toDouble(),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade200),
            color: Colors.blue.shade50,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.star),
              Icon(Icons.favorite),
              Icon(Icons.thumb_up),
            ],
          ),
        );

      case 'Column':
        return Container(
          width: (props['width'] ?? 150.0).toDouble(),
          height: (props['height'] ?? 300.0).toDouble(),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.pink.shade200),
            color: Colors.pink.shade50,
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.star),
              Icon(Icons.favorite),
              Icon(Icons.thumb_up),
            ],
          ),
        );

      default:
        return Container(
          width: 100,
          height: 100,
          color: Colors.grey.shade300,
          child: Center(child: Text(widget.type)),
        );
    }
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.black;
    }
  }

  void _addWidgetToCanvas(BuildContext context, String widgetType, Offset position) {
    final provider = context.read<WidgetProvider>();
    final uuid = const Uuid();

    final newWidget = WidgetModel(
      id: uuid.v4(),
      type: widgetType,
      properties: _getDefaultProperties(widgetType),
      position: position,
    );

    provider.addWidget(newWidget);
  }

  Map<String, dynamic> _getDefaultProperties(String type) {
    switch (type) {
      case 'Text':
        return {'text': 'Text Widget', 'fontSize': 16.0, 'color': '#000000'};
      case 'Button':
        return {'text': 'Button', 'backgroundColor': '#2196F3', 'color': '#FFFFFF'};
      case 'Container':
        return {'width': 200.0, 'height': 100.0, 'backgroundColor': '#E3F2FD'};
      case 'Image':
        return {'width': 200.0, 'height': 200.0, 'image': 'https://via.placeholder.com/200'};
      case 'TextField':
        return {'hint': 'Enter text', 'width': 250.0};
      default:
        return {};
    }
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    const spacing = 20.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}