import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:khuje_nao/activity_feed.dart';
import 'api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage(); // For secure storage
  String email = '';
  String password = '';
  bool rememberMe = false; // Track the "Remember Me" checkbox state

  @override
  void initState() {
    super.initState();
    _checkIfUserRemembered(); // Check if the user has already logged in
  }

  /// Check if email exists in secure storage and redirect if true
  Future<void> _checkIfUserRemembered() async {
    final savedEmail = await _storage.read(key: 'email');
    if (savedEmail != null) {
      // Email exists, redirect to the activity feed
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ActivityFeedPage()),
      );
    }
  }

  /// Show a dialog with a message
  void _showResponseDialog(String messagediag) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(messagediag),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dismiss the dialog
              },
              child: const Text("Okay"),
            ),
          ],
        );
      },
    );
  }

  /// Perform login and handle remember me logic
  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      int response = await apiService.login(email, password);
      switch (response) {
        case -1:
          _showResponseDialog("Invalid email");
          break;
        case -2:
          _showResponseDialog(
              "Invalid password: Must be at least 8 characters and have at least 1 uppercase letter and a number");
          break;
        case -9:
          _showResponseDialog("Login failed.");
          break;
        case 0:
          if (rememberMe) {
            // Save email securely if "Remember Me" is selected
            await _storage.write(key: 'email', value: email);
          }
          _showResponseDialog("Log in Successful");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ActivityFeedPage()),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => setState(() => email = value),
                initialValue: email, // Prepopulate if saved
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) => setState(() => password = value),
                initialValue: password, // Prepopulate if saved
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: const Text("Remember Me"),
                value: rememberMe,
                onChanged: (bool? value) {
                  setState(() {
                    rememberMe = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: login,
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
