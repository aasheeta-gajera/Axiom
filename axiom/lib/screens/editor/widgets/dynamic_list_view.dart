import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DynamicListView extends StatefulWidget {
  final String dataSource;
  final String itemTemplate;
  final String direction;
  final bool scroll;
  final String dataField;
  final String countField;

  const DynamicListView({
    Key? key,
    required this.dataSource,
    this.itemTemplate = 'card',
    this.direction = 'vertical',
    this.scroll = true,
    this.dataField = 'data',
    this.countField = 'count',
  }) : super(key: key);

  @override
  State<DynamicListView> createState() => _DynamicListViewState();
}

class _DynamicListViewState extends State<DynamicListView> {
  List<dynamic> _data = [];
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(DynamicListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataSource != widget.dataSource) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (widget.dataSource.isEmpty) {
      setState(() {
        _error = 'No data source configured';
        _data = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final response = await http.get(Uri.parse(widget.dataSource));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData[widget.dataField] ?? [];
        
        setState(() {
          _data = data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load data: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _loading = false;
      });
    }
  }

  Widget _buildItem(dynamic item) {
    switch (widget.itemTemplate) {
      case 'card':
        return _buildCard(item);
      case 'list':
        return _buildListItem(item);
      default:
        return _buildCard(item);
    }
  }

  Widget _buildCard(dynamic item) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Try to find a title field
            Text(
              item['mobile'] ?? item['name'] ?? item['title'] ?? 'Item',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Try to find common fields
            if (item['price'] != null)
              Text(
                'Price: ${item['price']}',
                style: TextStyle(color: Colors.green.shade700),
              ),
            if (item['category'] != null)
              Text('Category: ${item['category']}'),
            if (item['description'] != null)
              Text(item['description']),
            // Show all other fields as key-value pairs
            ...item.entries
                .where((entry) => !['mobile', 'name', 'title', 'price', 'category', 'description'].contains(entry.key))
                .map((entry) => Text('${entry.key}: ${entry.value}')),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(dynamic item) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          (item['id'] ?? '?').toString().substring(0, 1).toUpperCase(),
        ),
      ),
      title: Text(
        item['mobile'] ?? item['name'] ?? item['title'] ?? 'Item',
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item['price'] != null) Text('Price: ${item['price']}'),
          if (item['category'] != null) Text('Category: ${item['category']}'),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading data...'),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text('No data found'),
          ],
        ),
      );
    }

    if (widget.direction == 'horizontal') {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _data.length,
        itemBuilder: (context, index) => _buildItem(_data[index]),
      );
    }

    return ListView.builder(
      itemCount: _data.length,
      itemBuilder: (context, index) => _buildItem(_data[index]),
    );
  }
}
