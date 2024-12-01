import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:khuje_nao/api_service.dart';

/// The `AdminPage` widget provides an interface for the admin to view and approve lost items.
/// It fetches a list of lost items from the backend and displays them with options to approve or refresh the list.
class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  /// A list of lost items fetched from the backend server.
  List<dynamic> _lostItems = [];

  /// A boolean flag to indicate if the lost items are loading.
  bool _isLoading = true;

  /// The base URL of the backend server.
  final String baseUrl = 'http://10.0.2.2:5000'; // Replace with your backend URL

  /// An instance of the `ApiService` for making API calls.
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchLostItems();
  }

  /// Fetches the lost items from the backend and updates the state.
  ///
  /// This method sends a GET request to the backend and updates the list of lost items
  /// once the data is successfully fetched.
  Future<void> _fetchLostItems() async {
    final url = '$baseUrl/lost-items-admin'; // Replace with your server URL
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _lostItems = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        _showError('Failed to load items.');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  /// Approves a specific lost item by sending a POST request to the backend.
  ///
  /// This method takes the item ID, sends a POST request to approve the item, and refreshes
  /// the list of items once the approval is successful.
  Future<void> _approveItem(String itemId) async {
    final url = '$baseUrl/lost-items/$itemId/approve'; // Replace with your server URL
    try {
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        _showMessage('Item approved successfully.');
        _fetchLostItems(); // Refresh the list after approval
      } else {
        _showError('Failed to approve item.');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  /// Displays an error message in a snackbar.
  ///
  /// This method is used to show error messages to the user via a snackbar.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.red))),
    );
  }

  /// Displays a success message in a snackbar.
  ///
  /// This method is used to show success messages to the user via a snackbar.
  void _showMessage(String message) {
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
                _fetchLostItems(); // Trigger refresh when pressed
              },
            ),
            ElevatedButton(
              onPressed: () {
                apiService.sendEmails();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emails submitted successfully.')),
                );
              },
              child: const Text('Send Emails'),
            ),
  ]),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _lostItems.length,
        itemBuilder: (context, index) {
          final item = _lostItems[index];
          return Card(
            child: ListTile(
              leading: item['image'] != null
                  ? Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover)
                  : Icon(Icons.image_not_supported),
              title: Text(item['description'] ?? 'No description'),
              subtitle: Text('Location: ${item['location'] ?? 'Unknown'}'),
              trailing: ElevatedButton(
                onPressed: () => _approveItem(item['_id'].toString()), // Approve button
                child: Text('Approve'),
              ),
            ),
          );
        },
      ),
    );
  }
}