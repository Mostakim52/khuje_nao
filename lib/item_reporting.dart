import 'dart:convert';
import 'package:http/http.dart' as http;

class ChangeStatusService {
    // Base URL of Flask backend
    final serverurl = 'http://10.0.2.2:5000';

    /// Function to update the `is_found` status of an item
    /// [itemId] - The ID of the item in the MongoDB database
    /// Returns a boolean indicating success or failure
    Future<bool> updateStatus(String itemId) async {
        final url = Uri.parse('$serverurl/lost-items/$itemId/found'); //  endpoint

        try {
        // Sending a POST request to mark the item as found
        final response = await http.post(
            url,
            headers: {
                'Content-Type': 'application/json',
            },
            body: jsonEncode({}),  // Empty body
        );

      // Check if the update was successful
        if (response.statusCode == 200) {
            print("Item marked as found.");
            return true; // Success
        } else {
            print('Failed to update status: ${response.body}');
            return false; // Failure
      }
        } catch (e) {
            print('Error updating status: $e');
            return false; // Failure
        }
    }
}
