
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ApiProvider.dart';
import '../Library/CommonWidgets/APICard.dart';
import '../Library/Utils.dart';

class APIManagementScreen extends StatelessWidget {
  const APIManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Load APIs when screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApiProvider>().loadAPIs();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('API Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Utils().showAddAPIDialog(context),
          ),
        ],
      ),
      body: Consumer<ApiProvider>(
        builder: (context, apiProvider, child) {
          if (apiProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (apiProvider.endpoints.isEmpty) {
            return Utils().buildEmptyState(context,'api');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apiProvider.endpoints.length,
            itemBuilder: (context, index) {
              return APICard(
                endpoint: apiProvider.endpoints[index],
                onEdit: () => Utils().showEditAPIDialog(
                  context,
                  apiProvider.endpoints[index],
                ),
                onDelete: () => Utils().deleteAPI(
                  context,
                  apiProvider.endpoints[index],
                ),
                onTest: () => Utils().testAPI(
                  context,
                  apiProvider.endpoints[index],
                ),
              );
            },
          );
        },
      ),
    );
  }
}