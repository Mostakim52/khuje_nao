import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:khuje_nao/report_lost_item_screen.dart';
import 'package:khuje_nao/search_lost_item_screen.dart';
import 'package:khuje_nao/login_screen.dart';

class ActivityFeedPage extends StatefulWidget {
  @override
  _ActivityFeedPageState createState() => _ActivityFeedPageState();
}

class _ActivityFeedPageState extends State<ActivityFeedPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> lostItems = [];
  List<Map<String, dynamic>> foundItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  /// Fetch lost and found items from the backend
  Future<void> fetchItems() async {
    try {
      setState(() {
        isLoading = true;
      });

      final lostItemsResponse =
      await http.get(Uri.parse('http://10.0.2.2:5000/lost-items'));
      final foundItemsResponse =
      await http.get(Uri.parse('http://10.0.2.2:5000/found-items'));

      if (lostItemsResponse.statusCode == 200 &&
          foundItemsResponse.statusCode == 200) {
        setState(() {
          lostItems = List<Map<String, dynamic>>.from(
              json.decode(lostItemsResponse.body));
          foundItems = List<Map<String, dynamic>>.from(
              json.decode(foundItemsResponse.body));
        });
      } else {
        print('Failed to fetch items. Status code: ${lostItemsResponse.statusCode}');
      }
    } catch (e) {
      print('Error fetching items: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                            builder: (context) =>
                            const ReportLostItemScreen()),
                      );
                    },
                    child: const Text('Report Lost Item'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                            const SearchLostItemsScreen()),
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
                          title: Text(item["description"] ?? "No Title"),
                          subtitle: Text(
                            "Location: ${item["location"] ?? "Unknown"}",
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
                          title: Text(item["description"] ?? "No Title"),
                          subtitle: Text(
                            "Location: ${item["location"] ?? "Unknown"}",
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
