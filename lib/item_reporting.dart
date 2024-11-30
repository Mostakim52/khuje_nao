import 'dart:convert';
import 'package:http/http.dart' as http;


/// A service class responsible for updating the status of lost items.
class ChangeStatusService {
    // Base URL of Flask backend
    final serverurl = 'http://10.0.2.2:5000';

    /// Updates the `is_found` status of a lost item in the database.
    ///
    /// This function sends a POST request to the backend to mark an item as found.
    /// It requires the item ID to identify the item in the database.
    ///
    /// [itemId] - The ID of the item in the MongoDB database that needs its status updated.
    ///
    /// Returns a `Future<bool>`:
    /// - `true` if the status update was successful (HTTP status 200).
    /// - `false` if the status update failed or an error occurred.
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

      // Checks if the update was successful
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
