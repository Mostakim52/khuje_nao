import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'chat_page.dart';

class SearchLostItemsScreen extends StatefulWidget {
  const SearchLostItemsScreen({Key? key}) : super(key: key);

  @override
  _SearchLostItemsScreenState createState() => _SearchLostItemsScreenState();
}

class _SearchLostItemsScreenState extends State<SearchLostItemsScreen> {
  final TextEditingController queryController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool isLoading = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _searchItems() async {
    try {
      final query = queryController.text;

      if (query.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a search query!')),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      final results = await ApiService().searchLostItems(query: query);

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Error searching items: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
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
            isLoading
                ? const Center(child: CircularProgressIndicator())
                :
            Expanded(
              child:
              ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  final reportedByEmail = item["reported_by"] ?? "";
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display Image
                        item["image"] != null && item["image"]!.isNotEmpty
                            ? Image.network(
                          item["image"]!,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.broken_image,
                            size: 50,
                          ),
                        )
                            : Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["description"] ?? "No description provided",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Location: ${item["location"] ?? "Unknown"}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  // Save the receiver email to storage
                                  await _storage.write(key: "receiver_email", value: reportedByEmail);

                                  // Navigate to the ChatPage
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ChatPage()),
                                  );
                                },
                                child: const Text("Chat"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
