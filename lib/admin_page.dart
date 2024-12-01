import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:khuje_nao/api_service.dart';

/// The `AdminPage` widget provides an interface for the admin to view and approve lost items.
/// It fetches a list of lost items from the backend and displays them with options to approve or refresh the list.
class AdminPage extends StatefulWidget {
  @override
  AdminPageState createState() => AdminPageState();
}

class AdminPageState extends State<AdminPage> {
  /// A list of lost items fetched from the backend server.
  List<dynamic> lost_items = [];

  /// A boolean flag to indicate if the lost items are loading.
  bool is_loading = true;

  /// The base URL of the backend server.
  final String base_url = 'https://alien-witty-monitor.ngrok-free.app'; // Replace with your backend URL

  /// An instance of the `ApiService` for making API calls.
  final ApiService api_service = ApiService();

  @override
  void initState() {
    super.initState();
    fetchLostItems();
  }

  /// Fetches the lost items from the backend and updates the state.
  ///
  /// This method sends a GET request to the backend and updates the list of lost items
  /// once the data is successfully fetched.
  Future<void> fetchLostItems() async {
    final url = '$base_url/lost-items-admin'; // Replace with your server URL
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          lost_items = json.decode(response.body);
          is_loading = false;
        });
      } else {
        showError('Failed to load items.');
      }
    } catch (e) {
      showError('Error: $e');
    }
  }

  /// Approves a specific lost item by sending a POST request to the backend.
  ///
  /// This method takes the item ID, sends a POST request to approve the item, and refreshes
  /// the list of items once the approval is successful.
  Future<void> approveItem(String itemId) async {
    final url = '$base_url/lost-items/$itemId/approve'; // Replace with your server URL
    try {
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        showMessage('Item approved successfully.');
        fetchLostItems(); // Refresh the list after approval
      } else {
        showError('Failed to approve item.');
      }
    } catch (e) {
      showError('Error: $e');
    }
  }

  /// Displays an error message in a snackbar.
  ///
  /// This method is used to show error messages to the user via a snackbar.
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.red))),
    );
  }

  /// Displays a success message in a snackbar.
  ///
  /// This method is used to show success messages to the user via a snackbar.
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Admin Panel - Lost Items'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh), // Refresh icon
              onPressed: () {
                fetchLostItems(); // Trigger refresh when pressed
              },
            ),
            ElevatedButton(
              onPressed: () {
                api_service.sendEmails();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emails submitted successfully.')),
                );
              },
              child: const Text('Send Emails'),
            ),
  ]),
      body: is_loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: lost_items.length,
        itemBuilder: (context, index) {
          final item = lost_items[index];
          return Card(
            child: ListTile(
              leading: item['image'] != null
                  ? Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover)
                  : Icon(Icons.image_not_supported),
              title: Text(item['description'] ?? 'No description'),
              subtitle: Text('Location: ${item['location'] ?? 'Unknown'}'),
              trailing: ElevatedButton(
                onPressed: () => approveItem(item['_id'].toString()), // Approve button
                child: Text('Approve'),
              ),
            ),
          );
        },
      ),
    );
  }
}