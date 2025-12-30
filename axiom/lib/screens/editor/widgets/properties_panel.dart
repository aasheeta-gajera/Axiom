import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../providers/widget_provider.dart';
import '../../../providers/project_provider.dart';
import '../../../models/widget_model.dart';

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

          // API BINDING SECTION (for Button and TextField widgets)
          if (selectedWidget.type == 'Button' || selectedWidget.type == 'TextField')
            _buildAPIBindingSection(context, selectedWidget, provider),
        ],
      ),
    );
  }

  Widget _buildAPIBindingSection(
      BuildContext context,
      WidgetModel widget,
      WidgetProvider provider,
      ) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        final apis = projectProvider.currentProject?.apis ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.api, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'API Binding',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // API Selection Dropdown
            if (apis.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    const Text('No APIs available'),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/api-management');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create API'),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: widget.apiEndpointId,
                decoration: const InputDecoration(
                  labelText: 'Select API Endpoint',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('None'),
                  ),
                  ...apis.map((api) {
                    return DropdownMenuItem(
                      value: api.id,
                      child: Text('${api.method} ${api.path}'),
                    );
                  }),
                ],
                onChanged: (value) {
                  if (value != null) {
                    final selectedApi = apis.firstWhere((api) => api.id == value);
                    final updatedWidget = widget.copyWith(
                      apiEndpointId: selectedApi.id,
                      apiMethod: selectedApi.method,
                      apiPath: selectedApi.path,
                      requiresAuth: selectedApi.auth,
                    );
                    provider.updateWidget(updatedWidget);
                  } else {
                    final updatedWidget = widget.copyWith(
                      apiEndpointId: null,
                      apiMethod: null,
                      apiPath: null,
                      requiresAuth: false,
                    );
                    provider.updateWidget(updatedWidget);
                  }
                },
              ),

            // Show API details if selected
            if (widget.apiEndpointId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'API Connected',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Method: ${widget.apiMethod}'),
                    Text('Path: ${widget.apiPath}'),
                    if (widget.requiresAuth)
                      const Row(
                        children: [
                          Icon(Icons.lock, size: 16, color: Colors.orange),
                          SizedBox(width: 4),
                          Text('Requires Authentication'),
                        ],
                      ),
                  ],
                ),
              ),
            ],

            // Action explanation based on widget type
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.type == 'Button'
                          ? 'Button will call this API when clicked'
                          : 'TextField data will be sent to this API',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
          _buildTextField('Text', props['text'] ?? '',
                  (value) => provider.updateWidgetProperty(widget.id, 'text', value)),
          const SizedBox(height: 16),
          _buildNumberField('Font Size', props['fontSize']?.toDouble() ?? 16.0,
                  (value) => provider.updateWidgetProperty(widget.id, 'fontSize', value)),
          const SizedBox(height: 16),
          _buildColorPicker(context, 'Text Color', props['color'] ?? '#000000',
                  (color) => provider.updateWidgetProperty(widget.id, 'color', color)),
          const SizedBox(height: 16),
          _buildDropdown('Font Weight', props['fontWeight'] ?? 'normal',
              ['normal', 'bold', 'w300', 'w500', 'w700'],
                  (value) => provider.updateWidgetProperty(widget.id, 'fontWeight', value)),
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
}