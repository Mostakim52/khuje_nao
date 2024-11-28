import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final String baseUrl = 'http://10.0.2.2:5000'; // Replace with your backend URL
  final storage = const FlutterSecureStorage();

  // Method for signing up users
  Future<int> signup(String name, String email, String password, int nsu_id, String phone_number ) async {

    final nameRegExp = RegExp(r"^[a-zA-Z\s]{2,50}$");
    if (!nameRegExp.hasMatch(name)) {
      return-1;
    }
    final emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegExp.hasMatch(email)){
      return -2;
    }
    final passwordRegExp = RegExp(r"^(?=.*[A-Z])(?=.*\d).{8,}$");
    if (!passwordRegExp.hasMatch(password)) {
      return -3;
    }
    final nsuIdRegExp = RegExp(r"^\d{2}[1-3]\d{4}$");
    print("NSU ID:" + nsu_id.toString());
    if (!nsuIdRegExp.hasMatch(nsu_id.toString())) {
      return -4;
    }
    final phoneRegExp = RegExp(r"^(?:\+88|88)?(01[3-9]\d{8})$");
    if (!phoneRegExp.hasMatch(phone_number)) {
      return -5;
    }

    try{
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name.toString(),
          "email": email.toString(),
          "phone_number" : phone_number.toString(),
          "password": password.toString(),
          "nsu_id" : nsu_id.toString()
        }),
      );

      if (response.statusCode == 201) {
        print("User registered successfully!");
        return 0;
      } else {
        print("Signup failed: ${response.body}");
        return -6;
      }
    }
    catch (e){
      print("Signup failed" + e.toString());
      return -6;
    }
  }

  // Method for logging in users
  Future<int> login(String email, String password) async {

    final emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegExp.hasMatch(email)){
      return -1;
    }
    final passwordRegExp = RegExp(r"^(?=.*[A-Z])(?=.*\d).{8,}$");
    if (!passwordRegExp.hasMatch(password)) {
      return -2;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data.toString());
        //String token = data['access_token'];
        //await storage.write(key: "jwt_token", value: token);
        await storage.write(key: "email", value: data["email"]);
        print("Login successful! Token stored.");
        return 0;
      } else {
        print("Login failed: ${response.body}");
        return -9;
      }
    }
    catch(e){
      print("Login failed." + e.toString());
      return -9;
    }
  }

  // Method to log out users by deleting the token
  Future<void> logout() async {
    await storage.delete(key: "jwt_token");
    print("User logged out!");
  }


  Future<bool> reportLostItem({
    required String description,
    required String location,
    required String imagePath,
  }) async {
    try {
      String? email = await storage.read(key: "email");

      if (email == null || email.isEmpty) {
        print('Email not found.');
        return false;
      }
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/lost-items'));
      request.fields['description'] = description;
      request.fields['location'] = location;
      request.fields['reported_by'] = email;
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      print('Email being sent: $email');
      final response = await request.send();

      if (response.statusCode == 201) {
        return true;
      } else {
        // Log server error response
        print('Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error reporting lost item: $e');
      return false;
    }
  }


  Future<void> markItemAsFound(String itemId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lost-items/$itemId/found'),
      );

      if (response.statusCode == 200) {
        print('Item marked as found successfully!');
      } else if (response.statusCode == 404) {
        print('Item not found or already marked as found.');
      } else {
        print('Failed to mark item as found: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> sendEmails() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send_lost_items_email'),
      );

      if (response.statusCode == 200) {
        print('Emails sent successfully!');
      } else if (response.statusCode == 404) {
        print('Failed to send emails.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }


  Future<List<Map<String, dynamic>>> searchLostItems({
    required String query,
  }) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/search-lost-items?query=$query'));
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

  Future<bool> sendOtp(String email) async {
    // Make API call to send OTP
    final response = await http.post(
      Uri.parse('$baseUrl/send_otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    return response.statusCode == 200;
  }

  Future<bool> verifyOtp(String email, String otp) async {
    // Make API call to verify OTP
    final response = await http.post(
      Uri.parse('$baseUrl/verify_otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    return response.statusCode == 200;
  }


}