
 import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/ApiEndpointmodel.dart';
import '../providers/ApiProvider.dart';
import '../providers/ProjectProvider.dart';
import '../screens/editor/widgets/api_creation_dialog.dart';
import 'package:provider/provider.dart';

class Utils {

   Widget buildEmptyState(BuildContext context, String type) {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(type == 'api' ?Icons.api : type == 'pp'
           ? Icons.touch_app
               : Icons.folder_open, size: 120, color: Colors.grey.shade300),
           const SizedBox(height: 24),
           Text(
             type == 'api'?'No APIs Created':type == 'pp'?'Select a widget\nto edit properties':'No projects yet',
             style: TextStyle(fontSize: 24, color: Colors.grey.shade600),
           ),
           const SizedBox(height: 16),
           ElevatedButton.icon(
             onPressed: () => showAddAPIDialog(context),
             icon: const Icon(Icons.add),
             label: type == 'api'?Text('Create First API'):Text('Create Your First Project'),
           ),
         ],
       ),
     );
   }

   Future<void> showAddAPIDialog(BuildContext context) async {
     final result = await showDialog<ApiEndpoint>(
       context: context,
       builder: (context) => const EnhancedAPICreationDialog(),
     );

     if (result != null && context.mounted) {
       final apiProvider = context.read<ApiProvider>();
       final success = await apiProvider.createAPI(result);

       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(
               success ? '✅ API created successfully' : '❌ ${apiProvider.errorMessage}',
             ),
           ),
         );
       }
     }
   }

   Future<void> showEditAPIDialog(
       BuildContext context,
       ApiEndpoint endpoint,
       ) async {
     final result = await showDialog<ApiEndpoint>(
       context: context,
       builder: (context) => EnhancedAPICreationDialog(existingApi: endpoint),
     );

     if (result != null && context.mounted) {
       final apiProvider = context.read<ApiProvider>();
       final success = await apiProvider.updateAPI(result);

       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(
               success ? '✅ API updated successfully' : '❌ ${apiProvider.errorMessage}',
             ),
           ),
         );
       }
     }
   }

   Future<void> deleteAPI(BuildContext context, ApiEndpoint endpoint) async {
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

     if (confirm == true && context.mounted) {
       final apiProvider = context.read<ApiProvider>();
       final success = await apiProvider.deleteAPI(endpoint);

       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(
               success ? '✅ API deleted successfully' : '❌ ${apiProvider.errorMessage}',
             ),
           ),
         );
       }
     }
   }

   Future<void> testAPI(BuildContext context, ApiEndpoint endpoint) async {
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
             onPressed: () async {
               Navigator.pop(context);

               if (context.mounted) {
                 final apiProvider = context.read<ApiProvider>();
                 final result = await apiProvider.testAPI(endpoint);

                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                       content: Text(
                         result != null
                             ? '✅ Test successful: ${result['response']}'
                             : '❌ Test failed',
                       ),
                     ),
                   );
                 }
               }
             },
             child: const Text('Send'),
           ),
         ],
       ),
     );
   }

   Color getMethodColor(String method) {
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

   Future<void> showCreateProjectDialog(BuildContext context) async {
     final nameController = TextEditingController();
     final descController = TextEditingController();

     return showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Create New Project'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             TextField(
               controller: nameController,
               decoration: const InputDecoration(
                 labelText: 'Project Name',
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
               maxLines: 3,
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('Cancel'),
           ),
           ElevatedButton(
             onPressed: () async {
               if (nameController.text.isNotEmpty) {
                 await context.read<ProjectProvider>().createProject(
                   nameController.text,
                   descController.text,
                 );
                 if (context.mounted) {
                   Navigator.pop(context);
                 }
               }
             },
             child: const Text('Create'),
           ),
         ],
       ),
     );
   }

   Future<bool?> showDeleteConfirmation(BuildContext context) {
     return showDialog<bool>(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Delete Project'),
         content: const Text('Are you sure you want to delete this project?'),
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
   }

}
