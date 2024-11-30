import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'chat_page.dart';
import 'localization.dart';

/// A screen for searching lost items by entering a query in a search bar.
///
/// The user can input a search query and view the list of lost items that match
/// the query. Each result includes an image of the lost item, and the option to
/// either start a chat with the person who reported the item or mark it as found.
///
/// The UI supports dynamic localization based on the user's language preference.
class SearchLostItemsScreen extends StatefulWidget {
  /// Creates a new instance of [SearchLostItemsScreen].
  const SearchLostItemsScreen({Key? key}) : super(key: key);

  @override
  _SearchLostItemsScreenState createState() => _SearchLostItemsScreenState();
}

class _SearchLostItemsScreenState extends State<SearchLostItemsScreen> {
  /// Controller for the search query text field.
  final TextEditingController queryController = TextEditingController();

  /// A list of search results containing information about the lost items.
  List<Map<String, dynamic>> _searchResults = [];

  /// A boolean that indicates whether the search is in progress.
  bool isLoading = false;

  /// An instance of [FlutterSecureStorage] to securely store user preferences.
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// The language code for localization (default is 'en').
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  /// Loads the user's preferred language from secure storage.
  ///
  /// If no language is stored, it defaults to `'en'` (English).
  Future<void> _loadLanguage() async {
    String? storedLanguage = await _storage.read(key: 'language');
    setState(() {
      _language = storedLanguage ?? 'en';
    });
  }

  /// Searches for lost items based on the entered query.
  ///
  /// If the query is empty, a snackbar is shown prompting the user to enter a query.
  /// Otherwise, the search results are fetched from the server using [ApiService].
  Future<void> _searchItems() async {
    try {
      final query = queryController.text;

      // If the search query is empty, show an error message
      if (query.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a search query!')),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      // Fetch the search results from the backend
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Text field for entering search query
            TextField(
              controller: queryController,
              decoration: InputDecoration(labelText: AppLocalization.getString(_language, 'search_query')),
            ),
            const SizedBox(height: 20),

            // Search button
            ElevatedButton(
              onPressed: _searchItems,
              child: Text(AppLocalization.getString(_language, 'search')),
            ),
            const SizedBox(height: 20),

            // Display a loading indicator while the search is in progress
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  final reportedByEmail = item["reported_by"] ?? "";
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display item image, or a placeholder if the image is missing
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // FutureBuilder to fetch the current user email and decide whether to show "Chat" or "Mark as Found" button
                              FutureBuilder<String?>(
                                future: _storage.read(key: "email"), // Fetch current user email
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(); // Show empty widget while loading
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
                                    return ElevatedButton(
                                      onPressed: () async {
                                        final itemId = item["_id"]; // Mark the item as found
                                        await ApiService().markItemAsFound(itemId);
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
