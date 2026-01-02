
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
    final screenSize = MediaQuery.of(context).size;

    return Consumer<WidgetProvider>(
      builder: (context, provider, child) {
        return DragTarget<String>(
          onAcceptWithDetails: (details) {
            final widgetType = details.data;
            _addWidgetToCanvas(context, widgetType, details.offset);
          },
          builder: (context, candidateData, rejectedData) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  margin: EdgeInsets.all(constraints.maxWidth > 600 ? 16 : 8),
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
                      if (constraints.maxWidth > 600)
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
                                size: screenSize.width > 600 ? 64 : 48,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: screenSize.width > 600 ? 16 : 8),
                              Text(
                                'Drag widgets here to start building',
                                style: TextStyle(
                                  fontSize: screenSize.width > 600 ? 18 : 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
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
      },
    );
  }

  Widget _buildDraggableWidget(
      BuildContext context,
      WidgetModel widget,
      WidgetProvider provider,
      ) {
    final isSelected = provider.selectedWidget?.id == widget.id;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    print('🎨 Building widget: ${widget.id} - Selected: $isSelected');

   return Positioned(
      left: isMobile ? widget.position.dx * 0.7 : widget.position.dx,
      top: isMobile ? widget.position.dy * 0.7 : widget.position.dy,
      child: GestureDetector(
        onTap: () {
          print('👆 Canvas tap detected on widget: ${widget.id} - Type: ${widget.type}');
          provider.selectWidget(widget);
        },
        child: Draggable<WidgetModel>(
          data: widget,
          feedback: Material(
            elevation: 8,
            child: Transform.scale(
              scale: isMobile ? 0.8 : 1.0,
              child: _renderWidget(widget, true),
            ),
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
                  : Border.all(color: Colors.transparent, width: 1),
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
            fontWeight: _getFontWeight(props['fontWeight'] ?? 'normal'),
          ),
          textAlign: _getTextAlign(props['alignment'] ?? 'left'),
        );

      case 'Button':
        return ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: _parseColor(props['backgroundColor'] ?? '#2196F3'),
            foregroundColor: _parseColor(props['color'] ?? '#FFFFFF'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                (props['borderRadius'] ?? 8.0).toDouble(),
              ),
            ),
          ),
          child: Text(
            props['text'] ?? 'Button',
            style: TextStyle(fontSize: (props['fontSize'] ?? 16.0).toDouble()),
          ),
        );

      case 'Container':
        final padding = props['padding'] ?? {};
        return Container(
          width: (props['width'] ?? 200.0).toDouble(),
          height: (props['height'] ?? 100.0).toDouble(),
          padding: EdgeInsets.only(
            top: (padding['top'] ?? 0).toDouble(),
            left: (padding['left'] ?? 0).toDouble(),
            right: (padding['right'] ?? 0).toDouble(),
            bottom: (padding['bottom'] ?? 0).toDouble(),
          ),
          decoration: BoxDecoration(
            color: _parseColor(props['backgroundColor'] ?? '#E3F2FD'),
            borderRadius: BorderRadius.circular(
              (props['borderRadius'] ?? 8.0).toDouble(),
            ),
          ),
          child: const Center(child: Text('Container')),
        );

      case 'Row':
        final padding = props['padding'] ?? {};
        return Container(
          width: (props['width'] ?? 300.0).toDouble(),
          height: (props['height'] ?? 100.0).toDouble(),
          padding: EdgeInsets.only(
            top: (padding['top'] ?? 8).toDouble(),
            left: (padding['left'] ?? 8).toDouble(),
            right: (padding['right'] ?? 8).toDouble(),
            bottom: (padding['bottom'] ?? 8).toDouble(),
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade200, width: 2),
            color: _parseColor(props['backgroundColor'] ?? '#E3F2FD'),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: _getMainAxisAlignment(
              props['mainAxisAlignment'] ?? 'start',
            ),
            crossAxisAlignment: _getCrossAxisAlignment(
              props['crossAxisAlignment'] ?? 'center',
            ),
            children: const [
              Icon(Icons.star, size: 24),
              SizedBox(width: 8),
              Icon(Icons.favorite, size: 24),
              SizedBox(width: 8),
              Icon(Icons.thumb_up, size: 24),
            ],
          ),
        );

      case 'Column':
        final padding = props['padding'] ?? {};
        return Container(
          width: (props['width'] ?? 150.0).toDouble(),
          height: (props['height'] ?? 300.0).toDouble(),
          padding: EdgeInsets.only(
            top: (padding['top'] ?? 8).toDouble(),
            left: (padding['left'] ?? 8).toDouble(),
            right: (padding['right'] ?? 8).toDouble(),
            bottom: (padding['bottom'] ?? 8).toDouble(),
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.pink.shade200, width: 2),
            color: _parseColor(props['backgroundColor'] ?? '#FFF3E0'),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: _getMainAxisAlignment(
              props['mainAxisAlignment'] ?? 'start',
            ),
            crossAxisAlignment: _getCrossAxisAlignment(
              props['crossAxisAlignment'] ?? 'center',
            ),
            children: const [
              Icon(Icons.star, size: 24),
              SizedBox(height: 8),
              Icon(Icons.favorite, size: 24),
              SizedBox(height: 8),
              Icon(Icons.thumb_up, size: 24),
            ],
          ),
        );

      case 'AppBar':
        return Container(
          width: 400,
          child: AppBar(
            title: Text(
              props['title'] ?? 'App Bar',
              style: TextStyle(
                color: _parseColor(props['color'] ?? '#FFFFFF'),
              ),
            ),
            backgroundColor: _parseColor(props['backgroundColor'] ?? '#2196F3'),
            elevation: (props['elevation'] ?? 4.0).toDouble(),
            centerTitle: props['centerTitle'] ?? true,
            leading: const Icon(Icons.menu, color: Colors.white),
            actions: const [
              Icon(Icons.search, color: Colors.white),
              SizedBox(width: 16),
              Icon(Icons.more_vert, color: Colors.white),
              SizedBox(width: 8),
            ],
          ),
        );

      case 'Image':
        return Image.network(
          props['image'] ?? 'https://via.placeholder.com/200',
          width: (props['width'] ?? 200.0).toDouble(),
          height: (props['height'] ?? 200.0).toDouble(),
          fit: _getBoxFit(props['fit'] ?? 'cover'),
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
          elevation: (props['elevation'] ?? 4.0).toDouble(),
          color: _parseColor(props['color'] ?? '#FFFFFF'),
          child: Container(
            width: (props['width'] ?? 250.0).toDouble(),
            height: (props['height'] ?? 150.0).toDouble(),
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Card Title',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Card content goes here'),
              ],
            ),
          ),
        );

      case 'TextField':
        return SizedBox(
          width: (props['width'] ?? 250.0).toDouble(),
          child: TextField(
            decoration: InputDecoration(
              hintText: props['hint'] ?? 'Enter text',
              labelText: props['label'] ?? '',
              border: const OutlineInputBorder(),
            ),
            obscureText: props['obscureText'] ?? false,
          ),
        );

      case 'ListView':
        return Container(
          width: (props['width'] ?? 300.0).toDouble(),
          height: (props['height'] ?? 400.0).toDouble(),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text('List Item ${index + 1}'),
              subtitle: const Text('Subtitle'),
            ),
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

  FontWeight _getFontWeight(String weight) {
    switch (weight) {
      case 'bold':
        return FontWeight.bold;
      case 'w300':
        return FontWeight.w300;
      case 'w500':
        return FontWeight.w500;
      case 'w700':
        return FontWeight.w700;
      default:
        return FontWeight.normal;
    }
  }

  TextAlign _getTextAlign(String alignment) {
    switch (alignment) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  MainAxisAlignment _getMainAxisAlignment(String alignment) {
    switch (alignment) {
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'spaceBetween':
        return MainAxisAlignment.spaceBetween;
      case 'spaceAround':
        return MainAxisAlignment.spaceAround;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  CrossAxisAlignment _getCrossAxisAlignment(String alignment) {
    switch (alignment) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.start;
    }
  }

  BoxFit _getBoxFit(String fit) {
    switch (fit) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      default:
        return BoxFit.cover;
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
        return {
          'text': 'Text Widget',
          'fontSize': 16.0,
          'color': '#000000',
          'fontWeight': 'normal',
          'alignment': 'left',
        };
      case 'Button':
        return {
          'text': 'Button',
          'backgroundColor': '#2196F3',
          'color': '#FFFFFF',
          'fontSize': 16.0,
          'borderRadius': 8.0,
        };
      case 'Container':
        return {
          'width': 200.0,
          'height': 100.0,
          'backgroundColor': '#E3F2FD',
          'borderRadius': 8.0,
          'padding': {'top': 0, 'left': 0, 'right': 0, 'bottom': 0},
        };
      case 'Row':
        return {
          'width': 300.0,
          'height': 100.0,
          'backgroundColor': '#E3F2FD',
          'mainAxisAlignment': 'start',
          'crossAxisAlignment': 'center',
          'padding': {'top': 8, 'left': 8, 'right': 8, 'bottom': 8},
        };
      case 'Column':
        return {
          'width': 150.0,
          'height': 300.0,
          'backgroundColor': '#FFF3E0',
          'mainAxisAlignment': 'start',
          'crossAxisAlignment': 'center',
          'padding': {'top': 8, 'left': 8, 'right': 8, 'bottom': 8},
        };
      case 'AppBar':
        return {
          'title': 'App Bar',
          'backgroundColor': '#2196F3',
          'color': '#FFFFFF',
          'elevation': 4.0,
          'centerTitle': true,
        };
      case 'Image':
        return {
          'width': 200.0,
          'height': 200.0,
          'image': 'https://via.placeholder.com/200',
          'fit': 'cover',
        };
      case 'TextField':
        return {
          'hint': 'Enter text',
          'label': '',
          'width': 250.0,
          'obscureText': false,
          'fieldKey': '',
        };
      case 'Card':
        return {
          'width': 250.0,
          'height': 150.0,
          'elevation': 4.0,
          'color': '#FFFFFF',
        };
      case 'ListView':
        return {
          'width': 300.0,
          'height': 400.0,
        };
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