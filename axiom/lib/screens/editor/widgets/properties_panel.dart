import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../providers/widget_provider.dart';
import '../../../providers/project_provider.dart';
import '../../../models/widget_model.dart';
import '../../../models/ApiEndpointmodel.dart';
import 'event_binding_panel.dart';

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WidgetProvider>(
      builder: (context, provider, child) {
        final selectedWidget = provider.selectedWidget;
        print('🏠 Properties panel - Selected widget: ${selectedWidget?.id}');

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
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesForm(
      BuildContext context,
      WidgetModel selectedWidget,
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
          ..._buildWidgetSpecificProperties(context, selectedWidget, provider),

          //API BINDING SECTION (for Button and TextField widgets)
          // if (selectedWidget.type == 'Button' || selectedWidget.type == 'TextField')
          //   _buildAPIBindingSection(context, selectedWidget, provider),
          if (selectedWidget.type == 'Button' ||
              selectedWidget.type == 'TextField' ||
              selectedWidget.type == 'TextFormField')
            EventBindingPanel(widget: selectedWidget),
        ],
      ),
    );
  }

  List<Widget> _buildWidgetSpecificProperties(
      BuildContext context,
      WidgetModel widget,
      WidgetProvider provider,
      ) {
    final props = widget.properties;
    final List<Widget> fields = [];

    switch (widget.type) {
      case 'Text':
        fields.addAll([
          _buildTextField('Text', props['text'] ?? '', (value) => provider.updateWidgetProperty(widget.id, 'text', value)),
          const SizedBox(height: 16),
          _buildNumberField('Font Size', props['fontSize']?.toDouble() ?? 16.0, (value) => provider.updateWidgetProperty(widget.id, 'fontSize', value)),
          const SizedBox(height: 16),
          _buildColorPicker(context, 'Text Color', props['color'] ?? '#000000', (color) => provider.updateWidgetProperty(widget.id, 'color', color)),
          const SizedBox(height: 16),
          _buildDropdown('Font Weight', props['fontWeight'] ?? 'normal', ['normal', 'bold', 'w300', 'w500', 'w700'], (value) => provider.updateWidgetProperty(widget.id, 'fontWeight', value)),
        ]);
        break;

      case 'Button':
        fields.addAll([
          _buildTextField('Button Text', props['text'] ?? '',
                  (value) => provider.updateWidgetProperty(widget.id, 'text', value)),
          const SizedBox(height: 16),
          _buildColorPicker(context, 'Background Color',
              props['backgroundColor'] ?? '#2196F3',
                  (color) => provider.updateWidgetProperty(widget.id, 'backgroundColor', color)),
          const SizedBox(height: 16),
          _buildNumberField('Font Size', props['fontSize']?.toDouble() ?? 16.0,
                  (value) => provider.updateWidgetProperty(widget.id, 'fontSize', value)),
        ]);
        break;

      case 'Container':
        fields.addAll([
          _buildNumberField('Width', props['width']?.toDouble() ?? 200.0,
                  (value) => provider.updateWidgetProperty(widget.id, 'width', value)),
          const SizedBox(height: 16),
          _buildNumberField('Height', props['height']?.toDouble() ?? 100.0,
                  (value) => provider.updateWidgetProperty(widget.id, 'height', value)),
          const SizedBox(height: 16),
          _buildColorPicker(context, 'Background Color',
              props['backgroundColor'] ?? '#E3F2FD',
                  (color) => provider.updateWidgetProperty(widget.id, 'backgroundColor', color)),
        ]);
        break;

      case 'TextField':
        fields.addAll([
          _buildTextField('Hint Text', props['hint'] ?? '',
                  (value) => provider.updateWidgetProperty(widget.id, 'hint', value)),
          const SizedBox(height: 16),
          _buildTextField('Label', props['label'] ?? '',
                  (value) => provider.updateWidgetProperty(widget.id, 'label', value)),
          const SizedBox(height: 16),
          _buildTextField('Field Key (for API)', props['fieldKey'] ?? '',
                  (value) => provider.updateWidgetProperty(widget.id, 'fieldKey', value)),
          const SizedBox(height: 16),
          _buildDynamicArrayKeySelector(context, widget, provider),
          const SizedBox(height: 16),
          _buildSwitch('Obscure Text', props['obscureText'] ?? false,
                  (value) => provider.updateWidgetProperty(widget.id, 'obscureText', value)),
        ]);
        break;

      case 'Image':
        fields.addAll([
          _buildTextField('Image URL', props['image'] ?? '',
                  (value) => provider.updateWidgetProperty(widget.id, 'image', value)),
          const SizedBox(height: 16),
          _buildNumberField('Width', props['width']?.toDouble() ?? 200.0,
                  (value) => provider.updateWidgetProperty(widget.id, 'width', value)),
          const SizedBox(height: 16),
          _buildNumberField('Height', props['height']?.toDouble() ?? 200.0,
                  (value) => provider.updateWidgetProperty(widget.id, 'height', value)),
        ]);
        break;

      case 'ListView':
        fields.addAll([
          _buildTextField('Data Source API', props['dataSource'] ?? '',
                  (value) => provider.updateWidgetProperty(widget.id, 'dataSource', value)),
          const SizedBox(height: 16),
          _buildTextField('Item Template', props['itemTemplate'] ?? 'card',
                  (value) => provider.updateWidgetProperty(widget.id, 'itemTemplate', value)),
          const SizedBox(height: 16),
          _buildDropdown('Direction', props['direction'] ?? 'vertical', ['vertical', 'horizontal'], 
                  (value) => provider.updateWidgetProperty(widget.id, 'direction', value)),
          const SizedBox(height: 16),
          _buildSwitch('Scroll', props['scroll'] ?? true,
                  (value) => provider.updateWidgetProperty(widget.id, 'scroll', value)),
          const SizedBox(height: 16),
          _buildTextField('Data Field (for API response)', props['dataField'] ?? 'data',
                  (value) => provider.updateWidgetProperty(widget.id, 'dataField', value)),
          const SizedBox(height: 16),
          _buildTextField('Item Count Field', props['countField'] ?? 'count',
                  (value) => provider.updateWidgetProperty(widget.id, 'countField', value)),
        ]);
        break;
    }

    return fields;
  }

  Widget _buildTextField(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Switch(value: value, onChanged: onChanged),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: options.contains(value) ? value : options.first,
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

  Widget _buildDynamicArrayKeySelector(BuildContext context, WidgetModel widget, WidgetProvider provider) {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final currentProject = projectProvider.currentProject;
    
    if (currentProject == null || currentProject!.apis.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          'No APIs available for array binding.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    // Get all array fields and their keys
    final Map<String, List<String>> arrayFields = {};
    
    for (var api in currentProject!.apis) {
      for (var field in api.fields) {
        if (field.type.toLowerCase() == 'array') {
          final List<String> keys = [];
          
          if (field.arrayItems != null && field.arrayItems!.isNotEmpty) {
            if (field.arrayItems!.first is Map) {
              final firstItem = field.arrayItems!.first as Map;
              keys.addAll(firstItem.keys.cast<String>());
            } else {
              keys.addAll(['name', 'value', 'type']);
            }
          } else {
            keys.addAll(['name', 'value', 'type']);
          }
          
          arrayFields[field.name] = keys;
        }
      }
    }

    if (arrayFields.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          'No array fields found.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Array Field Selector
        const Text('Array Field:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: widget.properties['arrayField']?.isNotEmpty == true ? widget.properties['arrayField'] : null,
          decoration: const InputDecoration(
            hintText: 'Select array field',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: arrayFields.keys.map((fieldName) {
            return DropdownMenuItem(value: fieldName, child: Text(fieldName));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              provider.updateWidgetProperty(widget.id, 'arrayField', value);
              provider.updateWidgetProperty(widget.id, 'fieldKey', ''); // Reset key when array changes
              provider.updateWidgetProperty(widget.id, 'arrayKey', ''); // Reset array key when array changes
            }
          },
        ),

        const SizedBox(height: 16),

        // Array Key Selector (appears when array field is selected)
        if (widget.properties['arrayField'] != null && widget.properties['arrayField']!.isNotEmpty) ...[
          const Text('Array Key:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: widget.properties['arrayKey']?.isNotEmpty == true &&
                  arrayFields[widget.properties['arrayField']]?.contains(widget.properties['arrayKey']) == true
                  ? widget.properties['arrayKey'] : null,
            decoration: const InputDecoration(
              hintText: 'Select array key',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: arrayFields[widget.properties['arrayField']]?.map((key) {
              return DropdownMenuItem(value: key, child: Text(key));
            }).toList() ?? [],
            onChanged: (value) {
              if (value != null) {
                final arrayField = widget.properties['arrayField'] ?? '';
                final fieldKey = '$arrayField[].$value';
                provider.updateWidgetProperty(widget.id, 'arrayKey', value);
                provider.updateWidgetProperty(widget.id, 'fieldKey', fieldKey);
              }
            },
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Generated Field Key:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  widget.properties['fieldKey'] ?? 'Select array key above',
                  style: const TextStyle(fontSize: 11, color: Colors.green, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}