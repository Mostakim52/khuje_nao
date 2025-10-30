import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A service class to handle API calls for user authentication, lost items, and email-related tasks.
class ApiService {
  /// Base URL for the backend API.
  final String base_url = 'https://alien-witty-monitor.ngrok-free.app'; // Replace with your backend URL

  /// Instance of [FlutterSecureStorage] to store secure data like tokens.
  final STORAGE = const FlutterSecureStorage();

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Signs up a new user by sending their details to the backend.
  ///
  /// Returns:
  /// - `0` if the signup is successful.
  /// - `-1` to `-5` for input validation errors (name, email, password, NSU ID, phone number).
  /// - `-6` if signup fails due to server issues.
  Future<int> signup(String name, String email, String password, int nsu_id, String phone_number) async {
    // Input validation for various fields
    final nameRegExp = RegExp(r"^[a-zA-Z\s]{2,50}$");
    if (!nameRegExp.hasMatch(name)) {
      return -1;
    }
    final emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegExp.hasMatch(email)) {
      return -2;
    }
    final passwordRegExp = RegExp(r"^(?=.*[A-Z])(?=.*\d).{8,}$");
    if (!passwordRegExp.hasMatch(password)) {
      return -3;
    }
    final nsuIdRegExp = RegExp(r"^\d{2}[1-3]\d{4}$");
    if (!nsuIdRegExp.hasMatch(nsu_id.toString())) {
      return -4;
    }
    final phoneRegExp = RegExp(r"^(?:\+88|88)?(01[3-9]\d{8})$");
    if (!phoneRegExp.hasMatch(phone_number)) {
      return -5;
    }

    try {
      // Sending signup request to the server
      final response = await http.post(
        Uri.parse('$base_url/signup'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "phone_number": phone_number,
          "password": password,
          "nsu_id": nsu_id.toString()
        }),
      );

      if (response.statusCode == 201) {
        print("User registered successfully!");
        return 0;
      } else {
        print("Signup failed: ${response.body}");
        return -6;
      }
    } catch (e) {
      print("Signup failed: $e");
      return -6;
    }
  }

  /// Logs in a user with their email and password.
  ///
  /// Returns:
  /// - `0` if login is successful.
  /// - `-1` or `-2` for validation errors in email or password.
  /// - `-9` for any other login failure.
  Future<int> login(String email, String password) async {
    final emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegExp.hasMatch(email)) {
      return -1;
    }
    final passwordRegExp = RegExp(r"^(?=.*[A-Z])(?=.*\d).{8,}$");
    if (!passwordRegExp.hasMatch(password)) {
      return -2;
    }

    try {
      final response = await http.post(
        Uri.parse('$base_url/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await STORAGE.write(key: "email", value: data["email"]);
        print("Login successful! Token stored.");
        return 0;
      } else {
        print("Login failed: ${response.body}");
        return -9;
      }
    } catch (e) {
      print("Login failed: $e");
      return -9;
    }
  }

  /// Logs out the user by deleting their stored token.
  Future<void> logout() async {
    await STORAGE.delete(key: "jwt_token");
    print("User logged out!");
  }

  /// Reports a lost item by sending its description, location, and image to the backend.
  ///
  /// Returns `true` if the item is reported successfully, otherwise `false`.
  Future<bool> reportLostItem({
    required String description,
    required String location,
    required String imagePath,
  }) async {
    try {
      String? email = await STORAGE.read(key: "email");
      if (email == null || email.isEmpty) {
        print('Email not found.');
        return false;
      }
      var request = http.MultipartRequest('POST', Uri.parse('$base_url/lost-items'));
      request.fields['description'] = description;
      request.fields['location'] = location;
      request.fields['reported_by'] = email;
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      print('Error reporting lost item: $e');
      return false;
    }
  }

  /// Marks an item as found by sending a request to the backend.
  Future<void> markItemAsFound(String itemId) async {
    try {
      final response = await http.post(
        Uri.parse('$base_url/lost-items/$itemId/found'),
      );

      if (response.statusCode == 200) {
        print('Item marked as found successfully!');
      } else {
        print('Failed to mark item as found: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Sends emails related to lost items.
  Future<void> sendEmails() async {
    try {
      final response = await http.post(
        Uri.parse('$base_url/send_lost_items_email'),
      );

      if (response.statusCode == 200) {
        print('Emails sent successfully!');
      } else {
        print('Failed to send emails.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  /// Searches for lost items based on a query string.
  ///
  /// Returns a list of matching items.
  Future<List<Map<String, dynamic>>> searchLostItems({
    required String query,
  }) async {
    try {
      final response = await http.get(Uri.parse('$base_url/search-lost-items?query=$query'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        print('Search failed: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error searching lost items: $e');
      return [];
    }
  }

  /// Sends an OTP to the user's email.
  ///
  /// Returns `true` if the OTP is sent successfully.
  Future<bool> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse('$base_url/send_otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return response.statusCode == 200;
  }

  /// Verifies the OTP entered by the user.
  ///
  /// Returns `true` if the OTP is valid.
  Future<bool> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$base_url/verify_otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return response.statusCode == 200;
  }

  /// Verifies a Firebase Google ID token with the backend for secure login.
  Future<bool> firebaseGoogleLogin(String idToken) async {
    final response = await http.post(
      Uri.parse('$base_url/firebase-google-login'), // Backend endpoint must verify the token
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    if (response.statusCode == 200) {
      // Optionally: store any user/session info returned
      return true;
    }
    return false;
  }

  // Save or update profile fields server-side tied to Firebase uid
  Future<bool> completeProfileWithToken({
    required String token,
    required String name,
    required int nsuId,
    required String phone,
  }) async {
    final res = await http.post(
      Uri.parse('$base_url/profile'),
      headers: _headers(token),
      body: jsonEncode({'name': name, 'nsu_id': nsuId, 'phone': phone}),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // Optional: fetch profile to prefill name/NSU if it already exists
  Future<Map<String, dynamic>?> getProfile(String token) async {
    final res = await http.get(
      Uri.parse('$base_url/profile'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

}
