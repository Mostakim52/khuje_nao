import 'package:flutter/material.dart';
import 'api_service.dart';

class SearchLostItemsScreen extends StatefulWidget {
  const SearchLostItemsScreen({Key? key}) : super(key: key);

  @override
  _SearchLostItemsScreenState createState() => _SearchLostItemsScreenState();
}

class _SearchLostItemsScreenState extends State<SearchLostItemsScreen> {
  final TextEditingController queryController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _searchItems() async {
    try {
      final query = queryController.text;
      final location = locationController.text;

      if (query.isEmpty && location.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter at least one search criterion!')),
        );
        return;
      }

      final results = await ApiService().searchLostItems(
        query: query,
        location: location,
      );

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Error searching items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Lost Items')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: queryController,
              decoration: const InputDecoration(labelText: 'Search Query'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _searchItems,
              child: const Text('Search'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return ListTile(
                    title: Text(item['description']),
                    subtitle: Text('Location: ${item['location']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
