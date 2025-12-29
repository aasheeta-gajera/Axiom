import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../providers/widget_provider.dart';

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WidgetProvider>(
      builder: (context, provider, child) {
        final selectedWidget = provider.selectedWidget;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.settings, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Properties',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (selectedWidget != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        provider.deleteWidget(selectedWidget.id);
                      },
                      tooltip: 'Delete Widget',
                    ),
                ],
              ),
            ),
            Expanded(
              child: selectedWidget == null
                  ? _buildEmptyState()
                  : _buildPropertiesForm(context, selectedWidget, provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Select a widget\nto edit properties',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesForm(
      BuildContext context,
      dynamic selectedWidget,
      WidgetProvider provider,
      ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Widget Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              selectedWidget.type,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Dynamic properties based on widget type
          ..._buildWidgetSpecificProperties(
            context,
            selectedWidget,
            provider,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWidgetSpecificProperties(
      BuildContext context,
      dynamic widget,
      WidgetProvider provider,
      ) {
    final props = widget.properties;
    final List<Widget> fields = [];

    switch (widget.type) {
      case 'Text':
        fields.addAll([
          _buildTextField(
            'Text',
            props['text'] ?? '',
                (value) => provider.updateWidgetProperty(widget.id, 'text', value),
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            'Font Size',
            props['fontSize']?.toDouble() ?? 16.0,
                (value) => provider.updateWidgetProperty(widget.id, 'fontSize', value),
          ),
          const SizedBox(height: 16),
          _buildColorPicker(
            context,
            'Text Color',
            props['color'] ?? '#000000',
                (color) => provider.updateWidgetProperty(widget.id, 'color', color),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Font Weight',
            props['fontWeight'] ?? 'normal',
            ['normal', 'bold'],
                (value) => provider.updateWidgetProperty(widget.id, 'fontWeight', value),
          ),
        ]);
        break;

      case 'Button':
        fields.addAll([
          _buildTextField(
            'Button Text',
            props['text'] ?? '',
                (value) => provider.updateWidgetProperty(widget.id, 'text', value),
          ),
          const SizedBox(height: 16),
          _buildColorPicker(
            context,
            'Background Color',
            props['backgroundColor'] ?? '#2196F3',
                (color) => provider.updateWidgetProperty(widget.id, 'backgroundColor', color),
          ),
          const SizedBox(height: 16),
          _buildColorPicker(
            context,
            'Text Color',
            props['color'] ?? '#FFFFFF',
                (color) => provider.updateWidgetProperty(widget.id, 'color', color),
          ),
        ]);
        break;

      case 'Container':
        fields.addAll([
          _buildNumberField(
            'Width',
            props['width']?.toDouble() ?? 200.0,
                (value) => provider.updateWidgetProperty(widget.id, 'width', value),
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            'Height',
            props['height']?.toDouble() ?? 100.0,
                (value) => provider.updateWidgetProperty(widget.id, 'height', value),
          ),
          const SizedBox(height: 16),
          _buildColorPicker(
            context,
            'Background Color',
            props['backgroundColor'] ?? '#E3F2FD',
                (color) => provider.updateWidgetProperty(widget.id, 'backgroundColor', color),
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            'Border Radius',
            props['borderRadius']?.toDouble() ?? 8.0,
                (value) => provider.updateWidgetProperty(widget.id, 'borderRadius', value),
          ),
        ]);
        break;

      case 'Image':
        fields.addAll([
          _buildTextField(
            'Image URL',
            props['image'] ?? '',
                (value) => provider.updateWidgetProperty(widget.id, 'image', value),
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            'Width',
            props['width']?.toDouble() ?? 200.0,
                (value) => provider.updateWidgetProperty(widget.id, 'width', value),
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            'Height',
            props['height']?.toDouble() ?? 200.0,
                (value) => provider.updateWidgetProperty(widget.id, 'height', value),
          ),
        ]);
        break;

      case 'TextField':
        fields.addAll([
          _buildTextField(
            'Hint Text',
            props['hint'] ?? '',
                (value) => provider.updateWidgetProperty(widget.id, 'hint', value),
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            'Width',
            props['width']?.toDouble() ?? 250.0,
                (value) => provider.updateWidgetProperty(widget.id, 'width', value),
          ),
        ]);
        break;
    }

    return fields;
  }

  Widget _buildTextField(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value.toString()),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            final numValue = double.tryParse(val);
            if (numValue != null) onChanged(numValue);
          },
        ),
      ],
    );
  }

  Widget _buildColorPicker(
      BuildContext context,
      String label,
      String hexColor,
      Function(String) onChanged,
      ) {
    Color currentColor = _parseColor(hexColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Pick $label'),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: currentColor,
                    onColorChanged: (color) {
                      onChanged(_colorToHex(color));
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          },
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: currentColor,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                hexColor,
                style: TextStyle(
                  color: currentColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
      String label,
      String value,
      List<String> options,
      Function(String) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: options.map((option) {
            return DropdownMenuItem(value: option, child: Text(option));
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ],
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.black;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}