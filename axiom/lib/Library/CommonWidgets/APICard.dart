
import 'package:axiom/Library/Utils.dart';
import 'package:flutter/material.dart';
import '../../models/ApiEndpointmodel.dart';

class APICard extends StatefulWidget {

  final ApiEndpoint endpoint;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTest;

  const APICard({super.key, required this.endpoint, required this.onEdit, required this.onDelete, required this.onTest});

  @override
  State<APICard> createState() => _APICardState();
}

class _APICardState extends State<APICard> {
  @override
  Widget build(BuildContext context) {
    final methodColor = Utils().getMethodColor(widget.endpoint.method);

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
                    widget.endpoint.method,
                    style: TextStyle(
                      color: methodColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.endpoint.path,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.endpoint.auth)
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
                    if (value == 'edit') widget.onEdit();
                    if (value == 'test') widget.onTest();
                    if (value == 'delete') widget.onDelete();
                  },
                ),
              ],
            ),
            if (widget.endpoint.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.endpoint.description,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
