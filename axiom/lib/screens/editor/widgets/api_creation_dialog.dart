
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/ApiEndpointmodel.dart';
import '../../../models/ApiFieldModel.dart';
import 'dart:convert';
import '../../../providers/ProjectProvider.dart';

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
  String _usageScenario = ''; // New field for usage guidance

  // Step 2: Database Configuration
  String _collectionName = '';
  bool _createNewCollection = true;
  List<String> _existingCollections = [];
  List<ApiField> _fields = [];

  // Step 3: Preview & Usage
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
    
    // Ensure project is loaded
    if (projectProvider.currentProject == null) {
      setState(() {
        _existingCollections = [];
      });
      print('🔍 No project loaded, collections set to empty');
      return;
    }
    
    // Get collections from current project
    final collections = projectProvider.currentProject!.collections;
    print('🔍 Project collections: $collections');
    
    // Also add collection names from existing APIs
    final apiCollections = projectProvider.currentProject!.apis
        .map((api) => api.collectionName)
        .where((name) => name.isNotEmpty)
        .toList();
    print('🔍 API collections: $apiCollections');
    
    // Merge both lists and remove duplicates properly
    final allCollections = [...collections, ...apiCollections];
    allCollections.removeWhere((name) => name.isEmpty);
    
    // Remove duplicates using Set
    final uniqueCollections = allCollections.toSet().toList();
    
    setState(() {
      _existingCollections = uniqueCollections;
    });
    
    print('🔍 Final collections loaded: $_existingCollections');
    print('🔍 Total collections count: ${_existingCollections.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 650,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _currentStep < 3 ? () {
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
              title: const Text('Usage Guidance'),
              content: _buildUsageStep(),
              isActive: _currentStep >= 2,
            ),
            Step(
              title: const Text('Preview & Create'),
              content: _buildPreviewStep(),
              isActive: _currentStep >= 3,
            ),
          ],
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (details.currentStep < 3)
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: const Text('Next'),
                    ),
                  if (details.currentStep == 3)
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
                if (!_createNewCollection) {
                  _fields.clear();
                  _loadExistingCollections(); // Reload when switching to existing
                }
              }),
            ),
            const Text('Create New Collection'),
            const SizedBox(width: 24),
            Radio<bool>(
              value: false,
              groupValue: _createNewCollection,
              onChanged: (value) => setState(() {
                _createNewCollection = value!;
                if (!_createNewCollection) {
                  _fields.clear();
                  _loadExistingCollections(); // Reload when switching to existing
                }
              }),
            ),
            const Text('Use Existing Collection'),
          ],
        ),
        const SizedBox(height: 8),

        // Debug info
        if (!_createNewCollection)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.info, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Found ${_existingCollections.length} collections: ${_existingCollections.join(", ")}',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),

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
            decoration: InputDecoration(
              labelText: 'Select Collection *',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadExistingCollections,
                tooltip: 'Refresh Collections',
              ),
            ),
            items: _existingCollections
                .map((col) => DropdownMenuItem(value: col, child: Text(col)))
                .toList(),
            onChanged: (value) => setState(() => _collectionName = value!),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No existing collections found. Create a new collection or refresh.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadExistingCollections,
                  tooltip: 'Refresh Collections',
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fields',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (_createNewCollection || _method == 'POST' || _method == 'PUT' || _method == 'DELETE' || _method == 'GET')
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

        // Fields List or Info Message
        if (_createNewCollection || _method == 'POST') ...[
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
        ]
        else ...[
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
        // Auto-add ID field for update operations
        _fields = [
          ApiField(name: 'id', type: 'String', required: true, unique: true),
        ];
        break;
      case 'delete':
        _method = 'DELETE';
        _pathController.text = '/delete';
        _requiresAuth = true;
        // Auto-add ID field for delete operations
        _fields = [
          ApiField(name: 'id', type: 'String', required: true, unique: true),
        ];
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
          _requestExample[field.name] = field.arrayItems ?? [];
          break;
        case 'Object':
          _requestExample[field.name] = field.objectSchema ?? {};
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

  Widget _buildUsageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'API Usage Guidance',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Usage Scenario Selector
        DropdownButtonFormField<String>(
          value: _usageScenario.isNotEmpty ? _usageScenario : _getSuggestedScenario(),
          decoration: const InputDecoration(
            labelText: 'How will this API be used? *',
            hintText: 'Select usage scenario for UI binding guidance',
            border: OutlineInputBorder(),
            helperText: 'This helps generate proper field mapping',
          ),
          items: const [
            DropdownMenuItem(value: 'form_submission', child: Text('Form Submission')),
            DropdownMenuItem(value: 'data_display', child: Text('Data Display in ListView')),
            DropdownMenuItem(value: 'search_filter', child: Text('Search with Filters')),
            DropdownMenuItem(value: 'crud_operations', child: Text('CRUD Operations')),
            DropdownMenuItem(value: 'custom', child: Text('Custom Implementation')),
          ],
          onChanged: (value) => setState(() => _usageScenario = value!),
        ),

        const SizedBox(height: 16),

        // Usage Guidance based on scenario
        if (_usageScenario.isNotEmpty) ...[
          _buildUsageGuidance(),
        ],
      ],
    );
  }

  String _getSuggestedScenario() {
    switch (_purpose) {
      case 'login':
      case 'register':
        return 'form_submission';
      case 'read':
      case 'list':
        return 'data_display';
      case 'create':
        return 'form_submission';
      case 'update':
      case 'delete':
        return 'crud_operations';
      default:
        return 'custom';
    }
  }

  Widget _buildUsageGuidance() {
    switch (_usageScenario) {
      case 'form_submission':
        return _buildFormSubmissionGuidance();
      case 'data_display':
        return _buildDataDisplayGuidance();
      case 'search_filter':
        return _buildSearchFilterGuidance();
      case 'crud_operations':
        return _buildCrudOperationsGuidance();
      case 'custom':
        return _buildCustomImplementationGuidance();
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Select a usage scenario to see guidance'),
        );
    }
  }

  Widget _buildFormSubmissionGuidance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📝 Form Submission Usage',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text('1. Drag Form Components:', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('   • TextField for each field'),
          const Text('   • Button for submission'),
          const SizedBox(height: 8),
          const Text('2. Bind Button to API:', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('   • Select this API in button properties'),
          const Text('   • Map fields: formField → apiField'),
          const SizedBox(height: 8),
          const Text('3. Test Form:', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('   • Fill form and click button'),
          const Text('   • Check API response in console'),
        ],
      ),
    );
  }

  Widget _buildDataDisplayGuidance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Data Display Usage',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text('1. Drag ListView:', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('   • Add ListView to canvas'),
          const Text('   • Set Data Source API to this endpoint'),
          const Text('   • Configure item template and data field'),
          const SizedBox(height: 8),
          const Text('2. Automatic Data:', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('   • ListView will automatically fetch and display data'),
          const Text('   • Supports pagination and search parameters'),
          const SizedBox(height: 8),
          const Text('3. Advanced Usage:', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('   • Add search field to filter results'),
          const Text('   • Add sort options for better UX'),
        ],
      ),
    );
  }

  Widget _buildSearchFilterGuidance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔍 Search with Filters Usage',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text('1. Search Components:', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('   • TextField for search input'),
          const Text('   • Button for search action'),
          const Text('   • ListView for filtered results'),
          const SizedBox(height: 8),
          const Text('2. API Integration:', style: TextStyle(fontWeight: FontWeight.w500)),
          Text('   • Search API: ' + _pathController.text + '?search=keyword'),
          const Text('   • Map search field to search parameter'),
          const SizedBox(height: 8),
          const Text('3. Real-time Updates:', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('   • Use onChanged to update ListView URL dynamically'),
          const Text('   • Supports multiple filter parameters'),
        ],
      ),
    );
  }

  Widget _buildCrudOperationsGuidance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ CRUD Operations Usage',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text('1. Setup Forms:', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('   • Create form with all fields'),
          const Text('   • Edit form with ID field'),
          const Text('   • Delete button with ID confirmation'),
          const SizedBox(height: 8),
          const Text('2. API Endpoints:', style: TextStyle(fontWeight: FontWeight.w500)),
          Text('   • Create: POST ' + _pathController.text),
          Text('   • Read: GET ' + _pathController.text + '/:id'),
          Text('   • Update: PUT ' + _pathController.text + '/:id'),
          Text('   • Delete: DELETE ' + _pathController.text + '/:id'),
          const SizedBox(height: 8),
          const Text('3. ListView Integration:', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('   • Configure different templates for each operation'),
          const Text('   • Use conditional rendering based on operation type'),
        ],
      ),
    );
  }

  Widget _buildCustomImplementationGuidance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎨 Custom Implementation',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text('1. Define Your Use Case:', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('   • What specific problem does this API solve?'),
          const Text('   • Who are the users?'),
          const Text('   • What workflows need support?'),
          const SizedBox(height: 8),
          const Text('2. Design Components:', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('   • Choose appropriate widgets for your use case'),
          const Text('   • Consider user experience and accessibility'),
          const SizedBox(height: 8),
          const Text('3. Implementation Tips:', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('   • Start with minimum viable product'),
          const Text('   • Add error handling and loading states'),
          const Text('   • Test with real data scenarios'),
          const Text('   • Document API usage for team'),
        ],
      ),
    );
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

        // Only require fields if creating new collection OR if it's a POST/create operation
        // Exception: PUT and DELETE operations need ID field even with existing collections
        final needsFields = _createNewCollection || 
                            _method == 'POST' || 
                            _method == 'PUT' || 
                            _method == 'DELETE';
        
        if (needsFields && _fields.isEmpty) {
          _showError('Please add at least one field (ID required for PUT/DELETE operations)');
          return false;
        }

        return true;

      default:
        return true;
    }
  }

  Future<void> _createAPI() async {
    print(' Creating API with createCollection: $_createNewCollection');
    print(' Collection name: $_collectionName');
    
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

    // Force refresh collections after creating new collection
    if (_createNewCollection) {
      print(' New collection created, refreshing collections...');
      await _loadExistingCollections();
    }

    if (mounted) {
      Navigator.pop(context, api);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' API ${widget.existingApi != null ? "updated" : "created"} successfully${_createNewCollection ? " with new collection" : ""}'),
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
  dynamic _defaultValue;
  final _descriptionController = TextEditingController();
  List<dynamic> _arrayItems = [];
  final _jsonController = TextEditingController();
  bool _showJsonEditor = false;

  @override
  void initState() {
    super.initState();
    if (widget.field != null) {
      _nameController.text = widget.field!.name;
      _type = widget.field!.type;
      _required = widget.field!.required;
      _unique = widget.field!.unique;
      _validation = widget.field!.validation;
      _defaultValue = widget.field!.defaultValue;
      _descriptionController.text = widget.field!.description ?? '';
      _arrayItems = widget.field!.arrayItems ?? [];
      if (widget.field!.objectSchema != null) {
        _jsonController.text = const JsonEncoder.withIndent('  ').convert(widget.field!.objectSchema);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.field != null ? 'Edit Field' : 'Add Field'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Field Name *',
                  hintText: 'e.g., email, username, tags',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
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
                        DropdownMenuItem(value: 'ObjectId', child: Text('ObjectId')),
                        DropdownMenuItem(value: 'Array', child: Text('Array')),
                        DropdownMenuItem(value: 'Object', child: Text('Object')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _type = value!;
                          _showJsonEditor = (value == 'Object' || value == 'Array');
                          // Show array structure dialog for Array type
                          if (value == 'Array') {
                            _showArrayStructureDialog();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_type == 'Array')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showArrayStructureDialog(),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Array'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.blue.shade800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe this field for UI guidance',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // Array-specific options
              if (_type == 'Array') ...[
                const Text('Array Items (JSON format):', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                // Quick templates for common array types
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _jsonController.text = '["item1", "item2", "item3"]';
                        setState(() {});
                      },
                      child: const Text('Simple Array'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _jsonController.text = '[{"name": "value1", "quantity": 1}, {"name": "value2", "quantity": 2}]';
                        setState(() {});
                      },
                      child: const Text('Object Array'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _jsonController.text = '[{"key": "value", "number": 123, "boolean": true}]';
                        setState(() {});
                      },
                      child: const Text('Mixed Types'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: _jsonController,
                    decoration: const InputDecoration(
                      hintText: '[{"name": "ingredient", "quantity": "2 cups", "unit": "cups"}]',
                      border: InputBorder.none,
                      helperText: 'Enter JSON array with objects for key-value pairs',
                    ),
                    maxLines: 6,
                    onChanged: (value) {
                      try {
                        if (value.isNotEmpty) {
                          _arrayItems = json.decode(value);
                        }
                      } catch (e) {
                        // Invalid JSON, keep current items
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ' Tip: Use objects in arrays for key-value pairs like ingredients',
                  style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
                ),
              ],
              
              // Object-specific JSON editor
              if (_type == 'Object') ...[
                const Text('Object Schema (JSON format):', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: _jsonController,
                    decoration: const InputDecoration(
                      hintText: '{\n  "field1": "value1",\n  "field2": "value2"\n}',
                      border: InputBorder.none,
                    ),
                    maxLines: 8,
                    onChanged: (value) {
                      // Just store the JSON, validation on save
                    },
                  ),
                ),
              ],
              
              // Default value for simple types
              if (_type != 'Array' && _type != 'Object') ...[
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Default Value',
                    hintText: 'e.g., John Doe, true, 123',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _defaultValue = value,
                ),
              ],
              
              const SizedBox(height: 16),
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveField,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _showArrayStructureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Define Array Structure'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose array type:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              ListTile(
                title: const Text('Simple Array'),
                subtitle: const Text('Array of simple values: ["item1", "item2"]'),
                leading: const Icon(Icons.list),
                onTap: () {
                  _jsonController.text = '["item1", "item2", "item3"]';
                  Navigator.pop(context);
                },
              ),
              
              ListTile(
                title: const Text('Object Array'),
                subtitle: const Text('Array of objects with keys: [{"name": "value"}]'),
                leading: const Icon(Icons.format_list_bulleted),
                onTap: () {
                  _jsonController.text = '[{"name": "", "quantity": "", "unit": ""}]';
                  Navigator.pop(context);
                },
              ),
              
              ListTile(
                title: const Text('Mixed Types'),
                subtitle: const Text('Array with mixed data types'),
                leading: const Icon(Icons.category),
                onTap: () {
                  _jsonController.text = '[{"key": "value", "number": 123}]';
                  Navigator.pop(context);
                },
              ),
              
              const SizedBox(height: 16),
              const Text('Or define custom structure:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Enter custom JSON array',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  _jsonController.text = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _saveField() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter field name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate JSON for Array/Object types
    if ((_type == 'Array' || _type == 'Object') && _jsonController.text.isNotEmpty) {
      try {
        if (_type == 'Array') {
          _arrayItems = json.decode(_jsonController.text);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid JSON format'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    Map<String, dynamic>? objectSchema;
    if (_type == 'Object' && _jsonController.text.isNotEmpty) {
      try {
        objectSchema = json.decode(_jsonController.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid JSON format'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    widget.onSave(ApiField(
      name: _nameController.text,
      type: _type,
      required: _required,
      unique: _unique,
      validation: _validation,
      defaultValue: _defaultValue,
      description: _descriptionController.text,
      arrayItems: _arrayItems,
      objectSchema: objectSchema,
    ));
  }
}