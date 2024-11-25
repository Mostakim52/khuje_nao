import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:khuje_nao/report_lost_item_screen.dart';
import 'package:khuje_nao/search_lost_item_screen.dart';
import 'package:khuje_nao/login_screen.dart';

class ActivityFeedPage extends StatefulWidget {
  @override
  _ActivityFeedPageState createState() => _ActivityFeedPageState();
}

class _ActivityFeedPageState extends State<ActivityFeedPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Mock data for lost and found items (replace with API data)
  final List<Map<String, String>> lostItems = [
    {
      "title": "Lost Wallet",
      "description": "Black leather wallet lost in the library.",
      "location": "Library"
    },
    {
      "title": "Lost Laptop",
      "description": "Silver Dell XPS laptop lost in the cafeteria.",
      "location": "Cafeteria"
    }
  ];

  final List<Map<String, String>> foundItems = [
    {
      "title": "Found Phone",
      "description": "Blue Samsung phone found near the main gate.",
      "location": "Main Gate"
    },
    {
      "title": "Found Backpack",
      "description": "Black backpack found in the auditorium.",
      "location": "Auditorium"
    }
  ];

  /// Logout and redirect to login screen
  Future<void> _logout() async {
    await _storage.deleteAll(); // Clear all stored session data
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Lost Items and Found Items
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity Feed'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ),
        body: Column(
          children: [
            // Buttons Row
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ReportLostItemScreen()),
                      );
                    },
                    child: const Text('Report Lost Item'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SearchLostItemsScreen()),
                      );
                    },
                    child: const Text('Search Item'),
                  ),
                ],
              ),
            ),
            // TabBar
            const TabBar(
              tabs: [
                Tab(text: "Lost Items"),
                Tab(text: "Found Items"),
              ],
            ),
            // Expanded TabBarView to fill the rest of the screen
            Expanded(
              child: TabBarView(
                children: [
                  // Lost Items Tab
                  ListView.builder(
                    itemCount: lostItems.length,
                    itemBuilder: (context, index) {
                      final item = lostItems[index];
                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          title: Text(item["title"] ?? ""),
                          subtitle: Text(
                            "${item["description"]}\nLocation: ${item["location"]}",
                          ),
                        ),
                      );
                    },
                  ),

                  // Found Items Tab
                  ListView.builder(
                    itemCount: foundItems.length,
                    itemBuilder: (context, index) {
                      final item = foundItems[index];
                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          title: Text(item["title"] ?? ""),
                          subtitle: Text(
                            "${item["description"]}\nLocation: ${item["location"]}",
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddItemPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: const Center(
        child: Text('This is the Add Item Page.'),
      ),
    );
  }
}
