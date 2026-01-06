
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/ApiEndpointmodel.dart';
import '../../../models/EventBindingModel.dart';
import '../../../models/ScreenModel.dart';
import '../../../models/widget_model.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/widget_provider.dart';
import 'api_creation_dialog.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Event Binding Panel Component
class EventBindingPanel extends StatelessWidget {
  final WidgetModel widget;

  const EventBindingPanel({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    return Consumer2<WidgetProvider, ProjectProvider>(
      builder: (context, widgetProvider, projectProvider, child) {
        final apis = projectProvider.currentProject?.apis ?? [];
        final screens = projectProvider.currentProject?.screens ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.bolt, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Event Binding',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

          
            if (widget.type == 'Button' || widget.type == 'Card')
              _buildEventSection(
                context,
                'On Click',
                widget.onClick,
                    (binding) => _updateEvent(context, 'onClick', binding),
                apis,
                screens,
              ),

            // onChange Event
            if (widget.type == 'TextField' || widget.type == 'TextFormField')
              _buildEventSection(
                context,
                'On Change',
                widget.onChange,
                    (binding) => _updateEvent(context, 'onChange', binding),
                apis,
                screens,
              ),

            // Data Binding for TextFields
            if (widget.type == 'TextField' || widget.type == 'TextFormField')
              _buildDataBindingSection(context, widgetProvider),
          ],
        );
      },
    );
  }

  Widget _buildEventSection(
      BuildContext context,
      String eventName,
      EventBinding? currentBinding,
      Function(EventBinding?) onUpdate,
      List<ApiEndpoint> apis,
      List<ScreenModel> screens,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eventName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: currentBinding?.action,
              decoration: const InputDecoration(
                labelText: 'Action',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(value: 'callAPI', child: Text('Call API')),
                DropdownMenuItem(value: 'navigate', child: Text('Navigate')),
                DropdownMenuItem(value: 'validate', child: Text('Validate Form')),
              ],
              onChanged: (value) {
                if (value == null) {
                  onUpdate(null);
                } else {
                  onUpdate(EventBinding(action: value));
                }
              },
            ),

            if (currentBinding?.action == 'callAPI') ...[
              const SizedBox(height: 12),
              _buildAPISelector(context, currentBinding!, apis, onUpdate),
            ],

            if (currentBinding?.action == 'navigate') ...[
              const SizedBox(height: 12),
              _buildNavigationSelector(context, currentBinding!, screens, onUpdate),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAPISelector(
      BuildContext context,
      EventBinding binding,
      List<ApiEndpoint> apis,
      Function(EventBinding?) onUpdate,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (apis.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text('No APIs available'),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const EnhancedAPICreationDialog(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create API'),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: apis.isNotEmpty && binding.apiId != null ? binding.apiId : null,
            decoration: const InputDecoration(
              labelText: 'Select API',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: apis.map((api) {
              return DropdownMenuItem(
                value: api.id,
                child: Text(
                  '${api.method} ${api.path}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final api = apis.firstWhere((a) => a.id == value);
                onUpdate(EventBinding(
                  action: 'callAPI',
                  apiId: api.id,
                  apiMethod: api.method,
                  apiPath: api.path,
                ));
              }
            },
          ),

        if (binding.apiId != null) ...[
          const SizedBox(height: 12),
          _buildFieldMapping(context, binding, apis, onUpdate),
        ],
      ],
    );
  }

  Widget _buildFieldMapping(
      BuildContext context,
      EventBinding binding,
      List<ApiEndpoint> apis,
      Function(EventBinding?) onUpdate,
      ) {
    final api = apis.firstWhere((a) => a.id == binding.apiId);
    final widgetProvider = context.read<WidgetProvider>();
    final allWidgets = widgetProvider.widgets;
    final textFields = allWidgets
        .where((w) => w.type == 'TextField' || w.type == 'TextFormField')
        .toList();

    print('🔍 DEBUG: Field Mapping Check');
    print('   API: ${api.name}');
    print('   API Fields: ${api.fields.map((f) => '${f.name} (${f.type})').toList()}');
    print('   Total TextFields: ${textFields.length}');
    
    for (var tf in textFields) {
      print('   TextField: ${tf.properties['label'] ?? tf.id}');
      print('   FieldKey: ${tf.properties['fieldKey']}');
      print('   ArrayField: ${tf.properties['arrayField']}');
      print('   ArrayKey: ${tf.properties['arrayKey']}');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Map Form Fields to API',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Array Fields Section - Auto-mapped
          ...api.fields.where((f) => f.type.toLowerCase() == 'array').map((field) {
            final arrayTextFields = textFields.where((w) => 
              w.properties['fieldKey']?.contains('${field.name}[]') == true
            ).toList();
            
            // Auto-map array fields
            final newMapping = Map<String, String>.from(binding.fieldMapping ?? {});
            for (final arrayTextField in arrayTextFields) {
              final arrayKey = arrayTextField.properties['arrayKey'] ?? 'value';
              newMapping['${field.name}.$arrayKey'] = arrayTextField.id;
            }
            
            print('🔍 Array Field: ${field.name}');
            print('   ArrayTextFields Found: ${arrayTextFields.length}');
            print('   Auto-mapping: ${newMapping}');
            
            // Update binding with auto-mapped array fields
            if (newMapping.length != (binding.fieldMapping?.length ?? 0)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onUpdate(binding.copyWith(fieldMapping: newMapping));
              });
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📦 ${field.name} (Array)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                    const SizedBox(height: 8),
                    if (arrayTextFields.isEmpty) ...[
                      const Text(
                        '❌ No TextFields mapped to this array field',
                        style: TextStyle(fontSize: 10, color: Colors.red),
                      ),
                      const Text(
                        '💡 Set up TextFields with array field binding first',
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ] else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: arrayTextFields.map((w) {
                          final label = w.properties['label'] ?? w.properties['hint'] ?? w.id;
                          final arrayKey = w.properties['arrayKey'] ?? 'Unknown';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$label → $arrayKey',
                              style: const TextStyle(fontSize: 10, color: Colors.purple),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '✅ Auto-mapped array fields detected',
                        style: TextStyle(fontSize: 9, color: Colors.green),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          // Regular Fields Section  
          ...api.fields.where((f) => f.type.toLowerCase() != 'array').map((field) {
            final currentMapping = binding.fieldMapping?[field.name];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${field.name} (${field.type})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<String>(
                      value: textFields.any((w) => w.id == currentMapping) ? currentMapping : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Select field')),
                        ...textFields.map((w) {
                          final label = w.properties['label'] ?? w.properties['hint'] ?? w.id;
                          return DropdownMenuItem(value: w.id, child: Text(label));
                        }),
                      ],
                      onChanged: (value) {
                        final newMapping = Map<String, String>.from(binding.fieldMapping ?? {});
                        if (value != null) {
                          newMapping[field.name] = value;
                        } else {
                          newMapping.remove(field.name);
                        }
                        print('🔧 Updated Field Mapping: $newMapping');
                        onUpdate(binding.copyWith(fieldMapping: newMapping));
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavigationSelector(
      BuildContext context,
      EventBinding binding,
      List<ScreenModel> screens,
      Function(EventBinding?) onUpdate,
      ) {
    return DropdownButtonFormField<String>(
      value: binding.navigateTo,
      decoration: const InputDecoration(
        labelText: 'Navigate to Screen',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: screens.map((screen) {
        return DropdownMenuItem(
          value: screen.id,
          child: Text(screen.name),
        );
      }).toList(),
      onChanged: (value) {
        onUpdate(EventBinding(
          action: 'navigate',
          navigateTo: value,
        ));
      },
    );
  }

  Widget _buildDataBindingSection(BuildContext context, WidgetProvider provider) {
    final projectProvider = context.read<ProjectProvider>();
    final collections = projectProvider.currentProject?.collections ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Binding',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: TextEditingController(text: widget.bindToField),
              decoration: const InputDecoration(
                labelText: 'Bind to Database Field',
                hintText: 'e.g., email, username',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                provider.updateWidget(widget.copyWith(bindToField: value));
              },
            ),
            const SizedBox(height: 12),

            if (collections.isNotEmpty)
              DropdownButtonFormField<String>(
                value: widget.bindToCollection,
                decoration: const InputDecoration(
                  labelText: 'Collection',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: collections.map((col) {
                  return DropdownMenuItem(value: col, child: Text(col));
                }).toList(),
                onChanged: (value) {
                  provider.updateWidget(widget.copyWith(bindToCollection: value));
                },
              ),
          ],
        ),
      ),
    );
  }

  void _updateEvent(BuildContext context, String eventType, EventBinding? binding) {
    final provider = context.read<WidgetProvider>();

    switch (eventType) {
      case 'onClick':
        provider.updateWidget(widget.copyWith(onClick: binding));
        break;
      case 'onChange':
        provider.updateWidget(widget.copyWith(onChange: binding));
        break;
      case 'onSubmit':
        provider.updateWidget(widget.copyWith(onSubmit: binding));
        break;
    }
  }
}

// Extension for EventBinding
extension EventBindingExtension on EventBinding {
  EventBinding copyWith({
    String? action,
    String? apiId,
    String? apiMethod,
    String? apiPath,
    Map<String, String>? fieldMapping,
    String? navigateTo,
  }) {
    return EventBinding(
      action: action ?? this.action,
      apiId: apiId ?? this.apiId,
      apiMethod: apiMethod ?? this.apiMethod,
      apiPath: apiPath ?? this.apiPath,
      fieldMapping: fieldMapping ?? this.fieldMapping,
      navigateTo: navigateTo ?? this.navigateTo,
    );
  }
}

// Preview Screen List Component
class PreviewScreenList extends StatelessWidget {
  const PreviewScreenList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final screens = provider.currentProject?.screens ?? [];

        if (screens.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.preview, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No screens to preview'),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: screens.length,
          itemBuilder: (context, index) {
            final screen = screens[index];
            return _PreviewCard(screen: screen);
          },
        );
      },
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final ScreenModel screen;

  const _PreviewCard({required this.screen});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InteractivePreviewScreen(screen: screen),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: screen.thumbnail != null
                    ? Image.memory(
                  Uri.parse(screen.thumbnail!).data!.contentAsBytes(),
                  fit: BoxFit.cover,
                )
                    : const Icon(Icons.phone_android, size: 64, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    screen.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last modified: ${_formatDate(screen.lastModified)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        screen.isPublished ? Icons.check_circle : Icons.edit,
                        size: 16,
                        color: screen.isPublished ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        screen.isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                          fontSize: 12,
                          color: screen.isPublished ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Interactive Preview Screen - CRITICAL FOR YOUR REQUIREMENT
class InteractivePreviewScreen extends StatefulWidget {
  final ScreenModel screen;

  const InteractivePreviewScreen({super.key, required this.screen});

  @override
  State<InteractivePreviewScreen> createState() => _InteractivePreviewScreenState();
}

class _InteractivePreviewScreenState extends State<InteractivePreviewScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var widget in widget.screen.widgets) {
      if (widget.type == 'TextField' || widget.type == 'TextFormField') {
        _controllers[widget.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.screen.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              for (var controller in _controllers.values) {
                controller.clear();
              }
            }),
          ),
        ],
      ),
      body: Stack(
        children: widget.screen.widgets.map((w) => _buildInteractiveWidget(w)).toList(),
      ),
    );
  }

  Widget _buildInteractiveWidget(WidgetModel widget) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: _renderInteractiveWidget(widget),
    );
  }

  Widget _renderInteractiveWidget(WidgetModel widget) {
    final props = widget.properties;

    switch (widget.type) {
      case 'TextField':
      case 'TextFormField':
        return SizedBox(
          width: (props['width'] ?? 250).toDouble(),
          child: TextField(
            controller: _controllers[widget.id],
            decoration: InputDecoration(
              hintText: props['hint'] ?? '',
              labelText: props['label'] ?? '',
              border: const OutlineInputBorder(),
            ),
            obscureText: props['obscureText'] ?? false,
            onChanged: (value) {
              if (widget.bindToField != null) {
                _formData[widget.bindToField!] = value;
              }
              // Trigger onChange event if configured
              if (widget.onChange != null) {
                _handleEvent(widget.onChange!);
              }
            },
          ),
        );

      case 'Button':
        return ElevatedButton(
          onPressed: widget.onClick != null
              ? () => _handleEvent(widget.onClick!)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _parseColor(props['backgroundColor'] ?? '#2196F3'),
          ),
          child: Text(props['text'] ?? 'Button'),
        );

    // Add other widget types as needed...
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade300,
          child: Text(widget.type),
        );
    }
  }

  Future<void> _handleEvent(EventBinding event) async {
    switch (event.action) {
      case 'callAPI':
        await _callAPI(event);
        break;
      case 'navigate':
        _navigate(event);
        break;
      case 'validate':
        _validateForm();
        break;
    }
  }

  Future<void> _callAPI(EventBinding event) async {
    // Collect data from mapped fields
    final requestData = <String, dynamic>{};
    event.fieldMapping?.forEach((apiField, widgetId) {
      final controller = _controllers[widgetId];
      if (controller != null) {
        requestData[apiField] = controller.text;
      }
    });

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔄 Calling API...')),
      );
    }

    // Make REAL API call
    try {
            
      final url = 'https://axiom-mmd4.onrender.com${event.apiPath}';
      http.Response response;

      switch (event.apiMethod?.toUpperCase()) {
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          );
          break;
        case 'GET':
          response = await http.get(Uri.parse(url));
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          );
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url));
          break;
        default:
          throw Exception('Unsupported method');
      }

      if (mounted) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ API call successful!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigate(EventBinding event) {
    // Implement navigation to other screens
    print('Navigate to: ${event.navigateTo}');
  }

  void _validateForm() {
    // Implement form validation
    bool isValid = true;
    for (var entry in _controllers.entries) {
      if (entry.value.text.isEmpty) {
        isValid = false;
        break;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isValid ? '✅ Form is valid' : '❌ Please fill all fields'),
          backgroundColor: isValid ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}