import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:khuje_nao/api_config.dart';

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
    setState(() {
      is_loading = true;
    });
    
    try {
      final response = await http.get(Uri.parse(ApiConfig.getUrl(ApiConfig.lostItemsAdmin)));
      if (response.statusCode == 200) {
        setState(() {
          lost_items = json.decode(response.body);
          is_loading = false;
        });
      } else {
        setState(() {
          is_loading = false;
        });
        showError('Failed to load items. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        is_loading = false;
      });
      showError('Error: $e');
    }
  }

  /// Approves a specific lost item by sending a POST request to the backend.
  ///
  /// This method takes the item ID, sends a POST request to approve the item, and refreshes
  /// the list of items once the approval is successful.
  Future<void> approveItem(String itemId) async {
    try {
      final response = await http.post(Uri.parse(ApiConfig.getApproveUrl(itemId)));
      if (response.statusCode == 200) {
        showMessage('Item approved successfully.');
        fetchLostItems(); // Refresh the list after approval
      } else {
        final errorBody = json.decode(response.body);
        showError('Failed to approve item: ${errorBody['error'] ?? 'Unknown error'}');
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
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Displays a success message in a snackbar.
  ///
  /// This method is used to show success messages to the user via a snackbar.
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel - Lost Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: fetchLostItems,
          ),
        ],
      ),
      body: is_loading
          ? Center(child: CircularProgressIndicator())
          : lost_items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No items pending approval',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchLostItems,
                  child: ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: lost_items.length,
                    itemBuilder: (context, index) {
                      final item = lost_items[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(12),
                          leading: item['image'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item['image'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.image_not_supported, size: 40);
                                    },
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.image_not_supported, size: 40),
                                ),
                          title: Text(
                            item['description'] ?? 'No description',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Location: ${item['location'] ?? 'Unknown'}',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              if (item['reported_by'] != null) ...[
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.person, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Reported by: ${item['reported_by']}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          trailing: ElevatedButton.icon(
                            onPressed: () => approveItem(item['_id'].toString()),
                            icon: Icon(Icons.check),
                            label: Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}