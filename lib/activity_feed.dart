import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:khuje_nao/api_service.dart';
import 'package:khuje_nao/report_lost_item_screen.dart';
import 'package:khuje_nao/search_lost_item_screen.dart';
import 'package:khuje_nao/login_screen.dart';
import 'chat_page.dart';
import 'chat_page_list.dart';
import 'dart:ui' as ui; // Required for boundary.toImage
import 'dart:io'; // For File operations
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart'; // For temporary directory
import 'package:share_plus/share_plus.dart'; // For sharing
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'localization.dart';

/// A screen that displays a feed of lost and found items.
/// Allows users to report lost items, search for lost items, and chat about items.
/// The screen shows two tabs: Lost Items and Found Items.
class ActivityFeedPage extends StatefulWidget {
  @override
  ActivityFeedPageState createState() => ActivityFeedPageState();
}

/// The state for [ActivityFeedPage] that manages the feed data and user interactions.
class ActivityFeedPageState extends State<ActivityFeedPage> {
  final FlutterSecureStorage STORAGE = const FlutterSecureStorage();
  final String base_url = 'https://alien-witty-monitor.ngrok-free.app';
  List<Map<String, dynamic>> lost_items = [];
  List<Map<String, dynamic>> found_items = [];
  List<GlobalKey> lost_item_keys = []; // List of keys for lost items
  List<GlobalKey> found_item_keys = []; // List of keys for found items
  String language = 'en'; // Default language
  bool is_loading = true;

  @override
  void initState() {
    super.initState();
    fetchItems();
    loadLanguage();
  }

  /// Loads the stored language preference from secure storage.
  Future<void> loadLanguage() async {
    String? stored_language = await STORAGE.read(key: 'language');
    setState(() {
      language = stored_language ?? 'en';
    });
  }

  /// Fetches lost and found items from the backend API.
  Future<void> fetchItems() async {
    try {
      setState(() {
        is_loading = true;
      });

      final lostItemsResponse =
      await http.get(Uri.parse('$base_url/lost-items'));
      final foundItemsResponse =
      await http.get(Uri.parse('$base_url/found-items'));

      if (lostItemsResponse.statusCode == 200 &&
          foundItemsResponse.statusCode == 200) {
        setState(() {
          lost_items = List<Map<String, dynamic>>.from(
              json.decode(lostItemsResponse.body));
          found_items = List<Map<String, dynamic>>.from(
              json.decode(foundItemsResponse.body));

          // Initialize keys for each list item
          lost_item_keys = List.generate(
              lost_items.length, (index) => GlobalKey());
          found_item_keys = List.generate(
              found_items.length, (index) => GlobalKey());
        });
      } else {
        print('Failed to fetch items. Status code: ${lostItemsResponse.statusCode}');
      }
    } catch (e) {
      print('Error fetching items: $e');
    } finally {
      setState(() {
        is_loading = false;
      });
    }
  }

  /// Captures an image of the lost or found item and shares it.
  Future<void> captureAndShareCard(GlobalKey key) async {
    try {
      // Wait until the widget has been fully rendered
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // Find the render object using the provided GlobalKey
          RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;

          // Capture the image from the boundary
          ui.Image image = await boundary.toImage(pixelRatio: 2.0);
          ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

          if (byteData != null) {
            final Uint8List pngBytes = byteData.buffer.asUint8List();

            // Save the image to a temporary directory
            final directory = await getTemporaryDirectory();
            final imagePath = '${directory.path}/lost_item.png';
            File imgFile = File(imagePath);
            await imgFile.writeAsBytes(pngBytes);

            // Share the image using XFile from share_plus
            final XFile xFile = XFile(imagePath);
            await Share.shareXFiles(
              [xFile],
              text: AppLocalization.getString(language, 'share_msg'),
              //text: 'Check out this lost item!',
            );
          }
        } catch (e) {
          print('Error capturing and sharing image: $e');
        }
      });
    } catch (e) {
      print('Error scheduling post frame callback: $e');
    }
  }

  /// Logs out the user by clearing the session and navigating to the login screen.
  Future<void> logout() async {
    await STORAGE.deleteAll(); // Clear all stored session data
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Remove all previous routes
    );
  }

  /// Builds the main layout for the activity feed screen, which includes:
  /// - A tab bar with two tabs: Lost Items and Found Items.
  /// - A refresh button to reload the list of items.
  /// - A chat button to navigate to the chat page.
  /// - A logout button to log the user out.
  /// - A list view for each tab displaying items with options to interact with them (mark as found, chat, share, etc.).
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Lost Items and Found Items
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalization.getString(language, 'feed')),
          //title: const Text('Activity Feed'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh), // Refresh icon
              onPressed: () {
                fetchItems(); // Trigger refresh when pressed
              },
            ),
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () {
                // Navigate to the ChatPageList when the button is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPageList(), // Navigate to the chat list
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: logout,
            ),
          ],
        ),
        body: is_loading
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
                    child: Text(AppLocalization.getString(language,"report_lost")),
                    //child: const Text('Report Lost Item'),
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
                    child: Text(AppLocalization.getString(language, 'search_items')),
                    //child: const Text('Search Item'),
                  ),
                ],
              ),
            ),
            // TabBar
             TabBar(
              tabs: [
                Tab(text: AppLocalization.getString(language, 'lost_items')),
                Tab(text: AppLocalization.getString(language, 'found_items')),
                //Tab(text: "Lost Items"),
               // Tab(text: "Found Items"),
              ],
            ),
            // Expanded TabBarView to fill the rest of the screen
            Expanded(
              child: TabBarView(
                children: [
                  // Lost Items Tab
                  ListView.builder(
                    itemCount: lost_items.length,
                    itemBuilder: (context, index) {
                      final item = lost_items[index];
                      return RepaintBoundary(
                      key: lost_item_keys[index],
                        child: Card(
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
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 50),
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
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Location: ${item["location"] ?? "Unknown"}",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      FutureBuilder<String?>(
                                        future: STORAGE.read(key: "email"), // Fetch the current user email from storage
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
                                                await STORAGE.write(key: "receiver_email", value: reportedByEmail);

                                                // Navigate to the ChatPage
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => ChatPage()),
                                                );
                                              },
                                              child: Text(AppLocalization.getString(language, 'chat')),
                                            );
                                          } else {
                                            return
                                              ElevatedButton(
                                                onPressed: () async {
                                                  final itemId = item["_id"]; // Replace with the actual ID of the item to mark as found
                                                  await ApiService().markItemAsFound(itemId);
                                                  // Optionally show a confirmation dialog or refresh the list
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(AppLocalization.getString(language, 'mark_msg'))),
                                                    //const SnackBar(content: Text('Item marked as found')),
                                                  );
                                                },
                                                child: Text(AppLocalization.getString(language, 'mark_found')),
                                                //child: const Text("Mark as Found"),
                                              );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          await captureAndShareCard(lost_item_keys[index]);  // Share the card content
                                        },
                                        child: Text(AppLocalization.getString(language, 'share')),
                                        //child: const Text("Share"),
                                      ),
                                    ],
                                  ),

                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      );
                    },
                  ),

                  // Found Items Tab
                  ListView.builder(
                    itemCount: found_items.length,
                    itemBuilder: (context, index) {
                      final item = found_items[index];
                      key: found_item_keys[index]; // Use a unique key
                      return RepaintBoundary(
                          key: lost_item_keys[index],
                          child: Card(
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
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 50),
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
                                            fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "Location: ${item["location"] ?? "Unknown"}",
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey[700]),
                                      ),
                                      const SizedBox(height: 10),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          FutureBuilder<String?>(
                                            future: STORAGE.read(key: "email"), // Fetch the current user email from storage
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
                                                    await STORAGE.write(key: "receiver_email", value: reportedByEmail);

                                                    // Navigate to the ChatPage
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (context) => ChatPage()),
                                                    );
                                                  },
                                                  child: Text(AppLocalization.getString(language, 'chat')),
                                                );
                                              } else {
                                                return
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      final itemId = item["_id"]; // Replace with the actual ID of the item to mark as found
                                                      await ApiService().markItemAsFound(itemId);
                                                      // Optionally show a confirmation dialog or refresh the list
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text(AppLocalization.getString(language, 'mark_msg'))),
                                                        //const SnackBar(content: Text('Item marked as found')),
                                                      );
                                                    },
                                                    child: Text(AppLocalization.getString(language, 'mark_found')),
                                                    //child: const Text("Mark as Found"),
                                                  );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Column(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              await captureAndShareCard(lost_item_keys[index]);  // Share the card content
                                            },
                                            child: Text(AppLocalization.getString(language, 'share')),
                                            //child: const Text("Share"),
                                          ),
                                        ],
                                      ),

                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
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
