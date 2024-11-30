import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'chat_page.dart';
import 'localization.dart';

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
  String _language = 'en'; // Default language
  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }
  Future<void> _loadLanguage() async {
    String? storedLanguage = await _storage.read(key: 'language');
    setState(() {
      _language = storedLanguage ?? 'en';
    });
  }
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
      appBar: AppBar(title: Text(AppLocalization.getString(_language, 'search_lost'))),
      //appBar: AppBar(title: const Text('Search Lost Items')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: queryController,
              decoration: InputDecoration(labelText: AppLocalization.getString(_language, 'search_query')),
              //decoration: const InputDecoration(labelText: 'Search Query'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _searchItems,
              child: Text(AppLocalization.getString(_language, 'search')),
             // child: const Text('Search'),
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
                          child:
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FutureBuilder<String?>(
                                future: _storage.read(key: "email"), // Fetch the current user email from storage
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(); // Show an empty widget while loading
                                  }

                                  final currentUserEmail = snapshot.data;
                                  final reportedByEmail = item["reported_by"] ?? "";

                                  // Only show the button if the current user's email is not the same as the reported_by email
                                  if (currentUserEmail != null && currentUserEmail != reportedByEmail) {
                                    return ElevatedButton(
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
                                    );
                                  } else {
                                    return
                                      ElevatedButton(
                                        onPressed: () async {
                                          final itemId = item["_id"]; // Replace with the actual ID of the item to mark as found
                                          await ApiService().markItemAsFound(itemId);
                                          // Optionally show a confirmation dialog or refresh the list
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Item marked as found')),
                                          );
                                        },
                                        child: const Text("Mark as Found"),
                                      );
                                  }
                                },
                              ),
                            ],
                          )
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
