import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:khuje_nao/api_service.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<dynamic> _lostItems = [];
  bool _isLoading = true;
  final String baseUrl = 'http://10.0.2.2:5000'; // Replace with your backend URL
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchLostItems();
  }

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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.red))),
    );
  }

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