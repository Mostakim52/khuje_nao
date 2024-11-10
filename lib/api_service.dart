import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final String baseUrl = 'http://127.0.0.1:5000'; // Replace with your backend URL
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
          "name": name,
          "email": email,
          "phone_number" : phone_number,
          "password": password,
          "nsu_id" : nsu_id
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
        String token = data['access_token'];
        await storage.write(key: "jwt_token", value: token);
        await storage.write(key: "user_email", value: email);
        print("Login successful! Token stored.");
        return 0;
      } else {
        print("Login failed: ${response.body}");
        return -9;
      }
    }
    catch(e){
      print("Login failed.");
      return -9;
    }
  }

  // Method to log out users by deleting the token
  Future<void> logout() async {
    await storage.delete(key: "jwt_token");
    print("User logged out!");
  }
}