import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../models/widget_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';

class APIManagementScreen extends StatefulWidget {
  const APIManagementScreen({super.key});

  @override
  State<APIManagementScreen> createState() => _APIManagementScreenState();
}

class _APIManagementScreenState extends State<APIManagementScreen> {
  List<ApiEndpoint> _endpoints = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAPIs();
  }

  Future<void> _loadAPIs() async {
    final projectProvider = context.read<ProjectProvider>();
    if (projectProvider.currentProject != null) {
      setState(() {
        _endpoints = projectProvider.currentProject!.apis;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAPIDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _endpoints.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _endpoints.length,
        itemBuilder: (context, index) {
          return _APICard(
            endpoint: _endpoints[index],
            onEdit: () => _showEditAPIDialog(_endpoints[index]),
            onDelete: () => _deleteAPI(_endpoints[index]),
            onTest: () => _testAPI(_endpoints[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.api, size: 120, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            'No APIs Created',
            style: TextStyle(fontSize: 24, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddAPIDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create First API'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddAPIDialog() async {
    final methodController = TextEditingController(text: 'GET');
    final pathController = TextEditingController();
    final descController = TextEditingController();
    bool requiresAuth = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New API'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: methodController.text,
                  decoration: const InputDecoration(
                    labelText: 'HTTP Method',
                    border: OutlineInputBorder(),
                  ),
                  items: ['GET', 'POST', 'PUT', 'DELETE']
                      .map((method) => DropdownMenuItem(
                    value: method,
                    child: Text(method),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) methodController.text = value;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pathController,
                  decoration: const InputDecoration(
                    labelText: 'Path (e.g., /users)',
                    border: OutlineInputBorder(),
                    prefixText: '/api',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Requires Authentication'),
                  value: requiresAuth,
                  onChanged: (value) {
                    setState(() {
                      requiresAuth = value ?? false;
                    });
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
              onPressed: () async {
                if (pathController.text.isNotEmpty) {
                  await _createAPI(
                    methodController.text,
                    pathController.text,
                    descController.text,
                    requiresAuth,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditAPIDialog(ApiEndpoint endpoint) async {
    final methodController = TextEditingController(text: endpoint.method);
    final pathController = TextEditingController(text: endpoint.path);
    final descController = TextEditingController(text: endpoint.description);
    bool requiresAuth = endpoint.auth;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit API'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: methodController.text,
                  decoration: const InputDecoration(
                    labelText: 'HTTP Method',
                    border: OutlineInputBorder(),
                  ),
                  items: ['GET', 'POST', 'PUT', 'DELETE']
                      .map((method) => DropdownMenuItem(
                    value: method,
                    child: Text(method),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) methodController.text = value;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pathController,
                  decoration: const InputDecoration(
                    labelText: 'Path',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Requires Authentication'),
                  value: requiresAuth,
                  onChanged: (value) {
                    setState(() {
                      requiresAuth = value ?? false;
                    });
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
              onPressed: () async {
                await _updateAPI(
                  endpoint.id,
                  methodController.text,
                  pathController.text,
                  descController.text,
                  requiresAuth,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAPI(String method, String path, String description, bool auth) async {
    setState(() => _isLoading = true);

    try {
      final projectProvider = context.read<ProjectProvider>();
      final authService = context.read<AuthService>(); // ✅ Get auth service
      final projectId = projectProvider.currentProject?.id;

      if (projectId == null) return;

      final response = await http.post(
        Uri.parse('https://axiom-mmd4.onrender.com/api/apis/$projectId/endpoints'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.token}', // ✅ Use real token
        },
        body: json.encode({
          'method': method,
          'path': path,
          'description': description,
          'auth': auth,
        }),
      );

      if (response.statusCode == 201) {
        await _loadAPIs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ API created successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAPI(String id, String method, String path,
      String description, bool auth) async {
    // Implementation similar to _createAPI
  }

  Future<void> _deleteAPI(ApiEndpoint endpoint) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete API'),
        content: Text('Delete ${endpoint.method} ${endpoint.path}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Implement delete logic
    }
  }

  Future<void> _testAPI(ApiEndpoint endpoint) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test ${endpoint.method} ${endpoint.path}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Method: ${endpoint.method}'),
            Text('Path: ${endpoint.path}'),
            Text('Auth: ${endpoint.auth ? "Required" : "Not Required"}'),
            const SizedBox(height: 16),
            const Text('Send test request?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement test logic
              Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _APICard extends StatelessWidget {
  final ApiEndpoint endpoint;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTest;

  const _APICard({
    required this.endpoint,
    required this.onEdit,
    required this.onDelete,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    final methodColor = _getMethodColor(endpoint.method);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: methodColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    endpoint.method,
                    style: TextStyle(
                      color: methodColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    endpoint.path,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (endpoint.auth)
                  const Icon(Icons.lock, size: 20, color: Colors.orange),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'test', child: Text('Test')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'test') onTest();
                    if (value == 'delete') onDelete();
                  },
                ),
              ],
            ),
            if (endpoint.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                endpoint.description,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}