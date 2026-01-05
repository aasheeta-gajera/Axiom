
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/widget_model.dart';
import 'dart:convert';
import '../../../providers/project_provider.dart';

class EnhancedAPICreationDialog extends StatefulWidget {
  final ApiEndpoint? existingApi;

  const EnhancedAPICreationDialog({super.key, this.existingApi});

  @override
  State<EnhancedAPICreationDialog> createState() => _EnhancedAPICreationDialogState();
}

class _EnhancedAPICreationDialogState extends State<EnhancedAPICreationDialog> {
  int _currentStep = 0;

  // Step 1: Basic Info
  final _nameController = TextEditingController();
  final _pathController = TextEditingController();
  final _descController = TextEditingController();
  String _method = 'POST';
  String _purpose = 'create';
  bool _requiresAuth = false;

  // Step 2: Database Configuration
  String _collectionName = '';
  bool _createNewCollection = true;
  List<String> _existingCollections = [];
  List<ApiField> _fields = [];

  // Step 3: Preview
  Map<String, dynamic> _requestExample = {};
  Map<String, dynamic> _responseExample = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingApi != null) {
      _loadExistingApi();
    }
    _loadExistingCollections();
  }

  void _loadExistingApi() {
    final api = widget.existingApi!;
    _nameController.text = api.name;
    _pathController.text = api.path;
    _descController.text = api.description;
    _method = api.method;
    _purpose = api.purpose;
    _requiresAuth = api.auth;
    _collectionName = api.collectionName;
    _fields = List.from(api.fields);
    _createNewCollection = api.createCollection;
  }

  Future<void> _loadExistingCollections() async {
    final projectProvider = context.read<ProjectProvider>();
    setState(() {
      _existingCollections = projectProvider.currentProject?.collections ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 650,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _currentStep < 2 ? () {
            if (_validateStep(_currentStep)) {
              setState(() => _currentStep++);
              if (_currentStep == 2) _generateExamples();
            }
          } : null,
          onStepCancel: _currentStep > 0 ? () {
            setState(() => _currentStep--);
          } : null,
          steps: [
            Step(
              title: const Text('Basic Information'),
              content: _buildBasicInfoStep(),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Database Configuration'),
              content: _buildDatabaseStep(),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Preview & Create'),
              content: _buildPreviewStep(),
              isActive: _currentStep >= 2,
            ),
          ],
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (details.currentStep < 2)
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: const Text('Next'),
                    ),
                  if (details.currentStep == 2)
                    ElevatedButton(
                      onPressed: _createAPI,
                      child: Text(widget.existingApi != null ? 'Update API' : 'Create API'),
                    ),
                  const SizedBox(width: 12),
                  if (details.currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'API Name *',
            hintText: 'e.g., Register User, Login',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _purpose,
          decoration: const InputDecoration(
            labelText: 'What is this API for? *',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'login', child: Text('Login')),
            DropdownMenuItem(value: 'register', child: Text('Register')),
            DropdownMenuItem(value: 'create', child: Text('Create Data')),
            DropdownMenuItem(value: 'read', child: Text('Read/Fetch Data')),
            DropdownMenuItem(value: 'update', child: Text('Update Data')),
            DropdownMenuItem(value: 'delete', child: Text('Delete Data')),
            DropdownMenuItem(value: 'list', child: Text('List/Search Data')),
          ],
          onChanged: (value) {
            setState(() {
              _purpose = value!;
              _autoConfigureByPurpose();
            });
          },
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _method,
                decoration: const InputDecoration(
                  labelText: 'Method *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'GET', child: Text('GET')),
                  DropdownMenuItem(value: 'POST', child: Text('POST')),
                  DropdownMenuItem(value: 'PUT', child: Text('PUT')),
                  DropdownMenuItem(value: 'DELETE', child: Text('DELETE')),
                ],
                onChanged: (value) => setState(() => _method = value!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _pathController,
                decoration: InputDecoration(
                  labelText: 'Path *',
                  hintText: '/register',
                  border: const OutlineInputBorder(),
                  helperText: 'Will be: /api${_pathController.text}',
                  helperStyle: const TextStyle(fontSize: 11),
                ),
                // ✅ FIX: Auto-format path
                onChanged: (value) {
                  String formatted = value.trim();
                  // Ensure starts with /
                  if (formatted.isNotEmpty && !formatted.startsWith('/')) {
                    formatted = '/$formatted';
                  }
                  // Remove any /api prefix if user added it
                  if (formatted.startsWith('/api/')) {
                    formatted = formatted.substring(4);
                  }
                  // Update controller if changed
                  if (formatted != value) {
                    _pathController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                  setState(() {}); // Update helper text
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _descController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        SwitchListTile(
          title: const Text('Requires Authentication'),
          subtitle: const Text('Check if this API needs JWT token'),
          value: _requiresAuth,
          onChanged: (value) => setState(() => _requiresAuth = value),
        ),
      ],
    );
  }

  Widget _buildDatabaseStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Database Configuration',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Collection Selection
        Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: _createNewCollection,
              onChanged: (value) => setState(() {
                _createNewCollection = value!;
                if (!_createNewCollection) _fields.clear();
              }),
            ),
            const Text('Create New Collection'),
            const SizedBox(width: 24),
            Radio<bool>(
              value: false,
              groupValue: _createNewCollection,
              onChanged: (value) => setState(() {
                _createNewCollection = value!;
                if (!_createNewCollection) _fields.clear();
              }),
            ),
            const Text('Use Existing Collection'),
          ],
        ),
        const SizedBox(height: 16),

        if (_createNewCollection)
          TextField(
            decoration: const InputDecoration(
              labelText: 'Collection Name *',
              hintText: 'e.g., users, products',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _collectionName = value.toLowerCase(),
          )
        else if (_existingCollections.isNotEmpty)
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Collection *',
              border: OutlineInputBorder(),
            ),
            items: _existingCollections
                .map((col) => DropdownMenuItem(value: col, child: Text(col)))
                .toList(),
            onChanged: (value) => setState(() => _collectionName = value!),
          )
        else
          const Text('No existing collections found'),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fields',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _addField,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Field'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Fields List
        if (_fields.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('No fields added yet. Click "Add Field" to start.'),
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _fields.length,
              itemBuilder: (context, index) {
                final field = _fields[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(field.name),
                    subtitle: Text(
                      '${field.type}${field.required ? " (Required)" : ""}${field.unique ? " (Unique)" : ""}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editField(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => setState(() => _fields.removeAt(index)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'API Preview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildInfoCard('API Details', [
            'Name: ${_nameController.text}',
            'Purpose: $_purpose',
            'Method: $_method',
            'Path: /api${_pathController.text}',
            'Collection: $_collectionName',
            'Auth Required: ${_requiresAuth ? "Yes" : "No"}',
          ]),

          const SizedBox(height: 16),
          _buildCodePreview('Request Body', _requestExample),
          const SizedBox(height: 16),
          _buildCodePreview('Response Body', _responseExample),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(item),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCodePreview(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(data),
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.greenAccent,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  void _addField() {
    showDialog(
      context: context,
      builder: (context) => _FieldEditorDialog(
        onSave: (field) {
          setState(() => _fields.add(field));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _editField(int index) {
    showDialog(
      context: context,
      builder: (context) => _FieldEditorDialog(
        field: _fields[index],
        onSave: (field) {
          setState(() => _fields[index] = field);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _autoConfigureByPurpose() {
    switch (_purpose) {
      case 'login':
        _method = 'POST';
        _pathController.text = '/login';
        _requiresAuth = false;
        _collectionName = 'users';
        _fields = [
          ApiField(name: 'email', type: 'String', required: true, validation: 'email'),
          ApiField(name: 'password', type: 'String', required: true),
        ];
        break;
      case 'register':
        _method = 'POST';
        _pathController.text = '/register';
        _requiresAuth = false;
        _collectionName = 'users';
        _fields = [
          ApiField(name: 'name', type: 'String', required: true),
          ApiField(name: 'email', type: 'String', required: true, unique: true, validation: 'email'),
          ApiField(name: 'password', type: 'String', required: true),
        ];
        break;
      case 'create':
        _method = 'POST';
        _pathController.text = '/create';
        _requiresAuth = true;
        break;
      case 'read':
        _method = 'GET';
        _pathController.text = '/data';
        _requiresAuth = false;
        break;
      case 'update':
        _method = 'PUT';
        _pathController.text = '/update';
        _requiresAuth = true;
        break;
      case 'delete':
        _method = 'DELETE';
        _pathController.text = '/delete';
        _requiresAuth = true;
        break;
      case 'list':
        _method = 'GET';
        _pathController.text = '/list';
        _requiresAuth = false;
        break;
    }
  }

  void _generateExamples() {
    // Generate request example
    _requestExample = {};
    for (var field in _fields) {
      switch (field.type) {
        case 'String':
          _requestExample[field.name] = 'example_${field.name}';
          break;
        case 'Number':
          _requestExample[field.name] = 123;
          break;
        case 'Boolean':
          _requestExample[field.name] = true;
          break;
        case 'Date':
          _requestExample[field.name] = DateTime.now().toIso8601String();
          break;
        case 'Array':
          _requestExample[field.name] = [];
          break;
      }
    }

    // Generate response example
    _responseExample = {
      'success': true,
      'message': 'Operation successful',
      'data': _requestExample,
    };
  }
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
      // ✅ FIX: Validate path format
        String path = _pathController.text.trim();

        if (_nameController.text.isEmpty) {
          _showError('Please enter API name');
          return false;
        }

        if (path.isEmpty) {
          _showError('Please enter API path');
          return false;
        }

        if (!path.startsWith('/')) {
          _showError('Path must start with /');
          return false;
        }

        if (path.contains(' ')) {
          _showError('Path cannot contain spaces');
          return false;
        }

        return true;

      case 1:
        if (_collectionName.isEmpty) {
          _showError('Please enter collection name');
          return false;
        }

        if (_collectionName.contains(' ')) {
          _showError('Collection name cannot contain spaces');
          return false;
        }

        if (_fields.isEmpty) {
          _showError('Please add at least one field');
          return false;
        }

        return true;

      default:
        return true;
    }
  }

  Future<void> _createAPI() async {
    final api = ApiEndpoint(
      id: widget.existingApi?.id ?? 'api_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text,
      method: _method,
      path: _pathController.text,
      description: _descController.text,
      purpose: _purpose,
      auth: _requiresAuth,
      collectionName: _collectionName,
      fields: _fields,
      createCollection: _createNewCollection,
      requestExample: _requestExample,
      responseExample: _responseExample,
    );

    // Save API via provider
    final projectProvider = context.read<ProjectProvider>();
    await projectProvider.createOrUpdateAPI(api);

    if (mounted) {
      Navigator.pop(context, api);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ API ${widget.existingApi != null ? "updated" : "created"} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// Field Editor Dialog
class _FieldEditorDialog extends StatefulWidget {
  final ApiField? field;
  final Function(ApiField) onSave;

  const _FieldEditorDialog({this.field, required this.onSave});

  @override
  State<_FieldEditorDialog> createState() => _FieldEditorDialogState();
}

class _FieldEditorDialogState extends State<_FieldEditorDialog> {
  final _nameController = TextEditingController();
  String _type = 'String';
  bool _required = false;
  bool _unique = false;
  String? _validation;

  @override
  void initState() {
    super.initState();
    if (widget.field != null) {
      _nameController.text = widget.field!.name;
      _type = widget.field!.type;
      _required = widget.field!.required;
      _unique = widget.field!.unique;
      _validation = widget.field!.validation;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.field != null ? 'Edit Field' : 'Add Field'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Field Name *',
              hintText: 'e.g., email, username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(
              labelText: 'Type *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'String', child: Text('String')),
              DropdownMenuItem(value: 'Number', child: Text('Number')),
              DropdownMenuItem(value: 'Boolean', child: Text('Boolean')),
              DropdownMenuItem(value: 'Date', child: Text('Date')),
              DropdownMenuItem(value: 'Array', child: Text('Array')),
              DropdownMenuItem(value: 'ObjectId', child: Text('ObjectId')),
            ],
            onChanged: (value) => setState(() => _type = value!),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Required'),
            value: _required,
            onChanged: (value) => setState(() => _required = value!),
          ),
          CheckboxListTile(
            title: const Text('Unique'),
            value: _unique,
            onChanged: (value) => setState(() => _unique = value!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              widget.onSave(ApiField(
                name: _nameController.text,
                type: _type,
                required: _required,
                unique: _unique,
                validation: _validation,
              ));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}